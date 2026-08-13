# hush

`hush` is a Wayland desktop shell built with Quickshell and QML. It is part of the dotfiles repository and is designed for Hyprland.

## Features

- `Bar` panel with top, bottom, left, and right positions.
- Rotated side panels: left `-90` degrees, right `90` degrees.
- Workspace switcher and application launcher.
- Wi-Fi, Bluetooth, audio, brightness, battery, calendar, media, and power popups.
- Separate macOS-inspired `ControlCenterPopup`.
- Notification toasts and notification center.
- Wallpaper picker with a three-column thumbnail grid.
- Persistent shell settings for theme, position, blur, borders, shadows, fonts, and display options.

## Structure

```text
.
├── shell.qml                 # hush entrypoint
├── Common/                   # Config and persistent settings
├── Modules/                  # Bar, popups, settings, notifications
├── Widgets/                  # Reusable controls
├── Services/                 # QML service singletons
├── scripts/qsctl.go          # Go helper source
└── settings.json             # Persisted user settings
```

## Run

From the repository root:

```bash
quickshell -p quickshell/.config/quickshell/shell.qml
```

The shell is normally started by Hyprland's `autostart.lua` configuration.

## Build Helper

```bash
go build -o quickshell/.config/quickshell/scripts/qsctl quickshell/.config/quickshell/scripts/qsctl.go
```

`qsctl` is called by QML `Process` objects and must print JSON responses to stdout.

## Configuration

Shared configuration belongs in `Common/Config.qml`. User settings are persisted by `Common/SettingsStore.qml` to `settings.json`.

The shell appearance toggles are:

- `shellBlurEnabled`
- `shellBordersEnabled`
- `shellShadowsEnabled`

They are persisted shell appearance options that apply to the Bar and overlay surfaces.

## Verification

```bash
git diff --check
```

When changing `qsctl.go`, rebuild the helper and reload `hush` to test the affected QML modules.
