package main

import (
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/fs"
	"math"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

var homeDir, _ = os.UserHomeDir()

func expand(path string) string {
	if path == "~" {
		return homeDir
	}
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(homeDir, path[2:])
	}
	return path
}

func output(v any) {
	data, _ := json.Marshal(v)
	fmt.Println(string(data))
}

func run(timeout time.Duration, name string, args ...string) (string, int) {
	cmd := exec.Command(name, args...)
	cmd.Stderr = nil
	if timeout > 0 {
		timer := time.AfterFunc(timeout, func() {
			if cmd.Process != nil {
				_ = cmd.Process.Kill()
			}
		})
		defer timer.Stop()
	}
	out, err := cmd.Output()
	if err != nil {
		if exit, ok := err.(*exec.ExitError); ok {
			return string(out), exit.ExitCode()
		}
		return "", 1
	}
	return string(out), 0
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func readText(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

func readInt(path string) int64 {
	value, _ := strconv.ParseInt(readText(path), 10, 64)
	return value
}

func writeJSONFile(path string, value any) {
	_ = os.MkdirAll(filepath.Dir(path), 0o755)
	data, _ := json.Marshal(value)
	tmp := fmt.Sprintf("%s.tmp.%d", path, os.Getpid())
	if os.WriteFile(tmp, data, 0o644) == nil {
		_ = os.Rename(tmp, path)
	} else {
		_ = os.Remove(tmp)
	}
}

func settingsPath() string { return filepath.Join(homeDir, ".config/quickshell/settings.json") }
func settingsLockPath() string {
	return filepath.Join(homeDir, ".cache/quickshell/settings.json.lock")
}
func wallutilPath() string  { return filepath.Join(homeDir, ".config/wallutil.json") }
func wallCachePath() string { return filepath.Join(homeDir, ".cache/wallutil/cache.json") }
func caffeinePath() string  { return filepath.Join(homeDir, ".cache/quickshell/caffeine.pid") }
func sysCachePath() string  { return filepath.Join(homeDir, ".cache/quickshell/sys-sample.json") }

func lockSettings() *os.File {
	_ = os.MkdirAll(filepath.Dir(settingsLockPath()), 0o755)
	f, err := os.OpenFile(settingsLockPath(), os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil
	}
	if syscall.Flock(int(f.Fd()), syscall.LOCK_EX) != nil {
		_ = f.Close()
		return nil
	}
	return f
}

func unlockSettings(f *os.File) {
	if f == nil {
		return
	}
	_ = syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
	_ = f.Close()
}

func settingsDefaults() map[string]string {
	return map[string]string{
		"themeName":                 "dark",
		"fontFamily":                "Geist Mono",
		"wallpaperDir":              "~/wallpapers/animated",
		"weatherLocation":           "",
		"dynamicAccent":             "#e2e8f0",
		"manualAccent":              "#e2e8f0",
		"manualDark":                "true",
		"caffeineEnabled":           "false",
		"timeFormat":                "24",
		"showSeconds":               "false",
		"language":                  "ru",
		"musicVisualizerEnabled":    "true",
		"uiScale":                   "1.0",
		"reduceMotion":              "false",
		"weatherEnabled":            "true",
		"brightnessMonitorBus":      "auto",
		"brightnessSleepMultiplier": ".2",
		"barPosition":               "top",
		"shellBlurEnabled":          "true",
		"shellBordersEnabled":       "true",
		"shellShadowsEnabled":       "true",
	}
}

func readSettings() map[string]string {
	settings := settingsDefaults()
	data, err := os.ReadFile(settingsPath())
	if err == nil {
		var parsed map[string]string
		if json.Unmarshal(data, &parsed) == nil {
			for key, value := range parsed {
				if _, ok := settings[key]; ok {
					settings[key] = value
				}
			}
		}
	}
	return settings
}

func cmdSettings(args []string) {
	lock := lockSettings()
	settings := readSettings()
	if len(args) >= 3 && args[0] == "set" {
		key, value := args[1], args[2]
		if _, ok := settings[key]; ok {
			settings[key] = value
			writeJSONFile(settingsPath(), settings)
			if key == "wallpaperDir" {
				writeJSONFile(wallutilPath(), map[string]string{"wallDir": value})
			}
		}
	}
	writeJSONFile(settingsPath(), settings)
	unlockSettings(lock)
	applyTheme(settings["themeName"], settings["manualDark"] == "true", settings["reduceMotion"] == "true")
	setCaffeineEnabled(settings["caffeineEnabled"] == "true")
	output(settings)
}

func saveSettingValue(key, value string) map[string]string {
	lock := lockSettings()
	settings := readSettings()
	if _, ok := settings[key]; ok {
		settings[key] = value
		writeJSONFile(settingsPath(), settings)
		if key == "wallpaperDir" {
			writeJSONFile(wallutilPath(), map[string]string{"wallDir": value})
		}
	}
	unlockSettings(lock)
	return settings
}

func applyTheme(theme string, manualDark bool, reduceMotion bool) {
	dark := theme != "light"
	if theme == "manual" {
		dark = manualDark
	}
	gtkTheme := "Adwaita"
	qtScheme := "BreezeLight"
	activeBorder := "rgba(e2e8f060)"
	inactiveBorder := "rgba(46464680)"
	shadow := "rgba(1a1a1aaa)"
	activeOpacity := "0.96"
	inactiveOpacity := "0.90"
	if !dark {
		gtkTheme = "Adwaita"
		qtScheme = "BreezeLight"
		activeBorder = "rgba(0f172aaa)"
		inactiveBorder = "rgba(94a3b870)"
		shadow = "rgba(94a3b870)"
		activeOpacity = "0.94"
		inactiveOpacity = "0.88"
	} else {
		qtScheme = "BreezeDark"
	}

	gtkValue := "0"
	if dark {
		gtkValue = "1"
	}
	gtkContent := fmt.Sprintf("[Settings]\ngtk-theme-name=%s\ngtk-application-prefer-dark-theme=%s\n", gtkTheme, gtkValue)
	for _, path := range []string{filepath.Join(homeDir, ".config/gtk-3.0/settings.ini"), filepath.Join(homeDir, ".config/gtk-4.0/settings.ini")} {
		_ = os.MkdirAll(filepath.Dir(path), 0o755)
		_ = os.WriteFile(path, []byte(gtkContent), 0o644)
	}
	_ = os.MkdirAll(filepath.Join(homeDir, ".config"), 0o755)
	_ = os.WriteFile(filepath.Join(homeDir, ".config/kdeglobals"), []byte(fmt.Sprintf("[General]\nColorScheme=%s\n", qtScheme)), 0o644)
	if commandExists("gsettings") {
		_, _ = run(2*time.Second, "gsettings", "set", "org.gnome.desktop.interface", "color-scheme", map[bool]string{true: "prefer-dark", false: "prefer-light"}[dark])
	}
	if commandExists("hyprctl") {
		commands := [][]string{
			{"keyword", "general:col.active_border", activeBorder},
			{"keyword", "general:col.inactive_border", inactiveBorder},
			{"keyword", "general:border_size", "1"},
			{"keyword", "decoration:rounding", "14"},
			{"keyword", "decoration:active_opacity", activeOpacity},
			{"keyword", "decoration:inactive_opacity", inactiveOpacity},
			{"keyword", "decoration:shadow:color", shadow},
			{"keyword", "decoration:blur:enabled", "true"},
			{"keyword", "decoration:blur:size", "3"},
			{"keyword", "decoration:blur:passes", "1"},
			{"keyword", "animations:enabled", map[bool]string{true: "0", false: "1"}[reduceMotion]},
		}
		for _, args := range commands {
			_, _ = run(2*time.Second, "hyprctl", args...)
		}
	}
}

func cmdFonts() {
	seen := map[string]bool{}
	out, code := run(4*time.Second, "fc-list", ":", "family")
	if code == 0 {
		for _, line := range strings.Split(out, "\n") {
			for _, part := range strings.Split(line, ",") {
				name := strings.TrimSpace(part)
				if name != "" {
					seen[name] = true
				}
			}
		}
	}
	for _, fallback := range []string{"Geist Mono", "JetBrains Mono", "Inter", "Noto Sans", "Cantarell", "Sans Serif"} {
		seen[fallback] = true
	}
	fonts := make([]string, 0, len(seen))
	for name := range seen {
		fonts = append(fonts, name)
	}
	sort.Slice(fonts, func(i, j int) bool { return strings.ToLower(fonts[i]) < strings.ToLower(fonts[j]) })
	output(map[string]any{"ok": true, "fonts": fonts})
}

func cmdI18n(args []string) {
	lang := "ru"
	if len(args) > 0 {
		lang = args[0]
	}
	if !map[string]bool{"ru": true, "en": true, "ja": true, "zh": true, "de": true}[lang] {
		lang = "ru"
	}
	base := filepath.Join(filepath.Dir(os.Args[0]), "..", "translations")
	path := filepath.Clean(filepath.Join(base, lang+".json"))
	data, err := os.ReadFile(path)
	if err != nil && lang != "ru" {
		data, err = os.ReadFile(filepath.Clean(filepath.Join(base, "ru.json")))
	}
	stringsMap := map[string]string{}
	if err == nil {
		_ = json.Unmarshal(data, &stringsMap)
	}
	output(map[string]any{"ok": err == nil, "language": lang, "strings": stringsMap})
}

func cmdPickFolder(args []string) {
	start := homeDir
	if len(args) > 0 && args[0] != "" {
		start = expand(args[0])
	}
	commands := [][]string{
		{"kdialog", "--getexistingdirectory", start},
		{"zenity", "--file-selection", "--directory", "--filename", start + string(os.PathSeparator)},
	}
	for _, command := range commands {
		if !commandExists(command[0]) {
			continue
		}
		out, code := run(0, command[0], command[1:]...)
		path := strings.TrimSpace(out)
		if code == 0 && path != "" {
			output(map[string]any{"ok": true, "path": path})
			return
		}
	}
	output(map[string]any{"ok": false, "path": ""})
}

func parseDesktop(path string) map[string]string {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	inEntry := false
	entry := map[string]string{}
	for _, raw := range strings.Split(string(data), "\n") {
		line := strings.TrimSpace(raw)
		if line == "[Desktop Entry]" {
			inEntry = true
			continue
		}
		if strings.HasPrefix(line, "[") && line != "[Desktop Entry]" {
			inEntry = false
		}
		if !inEntry || line == "" || strings.HasPrefix(line, "#") || !strings.Contains(line, "=") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		entry[parts[0]] = parts[1]
	}
	return entry
}

func cmdAppScanner() {
	type app struct {
		Name      string `json:"name"`
		Icon      string `json:"icon"`
		ExecCmd   string `json:"execCmd"`
		DesktopID string `json:"desktopId"`
	}
	apps := []app{}
	seen := map[string]bool{}
	fieldCode := regexp.MustCompile(`%[fFuUiIcCkKvm%]`)
	for _, dir := range []string{"/usr/share/applications", filepath.Join(homeDir, ".local/share/applications")} {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, entry := range entries {
			if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".desktop") {
				continue
			}
			desktop := parseDesktop(filepath.Join(dir, entry.Name()))
			if desktop == nil || strings.EqualFold(desktop["NoDisplay"], "true") || (desktop["Type"] != "" && desktop["Type"] != "Application") {
				continue
			}
			name := desktop["Name[ru_RU]"]
			if name == "" {
				name = desktop["Name[ru]"]
			}
			if name == "" {
				name = desktop["Name"]
			}
			execCmd := strings.Join(strings.Fields(fieldCode.ReplaceAllString(desktop["Exec"], "")), " ")
			if name == "" || execCmd == "" || seen[name] {
				continue
			}
			seen[name] = true
			apps = append(apps, app{Name: name, Icon: desktop["Icon"], ExecCmd: execCmd, DesktopID: entry.Name()})
		}
	}
	sort.Slice(apps, func(i, j int) bool { return strings.ToLower(apps[i].Name) < strings.ToLower(apps[j].Name) })
	output(apps)
}

func memoryInfo() (float64, float64, int, float64) {
	data, _ := os.ReadFile("/proc/meminfo")
	values := map[string]float64{}
	for _, line := range strings.Split(string(data), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 2 {
			value, _ := strconv.ParseFloat(fields[1], 64)
			values[strings.TrimSuffix(fields[0], ":")] = value
		}
	}
	total := values["MemTotal"] / 1024 / 1024
	avail := values["MemAvailable"] / 1024 / 1024
	used := total - avail
	swapUsed := (values["SwapTotal"] - values["SwapFree"]) / 1024 / 1024
	pct := 0
	if total > 0 {
		pct = int(math.Round(used * 100 / total))
	}
	return math.Round(used*10) / 10, math.Round(total*10) / 10, pct, math.Round(swapUsed*10) / 10
}

func cpuSnapshot() (uint64, uint64) {
	data, _ := os.ReadFile("/proc/stat")
	lines := strings.SplitN(string(data), "\n", 2)
	fields := strings.Fields(lines[0])
	var total, idle uint64
	for i := 1; i < len(fields); i++ {
		value, _ := strconv.ParseUint(fields[i], 10, 64)
		total += value
		if i == 4 || i == 5 {
			idle += value
		}
	}
	return total, idle
}

func netSnapshot() (uint64, uint64) {
	data, _ := os.ReadFile("/proc/net/dev")
	var rx, tx uint64
	for _, line := range strings.Split(string(data), "\n") {
		parts := strings.Split(line, ":")
		if len(parts) != 2 {
			continue
		}
		name := strings.TrimSpace(parts[0])
		if name == "lo" || strings.HasPrefix(name, "veth") || strings.HasPrefix(name, "docker") {
			continue
		}
		fields := strings.Fields(parts[1])
		if len(fields) >= 16 {
			r, _ := strconv.ParseUint(fields[0], 10, 64)
			t, _ := strconv.ParseUint(fields[8], 10, 64)
			rx += r
			tx += t
		}
	}
	return rx, tx
}

func formatBandwidth(bps float64) string {
	if bps >= 10*1024*1024 {
		return fmt.Sprintf("%4.0fM/s", bps/(1024*1024))
	}
	if bps >= 1024*1024 {
		return fmt.Sprintf("%4.1fM/s", bps/(1024*1024))
	}
	if bps >= 1024 {
		return fmt.Sprintf("%4.0fK/s", bps/1024)
	}
	return fmt.Sprintf("%4.0fB/s", bps)
}

func cpuTemp() int {
	for _, label := range []string{"Tdie", "Package id 0", "Tctl"} {
		matches, _ := filepath.Glob("/sys/class/hwmon/hwmon*/temp*_label")
		for _, labelPath := range matches {
			if readText(labelPath) == label {
				value := readInt(strings.TrimSuffix(labelPath, "_label") + "_input")
				if value > 1000 {
					value /= 1000
				}
				if value > 0 && value < 130 {
					return int(value)
				}
			}
		}
	}
	candidates := []string{}
	matches, _ := filepath.Glob("/sys/class/hwmon/hwmon*/temp1_input")
	candidates = append(candidates, matches...)
	_ = filepath.WalkDir("/sys/class/thermal", func(path string, d fs.DirEntry, err error) error {
		if err == nil && !d.IsDir() && d.Name() == "temp" {
			candidates = append(candidates, path)
		}
		return nil
	})
	for _, path := range candidates {
		value := readInt(path)
		if value > 1000 {
			value /= 1000
		}
		if value > 0 && value < 130 {
			return int(value)
		}
	}
	return 0
}

func gpuInfo() map[string]any {
	info := map[string]any{"has": false, "vendor": "none", "load": 0, "temp": 0, "has_vram": false, "vram_used": 0.0, "vram_total": 0.0}
	if commandExists("nvidia-smi") {
		out, code := run(3*time.Second, "nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits")
		if code == 0 {
			line := strings.TrimSpace(strings.Split(out, "\n")[0])
			parts := strings.Split(line, ",")
			if len(parts) >= 4 {
				load, _ := strconv.ParseFloat(strings.TrimSpace(parts[0]), 64)
				temp, _ := strconv.ParseFloat(strings.TrimSpace(parts[1]), 64)
				used, _ := strconv.ParseFloat(strings.TrimSpace(parts[2]), 64)
				total, _ := strconv.ParseFloat(strings.TrimSpace(parts[3]), 64)
				info["has"] = true
				info["vendor"] = "nvidia"
				info["load"] = int(math.Round(load))
				info["temp"] = int(math.Round(temp))
				info["has_vram"] = true
				info["vram_used"] = math.Round((used/1024)*10) / 10
				info["vram_total"] = math.Round((total/1024)*10) / 10
				return info
			}
		}
	}
	devices, _ := filepath.Glob("/sys/class/drm/card*/device")
	for _, dev := range devices {
		if readText(filepath.Join(dev, "vendor")) != "0x1002" || readText(filepath.Join(dev, "gpu_busy_percent")) == "" {
			continue
		}
		load := int(readInt(filepath.Join(dev, "gpu_busy_percent")))
		temp := int64(0)
		if matches, _ := filepath.Glob(filepath.Join(dev, "hwmon/hwmon*/temp1_input")); len(matches) > 0 {
			temp = readInt(matches[0])
			if temp > 1000 {
				temp /= 1000
			}
		}
		vramTotal := readInt(filepath.Join(dev, "mem_info_vram_total"))
		vramUsed := readInt(filepath.Join(dev, "mem_info_vram_used"))
		info["has"] = true
		info["vendor"] = "amd"
		info["load"] = max(0, min(100, load))
		info["temp"] = int(temp)
		info["has_vram"] = vramTotal > 0
		info["vram_used"] = math.Round((float64(vramUsed)/(1024*1024*1024))*10) / 10
		info["vram_total"] = math.Round((float64(vramTotal)/(1024*1024*1024))*10) / 10
		return info
	}
	return info
}

func diskInfo(path string) map[string]any {
	var st syscall.Statfs_t
	if syscall.Statfs(path, &st) != nil {
		return map[string]any{"exists": false}
	}
	total := float64(st.Blocks*uint64(st.Bsize)) / (1024 * 1024 * 1024)
	avail := float64(st.Bavail*uint64(st.Bsize)) / (1024 * 1024 * 1024)
	used := total - avail
	pct := 0
	if total > 0 {
		pct = int(math.Round(used * 100 / total))
	}
	return map[string]any{"exists": true, "used_gb": math.Round(used*10) / 10, "total_gb": math.Round(total*10) / 10, "percent": pct}
}

func uptimeText() string {
	fields := strings.Fields(readText("/proc/uptime"))
	if len(fields) == 0 {
		return "0м"
	}
	secondsF, _ := strconv.ParseFloat(fields[0], 64)
	seconds := int(secondsF)
	days := seconds / 86400
	hours := (seconds % 86400) / 3600
	minutes := (seconds % 3600) / 60
	if days > 0 {
		return fmt.Sprintf("%dд %dч", days, hours)
	}
	if hours > 0 {
		return fmt.Sprintf("%dч %dм", hours, minutes)
	}
	return fmt.Sprintf("%dм", minutes)
}

func uptimeSysmonText() string {
	fields := strings.Fields(readText("/proc/uptime"))
	if len(fields) == 0 {
		return "UP 0D 00:00"
	}
	secondsF, _ := strconv.ParseFloat(fields[0], 64)
	seconds := int(secondsF)
	days := seconds / 86400
	hours := (seconds % 86400) / 3600
	minutes := (seconds % 3600) / 60
	return fmt.Sprintf("UP %dD %02d:%02d", days, hours, minutes)
}

type sysSample struct {
	CpuTotal int64 `json:"cpu_total"`
	CpuIdle  int64 `json:"cpu_idle"`
	Rx       int64 `json:"rx"`
	Tx       int64 `json:"tx"`
	UnixNano int64 `json:"unix_nano"`
	Cpu      int   `json:"cpu"`
	RxBps    int64 `json:"rx_bps"`
	TxBps    int64 `json:"tx_bps"`
}

func readSysSample() sysSample {
	var sample sysSample
	data, err := os.ReadFile(sysCachePath())
	if err == nil {
		_ = json.Unmarshal(data, &sample)
	}
	return sample
}

func cmdSys() {
	total, idle := cpuSnapshot()
	rx, tx := netSnapshot()
	now := time.Now()
	prev := readSysSample()
	elapsed := float64(now.UnixNano()-prev.UnixNano) / float64(time.Second)
	cpu := prev.Cpu
	rxBps, txBps := float64(prev.RxBps), float64(prev.TxBps)
	if prev.UnixNano == 0 || elapsed >= 0.7 || elapsed < 0 || elapsed > 30 {
		dt, di := float64(0), float64(0)
		if prev.CpuTotal > 0 && int64(total) >= prev.CpuTotal && int64(idle) >= prev.CpuIdle {
			dt = float64(int64(total) - prev.CpuTotal)
			di = float64(int64(idle) - prev.CpuIdle)
		}
		cpu = 0
		if dt > 0 && di >= 0 && di <= dt {
			cpu = int(math.Round((dt - di) * 100 / dt))
		}
		rxBps, txBps = 0, 0
		if elapsed > 0 && elapsed < 30 && int64(rx) >= prev.Rx && int64(tx) >= prev.Tx {
			rxBps = float64(int64(rx)-prev.Rx) / elapsed
			txBps = float64(int64(tx)-prev.Tx) / elapsed
		}
		writeJSONFile(sysCachePath(), sysSample{CpuTotal: int64(total), CpuIdle: int64(idle), Rx: int64(rx), Tx: int64(tx), UnixNano: now.UnixNano(), Cpu: cpu, RxBps: int64(math.Round(rxBps)), TxBps: int64(math.Round(txBps))})
	}
	ramUsed, ramTotal, ramPct, swapUsed := memoryInfo()
	load := 0.0
	if fields := strings.Fields(readText("/proc/loadavg")); len(fields) > 0 {
		load, _ = strconv.ParseFloat(fields[0], 64)
	}
	output(map[string]any{
		"cpu": cpu, "cpu_temp": cpuTemp(), "load1": math.Round(load*100) / 100, "uptime": uptimeText(), "uptime_sysmon": uptimeSysmonText(),
		"ram_used": ramUsed, "ram_total": ramTotal, "ram_pct": ramPct, "swap_used": swapUsed,
		"net_rx": formatBandwidth(rxBps), "net_tx": formatBandwidth(txBps), "net_rx_bps": math.Round(rxBps), "net_tx_bps": math.Round(txBps),
		"root_disk": diskInfo("/"), "storage_disk": diskInfo("/mnt/storage"), "gpu": gpuInfo(),
	})
}

func cmdNet() {
	out, code := run(4*time.Second, "nmcli", "-t", "-f", "TYPE,STATE,DEVICE", "device")
	state := map[string]bool{"wifi": false, "eth": false, "connecting": false}
	if code == 0 {
		for _, line := range strings.Split(out, "\n") {
			parts := strings.Split(line, ":")
			if len(parts) < 2 {
				continue
			}
			typ, status := parts[0], parts[1]
			dev := ""
			if len(parts) > 2 {
				dev = parts[2]
			}
			if typ == "wifi" && status == "connected" {
				state["wifi"] = true
			}
			if typ == "ethernet" && status == "connected" && !strings.HasPrefix(dev, "veth") {
				state["eth"] = true
			}
			if strings.Contains(status, "connecting") {
				state["connecting"] = true
			}
		}
	}
	output(state)
}

func batteryDir() string {
	entries, _ := os.ReadDir("/sys/class/power_supply")
	sort.Slice(entries, func(i, j int) bool { return entries[i].Name() < entries[j].Name() })
	for _, entry := range entries {
		path := filepath.Join("/sys/class/power_supply", entry.Name())
		if strings.EqualFold(readText(filepath.Join(path, "type")), "battery") {
			return path
		}
	}
	return ""
}

func acOnline() bool {
	entries, _ := os.ReadDir("/sys/class/power_supply")
	for _, entry := range entries {
		path := filepath.Join("/sys/class/power_supply", entry.Name())
		typ := strings.ToLower(readText(filepath.Join(path, "type")))
		if (typ == "mains" || typ == "usb" || typ == "usb_c") && readInt(filepath.Join(path, "online")) == 1 {
			return true
		}
	}
	return false
}

func wh(value int64) float64 { return math.Round(float64(value)/1000000*100) / 100 }

func profileState() string {
	out, code := run(3*time.Second, "powerprofilesctl", "get")
	if code != 0 || strings.TrimSpace(out) == "" {
		return "balanced"
	}
	return strings.TrimSpace(out)
}

func cmdBattery(args []string) {
	if len(args) >= 2 && args[0] == "set-profile" {
		_, _ = run(4*time.Second, "powerprofilesctl", "set", args[1])
	}
	bat := batteryDir()
	if bat == "" {
		output(map[string]any{"ok": false, "percentage": 0, "status": "Unknown", "charging": false, "profile": profileState()})
		return
	}
	percentage := int(readInt(filepath.Join(bat, "capacity")))
	status := readText(filepath.Join(bat, "status"))
	energyNow := readInt(filepath.Join(bat, "energy_now"))
	energyFull := readInt(filepath.Join(bat, "energy_full"))
	energyDesign := readInt(filepath.Join(bat, "energy_full_design"))
	powerNow := readInt(filepath.Join(bat, "power_now"))
	if energyNow == 0 {
		energyNow = readInt(filepath.Join(bat, "charge_now"))
		energyFull = readInt(filepath.Join(bat, "charge_full"))
		energyDesign = readInt(filepath.Join(bat, "charge_full_design"))
	}
	charging := strings.EqualFold(status, "Charging") || (strings.EqualFold(status, "Full") && acOnline())
	capacity := percentage
	if energyDesign > 0 && energyFull > 0 {
		capacity = int(math.Round(float64(energyFull) * 100 / float64(energyDesign)))
	}
	hours := 0.0
	if powerNow > 0 {
		if strings.EqualFold(status, "Charging") {
			hours = math.Max(0, float64(energyFull-energyNow)/float64(powerNow))
		} else {
			hours = math.Max(0, float64(energyNow)/float64(powerNow))
		}
	}
	output(map[string]any{"ok": true, "nativePath": filepath.Base(bat), "percentage": percentage, "status": status, "charging": charging, "online": acOnline(), "rate": wh(powerNow), "capacity": capacity, "energyNow": wh(energyNow), "energyFull": wh(energyFull), "timeHours": math.Round(hours*100) / 100, "profile": profileState()})
}

func brightnessResult(ok bool, brightness int, backend, bus, device, errText string) {
	p := map[string]any{"ok": ok}
	if brightness >= 0 {
		p["brightness"] = max(0, min(100, brightness))
	}
	if backend != "" {
		p["backend"] = backend
	}
	if bus != "" {
		p["bus"] = bus
	}
	if device != "" {
		p["device"] = device
	}
	if errText != "" {
		p["error"] = errText
	}
	output(p)
}

func brightnessGet(preferred string) (int, string, string, bool) {
	if commandExists("brightnessctl") {
		cur, c1 := run(4*time.Second, "brightnessctl", "g")
		maxv, c2 := run(4*time.Second, "brightnessctl", "m")
		if c1 == 0 && c2 == 0 {
			c, _ := strconv.Atoi(strings.TrimSpace(cur))
			m, _ := strconv.Atoi(strings.TrimSpace(maxv))
			if m > 0 {
				return int(math.Round(float64(c) * 100 / float64(m))), "brightnessctl", "", true
			}
		}
	}
	if commandExists("light") {
		out, code := run(4*time.Second, "light", "-G")
		if code == 0 {
			v, _ := strconv.ParseFloat(strings.TrimSpace(out), 64)
			return int(math.Round(v)), "light", "", true
		}
	}
	entries, _ := os.ReadDir("/sys/class/backlight")
	for _, entry := range entries {
		path := filepath.Join("/sys/class/backlight", entry.Name())
		cur := readInt(filepath.Join(path, "brightness"))
		maxv := readInt(filepath.Join(path, "max_brightness"))
		if maxv > 0 {
			return int(math.Round(float64(cur) * 100 / float64(maxv))), "sysfs", entry.Name(), true
		}
	}
	return 0, "", "", false
}

func brightnessSet(value int, preferred string) (int, string, string, bool) {
	value = max(0, min(100, value))
	if commandExists("brightnessctl") {
		_, code := run(5*time.Second, "brightnessctl", "set", fmt.Sprintf("%d%%", value))
		if code == 0 {
			return value, "brightnessctl", "", true
		}
	}
	if commandExists("light") {
		_, code := run(5*time.Second, "light", "-S", strconv.Itoa(value))
		if code == 0 {
			return value, "light", "", true
		}
	}
	for _, entry := range mustReadDir("/sys/class/backlight") {
		path := filepath.Join("/sys/class/backlight", entry.Name())
		maxv := readInt(filepath.Join(path, "max_brightness"))
		if maxv <= 0 {
			continue
		}
		raw := int(math.Round(float64(maxv) * float64(value) / 100))
		if value > 0 && raw == 0 {
			raw = 1
		}
		_, code := run(4*time.Second, "busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "SetBrightness", "ssu", "backlight", entry.Name(), strconv.Itoa(raw))
		if code == 0 {
			return value, "logind", entry.Name(), true
		}
	}
	return value, "", "", false
}

func mustReadDir(path string) []fs.DirEntry { entries, _ := os.ReadDir(path); return entries }

func cmdBrightness(args []string) {
	action := "get"
	if len(args) > 0 {
		action = args[0]
	}
	bus := "auto"
	if len(args) > 2 {
		bus = args[2]
	} else if len(args) > 1 {
		bus = args[1]
	}
	if action == "set" && len(args) > 1 {
		value, _ := strconv.Atoi(args[1])
		v, backend, device, ok := brightnessSet(value, bus)
		brightnessResult(ok, v, backend, "", device, "")
		return
	}
	if action == "adjust" && len(args) > 1 {
		delta, _ := strconv.Atoi(args[1])
		cur, _, device, ok := brightnessGet(bus)
		if ok {
			v, backend, dev, ok2 := brightnessSet(cur+delta, device)
			brightnessResult(ok2, v, backend, "", dev, "")
			return
		}
	}
	v, backend, device, ok := brightnessGet(bus)
	brightnessResult(ok, v, backend, "", device, "No brightness backend found")
}

func intNumber(value any) int {
	switch v := value.(type) {
	case float64:
		return int(v)
	case int:
		return v
	case json.Number:
		n, _ := v.Int64()
		return int(n)
	default:
		return 0
	}
}

type keyboardLayout struct {
	Index  int    `json:"index"`
	Layout string `json:"layout"`
	Name   string `json:"name"`
	Active bool   `json:"active"`
}

func keyboardShortName(active string) string {
	lower := strings.ToLower(active)
	if strings.Contains(lower, "russian") || lower == "ru" || lower == "rus" {
		return "RU"
	}
	if strings.Contains(lower, "english") || strings.Contains(lower, "us") || lower == "en" {
		return "EN"
	}
	if active != "" {
		runes := []rune(active)
		return strings.ToUpper(string(runes[0:min(2, len(runes))]))
	}
	return "??"
}

func keyboardLayoutName(code string) string {
	switch strings.ToLower(strings.TrimSpace(code)) {
	case "us", "en":
		return "English"
	case "ru", "rus":
		return "Russian"
	default:
		if code == "" {
			return "Unknown"
		}
		return strings.ToUpper(code)
	}
}

func keyboardState() (string, int, []keyboardLayout, bool) {
	out, code := run(3*time.Second, "hyprctl", "devices", "-j")
	if code != 0 {
		return "", 0, nil, false
	}
	var parsed struct {
		Keyboards []map[string]any `json:"keyboards"`
	}
	_ = json.Unmarshal([]byte(out), &parsed)
	active := ""
	activeIndex := 0
	selected := map[string]any(nil)
	for _, kbd := range parsed.Keyboards {
		if main, _ := kbd["main"].(bool); main {
			selected = kbd
			active, _ = kbd["active_keymap"].(string)
			activeIndex = intNumber(kbd["active_layout_index"])
			break
		}
	}
	if active == "" && len(parsed.Keyboards) > 0 {
		selected = parsed.Keyboards[0]
		active, _ = parsed.Keyboards[0]["active_keymap"].(string)
		activeIndex = intNumber(parsed.Keyboards[0]["active_layout_index"])
	}
	layouts := []keyboardLayout{}
	if selected != nil {
		layoutValue, _ := selected["layout"].(string)
		for index, code := range strings.Split(layoutValue, ",") {
			code = strings.TrimSpace(code)
			if code == "" {
				continue
			}
			name := keyboardLayoutName(code)
			if index == activeIndex && active != "" {
				name = active
			}
			layouts = append(layouts, keyboardLayout{Index: index, Layout: keyboardShortName(name), Name: name, Active: index == activeIndex})
		}
	}
	return active, activeIndex, layouts, active != ""
}

func cmdKeyboard(args []string) {
	active, activeIndex, layouts, ok := keyboardState()
	if len(args) > 0 && args[0] == "next" && ok {
		target := 0
		if len(layouts) > 0 {
			target = (activeIndex + 1) % len(layouts)
		} else if activeIndex == 0 {
			target = 1
		}
		_, _ = run(3*time.Second, "hyprctl", "switchxkblayout", "all", strconv.Itoa(target))
		active, activeIndex, layouts, ok = keyboardState()
	} else if len(args) > 1 && args[0] == "set" && ok {
		target, err := strconv.Atoi(args[1])
		if err == nil && target >= 0 {
			_, _ = run(3*time.Second, "hyprctl", "switchxkblayout", "all", strconv.Itoa(target))
			active, activeIndex, layouts, ok = keyboardState()
		}
	}
	if !ok {
		output(map[string]any{"ok": false, "layout": "??", "name": "Unknown", "index": 0, "layouts": []keyboardLayout{}})
		return
	}
	output(map[string]any{"ok": active != "", "layout": keyboardShortName(active), "name": active, "index": activeIndex, "layouts": layouts})
}

func cmdCaffeine(args []string) {
	action := "state"
	if len(args) > 0 {
		action = args[0]
	}
	running := caffeineRunning()
	if action == "toggle" {
		action = map[bool]string{true: "off", false: "on"}[running]
	}
	if action == "on" {
		running = setCaffeineEnabled(true)
		_ = saveSettingValue("caffeineEnabled", map[bool]string{true: "true", false: "false"}[running])
	} else if action == "off" {
		running = setCaffeineEnabled(false)
		_ = saveSettingValue("caffeineEnabled", "false")
	}
	output(map[string]any{"ok": true, "enabled": running})
}

func caffeineRunning() bool {
	pidText := readText(caffeinePath())
	pid, _ := strconv.Atoi(pidText)
	running := pid > 0 && syscall.Kill(pid, 0) == nil
	if !running && pidText != "" {
		_ = os.Remove(caffeinePath())
	}
	return running
}

func setCaffeineEnabled(enabled bool) bool {
	running := caffeineRunning()
	if enabled && !running {
		_ = os.MkdirAll(filepath.Dir(caffeinePath()), 0o755)
		cmd := exec.Command("systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=quickshell", "--why=Caffeine", "sleep", "infinity")
		if commandExists("systemd-inhibit") && cmd.Start() == nil {
			_ = os.WriteFile(caffeinePath(), []byte(strconv.Itoa(cmd.Process.Pid)), 0o644)
			running = true
		}
	}
	if !enabled && running {
		pidText := readText(caffeinePath())
		pid, _ := strconv.Atoi(pidText)
		_ = syscall.Kill(pid, syscall.SIGTERM)
		_ = os.Remove(caffeinePath())
		running = false
	}
	return running
}

func cmdAudio(args []string) {
	action := "get"
	if len(args) > 0 {
		action = args[0]
	}
	if len(args) > 1 && action != "get" {
		value := args[1]
		switch action {
		case "set-sink-volume":
			run(4*time.Second, "pactl", "set-sink-volume", "@DEFAULT_SINK@", value+"%")
		case "set-source-volume":
			run(4*time.Second, "pactl", "set-source-volume", "@DEFAULT_SOURCE@", value+"%")
		case "set-sink-mute":
			run(4*time.Second, "pactl", "set-sink-mute", "@DEFAULT_SINK@", value)
		case "set-source-mute":
			run(4*time.Second, "pactl", "set-source-mute", "@DEFAULT_SOURCE@", value)
		case "set-default-sink":
			run(4*time.Second, "pactl", "set-default-sink", value)
		case "set-default-source":
			run(4*time.Second, "pactl", "set-default-source", value)
		}
	}
	infoRaw, _ := run(4*time.Second, "pactl", "-f", "json", "info")
	var info map[string]any
	_ = json.Unmarshal([]byte(infoRaw), &info)
	defaultSink, _ := info["default_sink_name"].(string)
	defaultSource, _ := info["default_source_name"].(string)
	sinks := audioDevices("sinks", defaultSink, false)
	sources := audioDevices("sources", defaultSource, true)
	sinkVol, sinkMuted := selectedAudioState(sinks)
	sourceVol, sourceMuted := selectedAudioState(sources)
	output(map[string]any{"ok": true, "defaultSink": defaultSink, "defaultSource": defaultSource, "sinkVolume": sinkVol, "sinkMuted": sinkMuted, "sourceVolume": sourceVol, "sourceMuted": sourceMuted, "sinks": sinks, "sources": sources})
}

func firstPercent(text string) int {
	re := regexp.MustCompile(`(\d+)%`)
	m := re.FindStringSubmatch(text)
	if len(m) > 1 {
		v, _ := strconv.Atoi(m[1])
		return v
	}
	return 0
}

func audioDevices(kind, defaultName string, skipMonitors bool) []map[string]any {
	out, code := run(5*time.Second, "pactl", "-f", "json", "list", kind)
	if code != 0 {
		return []map[string]any{}
	}
	var raw []map[string]any
	if json.Unmarshal([]byte(out), &raw) != nil {
		return []map[string]any{}
	}
	items := []map[string]any{}
	for _, item := range raw {
		name, _ := item["name"].(string)
		props, _ := item["properties"].(map[string]any)
		if skipMonitors && (strings.HasSuffix(name, ".monitor") || stringProp(props, "device.class") == "monitor") {
			continue
		}
		desc, _ := item["description"].(string)
		if desc == "" || desc == "(null)" {
			desc = firstNonEmpty(stringProp(props, "node.description"), stringProp(props, "node.nick"), stringProp(props, "device.description"), name)
		}
		items = append(items, map[string]any{"index": item["index"], "name": name, "description": desc, "volume": volumePercent(item["volume"]), "muted": item["mute"] == true, "isDefault": name == defaultName})
	}
	return items
}

func selectedAudioState(items []map[string]any) (int, bool) {
	if len(items) == 0 {
		return 0, false
	}
	selected := items[0]
	for _, item := range items {
		if item["isDefault"] == true {
			selected = item
			break
		}
	}
	vol, _ := selected["volume"].(int)
	muted, _ := selected["muted"].(bool)
	return vol, muted
}

func stringProp(props map[string]any, key string) string {
	if props == nil {
		return ""
	}
	value, _ := props[key].(string)
	return value
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return "Audio device"
}

func volumePercent(value any) int {
	channels, _ := value.(map[string]any)
	if len(channels) == 0 {
		return 0
	}
	total := 0
	count := 0
	for _, channel := range channels {
		m, _ := channel.(map[string]any)
		percent, _ := m["value_percent"].(string)
		if percent != "" {
			total += firstPercent(percent)
			count++
		}
	}
	if count == 0 {
		return 0
	}
	return int(math.Round(float64(total) / float64(count)))
}

var imageExt = map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".bmp": true, ".gif": true}
var videoExt = map[string]bool{".mp4": true, ".mkv": true, ".webm": true, ".mov": true, ".avi": true}

func wallDir(override string) string {
	if override != "" {
		return expand(override)
	}
	var data map[string]string
	if raw, err := os.ReadFile(wallutilPath()); err == nil && json.Unmarshal(raw, &data) == nil {
		return expand(data["wallDir"])
	}
	return expand("~/wallpapers/animated")
}

func wallItems(dir string) []string {
	entries, _ := os.ReadDir(dir)
	items := []string{}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(entry.Name()))
		if imageExt[ext] || videoExt[ext] {
			items = append(items, filepath.Join(dir, entry.Name()))
		}
	}
	sort.Strings(items)
	return items
}

