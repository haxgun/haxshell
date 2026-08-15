# AGENTS.md

Guidelines for AI agents and contributors working in this repository.

## Project

`vey` is a customizable Wayland desktop shell for Hyprland and Niri, built with
Quickshell, QML, and a small Go helper (`veyctl`).

## Layout

```text
quickshell/            Quickshell configuration (QML)
  shell.qml            entry point
  Common/              Config.qml singleton, SettingsStore, shared services
  Modules/             Bar, ControlCenter, Media, OSD, Settings, Wallpapers, ...
  Widgets/             reusable components (registered in Widgets/qmldir)
  Services/            QML services (compositor, niri, wallpaper cycling)
  translations/        UI strings (de/en/ja/ru/zh)
core/                  Go module for veyctl
  cmd/veyctl/         command entry point
  internal/veyctl/    implementation
  pkg/                 public packages
install.sh             Arch Linux installer
```

## Commands

Build the Go helper (rebuild and restart Quickshell after changing `core/`):

```bash
go build -C core -o ../quickshell/veyctl ./cmd/veyctl
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

- Idiomatic Go; the helper is one package under `core/internal/veyctl`.
- System integration lives in the helper, not QML: QML calls `veyctl`
  subcommands via Process objects and consumes JSON output.
- Prefer the standard library; add a dependency only when it removes a
  subprocess dependency (e.g. `golang.org/x/image` for in-process webp/bmp
  decoding).

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
