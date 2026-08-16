# Quickshell Best Practices

Patterns learned from production shells (caelestia-shell, DankMaterialShell, illogical-impulse).

## 1. Design Token Architecture

Never hardcode colors, sizes, spacing, or durations. Use a centralized Appearance singleton with scale factors:

```qml
// config/AppearanceConfig.qml — persisted via JsonAdapter
JsonObject {
    objectName: "appearance"

    JsonObject {
        objectName: "rounding"
        property real scale: 1
        property int small: 12 * scale
        property int normal: 17 * scale
        property int large: 25 * scale
    }

    JsonObject {
        objectName: "spacing"
        property real scale: 1
        property int small: 7 * scale
        property int normal: 12 * scale
        property int large: 20 * scale
    }

    JsonObject {
        objectName: "font"
        property string sans: "Inter"
        property string mono: "JetBrains Mono"
        property int normal: 13
        property int large: 18
    }
}
```

Usage everywhere: `Appearance.rounding.normal`, `Appearance.spacing.small`, `Appearance.font.sans`. Changing the scale factor rescales the entire UI proportionally.

## 2. Color System

### Never Hardcode Hex Values

All colors flow through a singleton service. Components reference semantic tokens, not raw colors:

```qml
// WRONG
Rectangle { color: "#1a1a2e" }

// RIGHT
Rectangle { color: Colours.palette.m3surface }
Rectangle { color: Colours.tPalette.m3surfaceContainer }  // with transparency
```

### Wallpaper-Based Theming

Both caelestia and DMS use matugen (Material Design 3 color generator) to extract a palette from the wallpaper:

1. Wallpaper changes → trigger matugen or ImageAnalyser
2. Color scheme JSON is written to a file
3. FileView watches the file, Colours singleton reloads
4. All UI updates reactively through property bindings

### Transparency Layers

Don't use raw alpha. Use a layer function that adapts to wallpaper luminance and light/dark mode:

```qml
// Colours singleton
function layer(color, depth) {
    if (!transparency.enabled) return color
    // Adjusts alpha based on wallpaper brightness + layer depth
    return Qt.rgba(r * scale, g * scale, b * scale, computedAlpha)
}
```

### Dark/Light Mode

Store mode as a property. All 60+ color tokens auto-recalculate when it changes:

```qml
property bool isLight: false
readonly property color primary: isLight ? lightPrimary : darkPrimary
// ... all other colors follow
```

## 3. Animation Consistency

### Wrapper Components

Create `Anim.qml` and `CAnim.qml` that bake in your easing curves and duration system:

```qml
// components/Anim.qml
NumberAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}

// components/CAnim.qml
ColorAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
```

Usage: `Behavior on width { Anim {} }` — consistent animations everywhere with zero config.

### Global Speed Control

Duration system with a single scale factor:

```qml
component AnimDurations {
    property real scale: 1  // user can slow/speed all animations
    property int small: 200 * scale
    property int normal: 400 * scale
    property int large: 600 * scale
}
```

## 4. Property Conventions

### Use `readonly property` for derived state

Marks values as computed, prevents accidental reassignment:

```qml
readonly property bool muted: !!sink?.audio?.muted
readonly property real volume: sink?.audio?.volume ?? 0
readonly property bool connecting: connectProc.running || disconnectProc.running
```

### Use `property alias` for delegation

Exposes nested properties without re-computation. Common in Config singletons:

```qml
// Config.qml
property alias appearance: adapter.appearance
property alias bar: adapter.bar
property alias services: adapter.services
```

### Use `required property` for component inputs

Forces the parent to provide the value. Catches missing data at creation time:

```qml
component WsDelegate: Rectangle {
    required property HyprlandWorkspace modelData
    required property int index
}
```

## 5. Error Handling

### JSON parsing — always wrap

```qml
try {
    config = JSON.parse(fileView.text());
} catch (e) {
    console.warn(lc, "Failed to parse config:", e);
    config = {};
}
```

### Service availability — defensive chaining

Services initialize asynchronously. Chain with `?.` and provide defaults with `??`:

```qml
readonly property real volume: sink?.audio?.volume ?? 0
readonly property string ssid: Network.active?.ssid ?? "Disconnected"
readonly property string player: Mpris.players?.values[0]?.identity ?? "None"
```

### Process failures — always check exit codes

