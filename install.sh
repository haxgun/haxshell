#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SHELL_DIR="$PROJECT_DIR/quickshell"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
COMPOSITOR="${NATON_COMPOSITOR:-}"
readonly PACKAGES=(
  awww
  blueman
  bluez
  bluez-utils
  brightnessctl
  cava
  curl
  ffmpeg
  fontconfig
  grim
  khal
  go
  hyprland
  hyprlock
  imagemagick
  kdialog
  mpv
  networkmanager
  pavucontrol
  pipewire
  pipewire-pulse
  power-profiles-daemon
  qt6-declarative
  qt6-multimedia
  qt6-svg
  ttf-jetbrains-mono-nerd
  slurp
  swayidle
  wl-clipboard
  wlsunset
  wireplumber
  xdg-desktop-portal-hyprland
  zenity
)
readonly AUR_PACKAGES=(mpvpaper vicinae-bin)
readonly NIRI_PACKAGES=(base-devel cmake git niri)

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'Usage: %s [--compositor hyprland|niri]\n' "$(basename -- "$0")"
  exit "${1:-0}"
}

if [[ "$(uname -s)" != "Linux" ]]; then
  die "Naton is supported only on Linux"
fi

if ! command -v pacman >/dev/null; then
  die "this installer supports Arch Linux and pacman-based distributions only"
fi

if [[ "${EUID}" -eq 0 ]]; then
  die "run this script as a regular user, not root"
fi

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "--compositor" && $# -eq 2 ]]; then
    COMPOSITOR="$2"
  elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage 0
  else
    usage 1
  fi
fi
if [[ -z "$COMPOSITOR" ]]; then
  COMPOSITOR=$([[ -n "${NIRI_SOCKET:-}" ]] && printf 'niri' || printf 'hyprland')
fi
if [[ "$COMPOSITOR" != "hyprland" && "$COMPOSITOR" != "niri" ]]; then
  die "unsupported compositor: $COMPOSITOR"
fi

printf 'Installing repository dependencies...\n'
if [[ "$COMPOSITOR" == "niri" ]]; then
  sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" "${NIRI_PACKAGES[@]}"
else
  sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
fi

if ! command -v quickshell >/dev/null; then
  die "quickshell was not installed; enable a repository that provides it, then rerun this script"
fi

if systemctl --user is-active --quiet dunst.service; then
  printf 'Stopping Dunst so Quickshell can receive notifications...\n'
  systemctl --user mask --now dunst.service
fi

if ! command -v vicinae >/dev/null; then
  if ! command -v yay >/dev/null && ! command -v paru >/dev/null; then
    die "install an AUR helper (yay or paru), then rerun this script to install: ${AUR_PACKAGES[*]}"
  fi
  AUR_HELPER="$(command -v yay || command -v paru)"
  printf 'Installing AUR dependencies with %s...\n' "$(basename "$AUR_HELPER")"
  "$AUR_HELPER" -S --needed --noconfirm "${AUR_PACKAGES[@]}"
fi

if [[ "$COMPOSITOR" == "niri" ]]; then
  readonly NIRI_BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf -- "$NIRI_BUILD_DIR"' EXIT
  printf 'Building qml-niri QML module...\n'
  git clone --depth 1 https://github.com/imiric/qml-niri.git "$NIRI_BUILD_DIR/qml-niri"
  cmake -S "$NIRI_BUILD_DIR/qml-niri" -B "$NIRI_BUILD_DIR/qml-niri/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build "$NIRI_BUILD_DIR/qml-niri/build"
  sudo cmake --install "$NIRI_BUILD_DIR/qml-niri/build"
fi

printf 'Building natonctl...\n'
go build -C "$PROJECT_DIR/core" -o "$SHELL_DIR/natonctl" ./cmd/natonctl
chmod +x "$SHELL_DIR/natonctl"

if [[ -e "$CONFIG_DIR" && ! -L "$CONFIG_DIR" ]]; then
  die "$CONFIG_DIR already exists and is not a symbolic link; move it before installing Naton"
fi

mkdir -p "$(dirname "$CONFIG_DIR")"
if [[ -L "$CONFIG_DIR" ]]; then
  current_target="$(readlink -f "$CONFIG_DIR")"
  if [[ "$current_target" == "$PROJECT_DIR" ]]; then
    rm "$CONFIG_DIR"
    ln -s "$SHELL_DIR" "$CONFIG_DIR"
  elif [[ "$current_target" != "$SHELL_DIR" ]]; then
    die "$CONFIG_DIR points to $current_target; replace it manually if you want to use Naton"
  fi
else
  ln -s "$SHELL_DIR" "$CONFIG_DIR"
fi

if [[ "$COMPOSITOR" == "hyprland" ]]; then
  HYPR_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
  HYPR_BINDS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/naton"
  HYPR_BINDS="$HYPR_BINDS_DIR/binds.conf"
  HYPR_INCLUDE="source = ~/.config/quickshell/keybinds/hyprland.conf"
  HYPR_USER_INCLUDE="source = ~/.config/hypr/naton/binds.conf"
  mkdir -p "$HYPR_BINDS_DIR"
  [[ -e "$HYPR_BINDS" ]] || : > "$HYPR_BINDS"
  if [[ -f "$HYPR_CONFIG" ]] && ! grep -Fqx "$HYPR_INCLUDE" "$HYPR_CONFIG"; then
    printf '\n%s\n' "$HYPR_INCLUDE" >> "$HYPR_CONFIG"
  fi
  if [[ -f "$HYPR_CONFIG" ]] && ! grep -Fqx "$HYPR_USER_INCLUDE" "$HYPR_CONFIG"; then
    printf '\n%s\n' "$HYPR_USER_INCLUDE" >> "$HYPR_CONFIG"
  fi
elif [[ "$COMPOSITOR" == "niri" ]]; then
  NIRI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
  NIRI_BINDS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/niri/naton"
  NIRI_BINDS="$NIRI_BINDS_DIR/binds.kdl"
  NIRI_INCLUDE='include "../quickshell/keybinds/niri.kdl"'
  NIRI_USER_INCLUDE='include "./naton/binds.kdl"'
  mkdir -p "$NIRI_BINDS_DIR"
  [[ -e "$NIRI_BINDS" ]] || printf 'binds {}\n' > "$NIRI_BINDS"
  if [[ -f "$NIRI_CONFIG" ]] && ! grep -Fqx "$NIRI_INCLUDE" "$NIRI_CONFIG"; then
    printf '\n%s\n' "$NIRI_INCLUDE" >> "$NIRI_CONFIG"
  fi
  if [[ -f "$NIRI_CONFIG" ]] && ! grep -Fqx "$NIRI_USER_INCLUDE" "$NIRI_CONFIG"; then
    printf '\n%s\n' "$NIRI_USER_INCLUDE" >> "$NIRI_CONFIG"
  fi
fi

printf '\nNaton is installed. Start it with:\n  quickshell --path %s\n' "$SHELL_DIR"
printf 'Add this command to your %s startup configuration to launch it automatically.\n' "$COMPOSITOR"
