import QtQuick
import Niri

Item {
  id: root

  property var workspaces: []
  property string focusedOutputName: ""
  property var activeApp: ({ appId: "", title: "", iconPath: "", output: "" })
  property bool connected: false

  Timer {
    id: refreshTimer
    interval: 50
    repeat: false
    onTriggered: root.refreshState()
  }

  function refreshState() {
    let nextWorkspaces = []
    let focusedOutput = ""
    let focusedActiveWindowId = 0
    for (let i = 0; i < niri.workspaces.count; i++) {
      let workspace = niri.workspaces.get(i)
      if (!workspace || workspace.id === undefined) continue
      if (workspace.isFocused) {
        focusedOutput = workspace.output || ""
        focusedActiveWindowId = workspace.activeWindowId || 0
      }
      nextWorkspaces.push({
        key: workspace.id.toString(),
        label: workspace.name || workspace.index.toString(),
        output: workspace.output || "",
        active: !!workspace.isActive,
        occupied: workspace.activeWindowId > 0,
        sortIndex: workspace.index,
        switchRef: workspace.id.toString()
      })
    }
    workspaces = nextWorkspaces
    focusedOutputName = focusedOutput

    // The focused workspace's active_window_id is the authoritative source of
    // truth. Only trust niri.focusedWindow when its id matches it; otherwise
    // (empty workspace, or a stale focused window in the plugin) show nothing.
    let window = niri.focusedWindow
    if (window && focusedActiveWindowId > 0 && window.id === focusedActiveWindowId) {
      let output = ""
      let wsIdx = niri.workspaces.indexOfId(window.workspaceId)
      if (wsIdx >= 0) {
        let ws = niri.workspaces.get(wsIdx)
        output = ws ? (ws.output || "") : ""
      }
      activeApp = { appId: window.appId || "", title: window.title || "", iconPath: window.iconPath || "", output: output }
    } else {
      activeApp = { appId: "", title: "", iconPath: "", output: "" }
    }
  }

  function focusWorkspaceById(id) {
    niri.focusWorkspaceById(id)
  }

  Niri {
    id: niri
    Component.onCompleted: connect()
    onConnected: {
      root.connected = true
      root.refreshState()
    }
    onDisconnected: root.connected = false
    onErrorOccurred: root.connected = false
    onFocusedWindowChanged: root.refreshState()
    onRawEventReceived: refreshTimer.restart()
  }
}
