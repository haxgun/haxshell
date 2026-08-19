// BrightnessPopup.qml - Display Brightness Control Overlay
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: Config.scaledSize(16)
  property var osd: null
  property alias brightnessPercent: brightnessPanel.brightnessPercent
  function applyBrightness(val) { brightnessPanel.applyBrightness(val) }

  visible: isOpen || container.opacity > 0.01

  // Wayland LayerShell Configuration
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  // Background dismiss handler
  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: {
      root.isOpen = false
    }
  }

  // IPC Handler
  IpcHandler {
    target: "brightness"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
    function set(val: string) {
      let v = Math.max(0, Math.min(100, parseInt(val) || 0))
      brightnessPanel.applyBrightness(v)
    }
  }

  // Floating Container Box
  Rectangle {
    id: container
    width: Config.brightnessWidth
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: root.rightMargin

    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    color: Config.popupGlassBg
    radius: Config.overlayRadius

    MouseArea {
      anchors.fill: parent
      onClicked: (mouse) => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.popupBorderColor
      border.width: Config.popupBordersEnabled ? 1 : 0
    }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter

      BrightnessPanel {
        id: brightnessPanel
        width: parent.width
        active: root.isOpen
        osd: root.osd
      }
    }
  }
}
