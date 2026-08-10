// SysMetricPill.qml - compact system metric card
import QtQuick
import "../Common"

Rectangle {
  id: root

  property string icon: ""
  property string value: "--"
  property color accent: Config.textMuted
  property int cardWidth: 58

  width: cardWidth
  height: 22
  radius: 7
  color: "#151A1A1A"
  border.color: Config.borderColor
  border.width: 1

  Row {
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: root.icon
      color: root.accent
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.value
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontMono
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
    }
  }
}
