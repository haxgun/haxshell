package natonctl

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// presetThemes are the 16-color ANSI palettes ported from aether
// (frontend/src/lib/constants/colors.ts). Slot 0 = background,
// 7 = foreground, 8 = dim, 1-6 = accent hues.
type presetTheme struct {
	Name   string     `json:"name"`
	Colors [16]string `json:"colors"`
	Accent string     `json:"accent,omitempty"` // optional explicit accent override (not ANSI red)
}

var presetThemes = []presetTheme{
	{Name: "Aether", Colors: [16]string{
		"#141114",
		"#ff637e",
		"#b4e173",
		"#ffd568",
		"#ff9b66",
		"#c09ef5",
		"#76ecdb",
		"#ffffff",
		"#766974",
		"#ff637e",
		"#b4e173",
		"#ffd568",
		"#ff9b66",
		"#c09ef5",
		"#76ecdb",
		"#ffffff",
	}},
	{Name: "Catppuccin Mocha", Colors: [16]string{
		"#1e1e2e",
		"#f38ba8",
		"#a6e3a1",
		"#f9e2af",
		"#89b4fa",
		"#cba6f7",
		"#94e2d5",
		"#cdd6f4",
		"#45475a",
		"#f38ba8",
		"#a6e3a1",
		"#f9e2af",
		"#89b4fa",
		"#cba6f7",
		"#94e2d5",
		"#bac2de",
	}},
	{Name: "Dracula", Colors: [16]string{
		"#282a36",
		"#ff5555",
		"#50fa7b",
		"#f1fa8c",
		"#bd93f9",
		"#ff79c6",
		"#8be9fd",
		"#f8f8f2",
		"#6272a4",
		"#ff6e6e",
		"#69ff94",
		"#ffffa5",
		"#d6acff",
		"#ff92df",
		"#a4ffff",
		"#ffffff",
	}},
	{Name: "Gruvbox Dark", Colors: [16]string{
		"#282828",
		"#cc241d",
		"#98971a",
		"#d79921",
		"#458588",
		"#b16286",
		"#689d6a",
		"#ebdbb2",
		"#928374",
		"#fb4934",
		"#b8bb26",
		"#fabd2f",
		"#83a598",
		"#d3869b",
		"#8ec07c",
		"#fbf1c7",
	}},
	{Name: "Nord", Colors: [16]string{
		"#2e3440",
		"#bf616a",
		"#a3be8c",
		"#ebcb8b",
		"#81a1c1",
		"#b48ead",
		"#88c0d0",
		"#e5e9f0",
		"#4c566a",
		"#d08770",
		"#a3be8c",
		"#ebcb8b",
		"#81a1c1",
		"#b48ead",
		"#8fbcbb",
		"#eceff4",
	}},
	{Name: "Tokyo Night", Colors: [16]string{
		"#1a1b26",
		"#f7768e",
		"#9ece6a",
		"#e0af68",
		"#7aa2f7",
		"#bb9af7",
		"#7dcfff",
		"#a9b1d6",
		"#414868",
		"#f7768e",
		"#9ece6a",
		"#e0af68",
		"#7aa2f7",
		"#bb9af7",
		"#7dcfff",
		"#c0caf5",
	}},
}

// themeInfo is the unified semantic theme shape served to the shell. Built-in
// ANSI presets are expanded into it; user JSON themes are normalized into it.
// Accent is explicit and independent from the ANSI red slot, so a theme can
// carry a blue accent while red stays reserved for danger/status colors.
type themeInfo struct {
	Name             string     `json:"name"`
	Mode             string     `json:"mode"`
	Accent           string     `json:"accent"`
	Background       string     `json:"background"`
	Foreground       string     `json:"foreground"`
	Layer            string     `json:"layer"`
	Selection        string     `json:"selection"`
	Muted            string     `json:"muted"`
	Red              string     `json:"red"`
	Green            string     `json:"green"`
	Yellow           string     `json:"yellow"`
	Blue             string     `json:"blue"`
	Magenta          string     `json:"magenta"`
	Cyan             string     `json:"cyan"`
	BrightRed        string     `json:"brightRed"`
	BrightGreen      string     `json:"brightGreen"`
	BrightYellow     string     `json:"brightYellow"`
	BrightBlue       string     `json:"brightBlue"`
	BrightMagenta    string     `json:"brightMagenta"`
	BrightCyan       string     `json:"brightCyan"`
	BrightForeground string     `json:"brightForeground"`
	Colors           [16]string `json:"colors"`
	File             string     `json:"file,omitempty"`
}

func isHexColor(s string) bool {
	if len(s) != 7 || s[0] != '#' {
		return false
	}
	for i := 1; i < len(s); i++ {
		c := s[i]
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F') {
			return false
		}
	}
	return true
}

func upperHex(s string) string {
	if !isHexColor(s) {
		return ""
	}
	return strings.ToUpper(s)
}

func hexLuminance(hex string) float64 {
	r, _ := strconv.ParseInt(hex[1:3], 16, 64)
	g, _ := strconv.ParseInt(hex[3:5], 16, 64)
	b, _ := strconv.ParseInt(hex[5:7], 16, 64)
	return (0.2126*float64(r) + 0.7152*float64(g) + 0.0722*float64(b)) / 255
}

