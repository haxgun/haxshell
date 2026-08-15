# hush Design Philosophy

The aesthetic and technical rationale behind `hush` — the "why", not the "how to
build it". See `AGENTS.md` for structure, commands, and contribution conventions.

---

## Principles

### 1. Unified frosted glassmorphism

Every surface in the shell shares one material language: translucent dark glass
with a 1px inner border and a soft shadow. The tokens that define it live in
`quickshell/Common/Config.qml` as `glassBg`, `glassHoverBg`, `searchBg`,
`borderColor`, and friends, so a surface is described by *role* (glass, hover,
input, border) rather than by literal hex values.

- Surface tint and hover state are derived from the theme, not hardcoded.
- Borders and shadows are independent toggles (`shellBordersEnabled`,
  `popupShadowsEnabled`, ...); turning blur off collapses a surface to an opaque
  card rather than a broken translucency.

### 2. Strict dimensional standardization

Widgets share a single geometry vocabulary instead of each inventing its own
margins: `barThickness`, `buttonHeight`, `barMargin`, `widgetRadius`,
`overlayRadius`, `cardRadius`. The clock is centered by symmetry
(`mprisTargetSideWidth` extends the MPRIS block equally on both sides) so the
time stays anchored to the exact horizontal center of the bar regardless of
which other widgets are enabled.

### 3. Non-intrusive micro-animations

Motion is a hint, never a feature. Width, opacity, and color changes run through
`Behavior` animations at 150–400 ms with `Easing.InOutQuad`/`OutCubic`, and
every animation respects `Config.reduceMotion` by collapsing to zero duration.
Controls fade in over dedicated dead-space rather than resizing neighbors, so
nothing layout-shifts while a user hovers.

### 4. Dynamic theming from the wallpaper

The shell's colors are not fixed: a Go-side palette extractor (see below)
derives a four-color palette from the current wallpaper, and the whole theme
recolors from it. `applyDynamicPalette` writes the derived surface/layer/
highlight/accent colors, and `Behavior on animated*` interpolates between the
old and new palette over 400 ms so a wallpaper change ripples through the shell
smoothly rather than snapping. The extraction strategy is selectable per scheme
(`vibrant`, `faithful`, `dysfunctional`, `muted`, `soft`, `material`,
`monochrome`) via `wallpaperPaletteScheme`.

---

## Technical integration

### Centralized configuration

All tokens — colors, metrics, typography, component toggles, icon glyphs, and
launcher commands — are defined once in the `Config` singleton and registered in
`quickshell/qmldir`. Components import it with a relative path (`import
"../Common"`) and never embed their own values, so a design change is a one-line
edit in a single file.

### Externalized system integration

Anything that touches the system — brightness, audio, weather, wallpaper
scanning, palette extraction — lives in the `hushctl` Go helper, not in QML. QML
invokes `hushctl` subcommands through `Process` objects and consumes JSON. The
Go side decodes images in-process (`golang.org/x/image` for webp/bmp) and keeps
ImageMagick/ffmpeg only as a fallback, which removes subprocess spawns from the
hot wallpaper path and lets thumbnails generate concurrently.

### Compositor blur rules

For frosted glass to render, the bar and overlay windows advertise a Wayland
layer-shell namespace (`quickshell-bar`, `quickshell-tooltip`) that the
compositor matches to a blur rule (in Hyprland's `windows_and_workspaces.lua`).
The shell itself only declares the namespace; the compositor owns the blur.

### Detached application spawning

Apps launched from the drawer or status controls are started with
`setsid -f`, creating a new session group so they survive Quickshell reloads and
the shell's lifecycle entirely.
