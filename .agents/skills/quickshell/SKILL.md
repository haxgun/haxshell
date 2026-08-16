---
name: quickshell
description: "Use this skill when writing, reviewing, or debugging Quickshell configurations (QML files for desktop shell UI on Wayland/Hyprland). Triggers on: QML files with Quickshell imports, shell.qml entry points, PanelWindow or FloatingWindow usage, Quickshell service integration (PipeWire, MPRIS, notifications, Hyprland IPC), Wayland layer-shell or session-lock code, custom bar/panel/widget/dock/OSD/lockscreen/launcher development, or any question about building a desktop shell with Quickshell on Hyprland."
---

# Quickshell Development

## Overview

Quickshell is a Qt6/QML desktop shell toolkit that Claude does not have reliable training data for. This skill provides the complete API reference, architectural patterns, gotchas, and pointers to local reference repositories needed to write correct Quickshell QML. Without it, Claude will hallucinate Quickshell types, confuse it with other shell frameworks, or miss critical patterns like PwObjectTracker and the Variants multi-monitor pattern.

Build desktop shells (bars, panels, docks, lockscreens, launchers, OSDs, dashboards, notification daemons) using the Quickshell framework on Wayland compositors, primarily Hyprland.

## What Quickshell Is

Quickshell is a Qt6/QML-based shell toolkit. You write declarative QML that Quickshell renders as Wayland surfaces (panels, overlays, floating windows). It live-reloads on file save. Config lives at `~/.config/quickshell/shell.qml` by default.

Key differentiators from other shell frameworks (AGS, EWW):
- Native Qt6/QML with full QtQuick — not a custom DSL
- Reactive property bindings, not imperative updates
- Live reload with state preservation via the Reloadable system
- Direct Wayland protocol integration (layer-shell, session-lock, screencopy)
- Deep Hyprland IPC integration as first-class QML types

## Core Architecture

### Entry Point

Every shell starts with a `ShellRoot` in `shell.qml`:

```qml
import Quickshell

ShellRoot {
    // Non-visual root container for all shell objects
    // settings.watchFiles: true  — enables live reload on file change
}
```

### Window Types

| Type | Use | Key Properties |
|------|-----|----------------|
| `PanelWindow` | Bars, panels, widgets anchored to screen edges | `anchors.{top,bottom,left,right}`, `height`/`width`, `exclusiveZone`, `screen` |
| `FloatingWindow` | Standard desktop windows, settings UIs | Standard Qt window properties |
| `WlSessionLockSurface` | Lock screen surfaces | Used inside `WlSessionLock` |

### Multi-Monitor Pattern (critical)

**Always** use `Variants` with `Quickshell.screens` for per-monitor windows:

```qml
Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData
        anchors { top: true; left: true; right: true }
        height: 30
    }
}
```

This is reactive — windows create/destroy as monitors connect/disconnect. Never hardcode screens.

### Non-Visual Containers

- `Scope` — groups non-visual children (Process, Timer, Connections). Use when extracting components to separate files
- `Singleton` (with `pragma Singleton`) — global shared state accessible from any file. Use for services and shared data
- `ShellRoot` — the outermost Scope; properties defined here are accessible without an id from nested scopes

### Component Organization

```
~/.config/quickshell/
├── shell.qml          # Entry point (ShellRoot)
├── modules/           # Major UI subsystems (bar/, dashboard/, lock/, etc.)
├── components/        # Reusable UI components
├── services/          # Singleton services (Audio, Network, Hypr, etc.)
├── config/            # Configuration system
└── utils/             # Utility singletons
```

Uppercase QML filenames become types automatically. `Bar.qml` becomes `Bar {}`. Import subdirectories with `import "modules/bar"`.

## QML Patterns for Quickshell

See `references/qml-patterns.md` for the complete pattern library with code examples.

Key patterns:
1. **Reactive bindings** — `text: Time.time` auto-updates when `Time.time` changes
2. **Signal connections** — `Connections { target: X; function onSignal() {...} }` or arrow: `onRead: data => clock.text = data`
3. **LazyLoader** — `LazyLoader { active: condition; PanelWindow { ... } }` for memory-efficient ephemeral UI
4. **Process execution** — `Process { command: ["cmd"]; stdout: SplitParser { onRead: data => prop = data } }`
5. **Timers** — `Timer { interval: 1000; running: true; repeat: true; onTriggered: ... }`
6. **Required properties in delegates** — `required property PwLinkGroup modelData` in Repeater delegates
7. **Optional chaining** — `sink?.audio?.volume ?? 0` for nullable service objects
8. **Click-through windows** — `mask: Region {}` makes a window transparent to input

## Available Modules

See `references/modules-api.md` for the full module reference with all types and properties.

