// Osd.qml - Transient volume and brightness on-screen display
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common"

PanelWindow {
  id: root

  property bool visibleOsd: false
  property string icon: Config.iconVolHigh
  property string label: "Громкость"
  property int value: 0
  property bool muted: false
  readonly property bool osdAtTop: Config.osdPosition.indexOf("top-") === 0
  readonly property bool osdAtLeft: Config.osdPosition.indexOf("left") >= 0
  readonly property bool osdAtCenter: Config.osdPosition.indexOf("center") >= 0

  visible: visibleOsd || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  IpcHandler {
    target: "osd"
    function volume(value: string, muted: string) { root.showVolume(parseInt(value) || 0, muted === "true") }
    function brightness(value: string) { root.showBrightness(parseInt(value) || 0) }
  }

  Timer {
    id: hideTimer
    interval: 1800
    repeat: false
    onTriggered: root.visibleOsd = false
  }

  function showVolume(nextValue, isMuted) {
    value = Math.max(0, Math.min(150, Math.round(nextValue)))
    muted = isMuted
    label = muted ? "Звук выключен" : "Громкость"
    icon = muted ? Config.iconVolMuted : (value >= 70 ? Config.iconVolHigh : (value >= 30 ? Config.iconVolMedium : Config.iconVolLow))
    visibleOsd = true
    hideTimer.restart()
  }

  function showBrightness(nextValue) {
    value = Math.max(0, Math.min(100, Math.round(nextValue)))
    muted = false
    label = "Яркость"
    icon = value >= 75 ? Config.iconBrightHigh : (value >= 35 ? Config.iconBrightMedium : (value > 0 ? Config.iconBrightLow : Config.iconBrightOff))
    visibleOsd = true
    hideTimer.restart()
  }

  Rectangle {
    id: container
    width: 260
    height: 76
    anchors.top: root.osdAtTop ? parent.top : undefined
    anchors.topMargin: root.osdAtTop ? 72 : 0
    anchors.bottom: root.osdAtTop ? undefined : parent.bottom
    anchors.bottomMargin: root.osdAtTop ? 0 : 72
    anchors.left: root.osdAtLeft ? parent.left : undefined
    anchors.leftMargin: root.osdAtLeft ? 24 : 0
    anchors.right: root.osdAtLeft || root.osdAtCenter ? undefined : parent.right
    anchors.rightMargin: root.osdAtLeft || root.osdAtCenter ? 0 : 24
    anchors.horizontalCenter: root.osdAtCenter ? parent.horizontalCenter : undefined
    radius: Config.overlayRadius
    color: Config.popupGlassBg
    opacity: root.visibleOsd ? 1 : 0
    scale: root.visibleOsd ? 1 : 0.94

    Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 80 } }
    Behavior on scale { NumberAnimation { duration: Config.reduceMotion ? 0 : 100; easing.type: Easing.OutCubic } }

    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: parent.radius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    Row {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Text { width: 28; text: root.icon; color: root.muted ? Config.dangerRed : Config.textWhite; font.pixelSize: 22; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
      Column {
        width: parent.width - 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        Row {
          width: parent.width
          Text { text: root.label; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; width: parent.width - 46 }
          Text { text: root.muted ? "Выкл." : root.value + "%"; color: root.muted ? Config.dangerRed : Config.textWhite; font.pixelSize: Config.fontMonoSizeSmall; font.weight: Font.Bold; font.family: Config.fontMono; width: 46; horizontalAlignment: Text.AlignRight }
        }
        Rectangle {
          width: parent.width
          height: 6
          radius: 3
          color: Config.searchBg
          Rectangle { width: parent.width * Math.min(1, root.value / 100); height: parent.height; radius: parent.radius; color: root.muted ? Config.dangerRed : Config.textPrimary }
        }
      }
    }
  }
}
