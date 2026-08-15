<div align="center">

<p align="center">
    <img src="docs/logo.svg" alt="vey logo" width="160">
</p>

`vey` is a customizable Wayland desktop shell built with Quickshell, QML, and Go for Hyprland and Niri.

**English** · [Русский](README.ru.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Niri](https://img.shields.io/badge/Niri-Wayland-7c4dff.svg)](https://github.com/YaLTeR/niri)
[![Go](https://img.shields.io/badge/Go-1.25-00ADD8.svg)](https://go.dev/)
[![Stars](https://img.shields.io/github/stars/haxgun/vey?style=flat&color=green)](https://github.com/ValoryLabs/Valory/stargazers)
[![Forks](https://img.shields.io/github/forks/haxgun/vey?style=flat&color=green)](https://github.com/ValoryLabs/Valory/forks)
[![Issues](https://img.shields.io/github/issues/haxgun/vey?style=flat)](https://github.com/ValoryLabs/Valory/issues)
![GitHub last commit](https://img.shields.io/github/last-commit/haxgun/vey)

</div>

## Features

- Bar placement at the top, bottom, left, or right edge with configurable margins.
- Workspace switcher, focused application indicator, clock, weather, media, tray, and system widgets on the bar, each independently toggleable.
- Popups for Wi-Fi, Bluetooth, brightness, audio, battery, calendar, media, power, and settings, anchored to the bar so they follow its position on any edge.
- Compact control center with pill quick actions (Wi-Fi, Bluetooth, Do Not Disturb, keep screen on), a screenshot button, brightness and volume sliders, CPU/RAM/disk stats, power profiles, theme, and media controls with track switching.
- Separate speaker and microphone volume controls with PipeWire device selection.
- Shared MPRIS controller with album artwork, live playback progress, bar metadata, and a media popup with a blurred artwork backdrop.
- Notification toasts and notification center.
- Wallpaper picker with extracted color palettes and a dynamic theme that colors shell surfaces from the current wallpaper. Seven palette schemes (`vibrant`, `faithful`, `dysfunctional`, `muted`, `soft`, `material`, `monochrome`) with animated color transitions between wallpapers.
- Persistent settings for the theme, bar, typography (separate sans and mono families with independent scaling), notifications, OSD, wallpaper behavior, and shell appearance.

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
├── core/                     # Go module for veyctl
│   ├── cmd/veyctl/          # veyctl command entry point
│   ├── internal/veyctl/     # Shell-specific command implementation
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

The included installer targets Arch Linux. It installs repository and AUR dependencies, builds `veyctl`, and links this repository to `~/.config/quickshell` without replacing an existing configuration.

```bash
./install.sh
```

For Niri, install the event-driven `qml-niri` integration as a required dependency:

```bash
./install.sh --compositor niri
```

`yay` or `paru` is required when Vicinae is not installed because it is installed from the AUR.

## Dependencies

### Runtime

- `quickshell` — the shell runtime
- `curl` — weather, holidays, and the About section
- `awww` — wallpaper daemon
- `imagemagick` — palette extraction, thumbnails, wallpaper tiling
- `ffmpeg` — video wallpaper thumbnails
- `brightnessctl` — brightness control
- `power-profiles-daemon` — power profiles
- `pipewire`, `pipewire-pulse`, `wireplumber` — audio
- `networkmanager` — Wi-Fi and network status
- `bluez`, `bluez-utils`, `blueman` — Bluetooth
- `qt6-declarative`, `qt6-svg`, `qt6-multimedia` — Qt runtime
- `ttf-jetbrains-mono-nerd` — icon glyphs
- `zenity` or `kdialog` — folder picker
- `pavucontrol` — volume control GUI

### Build

- `go` 1.25+

### Compositor

One of:

- **Hyprland** — `hyprland`, `hyprlock`, `hyprpicker`, `xdg-desktop-portal-hyprland`, `grim`
- **Niri** — `niri`, plus `base-devel`, `cmake`, `git` to build the `qml-niri` module

### Optional

- `vicinae` (AUR) — app launcher
- `cava` — bar music visualizer

Quickshell handles notifications itself — disable any other notification daemon (such as Dunst) so toasts are not duplicated.

## Build `veyctl`

`veyctl` is used by QML components for system operations including brightness, audio, weather, and wallpaper control.

```bash
go build -C core -o ../quickshell/veyctl ./cmd/veyctl
```

Rebuild the utility and restart Quickshell after changing files under `core/`.

## Configuration

- Shared configuration is in `quickshell/Common/Config.qml`.
- User settings are persisted by `quickshell/Common/SettingsStore.qml` in `quickshell/settings.json`.
- Appearance settings: blur, borders, shadows, palette, typography (sans/mono family and scale), bar geometry and margins, per-widget bar toggles, popup positioning, notifications, OSD, and wallpaper rotation are available from the Settings popup.
- Screenshots are taken with the compositor tooling (`niri msg action screenshot` on Niri, `grim` on Hyprland).
- Dynamic theme stores the extracted wallpaper palette in `dynamicPalette` and applies it to shell surfaces, controls, borders, tracks, and workspace indicators.

## Verification

```bash
git diff --check
quickshell --path quickshell
```

## Stats

![Alt](https://repobeats.axiom.co/api/embed/3caf808ce8401c6c39d1913e45a21c801fd6263a.svg "Repobeats analytics image")

<div align="center">
    <a href="https://github.com/haxgun/vey/graphs/contributors" target="_blank">
      <table>
        <tr>
          <th colspan="2">
            <br><img src="https://contrib.rocks/image?repo=haxgun/vey" /><br><br>
          </th>
        </tr>
      </table>
    </a>
</div>