### Core
- **Quickshell** — ShellRoot, PanelWindow, FloatingWindow, Variants, Scope, Singleton, LazyLoader, Region, Quickshell.screens, Quickshell.iconPath(), Quickshell.env()
- **Quickshell.Io** — Process, SplitParser, Socket, SocketServer, FileView, IpcHandler, JsonAdapter
- **Quickshell.Widgets** — IconImage, ClippingRectangle, WrapperRectangle

### Wayland
- **Quickshell.Wayland** — WlrLayershell (WlrLayer.Overlay/Top/Bottom/Background), WlSessionLock, WlSessionLockSurface, idle inhibit/notify, screencopy, background effects
- **Quickshell.Hyprland** — Hyprland (singleton: monitors, workspaces, toplevels, focusedWorkspace, focusedMonitor, activeToplevel), HyprlandFocusGrab, CustomShortcut, dispatch()

### Services
- **Quickshell.Services.Pipewire** — Pipewire.defaultAudioSink/Source, PwNode (.audio.volume, .audio.muted), PwObjectTracker, PwNodeLinkTracker
- **Quickshell.Services.Mpris** — Mpris (singleton: players), MprisPlayer
- **Quickshell.Services.Notifications** — NotificationServer, Notification
- **Quickshell.Services.Pam** — PamContext, PamResult
- **Quickshell.Services.UPower** — UPower (singleton: devices)
- **Quickshell.Services.Polkit** — PolkitAgent
- **Quickshell.Services.Greetd** — Greetd

### Hardware
- **Quickshell.Bluetooth** — Bluetooth (singleton: adapters, devices)
- **Quickshell.Networking** — NetworkManager (singleton: devices, connections)

## Hyprland Integration

### Accessing Hyprland State

```qml
import Quickshell.Hyprland

// All reactive — auto-update on compositor changes
Hyprland.monitors          // ObjectModel<HyprlandMonitor>
Hyprland.workspaces        // ObjectModel<HyprlandWorkspace>
Hyprland.toplevels         // ObjectModel<HyprlandToplevel>
Hyprland.focusedMonitor    // HyprlandMonitor
Hyprland.focusedWorkspace  // HyprlandWorkspace
Hyprland.activeToplevel    // HyprlandToplevel

// Dispatch commands
Hyprland.dispatch("workspace 3")
Hyprland.dispatch("movetoworkspace 5")
```

### Layer Shell Positioning

```qml
PanelWindow {
    WlrLayershell.layer: WlrLayer.Top      // Top, Bottom, Overlay, Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive  // for modals
    exclusiveZone: 0                        // 0 = don't reserve space
    exclusionMode: ExclusionMode.Ignore     // ignore other panels' zones
}
```

### Focus Grab (for drawers/popups)

```qml
HyprlandFocusGrab {
    id: focusGrab
    active: drawerVisible
    windows: [drawerWindow]
    onCleared: drawerVisible = false  // clicked outside
}
```

### IPC: Triggering Shell Actions from Hyprland Keybinds

Two mechanisms to wire Hyprland keybinds to shell actions:

**1. Native global shortcuts (preferred, lower latency):**
```conf
# hyprland.conf
bind = Super, A, global, quickshell:sidebarToggle
bind = Super, Tab, global, quickshell:overviewToggle
```
Maps to `CustomShortcut { name: "sidebarToggle"; onPressed: ... }` in QML.

**2. IPC via CLI (resilient, works across instances):**
```conf
bind = , XF86MonBrightnessUp, exec, qs ipc call brightness increment
bind = Super, Super_L, exec, qs ipc call launcher toggle
```

Define targets in QML with `IpcHandler`:
```qml
IpcHandler {
    target: "brightness"
    function increment(): void { ... }
    function decrement(): void { ... }
    function get(): real { return currentBrightness }
}
```

CLI usage: `qs ipc show` (list targets), `qs ipc call <target> <func> [args]`

### Launching Applications

Use `DesktopEntry.command` (not `.execString`) with `Quickshell.execDetached()`:
```qml
function launch(entry: DesktopEntry): void {
    Quickshell.execDetached({
        command: entry.command,
        workingDirectory: entry.workingDirectory
    });
}
```

### SystemClock (preferred over new Date())

`SystemClock` fires within ±50ms of actual clock tick. `new Date()` can be off by up to 1 second:
```qml
SystemClock {
    id: clock
    precision: SystemClock.Seconds  // or .Minutes
}
// Use clock.date, clock.hours, clock.minutes, clock.seconds
// Format: Qt.formatDateTime(clock.date, "hh:mm")
```

## Configuration Persistence Pattern

Real shells use `JsonAdapter` + `FileView` for persistent user config:

