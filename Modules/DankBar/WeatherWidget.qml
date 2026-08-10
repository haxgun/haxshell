// WeatherWidget.qml - Compact wttr.in weather pill for the status bar
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  property string weatherText: "--"
  property bool loading: false
  readonly property string weatherUrl: "https://wttr.in/" + encodeURIComponent(Config.weatherLocation) + "?format=%c+%t"

  visible: Config.weatherEnabled
  implicitWidth: weatherRow.implicitWidth + 12
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: weatherMouse.containsMouse ? Config.hoverBg : "#00000000"

  Process {
    id: weatherProc
    command: ["curl", "-fsS", "--max-time", "4", root.weatherUrl]
    running: Config.weatherEnabled

    stdout: SplitParser {
      onRead: data => {
        let text = data.trim()
        root.weatherText = text.length > 0 ? text : "--"
        root.loading = false
      }
    }

    onExited: root.loading = false
  }

  Timer {
    interval: Config.weatherRefreshIntervalMs
    running: Config.weatherEnabled
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    if (!Config.weatherEnabled) return
    root.loading = true
    weatherProc.running = false
    weatherProc.command = ["curl", "-fsS", "--max-time", "4", root.weatherUrl]
    weatherProc.running = true
  }

  Row {
    id: weatherRow
    anchors.centerIn: parent
    spacing: 5

    Text {
      text: root.loading ? Config.iconRefresh : Config.iconWeather
      color: Config.textMuted
      rotation: root.loading ? 360 : 0
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
      anchors.verticalCenter: parent.verticalCenter

      Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    Text {
      text: root.weatherText
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontSans
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: weatherMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.refresh()
  }
}
