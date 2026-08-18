package natonctl

import (
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"image"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"sync"
	"time"

	_ "golang.org/x/image/bmp"
	_ "golang.org/x/image/webp"
)

// paletteSchemePresets mirrors the scheme presets offered in the settings UI.
// The scoring methods follow noctalia's palette generation:
//   - vibrant:      chroma-prioritized (high saturation wins, count^0.3 weight)
//   - faithful:     area-dominant by hue family
//   - dysfunctional: second most dominant hue family (visually distant)
//   - muted:        pure pixel count, no chroma filter (monochrome-friendly)
//   - soft:         count biased toward mid-lightness tones
//   - material:     Material Design "Score" algorithm (excited proportions)
//   - monochrome:   count-based, then desaturated to a grayscale ramp
var paletteSchemePresets = map[string]bool{
	"vibrant":       true,
	"faithful":      true,
	"dysfunctional": true,
	"muted":         true,
	"soft":          true,
	"material":      true,
	"monochrome":    true,
}

// paletteSchemeOverride lets the QML side pass the currently selected scheme
// directly, so the palette reacts immediately even before settings.json is
// flushed to disk. Empty means "read from settings".
var paletteSchemeOverride string

var paletteCache = struct {
	sync.Mutex
	path   string
	scheme string
	mtime  time.Time
	colors []string
}{}

// paletteCachePath returns a stable on-disk cache location for a wallpaper's
// palette. natonctl is invoked as a fresh process per query, so the in-memory
// cache above never survives between calls; persisting the result to disk keyed
// by path + mtime + scheme avoids re-decoding the full image on every request.
func paletteCachePath(path, scheme string, mtime time.Time) string {
	sum := sha1.Sum([]byte(path + "|" + scheme + "|" + mtime.Format(time.RFC3339Nano)))
	return filepath.Join(homeDir, ".cache/quickshell/wallpaper-palettes", hex.EncodeToString(sum[:])[:16]+".json")
}

func readPaletteCache(path, scheme string, mtime time.Time) []string {
	data, err := os.ReadFile(paletteCachePath(path, scheme, mtime))
	if err != nil {
		return nil
	}
	var colors []string
	if json.Unmarshal(data, &colors) != nil || len(colors) == 0 {
		return nil
	}
	return colors
}

func writePaletteCache(path, scheme string, mtime time.Time, colors []string) {
	target := paletteCachePath(path, scheme, mtime)
	_ = os.MkdirAll(filepath.Dir(target), 0o755)
	data, _ := json.Marshal(colors)
	_ = os.WriteFile(target, data, 0o644)
}

func extractInProcessPalette(path string) []string {
	if path == "" {
		return []string{}
	}
	settings := readSettings()
	scheme := paletteSchemeOverride
	if !paletteSchemePresets[scheme] {
		scheme = "vibrant"
		if s := settings["wallpaperPaletteScheme"]; paletteSchemePresets[s] {
			scheme = s
		}
	}
	lightMode := settings["dynamicDark"] == "false"
	if lightMode {
		scheme += ":light"
	}
	st, err := os.Stat(path)
	if err != nil {
		return []string{}
	}
	mtime := st.ModTime()
	paletteCache.Lock()
	if paletteCache.path == path && paletteCache.scheme == scheme && paletteCache.mtime.Equal(mtime) {
		colors := paletteCache.colors
		paletteCache.Unlock()
		return colors
	}
	paletteCache.Unlock()

	if cached := readPaletteCache(path, scheme, mtime); cached != nil {
		paletteCache.Lock()
		paletteCache.path = path
		paletteCache.scheme = scheme
		paletteCache.mtime = mtime
		paletteCache.colors = cached
		paletteCache.Unlock()
		return cached
	}

	colors := extractPalette(path, scheme, lightMode)
	if len(colors) == 0 {
		colors = magickPalette(path)
	}
	writePaletteCache(path, scheme, mtime, colors)

	paletteCache.Lock()
	paletteCache.path = path
	paletteCache.scheme = scheme
	paletteCache.mtime = mtime
	paletteCache.colors = colors
	paletteCache.Unlock()
	return colors
}

