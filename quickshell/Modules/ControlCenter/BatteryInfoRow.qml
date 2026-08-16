// BatteryInfoRow.qml - Compact battery metric card
import QtQuick
import "../../Common"

Column {
  id: root

  property string label: ""
  property string value: ""

  height: Config.scaledSize(42)
  spacing: Config.scaledSize(2)

  Text {
    text: root.label
    color: Config.textMuted
    font.pixelSize: Config.fontSizeSmall
    font.family: Config.fontSans
  }

  Text {
    text: root.value
    color: Config.textPrimary
    font.pixelSize: Config.fontMonoSizeNormal
    font.weight: Font.Medium
    font.family: Config.fontMono
    elide: Text.ElideRight
    width: parent.width
  }
}
