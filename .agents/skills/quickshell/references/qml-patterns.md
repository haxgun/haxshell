# Quickshell QML Pattern Library

## 1. Shell Entry Point

```qml
// shell.qml — always the starting file
import Quickshell

ShellRoot {
    settings.watchFiles: true  // enable live reload

    Bar {}          // your bar module
    Dashboard {}    // your dashboard module
    Lock { id: lock }
}
```

Pragmas go before imports:
```qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
```

## 2. Multi-Monitor Bar

```qml
import Quickshell
import QtQuick

ShellRoot {
    property string time

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            height: 30

            Text {
                anchors.centerIn: parent
                text: time
            }
        }
    }

    // Shared timer — one instance, not per-monitor
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: time = new Date().toLocaleTimeString(Qt.locale())
    }
}
```

## 3. Singleton Service

```qml
// Time.qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property var date: new Date()
    property string time: date.toLocaleString(Qt.locale())

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: date = new Date()
    }
}
```

Usage from any file: `text: Time.time` — no import needed for same-directory singletons.

## 4. Process Execution

```qml
import Quickshell.Io

Process {
    id: dateProc
    command: ["date", "+%H:%M:%S"]
    running: true

    stdout: SplitParser {
        onRead: data => clock.text = data
    }
}

// Rerun periodically
Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: dateProc.running = true
}
```

For shell commands with pipes:
```qml
Process {
    command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1"]
}
```

## 5. Socket IPC (Hyprland Event Stream)

```qml
import Quickshell.Io

Socket {
    id: hyprSocket
    path: "/tmp/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
    connected: true

    parser: SplitParser {
        onRead: data => {
            const match = data.match(/focusedmon>>(.+),.*/)
            if (match) {
                // handle focused monitor change
                monitorName = match[1]
            }
        }
    }
}
```

## 6. PipeWire Audio

```qml
import Quickshell.Services.Pipewire

// MUST bind tracker before reading properties
PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
}

// React to volume changes
Connections {
    target: Pipewire.defaultAudioSink?.audio
    function onVolumeChanged() {
        showOsd = true
        hideTimer.restart()
    }
}

// Read volume
property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0

// Set volume
function setVolume(v) {
    const sink = Pipewire.defaultAudioSink
    if (sink?.ready && sink?.audio) {
        sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
}

// Audio mixer — track what's connected to default sink
PwNodeLinkTracker {
    id: linkTracker
    node: Pipewire.defaultAudioSink
}
Repeater {
    model: linkTracker.linkGroups
    MixerEntry {
        required property PwLinkGroup modelData
        node: modelData.source
    }
}
```

## 7. LazyLoader (Ephemeral UI)

```qml
// Window only exists in memory when active
LazyLoader {
    active: shouldShowOsd

    PanelWindow {
        anchors.bottom: true
        margins.bottom: screen.height / 5
        exclusiveZone: 0
        implicitWidth: 400; implicitHeight: 50
        color: "transparent"
        mask: Region {}  // click-through

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#80000000"
            // ... OSD content
        }
    }
}
```

## 8. Lock Screen

```qml
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            // Per-monitor lock surface
            Rectangle {
                anchors.fill: parent
                color: "#1a1a2e"

                TextField {
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    onAccepted: pamContext.tryAuth(text)
                }
            }
        }

        onUnlocked: lock.unlock()
    }

    PamContext {
        id: pamContext
        onCompleted: result => {
            if (result === PamResult.Success) lock.unlock()
        }
    }
}
```

## 9. Wlogout / Power Menu (Overlay with Keyboard)

```qml
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true; bottom: true; right: true }

        contentItem.focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Qt.quit()
        }

        // Grid of power buttons...
    }
}
```

## 10. Custom Component with Required Properties

```qml
// LogoutButton.qml
import QtQuick
import Quickshell.Io

QtObject {
    required property string command
    required property int keybind
    required property string text
    required property string icon

    property Process process: Process {
        command: ["sh", "-c", parent.command]
    }

    function execute() {
        process.startDetached()
        Qt.quit()
    }
}
```

Usage with default property list:
```qml
// WLogout.qml — accepts LogoutButton children
Variants {
    default property list<LogoutButton> buttons
    model: Quickshell.screens

    PanelWindow {
        // Use buttons model in a Repeater
        Repeater {
            model: buttons
            delegate: Rectangle {
                required property LogoutButton modelData
                // render button...
            }
        }
    }
}
```

## 11. Reload Popup

```qml
import Quickshell

Scope {
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            popupLoader.active = true
        }
        function onReloadFailed(error) {
            errorText = error
            popupLoader.active = true
        }
    }

    Component.onCompleted: Quickshell.inhibitReloadPopup()

    LazyLoader {
        id: popupLoader
        active: false
        PanelWindow {
            // show reload status...
        }
    }
}
```

