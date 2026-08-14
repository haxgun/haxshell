import QtQuick
import Niri

Item {
  id: root

  property var workspaces: []
  property string focusedOutputName: ""
  property var activeApp: ({ appId: "", title: "", iconPath: "" })
  property bool connected: false

  function refreshState() {
    let nextWorkspaces = []
    let focusedOutput = ""
    for (let i = 0; i < niri.workspaces.count; i++) {
      let workspace = niri.workspaces.get(i)
      if (!workspace || workspace.id === undefined) continue
      if (workspace.isFocused) focusedOutput = workspace.output || ""
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

    let window = niri.focusedWindow
    activeApp = window
      ? { appId: window.appId || "", title: window.title || "", iconPath: window.iconPath || "" }
      : { appId: "", title: "", iconPath: "" }
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
    onRawEventReceived: root.refreshState()
  }
}