func cacheIndex(total int) int {
	var data map[string]int
	raw, _ := os.ReadFile(wallCachePath())
	_ = json.Unmarshal(raw, &data)
	idx := data["wallIndex"]
	if total <= 0 {
		return 0
	}
	if idx < 0 {
		return 0
	}
	if idx >= total {
		return total - 1
	}
	return idx
}

func fileURI(path string) string { u := url.URL{Scheme: "file", Path: path}; return u.String() }

func thumbPath(path string) string {
	sum := sha1.Sum([]byte(path))
	return filepath.Join(homeDir, ".cache/quickshell/wallpaper-thumbs", hex.EncodeToString(sum[:])[:16]+".jpg")
}

func makeThumb(path string) string {
	if path == "" {
		return ""
	}
	ext := strings.ToLower(filepath.Ext(path))
	target := thumbPath(path)
	_ = os.MkdirAll(filepath.Dir(target), 0o755)
	if st, err := os.Stat(target); err == nil {
		if src, err2 := os.Stat(path); err2 == nil && st.ModTime().After(src.ModTime()) {
			return fileURI(target)
		}
	}
	if imageExt[ext] && commandExists("magick") {
		if _, code := run(8*time.Second, "magick", path, "-auto-orient", "-thumbnail", "360x220^", "-gravity", "center", "-extent", "360x220", target); code == 0 {
			return fileURI(target)
		}
	}
	if videoExt[ext] && commandExists("ffmpeg") {
		if _, code := run(8*time.Second, "ffmpeg", "-y", "-loglevel", "error", "-ss", "00:00:01", "-i", path, "-frames:v", "1", "-vf", "scale=360:-1", target); code == 0 {
			return fileURI(target)
		}
	}
	if imageExt[ext] {
		return fileURI(path)
	}
	return ""
}

