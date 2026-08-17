import QtQuick
import "../Common"

Item {
  id: root

  property color selectedColor: "#ffffff"
  property real hue: 0
  property real saturation: 0
  property real value: 1
  signal colorEdited(color color)

  function updateFromColor(color) {
    hue = color.hsvHue < 0 ? 0 : color.hsvHue
    saturation = color.hsvSaturation
    value = color.hsvValue
  }
  function updateFromPoint(x, y) {
    saturation = Math.max(0, Math.min(1, x / plane.width))
    value = Math.max(0, Math.min(1, 1 - y / plane.height))
    colorEdited(Qt.hsva(hue, saturation, value, 1))
  }
  function setHue(y) {
    hue = Math.max(0, Math.min(1, y / hueStrip.height))
    colorEdited(Qt.hsva(hue, saturation, value, 1))
  }

  onSelectedColorChanged: updateFromColor(selectedColor)
  Component.onCompleted: updateFromColor(selectedColor)

  Row {
    anchors.fill: parent
    spacing: Config.scaledSize(10)

    Rectangle {
      id: plane
      width: parent.width - hueStrip.width - Config.scaledSize(10)
      height: parent.height
      radius: Config.popupRadiusPx(10)
      color: Qt.hsla(root.hue, 1, 0.5, 1)
      clip: true
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: "#ffffff" }
          GradientStop { position: 1; color: "#00ffffff" }
        }
      }
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0; color: "#00000000" }
          GradientStop { position: 1; color: "#ff000000" }
        }
      }
      Rectangle {
        width: Config.scaledSize(14)
        height: width
        radius: width / 2
        x: root.saturation * plane.width - width / 2
        y: (1 - root.value) * plane.height - height / 2
        color: "#00000000"
        border.color: Config.textWhite
        border.width: 2
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPressed: mouse => root.updateFromPoint(mouse.x, mouse.y)
        onPositionChanged: mouse => { if (pressed) root.updateFromPoint(mouse.x, mouse.y) }
      }
    }

    Rectangle {
      id: hueStrip
      width: Config.scaledSize(24)
      height: parent.height
      radius: Config.popupRadiusPx(10)
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0; color: "#ff0000" }
        GradientStop { position: 1 / 6; color: "#ffff00" }
        GradientStop { position: 2 / 6; color: "#00ff00" }
        GradientStop { position: 3 / 6; color: "#00ffff" }
        GradientStop { position: 4 / 6; color: "#0000ff" }
        GradientStop { position: 5 / 6; color: "#ff00ff" }
        GradientStop { position: 1; color: "#ff0000" }
      }
      Rectangle {
        width: parent.width
        height: Config.scaledSize(3)
        y: root.hue * (parent.height - height)
        color: Config.textWhite
        border.color: Config.textPrimary
        border.width: 1
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.SizeVerCursor
        onPressed: mouse => root.setHue(mouse.y)
        onPositionChanged: mouse => { if (pressed) root.setHue(mouse.y) }
      }
    }
  }
}
