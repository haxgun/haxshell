// GradientSurface.qml - rounded glass surface with a light-top gradient ring
import QtQuick
import "../Common"

Rectangle {
  id: root

  default property alias content: inner.data

  property real radiusValue: Config.overlayRadius
  property color surfaceColor: Config.glassBg
  property real ringThickness: Config.innerBorderMargin
  property bool clipContent: true
  readonly property color ringTopColor: Config.ringTopColor
  readonly property color ringBottomColor: "#00000000"

  color: "transparent"
  radius: radiusValue

  gradient: Gradient {
    GradientStop { position: 0.0; color: root.ringTopColor }
    GradientStop { position: 0.35; color: Qt.rgba(root.ringTopColor.r, root.ringTopColor.g, root.ringTopColor.b, root.ringTopColor.a * 0.25) }
    GradientStop { position: 1.0; color: root.ringBottomColor }
  }

  Rectangle {
    id: inner
    anchors.fill: parent
    anchors.margins: root.ringThickness
    radius: Math.max(1, root.radiusValue - root.ringThickness)
    color: root.surfaceColor
    clip: root.clipContent
  }
}