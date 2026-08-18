import QtQuick
import Quickshell.Io
import "../Common"

Item {
  id: root
  visible: false

  Process {
    id: cycleProc
    stdout: SplitParser {
      onRead: data => {
        try {
          let result = JSON.parse(data)
          if (result.palette && result.palette.length > 0) {
            Config.applyDynamicPalette(result.palette)
            SettingsStore.setValue("dynamicAccent", Config.dynamicAccent)
            SettingsStore.setValue("dynamicPalette", JSON.stringify(Config.dynamicPalette))
          }
        } catch(e) {}
      }
    }
  }

  Process {
    id: startupProc
    command: [Config.natonctl, "wallpaper", "apply"]
    running: true
  }

  Timer {
    interval: Math.max(30, Config.wallpaperCyclingInterval) * 1000
    running: Config.wallpaperCyclingEnabled
    repeat: true
    onTriggered: root.nextWallpaper()
  }

  function nextWallpaper() {
    cycleProc.running = false
    cycleProc.command = [Config.natonctl, "wallpaper", "next", Config.wallpaperDir, Config.wallpaperPaletteScheme + (Config.dynamicDark ? ":dark" : ":light")]
    cycleProc.running = true
  }
}
