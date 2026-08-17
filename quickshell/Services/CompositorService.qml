pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
  id: root

  readonly property string backend: Quickshell.env("NIRI_SOCKET") ? "niri" : "hyprland"
  readonly property var niriBackend: niriBackendLoader.item
  property var niriFallbackWorkspaces: []
  property var niriFallbackWindows: []
  readonly property bool niriPluginReady: niriBackend && niriBackend.connected
  readonly property var niriFallbackNormalizedWorkspaces: {
    let occupied = {}
    for (let i = 0; i < niriFallbackWindows.length; i++) {
      let window = niriFallbackWindows[i]
      if (window && window.workspace_id !== undefined) occupied[window.workspace_id.toString()] = true
    }
    let result = []
    for (let i = 0; i < niriFallbackWorkspaces.length; i++) {
      let workspace = niriFallbackWorkspaces[i]
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
  readonly property var niriWorkspaces: niriPluginReady ? niriBackend.workspaces : niriFallbackNormalizedWorkspaces
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
  readonly property var workspaces: backend === "niri" ? niriWorkspaces : hyprlandWorkspaces
  readonly property var toplevels: {
    let source = backend === "niri" ? niriFallbackWindows : (Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : [])
    let result = []
    for (let i = 0; i < source.length; i++) {
      let window = source[i]
      if (!window) continue
      let ipc = backend === "hyprland" ? (window.lastIpcObject || {}) : window
      result.push({
        id: backend === "niri" ? window.id : (ipc.address || ""),
        appId: backend === "niri" ? (window.app_id || "") : (ipc.class || ""),
        title: window.title || ipc.title || "",
        output: backend === "niri" ? outputForWorkspace(window.workspace_id) : (window.monitor ? window.monitor.name : ""),
        focused: backend === "niri" ? !!window.is_focused : window === Hyprland.activeToplevel
      })
    }
    return result
  }
  readonly property string focusedOutputName: {
    if (backend === "niri") {
      if (niriPluginReady) return niriBackend.focusedOutputName
      for (let i = 0; i < niriFallbackWorkspaces.length; i++) {
        if (niriFallbackWorkspaces[i] && niriFallbackWorkspaces[i].is_focused) return niriFallbackWorkspaces[i].output || ""
      }
      return ""
    }
    return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
  }
  readonly property var activeApp: {
    if (backend === "niri") {
      if (niriPluginReady) return niriBackend.activeApp
      for (let i = 0; i < niriFallbackWindows.length; i++) {
        let window = niriFallbackWindows[i]
        if (window && window.is_focused) {
          let output = ""
          for (let j = 0; j < niriFallbackWorkspaces.length; j++) {
            let ws = niriFallbackWorkspaces[j]
            if (ws && ws.id === window.workspace_id) { output = ws.output || ""; break }
          }
          return { appId: window.app_id || "", title: window.title || "", output: output }
        }
      }
      return { appId: "", title: "", output: "" }
    }
    let window = Hyprland.activeToplevel
    let ipc = window ? window.lastIpcObject : ({})
    return {
      appId: (ipc.class || ipc.initialClass || ipc.initialTitle || "").toString(),
      title: window ? (window.title || ipc.title || "") : "",
      output: window && window.monitor ? (window.monitor.name || "") : ""
    }
  }
  readonly property string exitCommand: backend === "niri" ? "niri msg action quit" : "hyprctl dispatch exit"

  Loader {
    id: niriBackendLoader
    active: root.backend === "niri"
    source: active ? "NiriBackend.qml" : ""
  }

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
    running: root.backend === "niri" && !root.niriPluginReady
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNiriFallback()
  }

  function applyNiriWorkspaces(data) {
    try {
      let value = JSON.parse(data)
      if (Array.isArray(value)) niriFallbackWorkspaces = value
    } catch (error) {}
  }

  function applyNiriWindows(data) {
    try {
      let value = JSON.parse(data)
      if (Array.isArray(value)) niriFallbackWindows = value
    } catch (error) {}
  }

  function refreshNiriFallback() {
    if (backend !== "niri" || niriPluginReady) return
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

  function outputForWorkspace(id) {
    for (let i = 0; i < niriFallbackWorkspaces.length; i++) {
      if (niriFallbackWorkspaces[i] && niriFallbackWorkspaces[i].id === id) return niriFallbackWorkspaces[i].output || ""
    }
    return ""
  }

  function toplevelsForOutput(output) {
    return toplevels.filter(window => !output || window.output === output)
  }

  function focusToplevel(window) {
    if (!window || !window.id) return
    if (backend === "hyprland") {
      Hyprland.dispatch("focuswindow address:" + window.id)
      return
    }
    niriActionProc.running = false
    niriActionProc.command = ["niri", "msg", "action", "focus-window", "--id", String(window.id)]
    niriActionProc.running = true
  }

  function switchWorkspace(workspace) {
    if (!workspace) return
    if (backend === "hyprland") {
      Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace.switchRef + " })")
      return
    }
    if (niriPluginReady) {
      niriBackend.focusWorkspaceById(Number(workspace.key))
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