## 12. Hyprland Workspace Switcher

```qml
import Quickshell.Hyprland

Row {
    Repeater {
        model: Hyprland.workspaces.values.filter(w => !w.name.startsWith("special:"))

        Rectangle {
            required property HyprlandWorkspace modelData
            width: 20; height: 20
            radius: 10
            color: modelData === Hyprland.focusedWorkspace ? "#fff" : "#555"

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
```

## 13. JsonAdapter Config Persistence

```qml
pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias bar: adapter.bar
    property bool recentlySaved: false

    FileView {
        id: configFile
        path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/myshell/config.json"
        watchChanges: true
        onChanged: {
            if (!root.recentlySaved) adapter.reload()
        }
    }

    JsonAdapter {
        id: adapter
        source: configFile

        JsonObject {
            objectName: "bar"
            property bool showClock: true
            property int height: 30
        }
    }

    function save(): void {
        saveTimer.restart()
        recentlySaved = true
        recentSaveCooldown.restart()
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: configFile.write(JSON.stringify(adapter.serialize(), null, 2))
    }

    Timer {
        id: recentSaveCooldown
        interval: 1000
        onTriggered: recentlySaved = false
    }
}
```

## 14. Notification Daemon

```qml
import Quickshell.Services.Notifications

NotificationServer {
    id: notifServer
    onNotification: notif => {
        notifModel.append(notif)
        popupLoader.active = true
    }
}
```

## 15. System Tray

```qml
import Quickshell.Services.StatusNotifier

Repeater {
    model: SystemTray.items

    Rectangle {
        required property StatusNotifierItem modelData
        Image {
            source: modelData.icon
        }
        MouseArea {
            onClicked: modelData.activate()
        }
    }
}
```

## 16. MPRIS Media Player

```qml
import Quickshell.Services.Mpris

// Access all players
Repeater {
    model: Mpris.players.values

    Row {
        required property MprisPlayer modelData
        Text { text: modelData.trackTitle }
        Text { text: modelData.trackArtist }
        Button { text: "Play/Pause"; onClicked: modelData.togglePlaying() }
    }
}
```

## 17. Battery Monitoring

```qml
import Quickshell.Services.UPower

Text {
    text: {
        const bat = UPower.displayDevice
        if (!bat) return "No battery"
        return Math.round(bat.percentage) + "%"
    }
}
```

## 18. Network Status

```qml
import Quickshell.Networking

Text {
    text: {
        const wifi = NetworkManager.primaryConnection
        return wifi ? wifi.id : "Disconnected"
    }
}
```

## 19. IPC Handler (CLI control of shell)

```qml
import Quickshell.Io

IpcHandler {
    target: "dashboard"

    function toggle(): void {
        dashboardVisible = !dashboardVisible
    }

    function show(): void {
        dashboardVisible = true
    }
}
```

Control from terminal: `qs ipc call dashboard toggle`

## 20. Animations

```qml
// Behavior-based (auto-animate on property change)
Rectangle {
    width: expanded ? 300 : 50
    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
}

// PropertyAnimation for explicit control
PropertyAnimation {
    id: fadeAnim
    target: popup
    property: "opacity"
    from: 1; to: 0
    duration: 800
    onFinished: popup.destroy()
}

// Pause animation on hover
PropertyAnimation {
    paused: mouseArea.containsMouse
    duration: 10000
}

// Disable Behavior during init to prevent jumpy animations
Behavior on implicitHeight {
    id: heightBehavior
    enabled: false
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
}
Component.onCompleted: enableTimer.restart()
Timer {
    id: enableTimer
    interval: 50
    onTriggered: heightBehavior.enabled = true
}
```

## 21. PersistentProperties (State Across Reloads)

```qml
import Quickshell

PersistentProperties {
    id: persist
    reloadableId: "myUniqueId"  // MUST be globally unique
    property bool drawerOpen: false
    property int activeTab: 0
}

// Use persist.drawerOpen instead of a regular property
// Value survives config reloads
```

## 22. Race Condition Delay Pattern

```qml
// External data needs time to settle — don't process immediately
Connections {
    target: Quickshell
    function onClipboardTextChanged() {
        delayTimer.restart()
    }
}

Timer {
    id: delayTimer
    interval: 50  // 20-100ms depending on service
    onTriggered: refreshClipboardData()
}
```

## 23. Caching modelData for Remove Animations

