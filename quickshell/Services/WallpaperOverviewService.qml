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
  Process { id: pauseProc }

  Timer {
    interval: 500
    running: root.available && (Config.blurWallpaperOnOverview || Config.videoWallpaperPauseOnOverview)
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Config
    function onBlurWallpaperOnOverviewChanged() {
      if (!Config.blurWallpaperOnOverview && root.overviewOpen) root.setBlurred(false)
    }
    function onVideoWallpaperPauseOnOverviewChanged() {
      if (!Config.videoWallpaperPauseOnOverview && root.overviewOpen) root.setVideoPaused(false)
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
      if (open !== root.overviewOpen) {
        root.overviewOpen = open
        if (Config.blurWallpaperOnOverview) root.setBlurred(open)
        if (Config.videoWallpaperPauseOnOverview) root.setVideoPaused(open)
      }
    } catch (error) {}
  }

  function setBlurred(enabled) {
    wallpaperProc.running = false
    wallpaperProc.command = [Config.natonctl, "wallpaper", "overview-blur", enabled ? "on" : "off", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function setVideoPaused(paused) {
    pauseProc.running = false
    pauseProc.command = [Config.natonctl, "wallpaper", "video-pause", paused ? "on" : "off"]
    pauseProc.running = true
  }
}
