# hush

<p align="center"><img src="logo.svg" alt="hush logo" width="160"></p>

[English](README.md) | [Русский](README.ru.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Niri](https://img.shields.io/badge/Niri-Wayland-7c4dff.svg)](https://github.com/YaLTeR/niri)
[![Go](https://img.shields.io/badge/Go-1.24-00ADD8.svg)](https://go.dev/)

`hush` is a customizable Wayland desktop shell built with Quickshell, QML, and Go for Hyprland and Niri.

## Features

- Bar placement at the top, bottom, left, or right edge.
- Workspace switcher and focused application indicator.
- Popups for Wi-Fi, Bluetooth, brightness, audio, battery, calendar, media, and power.
- Compact control center with quick settings, real-time brightness and volume sliders, power profiles, theme, airplane mode, and media controls.
- Separate speaker and microphone volume controls with PipeWire device selection.
- Shared MPRIS controller with album artwork, live playback progress, and bar metadata.
- Notification toasts and notification center.
- Wallpaper picker with extracted color palettes and a dynamic theme that colors shell surfaces from the current wallpaper.
- Persistent settings for the theme, bar, fonts, notifications, OSD, wallpaper behavior, and shell appearance.

## Structure

```text
.
├── quickshell/               # Quickshell configuration
│   ├── shell.qml             # Quickshell entry point
│   ├── Common/               # Shared configuration and singleton services
│   ├── Modules/              # Bar, popups, and settings
│   ├── Widgets/              # Reusable QML components
│   ├── Services/             # QML services
│   └── translations/         # UI translations
├── core/                     # Go module for hushctl
│   ├── cmd/hushctl/          # hushctl command entry point
│   ├── internal/hushctl/     # Shell-specific command implementation
│   ├── pkg/                  # Public Go packages
│   ├── go.mod
│   └── go.sum
└── install.sh                # Arch Linux installer
```

## Run

From the repository root:

```bash
quickshell --path quickshell
```

To start the shell automatically, create a symbolic link to the project directory:

```bash
ln -s "$(pwd)/quickshell" ~/.config/quickshell
```

## Install

The included installer targets Arch Linux. It installs repository and AUR dependencies, builds `hushctl`, and links this repository to `~/.config/quickshell` without replacing an existing configuration.

```bash
./install.sh
```

`yay` or `paru` is required when Vicinae is not installed because it is installed from the AUR.

## Build `hushctl`

`hushctl` is used by QML components for system operations including brightness, audio, weather, and wallpaper control.

```bash
go build -C core -o ../quickshell/hushctl ./cmd/hushctl
```

Rebuild the utility and restart Quickshell after changing files under `core/`.

## Configuration

- Shared configuration is in `quickshell/Common/Config.qml`.
- User settings are persisted by `quickshell/Common/SettingsStore.qml` in `quickshell/settings.json`.
- Appearance settings: blur, borders, shadows, palette, typography, bar geometry, notifications, OSD, and wallpaper rotation are available from the Settings popup.
- Dynamic theme stores the extracted wallpaper palette in `dynamicPalette` and applies it to shell surfaces, controls, borders, tracks, and workspace indicators.

## Verification

```bash
git diff --check
quickshell --path quickshell
```
