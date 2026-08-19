package colorpicker

import (
	"fmt"
	"math"
)

type Color struct {
	R, G, B, A uint8
}

type OutputFormat int

const (
	FormatHex OutputFormat = iota
	FormatRGB
	FormatHSL
	FormatHSV
	FormatCMYK
)

func (c Color) ToHex(lowercase bool) string {
	if lowercase {
		return fmt.Sprintf("#%02x%02x%02x", c.R, c.G, c.B)
	}
	return fmt.Sprintf("#%02X%02X%02X", c.R, c.G, c.B)
}

func (c Color) ToRGB() string {
	return fmt.Sprintf("%d %d %d", c.R, c.G, c.B)
}

func (c Color) ToHSL() string {
	h, s, l := rgbToHSL(c.R, c.G, c.B)
	return fmt.Sprintf("%d %d%% %d%%", h, s, l)
}

func (c Color) ToHSV() string {
	h, s, v := rgbToHSV(c.R, c.G, c.B)
	return fmt.Sprintf("%d %d%% %d%%", h, s, v)
}

func (c Color) ToCMYK() string {
	cy, m, y, k := rgbToCMYK(c.R, c.G, c.B)
	return fmt.Sprintf("%d%% %d%% %d%% %d%%", cy, m, y, k)
}

func rgbToHSL(r, g, b uint8) (int, int, int) {
	rf := float64(r) / 255.0
	gf := float64(g) / 255.0
	bf := float64(b) / 255.0

	maxVal := math.Max(rf, math.Max(gf, bf))
	minVal := math.Min(rf, math.Min(gf, bf))
	l := (maxVal + minVal) / 2

	if maxVal == minVal {
		return 0, 0, int(math.Round(l * 100))
	}

	d := maxVal - minVal
	var s float64
	if l > 0.5 {
		s = d / (2 - maxVal - minVal)
	} else {
		s = d / (maxVal + minVal)
	}

	var h float64
	switch maxVal {
	case rf:
		h = (gf - bf) / d
		if gf < bf {
			h += 6
		}
	case gf:
		h = (bf-rf)/d + 2
	case bf:
		h = (rf-gf)/d + 4
	}
	h /= 6

	return int(math.Round(h * 360)), int(math.Round(s * 100)), int(math.Round(l * 100))
}

func rgbToHSV(r, g, b uint8) (int, int, int) {
	rf := float64(r) / 255.0
	gf := float64(g) / 255.0
	bf := float64(b) / 255.0

	maxVal := math.Max(rf, math.Max(gf, bf))
	minVal := math.Min(rf, math.Min(gf, bf))
	v := maxVal
	d := maxVal - minVal

	var s float64
	if maxVal != 0 {
		s = d / maxVal
	}

	if maxVal == minVal {
		return 0, int(math.Round(s * 100)), int(math.Round(v * 100))
	}

	var h float64
	switch maxVal {
	case rf:
		h = (gf - bf) / d
		if gf < bf {
			h += 6
		}
	case gf:
		h = (bf-rf)/d + 2
	case bf:
		h = (rf-gf)/d + 4
	}
	h /= 6

	return int(math.Round(h * 360)), int(math.Round(s * 100)), int(math.Round(v * 100))
}

func rgbToCMYK(r, g, b uint8) (int, int, int, int) {
	if r == 0 && g == 0 && b == 0 {
		return 0, 0, 0, 100
	}

	rf := float64(r) / 255.0
	gf := float64(g) / 255.0
	bf := float64(b) / 255.0

	k := 1 - math.Max(rf, math.Max(gf, bf))
	c := (1 - rf - k) / (1 - k)
	m := (1 - gf - k) / (1 - k)
	y := (1 - bf - k) / (1 - k)

	return int(math.Round(c * 100)), int(math.Round(m * 100)), int(math.Round(y * 100)), int(math.Round(k * 100))
}
