# AGENTS.md

Guidelines for AI agents and contributors working in this repository.

## Project

`Naton` is a customizable Wayland desktop shell for Hyprland and Niri, built with
Quickshell, QML, and a small Go helper (`natonctl`).

## Layout

```text
quickshell/            Quickshell configuration (QML)
  shell.qml            entry point
  Common/              Config.qml singleton, SettingsStore, shared services
  Modules/             Bar, ControlCenter, Media, OSD, Settings, Wallpapers, ...
  Widgets/             reusable components (registered in Widgets/qmldir)
  Services/            QML services (compositor, niri, wallpaper cycling)
  translations/        UI strings (de/en/ja/ru/zh)
core/                  Go module for natonctl
  cmd/natonctl/         command entry point
  internal/natonctl/    implementation
  pkg/                 public packages
install.sh             Arch Linux installer
```

## Commands

Build the Go helper (rebuild and restart Quickshell after changing `core/`):

```bash
go build -C core -o ../quickshell/natonctl ./cmd/natonctl
```

Run the shell:

```bash
quickshell --path quickshell
```

Verify:

```bash
git diff --check
cd core && go build ./...
```

There is no test suite; verification is the Go build, `git diff --check`, and a
manual `quickshell` run.

## Conventions

### QML

- Two-space indentation, no trailing whitespace.
- Never hardcode colors, radii, spacing, or fonts in a component. Read them from
  the `Config` singleton (`quickshell/Common/Config.qml`), imported relative to
  the current file (`import "../Common"`, `import "../../Common"`, ...).
- New reusable components go in `quickshell/Widgets/` and must be registered in
  `quickshell/Widgets/qmldir`.
- Icons are Nerd Font glyphs rendered with `Config.fontIcon`.
- Any new user-facing string must be added to all five files under
  `quickshell/translations/`.

### Go

- Idiomatic Go; the helper is one package under `core/internal/natonctl`.
- System integration lives in the helper, not QML: QML calls `natonctl`
  subcommands via Process objects and consumes JSON output.
- Prefer the standard library; add a dependency only when it removes a
  subprocess dependency (e.g. `golang.org/x/image` for in-process webp/bmp
  decoding).

### Themes

Themes come from two sources, merged by `natonctl presets` (user themes win on
name collision):

- Built-in 16-color ANSI presets in `core/internal/natonctl/presets.go`. The
  optional `Accent` field overrides the accent (ANSI red is kept for
  danger/status) — e.g. the macOS Classic presets carry a blue `Accent`.
- User themes as JSON files in `~/.config/quickshell/presets/`. A theme file
  has semantic keys; only `name`, `background` and `foreground` are required:

  ```json
  {
    "name": "My Theme",
    "mode": "dark",
    "accent": "#077CFD",
    "background": "#131313",
    "foreground": "#DEDEDE",
    "layer": "#8F8F8F",
    "selection": "#2A2A2A",
    "muted": "#8F8F8F",
    "red": "#FF5257",
    "green": "#30D158",
    "yellow": "#CC9E00",
    "blue": "#419CFF",
    "magenta": "#A550A7",
    "cyan": "#0AC2A2",
    "brightRed": "#FF696D",
    "brightGreen": "#68DC7C",
    "brightYellow": "#DBBB76",
    "brightBlue": "#7FAEF9",
    "brightMagenta": "#B283F8",
    "brightCyan": "#5CDBC6",
    "brightForeground": "#F2F9FF"
  }
  ```

  `mode` (`dark`/`light`) is optional and falls back to background luminance.
  An optional 16-element `colors` array provides the ANSI ramp; explicit
  semantic keys always win over it. Editing the active theme file hot-reloads
  the shell (watched by a `FileView` in `Config.qml`).

### Docs

- `README.md` and `README.ru.md` must stay in sync; update both together.
- `DESIGN_PHILOSOPHY.md` documents design rationale (aesthetics and the "why"),
  not commands or structure.

## Agent tooling

- opencode config lives in `.opencode/`; the `ponytail` plugin (lazy senior dev
  mode) is enabled there via npm. Restart opencode after changing
  `.opencode/opencode.json`.
- Project skills live in `.agents/skills/` (bash-defensive-patterns,
  golang-patterns, golang-testing).
