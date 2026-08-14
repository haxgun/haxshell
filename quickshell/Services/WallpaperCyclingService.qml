import QtQuick
import Quickshell.Io
import "../Common"

Item {
  id: root
  visible: false

  Process { id: cycleProc }

  Timer {
    interval: Math.max(30, Config.wallpaperCyclingInterval) * 1000
    running: Config.wallpaperCyclingEnabled
    repeat: true
    onTriggered: root.nextWallpaper()
  }

  function nextWallpaper() {
    cycleProc.running = false
    cycleProc.command = [Config.hushctl, "wallpaper", "next", Config.wallpaperDir]
    cycleProc.running = true
  }
}
