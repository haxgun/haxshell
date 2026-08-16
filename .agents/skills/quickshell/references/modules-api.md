# Quickshell Modules API Reference

## Quickshell (core)

**Import:** `import Quickshell`

### Types
- **ShellRoot** — Root container for all shell objects. Only one per config. Default property accepts any QML objects.
- **PanelWindow** — Wayland panel window anchored to screen edges
  - `anchors.{top,bottom,left,right}: bool` — which edges to anchor to
  - `height`, `width` — panel dimensions (opposite dimension to anchored edges)
  - `screen: QScreen` — which screen to show on
  - `color: color` — background color
  - `mask: Region` — input mask (empty Region = click-through)
  - `exclusiveZone: int` — pixels to reserve (0 = no reservation)
  - `exclusionMode: ExclusionMode` — Normal, Ignore
  - `margins.{top,bottom,left,right}: int` — margin from edge
  - `contentItem` — the root Item for QML children
  - `WlrLayershell.layer: WlrLayer` — attached property for layer
  - `WlrLayershell.keyboardFocus: WlrKeyboardFocus` — None, OnDemand, Exclusive
- **FloatingWindow** — Standard desktop window
  - Standard QWindow properties
- **Variants** — Creates component instances from a model
  - `model: var` — data model (commonly `Quickshell.screens`)
  - `delegate: Component` — component to instantiate (default property)
  - Each instance gets `property var modelData`
- **Scope** — Non-visual container for grouping objects
- **Singleton** — Base type for singleton objects (use with `pragma Singleton`)
- **LazyLoader** — Conditionally loads a component
  - `active: bool` — whether the component should exist
  - Default property is the component to load
- **Region** — Click mask / input region
  - Empty Region = fully transparent to input
- **Quickshell** (global singleton)
  - `screens: list<QScreen>` — available screens (reactive)
  - `iconPath(name: string): url` — resolve icon path
  - `env(name: string): string` — read environment variable
  - `inhibitReloadPopup()` — suppress default reload popup
  - Signals: `reloadCompleted()`, `reloadFailed(error: string)`
- **PersistentProperties** — Properties that survive config reloads

### Enums
- `WlrLayer` — Background, Bottom, Top, Overlay
- `WlrKeyboardFocus` — None, OnDemand, Exclusive
- `ExclusionMode` — Normal, Ignore

---

## Quickshell.Io

**Import:** `import Quickshell.Io`

### Types
- **Process** — Execute external commands
  - `command: list<string>` — command and arguments (array, not string)
  - `running: bool` — set true to start, becomes false when done
  - `stdout: DataStreamParser` — parser for stdout
  - `stderr: DataStreamParser` — parser for stderr
  - `startDetached()` — start without tracking
  - `signal started()`, `signal exited(exitCode, exitStatus)`
- **SplitParser** — Splits stream on delimiter
  - `splitMarker: string` — delimiter (default: newline)
  - Signal: `read(data: string)`
- **Socket** — Unix socket client
  - `path: string` — socket path
  - `connected: bool` — connection state
  - `parser: DataStreamParser`
  - `write(data: string)`
- **SocketServer** — Unix socket server
- **FileView** — File contents with watching
  - `path: string`
  - `watchChanges: bool`
  - `text: string` — file contents
  - `write(data: string)`
  - Signal: `changed()`
- **IpcHandler** — Handle IPC calls from CLI
  - `target: string` — IPC target name
  - Define Q_INVOKABLE functions as handlers
  - CLI: `qs ipc call <target> <function> [args]`
- **JsonAdapter** — Bind JSON to QML properties
  - `source: FileView`
  - Children: `JsonObject` components defining schema
  - `serialize(): var` — export as JS object
  - `reload()` — re-read from source

---

## Quickshell.Wayland

**Import:** `import Quickshell.Wayland`

### Types
- **WlrLayershell** — Attached properties for layer shell
  - `layer: WlrLayer`
  - `keyboardFocus: WlrKeyboardFocus`
- **WlSessionLock** — Wayland session lock manager
  - `locked: bool`
  - `unlock()`
  - Signal: `onUnlocked()`
  - Children: `WlSessionLockSurface` instances
- **WlSessionLockSurface** — Per-monitor lock surface
- **IdleInhibitor** — Prevent screensaver/idle
- **IdleNotifier** — Track idle state
  - `timeout: int` — ms until idle
  - Signal: `idled()`, `resumed()`

---

## Quickshell.Hyprland

**Import:** `import Quickshell.Hyprland`

### Types
- **Hyprland** (global singleton)
  - `monitors: ObjectModel<HyprlandMonitor>`
  - `workspaces: ObjectModel<HyprlandWorkspace>`
  - `toplevels: ObjectModel<HyprlandToplevel>`
  - `focusedMonitor: HyprlandMonitor`
  - `focusedWorkspace: HyprlandWorkspace`
  - `activeToplevel: HyprlandToplevel`
  - `dispatch(request: string)` — send hyprctl dispatch
- **HyprlandMonitor**
  - `name: string`, `id: int`
  - `width: int`, `height: int`
  - `x: int`, `y: int`
  - `activeWorkspace: HyprlandWorkspace`
  - `scale: real`
- **HyprlandWorkspace**
  - `name: string`, `id: int`
  - `monitor: HyprlandMonitor`
  - `toplevels: ObjectModel<HyprlandToplevel>`
  - `lastIpcObject` — raw JSON data
- **HyprlandToplevel**
  - `title: string`, `appId: string`
  - `workspace: HyprlandWorkspace`
  - `monitor: HyprlandMonitor`
  - `fullscreen: bool`, `floating: bool`
  - `address: string`
