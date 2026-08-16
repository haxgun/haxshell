# Reference Repositories

Local repositories to consult for real-world Quickshell patterns and implementations.

## quickshell-examples (`~/repo/quickshell-examples/`)

**Best for:** Clean, minimal examples of individual features.

| Example | Demonstrates |
|---------|-------------|
| `activate_linux/` | Variants, PanelWindow, WlrLayer.Overlay, Region mask, multi-monitor |
| `focus_following_panel/` | Socket IPC, Hyprland event parsing, dynamic screen assignment |
| `lockscreen/` | WlSessionLock, PamContext, multi-surface shared state via Scope |
| `mixer/` | PipeWire API, PwNodeLinkTracker, PwObjectTracker, Repeater with required props |
| `volume-osd/` | LazyLoader, ephemeral PanelWindow, PwObjectTracker, click-through mask |
| `reload-popup/` | Quickshell.reloadCompleted signal, LazyLoader, PropertyAnimation |
| `wlogout/` | Overlay with keyboard focus, GridLayout, Process.startDetached, Keys.onPressed |

## caelestia-shell (`~/repo/shell/`)

**Best for:** Production shell architecture — config system, services, modules, C++ plugin.

| Path | Contains |
|------|----------|
| `shell.qml` | Entry point with pragmas, module imports |
| `config/Config.qml` | JsonAdapter + FileView config with debounced save |
| `config/*.qml` | Per-feature config sections (AppearanceConfig, BarConfig, etc.) |
| `services/Audio.qml` | PipeWire singleton with volume control, cava integration |
| `services/Hypr.qml` | Hyprland singleton wrapping IPC: workspaces, monitors, toplevels, keyboard state |
| `services/Brightness.qml` | Multi-backend brightness (backlight, DDC-CI, Apple Display) |
| `services/Colours.qml` | Material Design 3 dynamic color system from wallpaper |
| `services/Network.qml` | NetworkManager wrapper |
| `services/Players.qml` | MPRIS player management |
| `modules/bar/` | Status bar with DelegateChooser pattern |
| `modules/drawers/` | Drawer system with HyprlandFocusGrab, layer shell |
| `modules/dashboard/` | Dashboard with media, calendar, resources sparklines |
| `modules/launcher/` | App launcher with fuzzy search |
| `modules/controlcenter/` | Settings UI with NavRail |
| `modules/lock/` | Lock screen with PAM, notifications, media on lock |
| `modules/notifications/` | Full notification daemon |
| `components/controls/` | Material Design control library (switches, sliders, progress rings) |
| `plugin/src/Caelestia/` | C++20 native QML module for performance-critical components |

## DankMaterialShell (`~/repo/DankMaterialShell/`)

**Best for:** Large-scale QML architecture, Go backend IPC, Material Design 3 theming.

| Path | Contains |
|------|----------|
| `quickshell/Modules/` | 15+ UI modules (TopBar, Dock, ControlCenter, Notifications, Lock, Spotlight, etc.) |
| `quickshell/Services/` | 31 singleton services (AudioService, NetworkService, HyprlandService, etc.) |
| `quickshell/Widgets/` | Material Design 3 component library |
| `quickshell/Common/` | Themes, settings, translations (I18n) |
| `core/` | Go backend with Unix socket IPC, Wayland protocols, D-Bus |
| `core/cmd/dms/` | CLI tool for controlling the shell via IPC |

## dots-hyprland / illogical-impulse (`~/repo/dots-hyprland/`)

**Best for:** Feature-rich rice, swappable panel families, AI integration.

| Path | Contains |
|------|----------|
| `dots/.config/quickshell/ii/shell.qml` | Entry point loading panel families |
| `dots/.config/quickshell/ii/modules/ii/bar/` | Status bar widgets |
| `dots/.config/quickshell/ii/modules/ii/sidebarLeft/` | Left sidebar with quick settings |
| `dots/.config/quickshell/ii/modules/ii/overview/` | Workspace overview with live previews |
| `dots/.config/quickshell/ii/modules/ii/screenTranslator/` | Real-time OCR translation overlay |
| `dots/.config/quickshell/ii/services/` | 44 singleton services |
| `dots/.config/quickshell/ii/GlobalStates.qml` | Global state management |
| `dots/.config/hypr/hyprland/` | Hyprland config (keybinds, rules, animations, env) |

## noctalia-shell (`~/repo/noctalia-shell/`)

**Best for:** Notification system (history, rules, dedup), wallpaper transitions (GLSL shaders), multi-compositor support, widget library, plugin system.

| Path | Contains |
|------|----------|
| `shell.qml` | Entry point with deferred service init pattern (critical vs non-critical) |
| `Services/System/NotificationService.qml` | **1241 lines** — most complete notification daemon: persistent history, SHA256 dedup, rules engine, sounds, progress bars |
| `Services/System/NotificationRulesService.qml` | Regex/wildcard/text pattern matching with block/hide/mute actions |
| `Modules/Notification/Notification.qml` | 812-line popup with swipe gestures and threshold detection |
| `Modules/Panels/NotificationHistory/NotificationHistoryPanel.qml` | 1022-line history panel: time filtering, markdown rendering, keyboard navigation, link detection |
| `Services/UI/WallpaperService.qml` | Per-monitor wallpapers, Wallhaven API, favorites with color snapshots |
| `Shaders/frag/wp_*.frag` | 8 GLSL wallpaper transition effects (fade, wipe, disc, honeycomb, pixelate, etc.) |
| `Services/Compositor/` | 7-compositor abstraction layer (Hyprland, Niri, Sway, Labwc, MangoWC, Scroll, generic) |
| `Services/Theming/ColorSchemeService.qml` | 10 predefined color schemes + auto-generation from wallpaper |
| `Widgets/` | 50+ N-prefixed widget library (NButton, NSlider, NTabView, NAudioSpectrum, etc.) |
| `Commons/Settings.qml` | 46KB settings management with migration system |
| `Commons/Style.qml` | Centralized design tokens |
| `Modules/Panels/Settings/` | 20+ settings tabs |

## quickshell source (`~/repo/quickshell/src/`)

**Best for:** Understanding the framework internals, module.md files document the QML API.

| Path | Contains |
|------|----------|
| `src/core/module.md` | Quickshell module type list |
| `src/io/module.md` | Quickshell.Io module type list |
| `src/wayland/module.md` | Quickshell.Wayland module type list |
| `src/wayland/hyprland/module.md` | Quickshell.Hyprland module type list |
| `src/services/*/module.md` | Each service module's type list |
| `src/*/` | C++ source for each module |

## quickshell-docs (`~/repo/quickshell-docs/content/docs/`)

**Best for:** Official guides and tutorials.

| Path | Contains |
|------|----------|
| `configuration/intro.md` | Getting started tutorial (shell files, windows, processes, timers, variants, singletons) |
| `configuration/qml-overview.md` | QML language reference (imports, properties, signals, bindings, lazy loading) |
| `configuration/positioning.md` | Layout guide (anchors, layouts, manual positioning) |
