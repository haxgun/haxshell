// MediaPopup.qml - detailed MPRIS now-playing controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick.Effects
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
  readonly property string artUrl: normalizeArtUrl(MprisController.stableArtUrl)
  readonly property int positionSec: player ? Math.floor(player.position) : 0
  readonly property int durationSec: Math.floor(MprisController.stableLength)

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"

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
    width: 390
    implicitHeight: content.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg

    ClippingRectangle {
      anchors.fill: parent
      radius: parent.radius
      color: Config.popupGlassBg
      Image {
        id: backgroundArtwork
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
      }
      MultiEffect {
        anchors.fill: parent
        source: backgroundArtwork
        visible: root.artUrl.length > 0
        blurEnabled: true
        blur: 1.0
        blurMax: 128
        saturation: 1.15
      }
      Rectangle {
        anchors.fill: parent
        color: "#82000000"
      }
    }

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
      Row {
        width: parent.width
        height: 140
        spacing: 16

        Rectangle {
          width: 120
          height: 120
          radius: Config.cardRadius
          color: Config.searchBg
          ClippingRectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            Image { anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.artUrl.length > 0 }
          }
          Text { anchors.centerIn: parent; visible: root.artUrl.length === 0; text: Config.iconPlay; color: Config.textMuted; font.pixelSize: 36; font.family: Config.fontIcon }
          Rectangle { anchors.fill: parent; radius: parent.radius; color: "#00000000"; border.color: "#80ffffff"; border.width: 1 }
        }

        Column {
          width: parent.width - 196
          height: parent.height
          spacing: 4

          Item { width: 1; height: 6 }
          Text { width: parent.width; text: root.title || "Нет трека"; color: "#ffffff"; font.pixelSize: Config.fontSizeTitle; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.artist || "Неизвестный артист"; color: "#e8ffffff"; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.album || ""; color: "#b8ffffff"; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; visible: text.length > 0 }
          Item { width: 1; height: 6 }

          Item {
            width: parent.width
            height: 16
            Row {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: 17
              Repeater {
                model: [
                  { icon: Config.iconPrevTrack, action: "previous" },
                  { icon: root.isPlaying ? Config.iconPause : Config.iconPlay, action: "play-pause", primary: true },
                  { icon: Config.iconNextTrack, action: "next" }
                ]
                Rectangle {
                  required property var modelData
                  width: 36
                  height: 36
                  color: "transparent"
                  Text { anchors.centerIn: parent; text: parent.modelData.icon; color: mediaButtonMouse.containsMouse ? "#c8ffffff" : "#ffffff"; font.pixelSize: Config.fontSizeIconLarge; font.family: Config.fontIcon }
                  MouseArea { id: mediaButtonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (!root.player) return; if (parent.modelData.action === "previous") MprisController.previousOrRewind(); else if (parent.modelData.action === "next") MprisController.next(); else if (root.player.canTogglePlaying) root.player.togglePlaying() } }
                }
              }
            }
          }
          Item { width: 1; height: 5 }

          Rectangle {
            width: parent.width
            height: 5
            radius: 3
            color: "#55ffffff"
            Rectangle { width: parent.width * (root.durationSec > 0 ? Math.min(1, root.positionSec / root.durationSec) : 0); height: parent.height; radius: parent.radius; color: "#ffffff" }
          }

          Item {
            width: parent.width
            height: 14
            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: root.fmt(root.positionSec); color: "#c8ffffff"; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontMono }
            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.fmt(root.durationSec); color: "#c8ffffff"; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontMono }
          }
        }
      }

    }
  }
}