- **HyprlandFocusGrab** — Grab focus for overlays
  - `active: bool`
  - `windows: list<Window>`
  - Signal: `cleared()` — user clicked outside
- **CustomShortcut** — Register global shortcuts
  - `name: string`, `description: string`
  - Signal: `pressed()`, `released()`

---

## Quickshell.Services.Pipewire

**Import:** `import Quickshell.Services.Pipewire`

### Types
- **Pipewire** (global singleton)
  - `defaultAudioSink: PwNode` — system audio output
  - `defaultAudioSource: PwNode` — system audio input
  - `nodes: ObjectModel<PwNode>`
- **PwNode** — Audio/video node
  - `ready: bool`
  - `audio.volume: real` — 0.0 to ~1.5
  - `audio.muted: bool`
  - `properties: var` — dict with application.name, application.icon-name, media.name, description
- **PwObjectTracker** — REQUIRED to enable reactive property tracking
  - `objects: list<PwNode>` — nodes to track
- **PwNodeLinkTracker** — Track connections to a node
  - `node: PwNode`
  - `linkGroups: list<PwLinkGroup>` — connected nodes
- **PwLinkGroup**
  - `source: PwNode`, `target: PwNode`

---

## Quickshell.Services.Mpris

**Import:** `import Quickshell.Services.Mpris`

### Types
- **Mpris** (global singleton)
  - `players: ObjectModel<MprisPlayer>`
- **MprisPlayer**
  - `trackTitle: string`, `trackArtist: string`, `trackAlbum: string`
  - `trackArtUrl: url`
  - `playbackStatus: PlaybackStatus` — Playing, Paused, Stopped
  - `position: int` — current position in microseconds
  - `length: int` — track length in microseconds
  - `volume: real`
  - `canPlay: bool`, `canPause: bool`, `canGoNext: bool`, `canGoPrevious: bool`
  - `play()`, `pause()`, `togglePlaying()`, `next()`, `previous()`, `stop()`
  - `identity: string` — player name

---

## Quickshell.Services.Notifications

**Import:** `import Quickshell.Services.Notifications`

### Types
- **NotificationServer** — Implement a notification daemon
  - Signal: `notification(notif: Notification)`
- **Notification**
  - `appName: string`, `summary: string`, `body: string`
  - `appIcon: string`
  - `urgency: Urgency` — Low, Normal, Critical
  - `actions: list<NotificationAction>`
  - `expireTimeout: int`
  - `dismiss()`, `invokeAction(id: string)`

---

## Quickshell.Services.UPower

**Import:** `import Quickshell.Services.UPower`

- **UPower** (global singleton)
  - `displayDevice: UPowerDevice`
  - `devices: ObjectModel<UPowerDevice>`
- **UPowerDevice**
  - `percentage: real`, `state: DeviceState`, `timeToEmpty: int`, `timeToFull: int`
  - `type: DeviceType`

---

## Quickshell.Services.Pam

**Import:** `import Quickshell.Services.Pam`

- **PamContext**
  - `configDirectory: string`, `config: string`
  - `tryAuth(password: string)`
  - Signal: `completed(result: PamResult)`, `pamMessage(message: string)`
- **PamResult** — Success, AuthError, ...

---

## Quickshell.Services.StatusNotifier (System Tray)

**Import:** `import Quickshell.Services.StatusNotifier`

- **SystemTray** (global singleton)
  - `items: ObjectModel<StatusNotifierItem>`
- **StatusNotifierItem**
  - `icon: string`, `title: string`, `tooltip: string`
  - `activate()`, `secondaryActivate()`, `scrollUp()`, `scrollDown()`
  - `menu: DBusMenu`

---

## Quickshell.Bluetooth

**Import:** `import Quickshell.Bluetooth`

- **Bluetooth** (global singleton)
  - `adapters: ObjectModel<BluetoothAdapter>`
  - `devices: ObjectModel<BluetoothDevice>`
- **BluetoothAdapter** — `powered: bool`, `discoverable: bool`, `discovering: bool`
- **BluetoothDevice** — `name: string`, `connected: bool`, `paired: bool`, `connect()`, `disconnect()`

---

## Quickshell.Networking

**Import:** `import Quickshell.Networking`

- **NetworkManager** (global singleton)
  - `devices: ObjectModel<NetworkDevice>`
  - `connections: ObjectModel<NetworkConnection>`
  - `primaryConnection: NetworkConnection`
- **NetworkDevice** — `type: DeviceType`, `state: DeviceState`
- **WifiDevice** — extends NetworkDevice with `accessPoints`, `scan()`

---

## Quickshell.Widgets

**Import:** `import Quickshell.Widgets`

- **IconImage** — Display system icons
  - `source: url` — use `Quickshell.iconPath("icon-name")` or `"image://icon/name"`
  - `implicitSize: int` — size
- **ClippingRectangle** — Rectangle with clipping
- **WrapperRectangle**, **WrapperItem**, **WrapperMouseArea** — Wrapper components

---

## QtQuick Types (commonly used with Quickshell)

From `import QtQuick`:
- Rectangle, Text, Image, Item, MouseArea, Row, Column, Repeater, Timer, Connections, Component
- Animation types: NumberAnimation, PropertyAnimation, Behavior

From `import QtQuick.Layouts`:
- RowLayout, ColumnLayout, GridLayout (with Layout.fillWidth, Layout.fillHeight)

From `import QtQuick.Controls`:
- Button, Slider, TextField, ScrollView, Label, Switch, ComboBox
