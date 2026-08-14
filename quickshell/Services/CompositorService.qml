pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
  id: root

  readonly property string backend: Quickshell.env("NIRI_SOCKET") ? "niri" : "hyprland"
  property var niriWorkspaces: []
  property var niriWindows: []
  readonly property var hyprlandWorkspaces: {
    let result = []
    let list = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : []
    for (let i = 0; i < list.length; i++) {
      let workspace = list[i]
      if (!workspace || workspace.id <= 0) continue
      result.push({
        key: workspace.id.toString(),
        label: workspace.id.toString(),
        output: workspace.monitor ? workspace.monitor.name : "",
        active: workspace.active,
        occupied: workspace.toplevels ? workspace.toplevels.values.length > 0 : true,
        sortIndex: workspace.id,
        switchRef: workspace.id.toString()
      })
    }
    return result
  }
  readonly property var niriNormalizedWorkspaces: {
    let occupied = {}
    for (let i = 0; i < niriWindows.length; i++) {
      let window = niriWindows[i]
      if (window && window.workspace_id !== undefined) occupied[window.workspace_id.toString()] = true
    }

    let result = []
    for (let i = 0; i < niriWorkspaces.length; i++) {
      let workspace = niriWorkspaces[i]
      if (!workspace) continue
      let key = workspace.id.toString()
      result.push({
        key: key,
        label: workspace.name || workspace.idx.toString(),
        output: workspace.output || "",
        active: !!workspace.is_active,
        occupied: !!occupied[key],
        sortIndex: workspace.idx,
        switchRef: workspace.name || workspace.idx.toString()
      })
    }
    return result
  }
  readonly property var workspaces: backend === "niri" ? niriNormalizedWorkspaces : hyprlandWorkspaces
  readonly property string focusedOutputName: {
    if (backend === "niri") {
      for (let i = 0; i < niriWorkspaces.length; i++) {
        if (niriWorkspaces[i] && niriWorkspaces[i].is_focused) return niriWorkspaces[i].output || ""
      }
      return ""
    }
    return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
  }
  readonly property var activeApp: {
    if (backend === "niri") {
      for (let i = 0; i < niriWindows.length; i++) {
        let window = niriWindows[i]
        if (window && window.is_focused) return { appId: window.app_id || "", title: window.title || "" }
      }
      return { appId: "", title: "" }
    }
    let window = Hyprland.activeToplevel
    let ipc = window ? window.lastIpcObject : ({})
    return {
      appId: (ipc.class || ipc.initialClass || ipc.initialTitle || "").toString(),
      title: window ? (window.title || ipc.title || "") : ""
    }
  }
  readonly property string exitCommand: backend === "niri" ? "niri msg action quit" : "hyprctl dispatch exit"

  Process {
    id: niriWorkspacesProc
    command: ["niri", "msg", "--json", "workspaces"]
    stdout: SplitParser { onRead: data => root.applyNiriWorkspaces(data) }
  }

  Process {
    id: niriWindowsProc
    command: ["niri", "msg", "--json", "windows"]
    stdout: SplitParser { onRead: data => root.applyNiriWindows(data) }
  }

  Process { id: niriActionProc }

  Timer {
    interval: 500
    running: root.backend === "niri"
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNiri()
  }

  function applyNiriWorkspaces(data) {
    try {
      let value = JSON.parse(data)
      if (Array.isArray(value)) root.niriWorkspaces = value
    } catch (error) {}
  }

  function applyNiriWindows(data) {
    try {
      let value = JSON.parse(data)
      if (Array.isArray(value)) root.niriWindows = value
    } catch (error) {}
  }

  function refreshNiri() {
    if (backend !== "niri") return
    niriWorkspacesProc.running = false
    niriWindowsProc.running = false
    niriWorkspacesProc.running = true
    niriWindowsProc.running = true
  }

  function isScreenFocused(screen) {
    if (backend === "hyprland") {
      let monitor = Hyprland.monitorFor(screen)
      if (monitor) return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === monitor.name : monitor.focused
    }
    if (focusedOutputName) return screen && screen.name === focusedOutputName
    return Quickshell.screens.length === 0 || screen === Quickshell.screens[0]
  }

  function switchWorkspace(workspace) {
    if (!workspace) return
    if (backend === "hyprland") {
      Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace.switchRef + " })")
      return
    }
    niriActionProc.running = false
    niriActionProc.command = [
      "sh", "-c",
      "niri msg action focus-monitor \"$1\" && niri msg action focus-workspace \"$2\"",
      "sh", workspace.output, workspace.switchRef
    ]
    niriActionProc.running = true
  }
}
