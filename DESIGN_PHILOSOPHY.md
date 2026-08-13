# hush Design Philosophy & Technical Guide

A comprehensive overview of the design aesthetics, modular architecture, central configuration system, and advanced QML/Linux integration techniques used in the `hush` Hyprland desktop environment.

---

## 🎨 Design Philosophy & Aesthetics

### 1. Unified Frosted Glassmorphism
- **Color Palette & Theme Tokens (Centralized in `Config.qml`)**:
  - **Surface Tint (`Config.glassBg`)**: `#900f1823` (70% translucent dark obsidian blue).
  - **Hover Surface (`Config.glassHoverBg`)**: `#c00f1823` (85% translucent dark surface).
  - **Primary Text (`Config.textPrimary`)**: `#e2e8f0` (Bright Slate).
  - **Muted Text / Subtitles (`Config.textMuted`)**: `#94a3b8` (Muted Slate).
  - **Accents**: `#1db954` (Spotify Green), `#f59e0b` (Amber Warning), `#f87171` (Crimson Mute / Power Red).
- **Surface Elevation & Borders**:
  - `radius: 14` (`Config.widgetRadius`) for top bar floating widget cards; `radius: 18` (`Config.overlayRadius`) for main overlays.
  - 1px translucent inner border (`Config.borderColor`: `#80464646`) creating subtle contrast on dynamic wallpapers.
  - Shell-wide toggles in `Config.qml` control blur appearance, borders, and shadows for the `Bar` and overlay surfaces.

### 2. Strict Dimensional Standardization
- **Uniform Bar Height**: All top bar widgets (`WorkspaceWidget`, `ClockWidget`, `StatusWidget`) share a standardized `implicitHeight: 40px` (`Config.barHeight`) and 28px inner button heights (`Config.buttonHeight`).
- **Symmetric Centering**: The `ClockWidget` extends symmetrically on both sides (`Config.mprisTargetSideWidth: 190px`), ensuring the central Date & Time clock remains anchored to the exact horizontal center of the top bar.

### 3. Non-Intrusive Micro-Animations
- **Smooth Easing Curves**: All width, opacity, and color transitions utilize `Behavior` animations (`NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }`).
- **Zero Layout Shifting**: Interactive controls fade in using `opacity` in designated dead-space padding rather than resizing neighboring progress bars or timestamps.

---

## 🛠️ Modular Architecture & Technical Implementation

### 1. Centralized Configuration System (`Config.qml` & `qmldir`)
All theme tokens, design metrics, typography definitions, component behavior options, icon glyphs, and shell launcher commands are defined in a single QML singleton ([Config.qml](Config.qml)). Registered via [qmldir](qmldir), `Config` is accessible across all components without ad-hoc imports or duplicate hardcoded values.

### 2. Externalized System Integration
System integration and resource polling are decoupled from UI components into the `hushctl` Go command under `core/`.

### 3. Hyprland LayerShell Blur Rule Integration
For the frosted glass effect to render seamlessly on Wayland, `hush` `Bar` and overlay windows set `WlrLayershell.namespace: "quickshell-bar"`. Hyprland matches this namespace in [windows_and_workspaces.lua](../../hypr/.config/hypr/windows_and_workspaces.lua):
```lua
hl.layer_rule({
    name = "quickshell-frosted-glass",
    match = { namespace = "quickshell-bar" },
    blur = true,
    ignore_alpha = 0.2,
})
```

### 4. Detached Application Spawning (`setsid -f`)
Applications launched from the drawer or top bar status controls utilize POSIX session detachment:
```qml
appLauncher.command = ["setsid", "-f", "sh", "-c", commandStr]
```
`setsid -f` creates a brand new Linux session group, allowing launched applications (Firefox, Terminal, Dolphin) to survive Quickshell reloads completely unaffected.

---

## 📁 Component Architecture Overview

```
~/.config/quickshell/
├── Config.qml              # Central design tokens, metrics, options, icons & commands
├── qmldir                  # QML module definition registering Config singleton
├── shell.qml               # hush root entry point instantiating Bar & overlays
├── Modules/.../Bar.qml      # Bar container embedding widgets
├── WorkspaceWidget.qml     # Hyprland workspace indicator & app launcher icon
├── ClockWidget.qml         # Center Date/Time clock & symmetrical MPRIS player
├── StatusWidget.qml        # Audio volume, Bluetooth, Wi-Fi/Ethernet & Power controls
├── AppDrawer.qml           # Searchable application launcher overlay
├── CalendarPopup.qml       # Compact interactive month/year calendar overlay
├── BrightnessPopup.qml     # Hardware display brightness slider overlay
├── AppLauncher.qml         # Helper component for session-detached app spawning
├── AppScanner.qml          # Process wrapper executing hushctl
└── core/
    ├── cmd/hushctl/         # Command entry point
    ├── internal/hushctl/    # JSON system helper implementation
    └── hushctl              # Built helper executed by QML Process objects
```
