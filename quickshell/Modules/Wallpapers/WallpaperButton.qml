// WallpaperButton.qml - Current wallpaper thumbnail and next wallpaper button
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  property string thumbnail: ""
  property string wallName: ""
  property var wallpaperPopup: null
  property var closeFlyouts: null
  readonly property string hushctl: Config.hushctl

  width: 26
  height: Config.buttonHeight
  radius: Config.buttonRadius
  clip: true
  color: wallMouse.containsMouse ? Config.pressedBg : "#00000000"

  Process {
    id: wallpaperProc
    command: [root.hushctl, "wallpaper", "get", Config.wallpaperDir]
    running: true

    stdout: SplitParser {
      onRead: data => root.applyState(data)
    }
  }

  Connections {
    target: Config
    function onWallpaperDirChanged() { root.refresh() }
  }

  function refresh() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "get", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function applyState(data) {
    try {
      let res = JSON.parse(data)
      root.thumbnail = res.thumbnail || ""
      root.wallName = res.name || ""
    } catch(e) {}
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "next", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  Image {
    anchors.fill: parent
    source: root.thumbnail
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: root.thumbnail.length > 0
    opacity: 0.95
  }

  Rectangle {
    anchors.fill: parent
    color: root.thumbnail ? "#30000000" : "#151A1A1A"
  }

  Text {
    anchors.centerIn: parent
    text: Config.iconWallpaper
    color: Config.textWhite
    font.pixelSize: Config.fontSizeIconMedium
    font.family: Config.fontIcon
  }

  MouseArea {
    id: wallMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.wallpaperPopup) {
        let shouldOpen = !root.wallpaperPopup.isOpen
        if (root.closeFlyouts) root.closeFlyouts("wallpaper")
        root.wallpaperPopup.isOpen = shouldOpen
      } else {
        root.nextWallpaper()
      }
    }
  }
}
