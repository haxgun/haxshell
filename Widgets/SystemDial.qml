import QtQuick
import "../Common"

Item {
  id: root

  property real value: 0
  property string primary: ""
  property string unit: ""
  property string label: ""
  property string sub: ""
  property real display: value

  width: 104
  height: 104

  onValueChanged: display = value
  onDisplayChanged: face.requestPaint()
  readonly property color loadColor: display > 85 ? Config.dangerRed : (display > 70 ? Config.warningAmber : Config.themeAccent)
  onLoadColorChanged: face.requestPaint()
  Component.onCompleted: face.requestPaint()
  Behavior on display { NumberAnimation { duration: Config.reduceMotion ? 0 : 650; easing.type: Easing.OutCubic } }

  Canvas {
    id: face
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      let ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      let cx = width / 2
      let cy = height / 2
      let lineWidth = 8
      let radius = Math.min(width, height) / 2 - lineWidth / 2 - 1
      let start = 135 * Math.PI / 180
      let full = 270 * Math.PI / 180
      ctx.lineCap = "round"
      ctx.lineWidth = lineWidth
      ctx.strokeStyle = Config.isLightTheme ? "rgba(15, 23, 42, 0.14)" : "rgba(226, 232, 240, 0.13)"
      ctx.beginPath()
      ctx.arc(cx, cy, radius, start, start + full, false)
      ctx.stroke()

      let v = Math.max(0, Math.min(100, root.display))
      if (v > 0.5) {
        ctx.strokeStyle = root.loadColor
        ctx.beginPath()
        ctx.arc(cx, cy, radius, start, start + full * v / 100, false)
        ctx.stroke()
      }
    }
  }

  Row {
    id: valueRow
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -10
    spacing: 1

    Text { id: valueText; text: root.primary; color: Config.textWhite; font.pixelSize: root.primary.length > 3 ? 16 : 20; font.weight: Font.ExtraBold; font.family: Config.fontSans }
    Text { anchors.baseline: valueText.baseline; text: root.unit; color: Config.textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.family: Config.fontSans; visible: root.unit.length > 0 }
  }

  Column {
    anchors.top: valueRow.bottom
    anchors.topMargin: 3
    anchors.horizontalCenter: valueRow.horizontalCenter
    spacing: 3

    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.label; color: Config.textMuted; font.pixelSize: 9; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 1.1 }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sub; color: Config.textSubtle; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans }
  }
}
