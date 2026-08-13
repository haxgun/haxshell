// MediaWidget.qml - compact now-playing status button
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  property var mediaPopup: null
  property var closeFlyouts: null
  property bool hasMedia: false
  property bool isPlaying: false
  property string title: ""
  property string artist: ""
  property string artUrl: ""
  readonly property string mediaSeparator: "\u001f"

  visible: Config.musicVisualizerEnabled && root.hasMedia
  height: Config.buttonHeight
  implicitWidth: mediaRow.implicitWidth + 12
  radius: Config.buttonRadius
  color: mediaMouse.containsMouse || (mediaPopup && mediaPopup.isOpen) ? Config.pressedBg : "#00000000"
  clip: true

  Process {
    id: mediaProc
    command: ["playerctl", "metadata", "-F", "--format", "{{status}}" + root.mediaSeparator + "{{artist}}" + root.mediaSeparator + "{{title}}" + root.mediaSeparator + "{{mpris:artUrl}}" + root.mediaSeparator + "{{xesam:url}}"]
    running: true
    stdout: SplitParser {
      onRead: data => root.applyMedia(data)
    }
  }

  function applyMedia(data) {
    let parts = data.trim().split(root.mediaSeparator)
    if (parts.length >= 4) {
      root.isPlaying = parts[0] === "Playing"
      root.hasMedia = parts[0] === "Playing" || parts[0] === "Paused"
      root.artist = parts[1]
      root.title = parts[2]
      root.artUrl = root.resolveArtUrl(parts[3], parts.length >= 5 ? parts[4] : "")
    }
  }

  function resolveArtUrl(artValue, pageUrl) {
    let art = root.normalizeArtUrl(artValue)
    if (art.length > 0) return art
    return root.youtubeArtUrl(pageUrl)
  }

  function youtubeArtUrl(value) {
    let url = (value || "").trim()
    let match = url.match(/[?&]v=([^&#]+)/) || url.match(/youtu\.be\/([^?&#/]+)/) || url.match(/\/(?:shorts|embed)\/([^?&#/]+)/)
    if (!match || !match[1]) return ""
    return "https://i.ytimg.com/vi/" + match[1] + "/hqdefault.jpg"
  }

  function normalizeArtUrl(value) {
    let url = (value || "").trim()
    if (url.length === 0) return ""
    if (url.indexOf("/") === 0) return "file://" + url
    return url
  }

  Row {
    id: mediaRow
    anchors.centerIn: parent
    spacing: 7

    Rectangle {
      width: 22
      height: 22
      radius: 6
      clip: true
      color: Config.searchBg
      Image { anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.artUrl.length > 0 }
      Text { anchors.centerIn: parent; visible: root.artUrl.length === 0; text: root.isPlaying ? Config.iconPause : Config.iconPlay; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
      Rectangle { anchors.fill: parent; radius: parent.radius; color: "#00000000"; border.color: Config.borderColor; border.width: 1 }
    }

    Text {
      width: Math.min(150, implicitWidth)
      text: root.title || root.artist
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontSans
      elide: Text.ElideRight
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mediaMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.mediaPopup) {
        let statusRoot = root.parent ? root.parent.parent : null
        let row = root.parent
        if (statusRoot && row) root.mediaPopup.rightMargin = Math.max(16, Math.round(statusRoot.width - (row.x + root.x + root.width) + Config.barMargin))
        if (root.closeFlyouts) root.closeFlyouts("media")
        root.mediaPopup.isOpen = !root.mediaPopup.isOpen
      }
    }
  }
}
