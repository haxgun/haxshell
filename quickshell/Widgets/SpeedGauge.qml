// SpeedGauge.qml - Network throughput gauge
import QtQuick
import "../Common"

Item {
  id: root

  property real value: 0
  property real maximum: 100
  property string title: "NET"
  property string primary: "0"
  property string secondary: ""
  property color accent: Config.activeBorderColor

  width: 150
  height: 132

  readonly property real pct: Math.max(0, Math.min(1, maximum > 0 ? value / maximum : 0))
  readonly property color loadColor: pct > 0.85 ? Config.dangerRed : (pct > 0.70 ? Config.warningAmber : Config.themeAccent)

  onPctChanged: gauge.requestPaint()
  onAccentChanged: gauge.requestPaint()
  onLoadColorChanged: gauge.requestPaint()

  Canvas {
    id: gauge
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: 112
    height: 88

    onPaint: {
      let ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.lineCap = "round"
      ctx.lineWidth = 8

      let cx = width / 2
      let cy = height - 6
      let radius = 46
      let start = Math.PI
      let span = Math.PI

      ctx.beginPath()
      ctx.strokeStyle = Config.subtleBorder
      ctx.arc(cx, cy, radius, start, start + span, false)
      ctx.stroke()

      ctx.beginPath()
      ctx.strokeStyle = root.loadColor
      ctx.arc(cx, cy, radius, start, start + span * root.pct, false)
      ctx.stroke()
    }
  }

  Column {
    anchors.horizontalCenter: gauge.horizontalCenter
    y: 38
    spacing: 1

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.primary
      color: Config.textWhite
      font.pixelSize: 20
      font.weight: Font.Bold
      font.family: Config.fontMono
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.title
      color: Config.textMuted
      font.pixelSize: 9
      font.weight: Font.Bold
      font.family: Config.fontSans
      font.letterSpacing: 1.8
    }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    text: root.secondary
    color: Config.textSubtle
    font.pixelSize: Config.fontSizeSmall
    font.weight: Font.Bold
    font.family: Config.fontMono
  }
}
