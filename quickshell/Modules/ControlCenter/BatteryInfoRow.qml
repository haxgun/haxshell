// BatteryInfoRow.qml - Compact battery metric card
import QtQuick
import "../../Common"

Column {
  id: root

  property string label: ""
  property string value: ""

  height: 42
  spacing: 2

  Text {
    text: root.label
    color: Config.textMuted
    font.pixelSize: Config.fontSizeSmall
    font.family: Config.fontSans
  }

  Text {
    text: root.value
    color: Config.textPrimary
    font.pixelSize: Config.fontSizeNormal
    font.weight: Font.Bold
    font.family: Config.fontMono
    elide: Text.ElideRight
    width: parent.width
  }
}
