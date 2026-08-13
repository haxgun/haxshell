// GradientRing.qml - thin decorative ring with a light-top gradient border
import QtQuick
import "../Common"

Rectangle {
  id: root

  anchors.fill: parent

  property real radiusValue: Config.innerBorderRadius
  property real ringThickness: 1
  property color maskColor: Config.glassBg
  readonly property color ringTopColor: Config.ringTopColor
  readonly property color ringBottomColor: "#00000000"

  color: "transparent"
  radius: radiusValue

  gradient: Gradient {
    GradientStop { position: 0.0; color: root.ringTopColor }
    GradientStop { position: 0.5; color: Qt.rgba(root.ringTopColor.r, root.ringTopColor.g, root.ringTopColor.b, root.ringTopColor.a * 0.2) }
    GradientStop { position: 1.0; color: root.ringBottomColor }
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.ringThickness
    radius: Math.max(0, parent.radius - root.ringThickness)
    color: root.maskColor
  }
}