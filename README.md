# hush

[English](README.md) | [Русский](README.ru.md)

`hush` is a Wayland desktop shell built with Quickshell and QML, designed for Hyprland.

## Features

- Bar placement at the top, bottom, left, or right edge.
- Workspace switcher and focused application indicator.
- Popups for Wi-Fi, Bluetooth, brightness, audio, battery, calendar, media, and power.
- Control center with quick settings.
- Separate speaker and microphone volume controls with PipeWire device selection.
- Shared MPRIS controller for media player widgets.
- Notification toasts and notification center.
- Wallpaper picker with a thumbnail grid.
- Persistent settings for the theme, bar, fonts, and shell appearance.

## Structure

```text
.
├── shell.qml                 # Quickshell entry point
├── Common/                   # Shared configuration and singleton services
├── Modules/                  # Bar, popups, and settings
├── Widgets/                  # Reusable QML components
├── Services/                 # QML services
├── scripts/qsctl.go          # Helper utility source
├── translations/             # UI translations
└── settings.json             # Persisted user settings
```

## Run

From the repository root:

```bash
quickshell --path .
```

To start the shell automatically, create a symbolic link to the project directory:

```bash
ln -s "$(pwd)" ~/.config/quickshell
```

## Build `qsctl`

`qsctl` is used by QML components for system operations including brightness, audio, and wallpaper control.

```bash
go build -o scripts/qsctl scripts/qsctl.go
```

Rebuild the utility and restart Quickshell after changing `scripts/qsctl.go`.

## Configuration

- Shared configuration is in `Common/Config.qml`.
- User settings are persisted by `Common/SettingsStore.qml` in `settings.json`.
- Appearance settings: `shellBlurEnabled`, `shellBordersEnabled`, `shellShadowsEnabled`.

## Verification

```bash
git diff --check
quickshell --path .
```
