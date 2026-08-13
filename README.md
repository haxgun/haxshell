# hush

<p align="center"><img src="logo.svg" alt="hush logo" width="160"></p>

[English](README.md) | [Русский](README.ru.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Go](https://img.shields.io/badge/Go-1.24-00ADD8.svg)](https://go.dev/)

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
├── core/                     # Go module for hushctl
│   ├── cmd/hushctl/          # hushctl command entry point
│   ├── internal/hushctl/     # Shell-specific command implementation
│   ├── pkg/                  # Public Go packages
│   ├── go.mod
│   └── go.sum
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

## Install

The included installer targets Arch Linux with Hyprland. It installs repository and AUR dependencies, builds `hushctl`, and links this repository to `~/.config/quickshell` without replacing an existing configuration.

```bash
./install.sh
```

`yay` or `paru` is required when Vicinae is not installed because it is installed from the AUR.

## Build `hushctl`

`hushctl` is used by QML components for system operations including brightness, audio, weather, and wallpaper control.

```bash
go build -C core -o hushctl ./cmd/hushctl
```

Rebuild the utility and restart Quickshell after changing files under `core/`.

## Configuration

- Shared configuration is in `Common/Config.qml`.
- User settings are persisted by `Common/SettingsStore.qml` in `settings.json`.
- Appearance settings: `shellBlurEnabled`, `shellBordersEnabled`, `shellShadowsEnabled`.

## Verification

```bash
git diff --check
quickshell --path .
```
