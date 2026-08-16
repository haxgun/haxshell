package veyctl

import (
	"math"
	"sort"
)

// OKLab median-cut color quantization, ported from aether
// (docs/color-extraction.md). Quantizes sampled pixels into perceptually
// distinct clusters by splitting along the widest OKLab axis, which captures
// dominant colors more accurately than a plain RGB histogram.

type oklab struct{ L, A, B float64 }

func srgbToLinear(c float64) float64 {
	if c <= 0.04045 {
		return c / 12.92
	}
	return math.Pow((c+0.055)/1.055, 2.4)
}

func linearToSrgb(c float64) float64 {
	if c <= 0.0031308 {
		return 12.92 * c
	}
	return 1.055*math.Pow(c, 1.0/2.4) - 0.055
}

func rgbToOKLab(r, g, b int) oklab {
	rf := srgbToLinear(float64(r) / 255)
	gf := srgbToLinear(float64(g) / 255)
	bf := srgbToLinear(float64(b) / 255)

	l := 0.4122214708*rf + 0.5363325363*gf + 0.0514459929*bf
	m := 0.2119034982*rf + 0.6806995451*gf + 0.1073969566*bf
	s := 0.0883024619*rf + 0.2164557844*gf + 0.6952417517*bf

	lc := math.Cbrt(l)
	mc := math.Cbrt(m)
	sc := math.Cbrt(s)

	return oklab{
		L: 0.2104542553*lc + 0.7936177850*mc - 0.0040720468*sc,
		A: 1.9779984951*lc - 2.4285922050*mc + 0.4505937099*sc,
		B: 0.0259040371*lc + 0.7827717662*mc - 0.8086757660*sc,
	}
}

func clamp01(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

func oklabToRGB(lab oklab) (int, int, int) {
	lp := lab.L + 0.3963377774*lab.A + 0.2158037573*lab.B
	mp := lab.L - 0.1055613458*lab.A - 0.0638541728*lab.B
	sp := lab.L - 0.0894841775*lab.A - 1.2914855480*lab.B

	l := lp * lp * lp
	m := mp * mp * mp
	s := sp * sp * sp

	r := +4.0767416621*l - 3.3077115913*m + 0.2309699292*s
	g := -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
	b := -0.0041960863*l - 0.7034186147*m + 1.7076147010*s

	r = clamp01(r)
	g = clamp01(g)
	b = clamp01(b)

	return int(math.Round(linearToSrgb(r) * 255)),
		int(math.Round(linearToSrgb(g) * 255)),
		int(math.Round(linearToSrgb(b) * 255))
}

func oklabChroma(lab oklab) float64 {
	return math.Sqrt(lab.A*lab.A + lab.B*lab.B)
}

// boostChromaticPixels duplicates vivid pixels (graded by OKLCH chroma) so a
// small saturated subject isn't drowned out by a large muted background.
func boostChromaticPixels(pixels []oklab) []oklab {
	const threshold = 0.04
	const maxExtra = 3
	const rampChroma = 0.16

	result := make([]oklab, 0, len(pixels)*2)
	for _, p := range pixels {
		result = append(result, p)
		chroma := oklabChroma(p)
		if chroma <= threshold {
			continue
		}
		t := (chroma - threshold) / rampChroma
		extra := int(math.Round(t * float64(maxExtra)))
		if extra < 1 {
			extra = 1
		}
		if extra > maxExtra {
			extra = maxExtra
		}
		for j := 0; j < extra; j++ {
			result = append(result, p)
		}
	}
	return result
}

type oklabBucket struct {
	colors []oklab
	ranges [3][2]float64
}

func newOKLabBucket(colors []oklab) *oklabBucket {
	b := &oklabBucket{colors: colors}
	b.computeRanges()
	return b
}

func (b *oklabBucket) computeRanges() {
	if len(b.colors) == 0 {
		b.ranges = [3][2]float64{{0, 0}, {0, 0}, {0, 0}}
		return
	}
	first := b.colors[0]
	b.ranges = [3][2]float64{{first.L, first.L}, {first.A, first.A}, {first.B, first.B}}
	for _, c := range b.colors {
		vals := [3]float64{c.L, c.A, c.B}
		for ch := 0; ch < 3; ch++ {
			if vals[ch] < b.ranges[ch][0] {
				b.ranges[ch][0] = vals[ch]
			}
			if vals[ch] > b.ranges[ch][1] {
				b.ranges[ch][1] = vals[ch]
			}
		}
	}
}

func (b *oklabBucket) axisRange(axis int) float64 {
	return b.ranges[axis][1] - b.ranges[axis][0]
}

func (b *oklabBucket) longestAxis() int {
	l := b.axisRange(0) * 1.2
	a := b.axisRange(1)
	bl := b.axisRange(2)
	if l >= a && l >= bl {
		return 0
	}
	if a >= bl {
		return 1
	}
	return 2
}

func oklabAxis(c oklab, axis int) float64 {
	switch axis {
	case 0:
		return c.L
	case 1:
		return c.A
	default:
		return c.B
	}
}

func (b *oklabBucket) split() (*oklabBucket, *oklabBucket) {
	axis := b.longestAxis()
	sort.Slice(b.colors, func(i, j int) bool {
		return oklabAxis(b.colors[i], axis) < oklabAxis(b.colors[j], axis)
	})
	mid := len(b.colors) / 2
	left := make([]oklab, mid)
	right := make([]oklab, len(b.colors)-mid)
	copy(left, b.colors[:mid])
	copy(right, b.colors[mid:])
	return newOKLabBucket(left), newOKLabBucket(right)
}

func (b *oklabBucket) volume() float64 {
	return b.axisRange(0) * b.axisRange(1) * b.axisRange(2) * float64(len(b.colors))
}

func (b *oklabBucket) average() oklab {
	var l, a, bl float64
	for _, c := range b.colors {
		l += c.L
		a += c.A
		bl += c.B
	}
	n := float64(len(b.colors))
	return oklab{L: l / n, A: a / n, B: bl / n}
}

// medianCutBuckets quantizes OKLab pixels into up to numColors clusters and
// returns each cluster's average color as a scoring `bucket` (RGB + count +
// HSL-derived fields), ready for the existing scheme scoring.
func medianCutBuckets(pixels []oklab, numColors int) []bucket {
	if len(pixels) == 0 {
		return nil
	}
	buckets := []*oklabBucket{newOKLabBucket(pixels)}
	for len(buckets) < numColors {
		idx := -1
		maxVol := 0.0
		for i, b := range buckets {
			if len(b.colors) > 1 {
				v := b.volume()
				if v > maxVol {
					maxVol = v
					idx = i
				}
			}
		}
		if idx == -1 {
			break
		}
		left, right := buckets[idx].split()
		next := make([]*oklabBucket, 0, len(buckets)+1)
		next = append(next, buckets[:idx]...)
		next = append(next, left, right)
		next = append(next, buckets[idx+1:]...)
		buckets = next
	}

	result := make([]bucket, 0, len(buckets))
	for _, b := range buckets {
		if len(b.colors) == 0 {
			continue
		}
		avg := b.average()
		r, g, bl := oklabToRGB(avg)
		h01, sat, light := hslOf(r, g, bl)
		result = append(result, bucket{
			r:      r,
			g:      g,
			b:      bl,
			count:  len(b.colors),
			hue:    h01 * 360,
			sat:    sat,
			light:  light,
			chroma: sat * (1 - math.Abs(2*light-1)) * 100,
			tone:   light * 100,
		})
	}
	return result
}
