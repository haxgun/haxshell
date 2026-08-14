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
  readonly property string artUrl: normalizeArtUrl(player && player.trackArtUrl ? player.trackArtUrl : "")
  readonly property string trackLabel: {
    if (artist && title) return artist + " — " + title
    return title || artist
  }

  visible: Config.musicVisualizerEnabled && root.hasMedia
  height: Config.buttonHeight
  implicitWidth: mediaRow.implicitWidth + 12
  radius: Config.buttonRadius
  color: mediaMouse.containsMouse || (mediaPopup && mediaPopup.isOpen) ? Config.pressedBg : "#00000000"
  clip: true

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

    Item {
      id: trackViewport
      width: Math.min(150, trackText.implicitWidth)
      height: 22
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: trackText
        anchors.verticalCenter: parent.verticalCenter
        text: root.trackLabel
        color: Config.textPrimary
        font.pixelSize: Config.fontSizeSmall
        font.weight: Font.Medium
        font.family: Config.fontSans
      }

      SequentialAnimation {
        id: trackMarquee
        running: trackText.implicitWidth > trackViewport.width
        loops: Animation.Infinite
        PauseAnimation { duration: 1200 }
        NumberAnimation { target: trackText; property: "x"; from: 0; to: -(trackText.implicitWidth - trackViewport.width); duration: Math.max(1800, (trackText.implicitWidth - trackViewport.width) * 28); easing.type: Easing.InOutSine }
        PauseAnimation { duration: 1000 }
        NumberAnimation { target: trackText; property: "x"; to: 0; duration: Math.max(1200, (trackText.implicitWidth - trackViewport.width) * 20); easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) trackText.x = 0
      }
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
