# Shell Feature Matrix

Where to find each feature implemented across reference shells. Use this to study how a feature works before building your own.

## Legend
- **Caelestia** = `~/repo/shell/`
- **DMS** = `~/repo/DankMaterialShell/quickshell/`
- **II** = `~/repo/dots-hyprland/dots/.config/quickshell/ii/`
- **Noctalia** = `~/repo/noctalia-shell/`

## Status Bar

| Shell | Path |
|-------|------|
| Caelestia | `modules/bar/Bar.qml` — DelegateChooser pattern for configurable widget slots |
| DMS | `Modules/DankBar/DankBar.qml` — full bar with popout submenus |
| II | `modules/ii/bar/Bar.qml` — horizontal bar + `modules/ii/verticalBar/` alternative |
| Noctalia | `Modules/Bar/Bar.qml` — per-screen positioning (top/bottom/left/right), auto-hide, density modes |

## System Tray

| Shell | Path |
|-------|------|
| Caelestia | `modules/bar/components/Tray.qml` |
| DMS | DankBar includes tray |
| II | Bar includes tray |
| Noctalia | `Modules/Panels/Tray/` — SNI protocol |

## Workspace Switcher

| Shell | Path |
|-------|------|
| Caelestia | `modules/bar/components/workspaces/` — includes SpecialWorkspaces |
| DMS | `Modules/WorkspaceOverlays/` |
| II | Bar workspace widget + `modules/ii/overview/` for visual overview |
| Noctalia | Bar workspace widget |

## Audio Controls / Mixer

| Shell | Path |
|-------|------|
| Caelestia | `services/Audio.qml` (PipeWire singleton), `modules/controlcenter/audio/` |
| DMS | `Services/AudioService.qml`, ControlCenter audio pane |
| II | `services/Audio.qml`, `modules/ii/sidebarRight/volumeMixer/` |
| Noctalia | `Services/Media/AudioService.qml`, `Modules/Panels/Audio/` |

## Brightness Controls

| Shell | Path |
|-------|------|
| Caelestia | `services/Brightness.qml` — DDC-CI + backlight + Apple Display |
| DMS | `Services/DisplayService.qml` |
| II | `services/Brightness.qml` |
| Noctalia | `Services/Hardware/BrightnessService.qml` |

## Network / WiFi

| Shell | Path |
|-------|------|
| Caelestia | `services/Network.qml` + `services/Nmcli.qml`, `modules/controlcenter/network/WirelessPane.qml` |
| DMS | `Services/DMSNetworkService.qml` + `Services/NetworkService.qml` |
| II | `services/Network.qml`, `modules/ii/sidebarRight/wifiNetworks/` |
| Noctalia | `Services/Networking/NetworkService.qml`, `Modules/Panels/Network/` |

## Bluetooth

| Shell | Path |
|-------|------|
| Caelestia | `modules/controlcenter/bluetooth/BtPane.qml` |
| DMS | `Services/BluetoothService.qml` |
| II | `services/BluetoothStatus.qml`, `modules/ii/sidebarRight/bluetoothDevices/` |
| Noctalia | `Services/Networking/BluetoothService.qml`, `Modules/Panels/Bluetooth/` |

## Notification Daemon + Popups

| Shell | Path |
|-------|------|
| Caelestia | `modules/notifications/` — full daemon |
| DMS | `Modules/Notifications/Popup/` — popup notifications |
| II | `modules/ii/notificationPopup/`, `services/Notifications.qml` |
| Noctalia | `Modules/Notification/Notification.qml` (812 lines) — swipe gestures, 5-popup queue |

## Notification History

| Shell | Path | Notes |
|-------|------|-------|
| Caelestia | `modules/sidebar/NotifDock.qml` + `NotifGroup.qml` | Grouped by app |
| DMS | `Modules/Notifications/Center/` | Notification center panel |
| II | `modules/ii/sidebarRight/` notifications section | In right sidebar |
| Noctalia | `Modules/Panels/NotificationHistory/NotificationHistoryPanel.qml` (1022 lines) | **Most advanced**: persistent JSON storage (100 max), time-based filtering (All/Today/Yesterday/Earlier), markdown rendering, keyboard navigation, link detection, SHA256 deduplication, regex/wildcard rules engine |