func palette(path string) []string {
	if path == "" || !imageExt[strings.ToLower(filepath.Ext(path))] || !commandExists("magick") {
		return []string{}
	}
	out, code := run(4*time.Second, "magick", path, "-resize", "6x1!", "-depth", "8", "txt:-")
	if code != 0 {
		return []string{}
	}
	seen := map[string]bool{}
	colors := []string{}
	re := regexp.MustCompile(`#([0-9A-Fa-f]{6})`)
	for _, m := range re.FindAllStringSubmatch(out, -1) {
		c := "#" + m[1]
		if !seen[c] {
			seen[c] = true
			colors = append(colors, c)
		}
		if len(colors) >= 6 {
			break
		}
	}
	return colors
}

func applyWall(path string) {
	if commandExists("awww-daemon") {
		_ = exec.Command("awww-daemon").Start()
	}
	if commandExists("awww") {
		if _, code := run(5*time.Second, "awww", "img", path); code == 0 {
			return
		}
		run(5*time.Second, "awww", path)
	}
}

func wallState(override string) {
	dir := wallDir(override)
	items := wallItems(dir)
	idx := cacheIndex(len(items))
	current := ""
	if len(items) > 0 {
		current = items[idx]
	}
	list := []map[string]any{}
	for i, item := range items {
		list = append(list, map[string]any{"wallIndex": i, "name": filepath.Base(item), "path": item, "thumbnail": makeThumb(item)})
	}
	name := "Нет обоев"
	if current != "" {
		name = filepath.Base(current)
	}
	output(map[string]any{"ok": current != "", "path": current, "name": name, "thumbnail": makeThumb(current), "palette": palette(current), "count": len(items), "index": idx, "items": list})
}

