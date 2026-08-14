// MediaPopup.qml - detailed MPRIS now-playing controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  readonly property var player: MprisController.activePlayer
  readonly property bool hasMedia: player && !MprisController.isIdle(player)
  readonly property bool isPlaying: player && player.isPlaying
  readonly property string artist: MprisController.stableArtist
  readonly property string album: MprisController.stableAlbum
  readonly property string title: MprisController.stableTitle
  readonly property string artUrl: normalizeArtUrl(player && player.trackArtUrl ? player.trackArtUrl : "")
  readonly property int positionSec: player ? Math.floor(player.position) : 0
  readonly property int durationSec: Math.floor(MprisController.stableLength)

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "media"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  function normalizeArtUrl(value) {
    let url = (value || "").trim()
    if (url.length === 0) return ""
    if (url.indexOf("/") === 0) return "file://" + url
    return url
  }

  function fmt(seconds) {
    let safe = Math.max(0, seconds || 0)
    let m = Math.floor(safe / 60)
    let s = safe % 60
    return m + ":" + (s < 10 ? "0" + s : s)
  }

  Rectangle {
    id: container
    width: 330
    implicitHeight: content.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: 1 }

    Column {
      id: content
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Rectangle {
        width: parent.width
        height: 170
        radius: Config.cardRadius
        clip: true
        color: Config.searchBg
        ClippingRectangle {
          anchors.fill: parent
          radius: parent.radius
          color: "transparent"
          Image { anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.artUrl.length > 0 }
        }
        Rectangle { anchors.fill: parent; color: "#50000000" }
        Text { anchors.centerIn: parent; visible: root.artUrl.length === 0; text: Config.iconPlay; color: Config.textMuted; font.pixelSize: 44; font.family: Config.fontIcon }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: "#00000000"; border.color: Config.borderColor; border.width: 1 }
      }

      Column {
        width: parent.width
        spacing: 3
        Text { width: parent.width; text: root.title || "Нет трека"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
        Text { width: parent.width; text: root.artist || "Неизвестный артист"; color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans; elide: Text.ElideRight }
        Text { width: parent.width; text: root.album || ""; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; visible: text.length > 0 }
      }

      Rectangle {
        width: parent.width
        height: 5
        radius: 3
        color: Config.searchBg
        Rectangle { width: parent.width * (root.durationSec > 0 ? Math.min(1, root.positionSec / root.durationSec) : 0); height: parent.height; radius: parent.radius; color: Config.textPrimary }
      }

      Row {
        width: parent.width
        Text { text: root.fmt(root.positionSec); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontMono }
        Item { width: parent.width - 76; height: 1 }
        Text { text: root.fmt(root.durationSec); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontMono }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        Repeater {
          model: [
            { icon: Config.iconPrevTrack, action: "previous" },
            { icon: root.isPlaying ? Config.iconPause : Config.iconPlay, action: "play-pause", primary: true },
            { icon: Config.iconNextTrack, action: "next" }
          ]
          Rectangle {
            required property var modelData
            width: modelData.primary ? 42 : 34
            height: modelData.primary ? 42 : 34
            radius: height / 2
            color: mediaButtonMouse.containsMouse ? Config.activeHoverBg : (modelData.primary ? Config.selectedBg : Config.searchBg)
            border.color: Config.borderColor
            border.width: 1
            Text { anchors.centerIn: parent; text: parent.modelData.icon; color: Config.textWhite; font.pixelSize: parent.modelData.primary ? Config.fontSizeIconLarge : Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: mediaButtonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (!root.player) return; if (parent.modelData.action === "previous") MprisController.previousOrRewind(); else if (parent.modelData.action === "next") MprisController.next(); else if (root.player.canTogglePlaying) root.player.togglePlaying() } }
          }
        }
      }
    }
  }
}
