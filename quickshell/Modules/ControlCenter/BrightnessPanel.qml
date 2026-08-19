// BrightnessPanel.qml - Display brightness control
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Item {
  id: root
  implicitHeight: panelContent.implicitHeight

  property bool active: false
  property var osd: null
  property int brightnessPercent: 100
  property string activeBrightnessBus: Config.brightnessMonitorBus
  property int lastAppliedBrightness: -1
  property bool brightnessInitialized: false
  readonly property string natonctl: Config.natonctl

  Process {
    id: fetchBrightnessProc
    command: [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: root.active

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (res.ok && typeof res.brightness !== "undefined") root.brightnessPercent = res.brightness
          if (res.ok && res.bus) root.activeBrightnessBus = res.bus.toString()
          if (res.ok && res.device) root.activeBrightnessBus = res.device.toString()
          if (res.ok) root.brightnessInitialized = true
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 250
    running: root.active
    repeat: true
    onTriggered: {
      if (fetchBrightnessProc.running) return
      fetchBrightnessProc.command = [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
      fetchBrightnessProc.running = true
    }
  }

  onBrightnessPercentChanged: {
    if (brightnessInitialized && osd) osd.showBrightness(brightnessPercent)
  }

  Process {
    id: setBrightnessProc

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (res.ok && typeof res.brightness !== "undefined") root.brightnessPercent = res.brightness
          if (res.ok && res.bus) root.activeBrightnessBus = res.bus.toString()
          if (res.ok && res.device) root.activeBrightnessBus = res.device.toString()
        } catch(e) {}
      }
    }
  }

  function applyBrightness(val) {
    let target = Math.max(0, Math.min(100, Math.round(val)))
    if (target === root.lastAppliedBrightness && setBrightnessProc.running) return
    root.lastAppliedBrightness = target
    if (root.osd) root.osd.suppressOnce()
    root.brightnessPercent = target
    setBrightnessProc.running = false
    setBrightnessProc.command = [root.natonctl, "brightness", "set", target.toString(), root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    setBrightnessProc.running = true
  }

  onActiveChanged: {
    if (active) {
      fetchBrightnessProc.command = [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
      fetchBrightnessProc.running = true
    }
  }

  Column {
    id: panelContent
    width: parent.width
    spacing: Config.scaledSize(14)

    Item {
      width: parent.width
      height: Config.scaledSize(24)

      Row {
        spacing: Config.scaledSize(8)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: root.brightnessPercent >= 75 ? Config.iconBrightHigh : (root.brightnessPercent >= 35 ? Config.iconBrightMedium : (root.brightnessPercent > 0 ? Config.iconBrightLow : Config.iconBrightOff))
          color: Config.textPrimary
          font.pixelSize: Config.fontSizeTitle
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: I18n.tr("brightness.title")
          color: Config.textWhite
          font.pixelSize: Config.fontSizeLarge
          font.weight: Font.Medium
          font.family: Config.fontSans
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.brightnessPercent + "%"
        color: Config.textMuted
        font.pixelSize: Config.fontMonoSizeMedium
        font.weight: Font.Medium
        font.family: Config.fontMono
      }
    }

    Item {
      id: sliderBox
      width: parent.width
      height: Config.scaledSize(24)

      Rectangle {
        id: track
        width: parent.width
        height: 6
        radius: 3
        color: Config.searchBg
        border.color: Config.subtleBorder
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          height: parent.height
          radius: 3
          width: Math.min(parent.width, Math.max(0, parent.width * (sliderArea.tempValue / 100.0)))
          color: Config.themeAccent
        }
      }

      MouseArea {
        id: sliderArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property int tempValue: root.brightnessPercent

        Connections {
          target: root
          function onBrightnessPercentChanged() {
            if (!sliderArea.pressed) {
              sliderArea.tempValue = root.brightnessPercent
            }
          }
        }

        function updateTemp(mouse) {
          let posX = Math.max(0, Math.min(width, mouse.x))
          let pct = Math.round((posX / width) * 100)
          tempValue = pct
          root.applyBrightness(pct)
        }

        onPressed: (mouse) => {
          updateTemp(mouse)
        }

        onPositionChanged: (mouse) => {
          if (pressed) {
            updateTemp(mouse)
          }
        }

        onReleased: (mouse) => {
          updateTemp(mouse)
        }
      }
    }

    Row {
      width: parent.width
      spacing: Config.scaledSize(8)

      Repeater {
        model: [25, 50, 75, 100]

        Rectangle {
          id: presetBtn
          required property int modelData
          width: (parent.width - 24) / 4
          height: Config.scaledSize(26)
          radius: Config.popupRadiusPx(7)
          readonly property bool isSelected: root.brightnessPercent === modelData
          color: isSelected ? Config.selectedBg : (presetMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
          border.color: isSelected ? Config.activeBorderColor : Config.subtleBorder
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: presetBtn.modelData + "%"
            color: presetBtn.isSelected ? Config.textWhite : Config.textSubtle
            font.pixelSize: Config.fontMonoSizeSmall
            font.weight: presetBtn.isSelected ? Font.Medium : Font.Medium
            font.family: Config.fontMono
          }

          MouseArea {
            id: presetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.applyBrightness(presetBtn.modelData)
            }
          }
        }
      }
    }
  }
}