func cmdWallpaper(args []string) {
	action := "get"
	if len(args) > 0 {
		action = args[0]
	}
	if action == "config" && len(args) > 1 {
		writeJSONFile(wallutilPath(), map[string]string{"wallDir": args[1]})
		wallState(args[1])
		return
	}
	override := ""
	if len(args) > 1 && (action == "get" || action == "next") {
		override = args[1]
	}
	if action == "set" && len(args) > 2 {
		override = args[2]
	}
	items := wallItems(wallDir(override))
	idx := cacheIndex(len(items))
	if action == "next" && len(items) > 0 {
		idx = (idx + 1) % len(items)
		writeJSONFile(wallCachePath(), map[string]int{"wallIndex": idx})
		applyWall(items[idx])
	}
	if action == "apply" && len(items) > 0 {
		applyWall(items[idx])
	}
	if action == "set" && len(args) > 1 && len(items) > 0 {
		idx, _ = strconv.Atoi(args[1])
		if idx < 0 {
			idx = 0
		}
		if idx >= len(items) {
			idx = len(items) - 1
		}
		writeJSONFile(wallCachePath(), map[string]int{"wallIndex": idx})
		applyWall(items[idx])
	}
	wallState(override)
}

func main() {
	if len(os.Args) < 2 {
		output(map[string]any{"ok": false, "error": "missing command"})
		return
	}
	cmd, args := os.Args[1], os.Args[2:]
	switch cmd {
	case "app-scanner":
		cmdAppScanner()
	case "audio":
		cmdAudio(args)
	case "battery":
		cmdBattery(args)
	case "brightness":
		cmdBrightness(args)
	case "caffeine":
		cmdCaffeine(args)
	case "fonts":
		cmdFonts()
	case "i18n":
		cmdI18n(args)
	case "keyboard":
		cmdKeyboard(args)
	case "net":
		cmdNet()
	case "pick-folder":
		cmdPickFolder(args)
	case "settings":
		cmdSettings(args)
	case "sys":
		cmdSys()
	case "wallpaper":
		cmdWallpaper(args)
	default:
		output(map[string]any{"ok": false, "error": "unknown command"})
	}
}