```qml
pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property alias appearance: adapter.appearance

    FileView {
        id: configFile
        path: Paths.config + "/shell.json"
        watchChanges: true
    }

    JsonAdapter {
        id: adapter
        source: configFile
    }

    function save(): void { saveTimer.restart() }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: configFile.write(JSON.stringify(adapter.serialize(), null, 2))
    }
}
```

## Service Singleton Pattern

```qml
// services/Audio.qml
pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    function setVolume(v: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
}
```

## Bundled Resources

- `references/qml-patterns.md` — Complete QML pattern library with code examples for every common shell pattern. Read when implementing specific features.
- `references/modules-api.md` — Full Quickshell module/type reference. Read when you need the exact API for a module.
- `references/reference-repos.md` — Map of all local reference repositories with paths and what to look for in each. Read when searching for real-world implementation examples.
- `references/best-practices.md` — Architecture patterns for scalable shells: theming, design tokens, error handling, logging, performance, property conventions. Read when starting a new shell or reviewing architecture.
- `references/feature-matrix.md` — **Feature-by-feature comparison** across all 4 reference shells (Caelestia, DMS, illogical-impulse, Noctalia) with exact file paths. Read when you want to implement a specific feature and need to find a reference implementation.
- `references/visual-effects.md` — Qt visual effects guide: MultiEffect (blur, shadow, mask, colorize), ShaderEffect (custom GLSL), layer system, Canvas, compositor-level blur. Read when implementing any visual effect.
- `references/qt-essentials.md` — Core Qt/QML patterns: focus management, scrollable panels, states/transitions, color manipulation, gradients, utility functions, animations. Read for Qt fundamentals that aren't Quickshell-specific.

## Gotchas

### IDs inside Components are not accessible outside

`id: clock` inside a `Variants` delegate cannot be referenced from outside. Define a property on a parent Scope/ShellRoot and bind to it. Error: `ReferenceError: clock is not defined`.

### PwObjectTracker is required before reading PipeWire properties

You must bind `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }` before accessing `.audio.volume` on a PwNode. Without it, properties won't update reactively.

### Self-referencing property names in components

`time: time` inside a component binds `time` to itself. Use an id: `time: root.time`.

### pragma Singleton requires Singleton root type

Quickshell singletons must use `Singleton {}` as root (not `QtObject` or `Item`). This ensures proper reload behavior.

### Screen disappearance crashes hardcoded windows

A `PanelWindow { screen: someSpecificScreen }` without Variants will crash when that screen disconnects. Always use Variants + Quickshell.screens.

### exclusiveZone defaults reserve space

By default, `PanelWindow` reserves screen space. For overlays, OSDs, and popups that shouldn't push windows, set `exclusiveZone: 0`.

### Layer shell layers determine stacking

`Background` < `Bottom` < `Top` < `Overlay`. Bars use Top, lock screens use Overlay with exclusive keyboard focus. Wrong layer = UI renders behind other surfaces.

### Process.command takes an array, not a string

`command: "date +%H:%M"` fails. Use `command: ["date", "+%H:%M"]` or `command: ["sh", "-c", "date +%H:%M"]` for shell features.

### FileView watchChanges can cause save loops

External edits trigger `onChanged` which can re-trigger save logic. Use a debounce timer and a `recentlySaved` flag to break the loop.

### Quickshell.env() is not reactive

`Quickshell.env("VAR")` reads at startup only. Not reactive to later environment changes.

### ObjectModel requires .values for array operations

`Hyprland.workspaces` is an `ObjectModel`, not a JS array. To use `.filter()`, `.map()`, `.find()`, `.findIndex()` you must call `.values` first:
```qml
// WRONG: Hyprland.workspaces.filter(...)
// RIGHT:
Hyprland.workspaces.values.filter(w => !w.name.startsWith("special:"))
```

### lastIpcObject for Hyprland data not exposed as properties

Some Hyprland data is only accessible through `.lastIpcObject` (the raw JSON snapshot), not as direct QML properties:
```qml
workspace.lastIpcObject.windows    // window count
monitor.lastIpcObject.specialWorkspace.name
```

### Race conditions with external services

File changes, D-Bus signals, and subprocess output often arrive before data stabilizes. Use a short Timer delay (20-100ms) before processing:
```qml
Connections {
    target: someExternalSignal
    function onChanged() { delayTimer.restart() }
}
Timer {
    id: delayTimer
    interval: 50
    onTriggered: actuallyProcessTheData()
}
```

### modelData destroyed before remove animations finish

In ListView with remove transitions, `modelData` is destroyed immediately when the item is removed from the model — before the exit animation completes. Cache needed values in local properties during `Component.onCompleted`:
```qml
property int cachedId
Component.onCompleted: cachedId = modelData.id
```

### Behaviors fire during initialization

A `Behavior on width { NumberAnimation {} }` fires immediately when the component loads, causing jumpy animations. Start with `enabled: false` and enable via a Timer after `Component.onCompleted`.

