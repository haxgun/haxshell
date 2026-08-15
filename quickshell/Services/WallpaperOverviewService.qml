import QtQuick
import Quickshell.Io
import "../Common"
import "."

Item {
  id: root
  visible: false

  property bool overviewOpen: false
  readonly property bool available: CompositorService.backend === "niri"

  Process {
    id: overviewProc
    command: ["niri", "msg", "--json", "overview-state"]
    stdout: SplitParser { onRead: data => root.applyState(data) }
  }

  Process { id: wallpaperProc }

  Timer {
    interval: 500
    running: root.available && Config.blurWallpaperOnOverview
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Config
    function onBlurWallpaperOnOverviewChanged() {
      if (!Config.blurWallpaperOnOverview && root.overviewOpen) root.setBlurred(false)
    }
  }

  function refresh() {
    overviewProc.running = false
    overviewProc.running = true
  }

  function applyState(data) {
    try {
      let state = JSON.parse(data)
      let open = !!state.is_open
      if (open !== root.overviewOpen) root.setBlurred(open)
    } catch (error) {}
  }

  function setBlurred(enabled) {
    root.overviewOpen = enabled
    wallpaperProc.running = false
    wallpaperProc.command = [Config.veyctl, "wallpaper", "overview-blur", enabled ? "on" : "off", Config.wallpaperDir]
    wallpaperProc.running = true
  }
}
