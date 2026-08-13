// MediaWidget.qml - compact now-playing status button
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../Common"

Rectangle {
  id: root

  property var mediaPopup: null
  property var closeFlyouts: null
  readonly property var player: MprisController.activePlayer
  readonly property bool hasMedia: player && !MprisController.isIdle(player)
  readonly property bool isPlaying: player && player.isPlaying
  readonly property string title: MprisController.stableTitle
  readonly property string artist: MprisController.stableArtist
  readonly property string artUrl: resolveArtUrl(player && player.trackArtUrl ? player.trackArtUrl : "", player && player.metadata ? player.metadata["xesam:url"] : "")

  visible: Config.musicVisualizerEnabled && root.hasMedia
  height: Config.buttonHeight
  implicitWidth: mediaRow.implicitWidth + 12
  radius: Config.buttonRadius
  color: mediaMouse.containsMouse || (mediaPopup && mediaPopup.isOpen) ? Config.pressedBg : "#00000000"
  clip: true

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
      ClippingRectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        Image { anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.artUrl.length > 0 }
      }
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