```qml
ListView {
    model: someModel

    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
        NumberAnimation { property: "scale"; to: 0.5; duration: 200 }
    }

    delegate: Rectangle {
        required property HyprlandWorkspace modelData

        // Cache values — modelData is destroyed before animation finishes!
        property int wsId
        property string wsName
        Component.onCompleted: {
            wsId = modelData.id
            wsName = modelData.name
        }

        // Use cached values for display during remove animation
        Text { text: parent.wsName }
    }
}
```

## 24. Dynamic Object Creation

```qml
Component {
    id: notifComp
    NotifWrapper {
        required property var notification
        required property bool popup
    }
}

function createNotification(notif) {
    const comp = notifComp.createObject(root, {
        popup: shouldShowPopup(),
        notification: notif
    });
    // MUST reassign list to trigger change detection
    root.list = [comp, ...root.list];
}

// When iterating + modifying, copy the array first
function dismissAll() {
    for (const notif of root.list.slice())  // .slice() prevents skipping!
        notif.close();
}
```

## 25. Qt.callLater for Deferred Init

```qml
// Defer operation to next event loop — avoids init-order bugs
Component.onCompleted: {
    Qt.callLater(() => {
        proc.exec(proc.cmdArgs);
    });
}
```

## 26. Re-establishing Broken Bindings

```qml
// After user interaction breaks a reactive binding, re-establish it
onCurrentIndexChanged: {
    currentIndex = Qt.binding(() =>
        model.values.findIndex(w => w.name === root.activeSpecial)
    )
}
```

## 27. Environment Pragmas (shell.qml)

```qml
// These go BEFORE imports in shell.qml
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma ShellId myshell
//@ pragma RespectSystemStyle

import Quickshell
// ...
```

## 28. Root-Relative Imports (v0.2+)

```qml
// Old (broken in v0.2):
// import "root:/modules/bar"

// New — uses qs. prefix, resolved relative to shell root:
import qs.modules.bar
import qs.services
import qs.config
import qs.components.controls
```

## 29. SystemClock (Preferred Time Source)

```qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    // Prefer this over new Date() — fires within ±50ms of actual tick
    SystemClock {
        id: clock
        precision: SystemClock.Seconds  // or .Minutes for less overhead
    }
}
```

## 30. IpcHandler (CLI Control of Shell)

```qml
import Quickshell.Io

IpcHandler {
    target: "brightness"  // must be unique across shell

    // Functions callable via: qs ipc call brightness increment
    function increment(): void { brightness += 5 }
    function decrement(): void { brightness -= 5 }
    function get(): real { return brightness }
    function set(value: string): string {
        brightness = parseFloat(value)
        return "ok"
    }
}
```

Hyprland keybind wiring:
```conf
# hyprland.conf — two approaches

# 1. IPC call (resilient, works across instances)
bind = , XF86MonBrightnessUp, exec, qs ipc call brightness increment

# 2. Native global shortcut (faster, direct QML invocation)
bind = Super, A, global, quickshell:sidebarToggle
```

For native shortcuts, define in QML:
```qml
CustomShortcut {
    name: "sidebarToggle"
    description: "Toggle the sidebar"
    onPressed: sidebar.visible = !sidebar.visible
}
```

Discovery commands:
```bash
qs ipc show                          # list all targets and functions
qs ipc call <target> <func> [args]   # call a function
qs ipc prop get <target> <prop>      # read a property
```

## 31. Launching Applications via DesktopEntry

```qml
// DesktopEntry provides .command (list<string>) and .workingDirectory
function launch(entry: DesktopEntry): void {
    Quickshell.execDetached({
        command: entry.command,
        workingDirectory: entry.workingDirectory
    });
}

// For terminal apps:
function launchInTerminal(entry: DesktopEntry): void {
    Quickshell.execDetached({
        command: ["kitty", "--", ...entry.command],
        workingDirectory: entry.workingDirectory
    });
}

// Lookup by app ID:
// DesktopEntry.heuristicLookup(appId) — fuzzy match by WM class
```

**WARNING:** Do NOT use `entry.execString` — it cannot be reliably run as a command. Always use `entry.command`.

## 32. Quickshell.execDetached (Fire-and-Forget Commands)

```qml
// Simple command
Quickshell.execDetached(["brightnessctl", "s", "50%"]);

// With working directory (v0.2+)
Quickshell.execDetached({
    command: ["my-script", "--flag"],
    workingDirectory: "/some/path"
});

// Shell features (pipes, etc.) — must invoke shell
Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < /tmp/screenshot.png"]);
```

NOT a shell — each arg is separate. For pipes/redirects, use `["sh", "-c", "..."]`.

---

For Qt-general patterns (focus, scrolling, states/transitions, colors, gradients, utility functions, animations), see `qt-essentials.md`.
