// WeatherWidget.qml - Compact cached Open-Meteo weather pill for the status bar
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  property string weatherText: "--"
  property int weatherCode: -1
  property bool embedded: false
  property bool iconOnRight: false
  visible: Config.weatherEnabled
  implicitWidth: weatherRow.implicitWidth + (embedded ? 0 : 12)
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: embedded ? "#00000000" : (weatherMouse.containsMouse ? Config.hoverBg : "#00000000")

  Process {
    id: weatherProc
    command: [Config.veyctl, "weather"]
    running: Config.weatherEnabled

    stdout: SplitParser {
      onRead: data => {
        try {
          let weather = JSON.parse(data)
          root.weatherText = weather.ok ? (Math.round(weather.temperature) + "°") : "--"
          root.weatherCode = weather.ok ? weather.code : -1
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

  Connections {
    target: Config
    function onWeatherLocationChanged() { root.refresh() }
  }

  function refresh() {
    if (!Config.weatherEnabled) return
    weatherProc.running = false
    weatherProc.command = [Config.veyctl, "weather"]
    weatherProc.running = true
  }

  function weatherIcon(code) {
    if (code === 0) return "󰖙"
    if (code === 1 || code === 2) return "󰖕"
    if (code === 3) return "󰖐"
    if (code === 45 || code === 48) return "󰖑"
    if (code >= 51 && code <= 57) return "󰖗"
    if (code >= 61 && code <= 67) return "󰖖"
    if (code >= 71 && code <= 77) return "󰖘"
    if (code >= 80 && code <= 82) return "󰖖"
    if (code >= 95) return "󰖓"
    return Config.iconWeather
  }

  Row {
    id: weatherRow
    anchors.centerIn: parent
    spacing: Config.scaledSize(5)

    Item {
      visible: !root.iconOnRight
      width: weatherIconLeft.implicitWidth
      height: Config.scaledSize(20)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: weatherIconLeft
        anchors.centerIn: parent
        text: root.weatherIcon(root.weatherCode)
        color: Config.iconColor
        font.pixelSize: Config.fontSizeIconSmall
        font.family: Config.fontIcon
      }
    }

    Text {
      height: Config.scaledSize(20)
      text: root.weatherText
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontSans
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      visible: root.iconOnRight
      width: weatherIconRight.implicitWidth
      height: Config.scaledSize(20)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: weatherIconRight
        anchors.centerIn: parent
        text: root.weatherIcon(root.weatherCode)
        color: Config.iconColor
        font.pixelSize: Config.fontSizeIconSmall
        font.family: Config.fontIcon
      }
    }
  }

  MouseArea { id: weatherMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
}
