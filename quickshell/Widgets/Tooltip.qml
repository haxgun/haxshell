// Tooltip.qml - Transient hover tooltip overlay for bar widgets
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Common"

PanelWindow {
  id: root

  required property var screenInfo
  property string text: ""
  property bool tipVisible: false
  readonly property real tipWidth: tipLabel.implicitWidth + Config.scaledSize(20)
  readonly property real tipHeight: Config.scaledSize(24)

  visible: tipVisible || bubble.opacity > 0.01
  WlrLayershell.namespace: "quickshell-tooltip"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  screen: root.screenInfo
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? bubble : null
    radius: Math.round(bubble.radius)
  }

  Timer {
    id: showDelay
    interval: 400
    repeat: false
    onTriggered: {
      root.tipVisible = true
    }
  }

  Timer {
    id: hideDelay
    interval: 150
    repeat: false
    onTriggered: root.tipVisible = false
  }

  function show(target, tipText) {
    if (!Config.tooltipsEnabled) return
    root.text = tipText
    showDelay.restart()
    hideDelay.stop()
    if (!target) return
    let g = target.mapToGlobal(Qt.point(0, 0))
    let screenX = root.screenInfo ? root.screenInfo.x : 0
    let screenY = root.screenInfo ? root.screenInfo.y : 0
    let bw = root.tipWidth
    let bh = root.tipHeight
    let x = g.x - screenX + target.width / 2 - bw / 2
    let y = g.y - screenY + target.height / 2 - bh / 2
    if (Config.barPosition === "top") {
      y = 0
    } else if (Config.barPosition === "bottom") {
      y = root.height - bh
    } else if (Config.barPosition === "left") {
      x = 0
    } else if (Config.barPosition === "right") {
      x = root.width - bw
    }
    if (Config.barPosition === "top" || Config.barPosition === "bottom") {
      x = Math.max(6, Math.min(root.width - bw - 6, x))
    } else {
      y = Math.max(6, Math.min(root.height - bh - 6, y))
    }
    bubble.x = x
    bubble.y = y
  }

  function hide() {
    showDelay.stop()
    hideDelay.restart()
  }

  Rectangle {
    id: bubble
    width: root.tipWidth
    height: root.tipHeight
    radius: Config.overlayRadius
    color: Config.popupGlassBg
    opacity: root.tipVisible ? 1 : 0
    scale: root.tipVisible ? 1 : 0.96

    Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 90 } }
    Behavior on scale { NumberAnimation { duration: Config.reduceMotion ? 0 : 110; easing.type: Easing.OutCubic } }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.popupBorderColor
      border.width: Config.popupBordersEnabled ? 1 : 0
    }

    Text {
      id: tipLabel
      anchors.centerIn: parent
      text: root.text
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.family: Config.fontSans
    }
  }
}