```qml
Process {
    command: ["ddcutil", "getvcp", "10"]
    onExited: (exitCode, exitStatus) => {
        if (exitCode !== 0) {
            console.warn(lc, "ddcutil failed:", exitCode);
            return;
        }
        // process stdout only on success
    }
}
```

### Object destruction during reload

```qml
try { obj.destroy() } catch (_) {}
```

## 6. Logging

### Use LoggingCategory, not bare console.log

```qml
LoggingCategory {
    id: lc
    name: "myshell.services.audio"
    defaultLogLevel: LoggingCategory.Info
}

// Usage
console.info(lc, "Volume changed to:", volume);
console.warn(lc, "Sink not ready");
console.error(lc, "Failed to connect:", error);
```

Benefits: filterable, structured, consistent across services.

### Log only meaningful events

Don't log every property change. Log errors, state transitions, and unexpected conditions.

## 7. Performance Patterns

### LazyLoader for ephemeral UI

Windows that appear/disappear (OSDs, popups, notifications) should use LazyLoader:

```qml
LazyLoader {
    active: shouldShow
    PanelWindow { ... }
}
```

When `active` becomes false, the entire component tree is destroyed — zero memory cost when hidden.

### Loader with asynchronous for heavy content

For complex panels that shouldn't block the main thread:

```qml
Loader {
    asynchronous: true  // loads between frames
    active: panelOpen
    sourceComponent: HeavyDashboard {}
}
```

### visible:false for frequently toggled UI

If a component toggles often and is lightweight, prefer `visible: false` over destroying it:

```qml
PanelWindow {
    visible: showBar  // keeps component alive, just hidden
}
```

### ListView over Repeater for dynamic/long lists

- **Repeater**: creates ALL delegates upfront. Fine for small static lists (5-10 items)
- **ListView**: virtualizes — only creates visible delegates. Required for notifications, app lists, large sets

### Image optimization

```qml
Image {
    source: wallpaperPath
    sourceSize.width: targetWidth    // decode at display size, not native
    sourceSize.height: targetHeight
    asynchronous: true               // don't block UI thread
    cache: true                      // reuse decoded data
}
```

## 8. Initialization Order

### Minimal Component.onCompleted

Keep it short. Delegate to methods:

```qml
Component.onCompleted: initBrightness()
```

### Use Qt.callLater for order-dependent init

When you need the component fully rendered before running logic:

```qml
Component.onCompleted: {
    Qt.callLater(() => {
        initialized = true;
        proc.exec(proc.cmdArgs);
    });
}
```

### Conditional startup

```qml
Component.onCompleted: root.enabled && statusCheckTimer.start()
```

## 9. State Management Architecture

### Centralized state in singletons

Don't scatter state across components. Services own their domain state:

```
services/
├── Audio.qml      — owns volume, mute, sink/source state
├── Hypr.qml       — owns workspace, monitor, toplevel state
├── Network.qml    — owns connection, WiFi state
├── Colours.qml    — owns theme, palette state
└── Players.qml    — owns MPRIS player state
```

Components are purely presentational — they read from services and call service methods.

### PersistentProperties for reload-safe state

UI state that should survive hot reloads (drawer open/closed, active tab):

```qml
PersistentProperties {
    reloadableId: "dashboard"  // globally unique!
    property bool expanded: false
    property int activeTab: 0
}
```

### Config for user-facing settings

Anything the user configures goes through the JsonAdapter Config system, not PersistentProperties.

## 10. Module Organization

### Flat services, nested modules

```
services/       ← flat: Audio.qml, Hypr.qml, Network.qml (singletons)
modules/        ← nested by feature:
  bar/
    Bar.qml
    components/
      Clock.qml
      Workspaces.qml
  dashboard/
    Dashboard.qml
    components/
      Media.qml
      Calendar.qml
components/     ← shared UI primitives (controls, effects, containers)
config/         ← Config.qml + per-feature config objects
utils/          ← pure utility singletons (Icons, Paths, Strings)
```

### One concern per file

A service handles one domain. A component renders one thing. Don't mix network state into the audio service.

### Naming conventions

- `PascalCase.qml` for types (auto-registers as QML type)
- Singletons: `pragma Singleton` + `Singleton {}` root
- Internal components: `//@ pragma Internal` (v0.2+, prevents external import)
