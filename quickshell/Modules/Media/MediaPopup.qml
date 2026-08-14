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
  readonly property string artUrl: normalizeArtUrl(MprisController.stableArtUrl)
  readonly property int positionSec: player ? Math.floor(player.position) : 0
  readonly property int durationSec: Math.floor(MprisController.stableLength)
  property color artworkPrimary: Config.popupGlassBg
  property color artworkSecondary: Config.popupGlassBg

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

  function resetArtworkColors() {
    artworkPrimary = Config.popupGlassBg
    artworkSecondary = Config.popupGlassBg
  }

  onArtUrlChanged: {
    resetArtworkColors()
    if (artUrl.length > 0) artworkPalette.loadImage(artUrl)
  }

  Rectangle {
    id: container
    width: 390
    implicitHeight: content.implicitHeight + content.anchors.topMargin * 2
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

      Canvas {
        id: artworkPalette
        width: 32
        height: 32
        visible: false
        renderTarget: Canvas.Image
        Component.onCompleted: if (root.artUrl.length > 0) loadImage(root.artUrl)
        onImageLoaded: requestPaint()

        onPaint: {
          if (!root.artUrl || !isImageLoaded(root.artUrl)) return

          let context = getContext("2d")
          context.clearRect(0, 0, width, height)
          context.drawImage(root.artUrl, 0, 0, width, height)
          let pixels = context.getImageData(0, 0, width, height).data
          let buckets = {}

          for (let i = 0; i < pixels.length; i += 4) {
            if (pixels[i + 3] < 192) continue
            let key = Math.floor(pixels[i] / 32) + ":" + Math.floor(pixels[i + 1] / 32) + ":" + Math.floor(pixels[i + 2] / 32)
            let bucket = buckets[key]
            if (!bucket) bucket = buckets[key] = { count: 0, red: 0, green: 0, blue: 0 }
            bucket.count += 1
            bucket.red += pixels[i]
            bucket.green += pixels[i + 1]
            bucket.blue += pixels[i + 2]
          }

          let primary = null
          let secondary = null
          let keys = Object.keys(buckets)
          for (let i = 0; i < keys.length; i++) {
            let bucket = buckets[keys[i]]
            if (!primary || bucket.count > primary.count) primary = bucket
          }
          if (!primary) return

          let primaryRed = primary.red / primary.count
          let primaryGreen = primary.green / primary.count
          let primaryBlue = primary.blue / primary.count
          for (let i = 0; i < keys.length; i++) {
            let bucket = buckets[keys[i]]
            let red = bucket.red / bucket.count
            let green = bucket.green / bucket.count
            let blue = bucket.blue / bucket.count
            let distance = Math.abs(red - primaryRed) + Math.abs(green - primaryGreen) + Math.abs(blue - primaryBlue)
            if (distance >= 48 && (!secondary || bucket.count > secondary.count)) secondary = bucket
          }

          root.artworkPrimary = Qt.rgba(primaryRed / 255, primaryGreen / 255, primaryBlue / 255, 1)
          root.artworkSecondary = secondary
            ? Qt.rgba(secondary.red / secondary.count / 255, secondary.green / secondary.count / 255, secondary.blue / secondary.count / 255, 1)
            : root.artworkPrimary
        }
      }

      Rectangle {
        anchors.fill: parent
        visible: root.artUrl.length > 0
        gradient: Gradient {
          GradientStop { position: 0.0; color: root.artworkPrimary }
          GradientStop { position: 1.0; color: root.artworkSecondary }
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "#8a000000"
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
        height: Math.max(artwork.height, mediaDetails.implicitHeight)
        spacing: 16

        Rectangle {
          id: artwork
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
        }

        Column {
          id: mediaDetails
          width: parent.width - artwork.width - parent.spacing
          spacing: 4
            Item { width: 1; height: 6 }
            Text { width: parent.width; text: root.title || "Нет трека"; color: "#ffffff"; font.pixelSize: Config.fontSizeTitle; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
            Text { width: parent.width; text: root.artist || "Неизвестный артист"; color: "#e8ffffff"; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans; elide: Text.ElideRight }
            Text { width: parent.width; text: root.album || ""; color: "#b8ffffff"; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; visible: text.length > 0 }
            Item { width: 1; height: 6 }

            Item {
              width: parent.width
              height: 36
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
