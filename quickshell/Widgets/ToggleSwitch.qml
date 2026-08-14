// ToggleSwitch.qml - Reusable on/off switch control
import QtQuick
import "../Common"

Rectangle {
  id: root

  property bool checked: false
  property bool interactive: true
  signal toggled()

  width: 46
  height: 22
  radius: height / 2
  color: checked ? Config.selectedBg : Config.controlIdleBg
  border.color: checked ? Config.activeBorderColor : Config.borderColor
  border.width: 1

  Behavior on color { ColorAnimation { duration: 160 } }
  Behavior on border.color { ColorAnimation { duration: 160 } }

  Rectangle {
    id: glow
    anchors.fill: parent
    anchors.margins: 2
    radius: height / 2
    color: root.checked ? Config.activeHoverBg : "#00000000"
    opacity: switchMouse.containsMouse ? 0.9 : 0.55

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
  }

  Rectangle {
    id: knob
    width: 16
    height: 16
    radius: height / 2
    x: root.checked ? root.width - width - 3 : 3
    anchors.verticalCenter: parent.verticalCenter
    color: root.checked ? Config.textWhite : Config.textMuted
    border.color: root.checked ? Config.textWhite : Config.subtleBorder
    border.width: 1

    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 160 } }
  }

  MouseArea {
    id: switchMouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