### ScriptModel requires unique values

`ScriptModel` only works with unique values. Duplicate values cause undefined behavior.

### Opaque window color cannot become transparent later

If a window's color is opaque before becoming visible, it cannot later become transparent unless `surfaceFormat.opaque` is explicitly set to `false`.

### PersistentProperties need globally unique reloadableId

`PersistentProperties { reloadableId: "myId" }` preserves state across reloads, but the ID must be unique across the entire shell. Duplicate IDs cause silent state corruption.

### Pragmas for environment and shell behavior

Set in the root `shell.qml` before imports:
```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1        // suppress default reload popup
//@ pragma Env QSG_RENDER_LOOP=threaded     // threaded rendering
//@ pragma ShellId myshell                  // stable shell identity
//@ pragma RespectSystemStyle               // allow QT_QUICK_CONTROLS_STYLE
```

### v0.2 breaking: relative paths outside shell dir no longer work

`../../foo.png` style references fail. All files must be inside the shell directory or use absolute paths.

### v0.2 breaking: use `import qs.path.to.module` for root-relative imports

The old `"root:/"` syntax is replaced. `import qs.modules.bar` resolves to `modules/bar/` relative to the shell root. This also improves qmlls support.

### No qmldir files needed

Quickshell auto-discovers QML types. Don't create qmldir manifests — they're not used. Module structure is handled by directory layout and `import qs.` paths.

### Variants inside LazyLoader can block

Variants does not support async loading. If placed inside a LazyLoader, it blocks until all instances are created. For heavy content, use Loader with `asynchronous: true` instead.

### JSON.parse must always be wrapped in try/catch

Config files, IPC responses, and external data can be malformed. Always wrap `JSON.parse()` in try/catch with a fallback:
```qml
try { config = JSON.parse(fileView.text()) }
catch (e) { config = {} }
```

### .destroy() can throw during reload

Calling `.destroy()` on objects during a reload can throw. Wrap in try/catch:
```qml
try { obj.destroy() } catch (_) {}
```

### Reassign lists to trigger change detection

`root.list.push(item)` does NOT trigger reactive updates. You must reassign:
```qml
root.list = [newItem, ...root.list]  // triggers change
```

## Development Tooling

### LSP: qmlls (Qt QML Language Server)

Enable for a shell config by creating an empty `.qmlls.ini` next to `shell.qml`:
```sh
touch ~/.config/quickshell/.qmlls.ini
```
Quickshell auto-populates it with import paths on next run. Gitignore this file (machine-specific).

**Editor setup:**
- **Neovim**: `require("lspconfig").qmlls.setup {}` + `:TSInstall qmljs`
- **Helix**: built-in support, no config needed
- **Emacs**: `lsp-mode` or `eglot` with `qml-ts-mode` (tree-sitter grammar: `yuja/tree-sitter-qml`)
- **VS Code**: Install "Official QML Support" extension, enable `qt-qml.qmlls.useQmlImportPathEnvVar`

**qmlls caveats:**
- No documentation for Quickshell-specific types
- `PanelWindow` in particular cannot be resolved
- Completions/lints break when braces aren't closed
- Use `import qs.path.to.module` (v0.2+) instead of old `"root:/"` imports for better LSP resolution

### Formatter: qmlformat

Ships with Qt6 (`qt6-declarative-tools` or similar):
```sh
qmlformat -i file.qml          # format in-place
qmlformat -i **/*.qml          # format all QML files
```

### Linter: qmllint

Also from Qt6:
```sh
qmllint file.qml
qmllint **/*.qml
```

### Type checking

Handled by qmlls to the extent possible. No Quickshell-specific type checker exists — rely on qmlls plus runtime error checking via `qs -p .`.

## Verification

After writing QML:
1. Run `qs -p /path/to/config/` (or `quickshell -p .`) to test
2. Check stderr for QML errors — quickshell prints file:line references
3. Run `qmllint *.qml` to catch static issues
4. Edit and save — live reload shows changes immediately
5. Test multi-monitor: `hyprctl keyword monitor HDMI-A-1,disable` then re-enable
6. Check layer ordering: `hyprctl layers`
7. Inspect windows: `hyprctl clients`

## Success Criteria

- Generated QML uses correct Quickshell imports and types (not hallucinated APIs)
- Multi-monitor code always uses the Variants + Quickshell.screens pattern
- PipeWire code includes PwObjectTracker before reading node properties
- Singletons use `pragma Singleton` with `Singleton {}` root type
- Layer shell layers are appropriate for the UI type (Top for bars, Overlay for lock/power menus)
- Process.command is always an array, never a string
- Config persistence uses debounce to prevent save loops
- Code runs without errors when tested with `qs -p .`
