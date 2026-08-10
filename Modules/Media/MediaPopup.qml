// MediaPopup.qml - detailed MPRIS now-playing controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property bool hasMedia: false
  property bool isPlaying: false
  property string artist: ""
  property string album: ""
  property string title: ""
  property string artUrl: ""
  property int positionSec: 0
  property int durationSec: 0
  readonly property string mediaSeparator: "\u001f"

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

  Process {
    id: metadataProc
    command: ["playerctl", "metadata", "-F", "--format", "{{status}}" + root.mediaSeparator + "{{artist}}" + root.mediaSeparator + "{{album}}" + root.mediaSeparator + "{{title}}" + root.mediaSeparator + "{{mpris:artUrl}}" + root.mediaSeparator + "{{xesam:url}}" + root.mediaSeparator + "{{position}}" + root.mediaSeparator + "{{mpris:length}}"]
    running: true
    stdout: SplitParser { onRead: data => root.applyMedia(data) }
  }

  Process { id: controlProc }

  Timer {
    interval: 1000
    running: root.isPlaying
    repeat: true
    onTriggered: if (root.durationSec <= 0 || root.positionSec < root.durationSec) root.positionSec++
  }

  function runControl(action) {
    controlProc.running = false
    controlProc.command = ["playerctl", action]
    controlProc.running = true
  }

  function applyMedia(data) {
    let parts = data.trim().split(root.mediaSeparator)
    if (parts.length >= 8) {
      root.isPlaying = parts[0] === "Playing"
      root.hasMedia = parts[0] === "Playing" || parts[0] === "Paused"
      root.artist = parts[1]
      root.album = parts[2]
      root.title = parts[3]
      root.artUrl = root.resolveArtUrl(parts[4], parts[5])
      root.positionSec = Math.floor((parseInt(parts[6]) || 0) / 1000000)
      root.durationSec = Math.floor((parseInt(parts[7]) || 0) / 1000000)
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
    color: Config.glassBg

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
        Image { anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.artUrl.length > 0 }
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
            MouseArea { id: mediaButtonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.runControl(parent.modelData.action) }
          }
        }
      }
    }
  }
}
