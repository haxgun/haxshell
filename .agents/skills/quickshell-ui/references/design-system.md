# Design system guidance

## Tokens

Prefer centralized tokens for:

- colors;
- typography sizes/weights;
- spacing;
- radii;
- borders;
- icon sizes;
- opacity levels;
- motion.

Example conceptual scale:

```text
spacing: 4 / 8 / 12 / 16 / 24 / 32
radius:  6 / 10 / 14 / 20
```

Use the project's actual values rather than introducing this scale blindly.

## Hierarchy

A good desktop-shell surface should make these visually distinct:

- primary action/content;
- secondary metadata;
- selected/active state;
- disabled/unavailable state;
- background grouping.

Do not rely on color alone when shape, weight, iconography, or labels can clarify state.

## Typography

- Keep system UI text compact but readable.
- Use weight and opacity sparingly.
- Avoid many unrelated font sizes within one popup.
- Prefer tabular numerals where stable numeric alignment is important if the chosen font supports them.

## Icons

- Use one icon family per design system when possible.
- Normalize apparent icon size, not only numeric font size.
- Keep glyphs optically centered.
- Use labels or tooltips when an icon's meaning is not obvious.

## Surfaces

Use borders, tonal differences, blur, and shadow intentionally. One strong separator is usually better than stacking several subtle ones.

For translucent shells, verify contrast against both bright and dark wallpapers.