**Noctalia notification service**: `Services/System/NotificationService.qml` (1241 lines) — the most complete implementation. Features: persistent history at `~/.cache/noctalia/notifications.json`, deduplication via content hashing, per-urgency sounds with app exclusions, rules engine (block/hide/mute with regex/wildcard/text matching), progress bar support, image caching.

## Media Player (MPRIS)

| Shell | Path |
|-------|------|
| Caelestia | `services/Players.qml`, `modules/dashboard/dash/Media.qml` |
| DMS | `Services/MprisController.qml`, `Modules/DankDash/MediaPlayerTab.qml` |
| II | `services/MprisController.qml`, `modules/ii/mediaControls/` |
| Noctalia | `Services/Media/MediaService.qml`, `Modules/Panels/Media/` |

## App Launcher / Search

| Shell | Path |
|-------|------|
| Caelestia | `modules/launcher/` — fuzzy search, wallpaper picker, custom actions |
| DMS | `Modules/AppDrawer/` + `Services/AppSearchService.qml` |
| II | `services/LauncherSearch.qml` + `services/AppSearch.qml` |
| Noctalia | `Modules/Panels/Launcher/` + clipboard history + emoji picker integrated |

## Lock Screen

| Shell | Path |
|-------|------|
| Caelestia | `modules/lock/` — PAM auth, notifications on lock, media controls |
| DMS | `Modules/Lock/` |
| II | `modules/ii/lock/` |
| Noctalia | `Modules/LockScreen/` — PAM auth, spectrum visualizer, media controls |

## Power / Session Menu

| Shell | Path |
|-------|------|
| Caelestia | `modules/session/Content.qml` |
| DMS | `Services/SessionService.qml` |
| II | `modules/ii/sessionScreen/` |
| Noctalia | `Modules/Panels/SessionMenu/` |

## Screenshot / Area Picker

| Shell | Path |
|-------|------|
| Caelestia | `modules/areapicker/AreaPicker.qml` |
| DMS | `Services/PortalService.qml` |
| II | `modules/ii/regionSelector/` |
| Noctalia | Not found |

## Color Picker

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | `Modules/DankBar/Widgets/ColorPicker.qml` |
| II | `modules/ii/sidebarRight/quickToggles/ColorPickerToggle.qml` |
| Noctalia | Not found |

## Wallpaper Selector

| Shell | Path |
|-------|------|
| Caelestia | `modules/launcher/WallpaperList.qml` |
| DMS | `Modules/DankDash/WallpaperTab.qml`, `Services/WallpaperCyclingService.qml` |
| II | `modules/ii/wallpaperSelector/` |
| Noctalia | `Modules/Panels/Wallpaper/` — Wallhaven API integration, favorites with color snapshots, 8 GPU transition effects |

## Dashboard / Overview

| Shell | Path |
|-------|------|
| Caelestia | `modules/dashboard/` — media, calendar, resources sparklines, weather |
| DMS | `Modules/DankDash/` — media, weather, wallpaper tabs |
| II | `modules/ii/overview/` — workspace grid with live window previews |
| Noctalia | `Modules/Overview/` |

## OSD (Volume / Brightness)

| Shell | Path |
|-------|------|
| Caelestia | `modules/osd/` |
| DMS | `Modules/OSD/` |
| II | `modules/ii/onScreenDisplay/` |
| Noctalia | `Modules/OSD/` |

## Dock / Taskbar

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | `Modules/Dock/` |
| II | `modules/ii/dock/` |
| Noctalia | `Modules/Dock/` — auto-hide, pinned + running apps, window grouping |

## Control Center / Quick Settings

| Shell | Path |
|-------|------|
| Caelestia | `modules/controlcenter/` — NavRail with panes: appearance, audio, bluetooth, network, notifications, taskbar, launcher |
| DMS | `Modules/ControlCenter/ControlCenterPopout.qml` |
| II | `modules/ii/sidebarRight/quickToggles/` |
| Noctalia | `Modules/Panels/ControlCenter/` |

## Settings UI

