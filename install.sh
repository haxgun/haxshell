#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SHELL_DIR="$PROJECT_DIR/quickshell"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
readonly PACKAGES=(
  awww
  blueman
  bluez
  bluez-utils
  brightnessctl
  cava
  curl
  ffmpeg
  go
  hyprland
  hyprlock
  hyprpicker
  imagemagick
  kdialog
  networkmanager
  pavucontrol
  pipewire
  pipewire-pulse
  power-profiles-daemon
  qt6-declarative
  qt6-multimedia
  qt6-svg
  ttf-jetbrains-mono-nerd
  wireplumber
  xdg-desktop-portal-hyprland
  zenity
)
readonly AUR_PACKAGES=(vicinae-bin)

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ "$(uname -s)" != "Linux" ]]; then
  die "hush is supported only on Linux"
fi

if ! command -v pacman >/dev/null; then
  die "this installer supports Arch Linux and pacman-based distributions only"
fi

if [[ "${EUID}" -eq 0 ]]; then
  die "run this script as a regular user, not root"
fi

printf 'Installing repository dependencies...\n'
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

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

printf 'Building hushctl...\n'
go build -C "$PROJECT_DIR/core" -o "$SHELL_DIR/hushctl" ./cmd/hushctl
chmod +x "$SHELL_DIR/hushctl"

if [[ -e "$CONFIG_DIR" && ! -L "$CONFIG_DIR" ]]; then
  die "$CONFIG_DIR already exists and is not a symbolic link; move it before installing hush"
fi

mkdir -p "$(dirname "$CONFIG_DIR")"
if [[ -L "$CONFIG_DIR" ]]; then
  current_target="$(readlink -f "$CONFIG_DIR")"
  if [[ "$current_target" == "$PROJECT_DIR" ]]; then
    rm "$CONFIG_DIR"
    ln -s "$SHELL_DIR" "$CONFIG_DIR"
  elif [[ "$current_target" != "$SHELL_DIR" ]]; then
    die "$CONFIG_DIR points to $current_target; replace it manually if you want to use hush"
  fi
else
  ln -s "$SHELL_DIR" "$CONFIG_DIR"
fi

printf '\nhush is installed. Start it with:\n  quickshell --path %s\n' "$SHELL_DIR"
printf 'Add this command to your Hyprland startup configuration to launch it automatically.\n'