func themeFromBuiltin(p presetTheme) themeInfo {
	c := p.Colors
	mode := "dark"
	if hexLuminance(c[0]) > 0.52 {
		mode = "light"
	}
	accent := upperHex(p.Accent)
	if accent == "" {
		accent = c[1]
	}
	return themeInfo{
		Name:             p.Name,
		Mode:             mode,
		Accent:           accent,
		Background:       c[0],
		Foreground:       c[7],
		Layer:            c[8],
		Selection:        c[8],
		Muted:            c[8],
		Red:              c[1],
		Green:            c[2],
		Yellow:           c[3],
		Blue:             c[4],
		Magenta:          c[5],
		Cyan:             c[6],
		BrightRed:        c[9],
		BrightGreen:      c[10],
		BrightYellow:     c[11],
		BrightBlue:       c[12],
		BrightMagenta:    c[13],
		BrightCyan:       c[14],
		BrightForeground: c[15],
		Colors:           c,
	}
}

// userTheme is the JSON schema for a theme file in ~/.config/quickshell/presets/.
// Only name, background and foreground are required; everything else falls back
// to the colors array or is derived.
type userTheme struct {
	Name             string   `json:"name"`
	Mode             string   `json:"mode"`
	Accent           string   `json:"accent"`
	Background       string   `json:"background"`
	Foreground       string   `json:"foreground"`
	Layer            string   `json:"layer"`
	Selection        string   `json:"selection"`
	Muted            string   `json:"muted"`
	Red              string   `json:"red"`
	Green            string   `json:"green"`
	Yellow           string   `json:"yellow"`
	Blue             string   `json:"blue"`
	Magenta          string   `json:"magenta"`
	Cyan             string   `json:"cyan"`
	BrightRed        string   `json:"brightRed"`
	BrightGreen      string   `json:"brightGreen"`
	BrightYellow     string   `json:"brightYellow"`
	BrightBlue       string   `json:"brightBlue"`
	BrightMagenta    string   `json:"brightMagenta"`
	BrightCyan       string   `json:"brightCyan"`
	BrightForeground string   `json:"brightForeground"`
	Colors           []string `json:"colors"`
}

func pick(values ...string) string {
	for _, v := range values {
		if v = upperHex(v); v != "" {
			return v
		}
	}
	return ""
}

func parseUserTheme(data []byte) (themeInfo, bool) {
	var u userTheme
	if err := json.Unmarshal(data, &u); err != nil {
		fmt.Fprintf(os.Stderr, "natonctl: skipping invalid preset: %v\n", err)
		return themeInfo{}, false
	}
	if strings.TrimSpace(u.Name) == "" {
		fmt.Fprintln(os.Stderr, "natonctl: skipping preset without a name")
		return themeInfo{}, false
	}
	var c [16]string
	if len(u.Colors) == 16 {
		for i, v := range u.Colors {
			c[i] = upperHex(v)
		}
	}
	c[0] = pick(u.Background, c[0])
	c[1] = pick(u.Red, u.Accent, c[1])
	c[2] = pick(u.Green, c[2])
	c[3] = pick(u.Yellow, c[3])
	c[4] = pick(u.Blue, c[4])
	c[5] = pick(u.Magenta, c[5])
	c[6] = pick(u.Cyan, c[6])
	c[7] = pick(u.Foreground, c[7])
	c[8] = pick(u.Layer, u.Muted, c[8])
	c[9] = pick(u.BrightRed, c[9], u.Red)
	c[10] = pick(u.BrightGreen, c[10], u.Green)
	c[11] = pick(u.BrightYellow, c[11], u.Yellow)
	c[12] = pick(u.BrightBlue, c[12], u.Blue)
	c[13] = pick(u.BrightMagenta, c[13], u.Magenta)
	c[14] = pick(u.BrightCyan, c[14], u.Cyan)
	c[15] = pick(u.BrightForeground, c[15], u.Foreground)
	if c[0] == "" || c[7] == "" {
		fmt.Fprintf(os.Stderr, "natonctl: skipping preset %q: background and foreground are required\n", u.Name)
		return themeInfo{}, false
	}
	mode := u.Mode
	if mode != "light" && mode != "dark" {
		if hexLuminance(c[0]) > 0.52 {
			mode = "light"
		} else {
			mode = "dark"
		}
	}
	return themeInfo{
		Name:             u.Name,
		Mode:             mode,
		Accent:           pick(u.Accent, c[1]),
		Background:       c[0],
		Foreground:       c[7],
		Layer:            c[8],
		Selection:        pick(u.Selection, c[8]),
		Muted:            pick(u.Muted, c[8]),
		Red:              c[1],
		Green:            c[2],
		Yellow:           c[3],
		Blue:             c[4],
		Magenta:          c[5],
		Cyan:             c[6],
		BrightRed:        c[9],
		BrightGreen:      c[10],
		BrightYellow:     c[11],
		BrightBlue:       c[12],
		BrightMagenta:    c[13],
		BrightCyan:       c[14],
		BrightForeground: c[15],
		Colors:           c,
	}, true
}

func userPresetsDir() string { return filepath.Join(homeDir, ".config/quickshell/presets") }

func userThemeFiles() []themeInfo {
	entries, err := os.ReadDir(userPresetsDir())
	if err != nil {
		return nil
	}
	var out []themeInfo
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".json") {
			continue
		}
		path := filepath.Join(userPresetsDir(), e.Name())
		data, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		t, ok := parseUserTheme(data)
		if !ok {
			continue
		}
		t.File = path
		out = append(out, t)
	}
	return out
}

func cmdPresets() {
	byName := map[string]themeInfo{}
	for _, p := range presetThemes {
		t := themeFromBuiltin(p)
		byName[t.Name] = t
	}
	for _, t := range userThemeFiles() {
		byName[t.Name] = t // user themes override built-ins
	}
	out := make([]themeInfo, 0, len(byName))
	for _, t := range byName {
		out = append(out, t)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	output(out)
}