| Shell | Path |
|-------|------|
| Caelestia | Part of controlcenter panes |
| DMS | `Modules/Settings/` — dedicated settings module |
| II | Not present (config by code) |
| Noctalia | `Modules/Panels/Settings/` — 20+ tabs, comprehensive |

## Clipboard Manager

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | `Services/ClipboardService.qml` |
| II | `services/Cliphist.qml` — cliphist integration |
| Noctalia | `Services/Keyboard/ClipboardService.qml` — cliphistctl integration |

## Weather

| Shell | Path |
|-------|------|
| Caelestia | `services/Weather.qml`, `modules/dashboard/dash/SmallWeather.qml` |
| DMS | `Services/WeatherService.qml`, `Modules/DankDash/WeatherTab.qml` |
| II | `services/Weather.qml` |
| Noctalia | Bar weather widget |

## Battery Monitor

| Shell | Path |
|-------|------|
| Caelestia | `modules/BatteryMonitor.qml` |
| DMS | `Services/BatteryService.qml` |
| II | `services/Battery.qml` |
| Noctalia | `Services/Hardware/BatteryService.qml`, `Modules/Panels/Battery/` |

## Screen Recording

| Shell | Path |
|-------|------|
| Caelestia | `services/Recorder.qml`, `modules/utilities/cards/Record.qml` |
| DMS | Not present |
| II | `modules/ii/overlay/recorder/` |
| Noctalia | Not found |

## Virtual Keyboard

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | Not present |
| II | `modules/ii/onScreenKeyboard/` |
| Noctalia | Not found |

## AI Integration

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | Not present |
| II | `services/Ai.qml` (39KB) — Gemini, OpenAI, Mistral; `modules/ii/sidebarLeft/aiChat/` |
| Noctalia | Not present |

## Plugin System

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | `Modules/Plugins/`, `Services/PluginService.qml` — discovery, install, management |
| II | Not present |
| Noctalia | `Services/Noctalia/PluginService.qml` — widget/launcher registries, GitHub-based plugin sources |

## Screen Translation / OCR

| Shell | Path |
|-------|------|
| Caelestia | Not present |
| DMS | Not present |
| II | `modules/ii/screenTranslator/` — real-time OCR + translation overlay |
| Noctalia | Not present |

## IPC / CLI Control

| Shell | Path |
|-------|------|
| Caelestia | IpcHandler in modules (e.g., `qs ipc call dashboard toggle`) |
| DMS | Via `dms ipc call <target> <function>` (Go CLI) |
| II | Via Hyprland sockets |
| Noctalia | `Services/Control/` — IPC + custom buttons + hooks |

## Unique Features Per Shell

### Caelestia Only
- Blob-shaped custom borders (C++ BlobShape)
- Audio beat tracker + Cava visualizer
- C++20 native QML plugin for performance
- SparklineItem for resource graphs

### DMS Only
- Go backend with Unix socket IPC (full CLI)
- Multi-compositor support (Niri, Sway, labwc, etc.)
- Process monitor / task manager
- Notepad widget
- Greetd login greeter
- Desktop widget layer

### illogical-impulse Only
- AI chat (Gemini/OpenAI/Mistral)
- Virtual keyboard
- Screen translator (OCR)
- Keybind cheatsheet overlay
- FPS limiter overlay
- Floating notes overlay
- Pomodoro timer
- Song recognition
- Anti-flashbang shader
- Swappable panel families

### Noctalia Only
- 8 GPU-accelerated wallpaper transitions (GLSL shaders)
- Wallhaven API integration for wallpaper search
- Wallpaper favorites with color scheme snapshots
- Audio spectrum visualizer (3 modes: linear, mirrored, wave)
- Notification rules engine (regex/wildcard/text pattern matching)
- Notification deduplication (SHA256)
- Notification markdown rendering + link clicking
- Keyboard-navigable notification history with time filtering
- 10 predefined color schemes (Catppuccin, Dracula, Gruvbox, etc.)
- Setup wizard for first-time configuration
- 7-compositor support (Hyprland, Niri, Sway, Labwc, MangoWC, Scroll, generic)
- 50+ custom N-prefixed widget library
- Per-monitor wallpaper directories
- Deferred service initialization (critical vs non-critical split)
- i18n translations