// magickPalette keeps the previous ImageMagick pipeline as a fallback for
// formats the in-process decoder cannot open (or when decoding fails).
func magickPalette(path string) []string {
	if !commandExists("magick") {
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

type bucket struct {
	r, g, b int
	count   int
	hue     float64 // degrees 0-360
	sat     float64 // 0-1
	light   float64 // 0-1
	chroma  float64 // 0-100 (HSL-derived chroma approximation)
	tone    float64 // 0-100 (lightness)
	score   float64
}

func extractPalette(path, scheme string, lightMode bool) []string {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()
	img, _, err := image.Decode(f)
	if err != nil {
		return nil
	}
	b := img.Bounds()
	w, h := b.Dx(), b.Dy()
	if w <= 0 || h <= 0 {
		return nil
	}

	const grid = 80
	var pixels []oklab
	for gy := 0; gy < grid; gy++ {
		for gx := 0; gx < grid; gx++ {
			x := b.Min.X + gx*w/grid + w/grid/2
			y := b.Min.Y + gy*h/grid + h/grid/2
			r16, g16, b16, a16 := img.At(x, y).RGBA()
			if a16 < 0x8000 {
				continue
			}
			pixels = append(pixels, rgbToOKLab(int(r16>>8), int(g16>>8), int(b16>>8)))
		}
	}
	if len(pixels) == 0 {
		return nil
	}

	// Median-cut in OKLab perceptually clusters the sampled pixels into
	// dominant colors (aether docs/color-extraction.md), with vivid pixels
	// boosted so small saturated accents survive large muted backgrounds.
	buckets := medianCutBuckets(boostChromaticPixels(pixels), 48)

	scoreBuckets(buckets, scheme)
	sort.SliceStable(buckets, func(i, j int) bool { return buckets[i].score > buckets[j].score })

	colors := []string{}
	pickedHues := []float64{}
	pickedLights := []float64{}
	for _, bk := range buckets {
		r, g, bl := bk.r, bk.g, bk.b
		if scheme == "monochrome" {
			gray := grayscale(r, g, bl)
			r, g, bl = gray, gray, gray
		}
		hex := rgbHex(r, g, bl)
		if hex == "" || containsString(colors, hex) {
			continue
		}
		if scheme == "monochrome" {
			if !distinctLight(float64(r)/255, pickedLights, 0.12) {
				continue
			}
		} else if !distinctHueDeg(bk.hue, pickedHues, 30) {
			continue
		}
		colors = append(colors, hex)
		if scheme == "monochrome" {
			pickedLights = append(pickedLights, float64(r)/255)
		} else {
			pickedHues = append(pickedHues, bk.hue)
		}
		if len(colors) >= 4 {
			break
		}
	}
	if len(colors) == 0 {
		return nil
	}
	if lightMode && len(colors) > 1 {
		colors[1] = lightenHex(colors[1])
	}
	return ensurePalette(colors)
}

// lightenHex blends a color toward white so light-mode surfaces stay readable.
func lightenHex(hex string) string {
	if len(hex) < 7 {
		return hex
	}
	r := hexVal(hex[1:3])
	g := hexVal(hex[3:5])
	b := hexVal(hex[5:7])
	return rgbHex((r*3+255*7)/10, (g*3+255*7)/10, (b*3+255*7)/10)
}

// grayscale returns a perceptually-weighted luma for monochrome palettes.
func grayscale(r, g, b int) int {
	return int(math.Round(0.2126*float64(r) + 0.7152*float64(g) + 0.0722*float64(b)))
}

func distinctLight(light float64, picked []float64, threshold float64) bool {
	for _, other := range picked {
		if math.Abs(light-other) < threshold {
			return false
		}
	}
	return true
}

func scoreBuckets(buckets []bucket, scheme string) {
	switch scheme {
	case "faithful":
		scoreCount(buckets)
	case "dysfunctional":
		scoreDysfunctional(buckets)
	case "muted", "monochrome":
		scoreMuted(buckets)
	case "soft":
		scoreSoft(buckets)
	case "material":
		scorePopulation(buckets)
	default:
		scoreChroma(buckets)
	}
}

// scoreChroma (vibrant): chroma minus tone/hue penalties, weighted by count^0.3.
func scoreChroma(buckets []bucket) {
	for i := range buckets {
		b := &buckets[i]
		tone := b.tone
		tonePenalty := 0.0
		if tone < 20 {
			tonePenalty = (20 - tone) * 2
		} else if tone > 80 {
			tonePenalty = (tone - 80) * 1.5
		} else if tone < 40 {
			tonePenalty = (40 - tone) * 0.5
		} else if tone > 60 {
			tonePenalty = (tone - 60) * 0.3
		}
		huePenalty := 0.0
		if b.hue > 80 && b.hue < 110 {
			huePenalty = 5
		}
		b.score = (b.chroma - tonePenalty - huePenalty) * math.Pow(float64(b.count), 0.3)
	}
}

// scoreCount (faithful): dominant hue families first, then count, then chroma.
func scoreCount(buckets []bucket) {
	const minChroma = 10.0
	fams := map[int]*fam{}
	for i := range buckets {
		b := &buckets[i]
		if b.chroma < minChroma {
			continue
		}
		f := hueFamily(b.hue)
		if fams[f] == nil {
			fams[f] = &fam{family: f}
		}
		fams[f].total += b.count
		fams[f].list = append(fams[f].list, b)
	}
	if len(fams) == 0 {
		scoreMuted(buckets)
		return
	}
	sorted := sortFams(fams)
	for rank, f := range sorted {
		sort.SliceStable(f.list, func(i, j int) bool {
			if f.list[i].count != f.list[j].count {
				return f.list[i].count > f.list[j].count
			}
			return f.list[i].chroma > f.list[j].chroma
		})
		for _, b := range f.list {
			b.score = float64(len(sorted)-rank)*1e6 + float64(b.count)*1000 + b.chroma
		}
	}
}

type fam struct {
	family int
	total  int
	score  float64
	list   []*bucket
}

func sortFams(fams map[int]*fam) []*fam {
	sorted := make([]*fam, 0, len(fams))
	for _, f := range fams {
		sorted = append(sorted, f)
	}
	sort.SliceStable(sorted, func(i, j int) bool { return sorted[i].total > sorted[j].total })
	return sorted
}

var familyCenters = [...]float64{0, 45, 82.5, 147.5, 230, 300}

// scoreDysfunctional: skip the dominant family, prefer hue-distant families.
func scoreDysfunctional(buckets []bucket) {
	const minChroma = 10.0
	const minHueDist = 45.0
	const minCountRatio = 0.02
	fams := map[int]*fam{}
	totalColorful := 0
	for i := range buckets {
		b := &buckets[i]
		if b.chroma < minChroma {
			continue
		}
		f := hueFamily(b.hue)
		if fams[f] == nil {
			fams[f] = &fam{family: f}
		}
		fams[f].total += b.count
		fams[f].list = append(fams[f].list, b)
		totalColorful += b.count
	}
	if len(fams) < 2 {
		scoreCount(buckets)
		return
	}
	sorted := sortFams(fams)
	dominant := sorted[0]
	domCenter := familyCenters[dominant.family]
	minCount := int(float64(totalColorful) * minCountRatio)

	var distant, close []*fam
	for _, f := range sorted[1:] {
		diff := circularHueDiff(domCenter, familyCenters[f.family])
		if diff >= minHueDist && f.total >= minCount {
			maxChroma := 0.0
			for _, b := range f.list {
				if b.chroma > maxChroma {
					maxChroma = b.chroma
				}
			}
			f.score = diff * maxChroma
			distant = append(distant, f)
		} else {
			close = append(close, f)
		}
	}
	sort.SliceStable(distant, func(i, j int) bool { return distant[i].score > distant[j].score })

	for rank, f := range distant {
		sort.SliceStable(f.list, func(i, j int) bool {
			if f.list[i].chroma != f.list[j].chroma {
				return f.list[i].chroma > f.list[j].chroma
			}
			return f.list[i].count > f.list[j].count
		})
		for _, b := range f.list {
			b.score = float64(len(distant)-rank)*1e6 + b.chroma*1000 + float64(b.count)
		}
	}
	for _, f := range close {
		sort.SliceStable(f.list, func(i, j int) bool { return f.list[i].count > f.list[j].count })
		for _, b := range f.list {
			b.score = float64(b.count) * 1000 + b.chroma
		}
	}
}

// scoreMuted: pure pixel count, no chroma filter (monochrome wallpapers).
func scoreMuted(buckets []bucket) {
	for i := range buckets {
		buckets[i].score = float64(buckets[i].count)
	}
}

// scoreSoft: count biased toward mid-lightness tones.
func scoreSoft(buckets []bucket) {
	for i := range buckets {
		b := &buckets[i]
		mid := 1 - math.Abs(b.light-0.55)*1.6
		if mid < 0.1 {
			mid = 0.1
		}
		b.score = float64(b.count) * mid
	}
}

// scorePopulation: Material Design "Score" algorithm using excited proportions.
func scorePopulation(buckets []bucket) {
	const targetChroma = 48.0
	const weightProp = 0.7
	const weightAbove = 0.3
	const weightBelow = 0.1
	const cutoffChroma = 5.0
	const cutoffProp = 0.01

	huePop := make([]float64, 360)
	total := 0
	for i := range buckets {
		hue := int(buckets[i].hue) % 360
		huePop[hue] += float64(buckets[i].count)
		total += buckets[i].count
	}
	if total == 0 {
		scoreMuted(buckets)
		return
	}
	excited := make([]float64, 360)
	for hue := 0; hue < 360; hue++ {
		prop := huePop[hue] / float64(total)
		for off := -14; off <= 15; off++ {
			excited[(hue+off+360)%360] += prop
		}
	}
	for i := range buckets {
		b := &buckets[i]
		hue := int(b.hue) % 360
		prop := excited[hue]
		if b.chroma < cutoffChroma || prop <= cutoffProp {
			continue
		}
		propScore := prop * 100 * weightProp
		var chromaScore float64
		if b.chroma < targetChroma {
			chromaScore = (b.chroma - targetChroma) * weightBelow
		} else {
			chromaScore = (b.chroma - targetChroma) * weightAbove
		}
		b.score = propScore + chromaScore
	}
}

func hueFamily(hue float64) int {
	if hue >= 330 || hue < 30 {
		return 0
	}
	if hue < 60 {
		return 1
	}
	if hue < 105 {
		return 2
	}
	if hue < 190 {
		return 3
	}
	if hue < 270 {
		return 4
	}
	return 5
}

func circularHueDiff(a, b float64) float64 {
	d := math.Abs(a - b)
	if d > 180 {
		d = 360 - d
	}
	return d
}

func distinctHueDeg(hue float64, picked []float64, threshold float64) bool {
	for _, other := range picked {
		if circularHueDiff(hue, other) < threshold {
			return false
		}
	}
	return true
}

func containsString(list []string, value string) bool {
	for _, item := range list {
		if item == value {
			return true
		}
	}
	return false
}

func hslOf(r, g, b int) (h, s, l float64) {
	rf := float64(r) / 255
	gf := float64(g) / 255
	bf := float64(b) / 255
	max := math.Max(rf, math.Max(gf, bf))
	min := math.Min(rf, math.Min(gf, bf))
	l = (max + min) / 2
	if max == min {
		return 0, 0, l
	}
	d := max - min
	if l > 0.5 {
		s = d / (2 - max - min)
	} else {
		s = d / (max + min)
	}
	switch max {
	case rf:
		h = (gf - bf) / d
		if h < 0 {
			h += 6
		}
	case gf:
		h = (bf-rf)/d + 2
	case bf:
		h = (rf-gf)/d + 4
	}
	h /= 6
	return
}

func rgbHex(r, g, b int) string {
	if r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255 {
		return ""
	}
	return "#" + hexByte(r) + hexByte(g) + hexByte(b)
}

func hexByte(v int) string {
	const digits = "0123456789ABCDEF"
	return string([]byte{digits[v>>4], digits[v&0xF]})
}

// ensurePalette guarantees at least 4 colors by deriving surface/layer/highlight
// tones from the first (accent) color, matching how Config consumes the palette.
func ensurePalette(colors []string) []string {
	for len(colors) < 4 {
		base := colors[len(colors)-1]
		colors = append(colors, deriveTone(base, len(colors)-1))
	}
	return colors
}

func deriveTone(hex string, index int) string {
	r := hexVal(hex[1:3])
	g := hexVal(hex[3:5])
	b := hexVal(hex[5:7])
	h, s, l := hslOf(r, g, b)
	s = s * 0.6
	switch index {
	case 1:
		l = math.Max(0.08, l*0.72)
	case 2:
		l = math.Max(0.1, l*0.85)
	default:
		l = math.Min(0.92, l*1.15)
	}
	r2, g2, b2 := rgbFromHsl(h, s, l)
	return rgbHex(r2, g2, b2)
}

func hexVal(s string) int {
	var v int
	for i := 0; i < len(s); i++ {
		c := s[i]
		d := 0
		switch {
		case c >= '0' && c <= '9':
			d = int(c - '0')
		case c >= 'A' && c <= 'F':
			d = int(c-'A') + 10
		case c >= 'a' && c <= 'f':
			d = int(c-'a') + 10
		}
		v = v*16 + d
	}
	return v
}

func rgbFromHsl(h, s, l float64) (int, int, int) {
	if s == 0 {
		v := int(math.Round(l * 255))
		return v, v, v
	}
	var q float64
	if l < 0.5 {
		q = l * (1 + s)
	} else {
		q = l + s - l*s
	}
	p := 2*l - q
	hueToRgb := func(t float64) float64 {
		if t < 0 {
			t++
		}
		if t > 1 {
			t--
		}
		if t < 1.0/6 {
			return p + (q-p)*6*t
		}
		if t < 1.0/2 {
			return q
		}
		if t < 2.0/3 {
			return p + (q-p)*(2.0/3-t)*6
		}
		return p
	}
	return int(math.Round(hueToRgb(h+1.0/3) * 255)),
		int(math.Round(hueToRgb(h) * 255)),
		int(math.Round(hueToRgb(h-1.0/3) * 255))
}
