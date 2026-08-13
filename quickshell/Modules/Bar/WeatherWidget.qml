// WeatherWidget.qml - Compact cached Open-Meteo weather pill for the status bar
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  property string weatherText: "--"
  visible: Config.weatherEnabled
  implicitWidth: weatherRow.implicitWidth + 12
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: weatherMouse.containsMouse ? Config.hoverBg : "#00000000"

  Process {
    id: weatherProc
    command: [Config.hushctl, "weather"]
    running: Config.weatherEnabled

    stdout: SplitParser {
      onRead: data => {
        try {
          let weather = JSON.parse(data)
          root.weatherText = weather.ok ? (Math.round(weather.temperature) + "°") : "--"
        } catch(e) { root.weatherText = "--" }
      }
    }
  }

  Timer {
    interval: Config.weatherRefreshIntervalMs
    running: Config.weatherEnabled
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    if (!Config.weatherEnabled) return
    weatherProc.running = false
    weatherProc.command = [Config.hushctl, "weather"]
    weatherProc.running = true
  }

  Row {
    id: weatherRow
    anchors.centerIn: parent
    spacing: 5

    Text {
      text: Config.iconWeather
      color: Config.textMuted
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
      anchors.verticalCenter: parent.verticalCenter
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

  MouseArea { id: weatherMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
}
