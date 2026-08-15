// BrightnessPopup.qml - Display Brightness Control Overlay
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property var osd: null
  property int brightnessPercent: 100
  property string activeBrightnessBus: Config.brightnessMonitorBus
  property int lastAppliedBrightness: -1
  property bool brightnessInitialized: false
  readonly property string veyctl: Config.veyctl

  visible: isOpen || container.opacity > 0.01

  // Wayland LayerShell Configuration
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  // Background dismiss handler
  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: {
      root.isOpen = false
    }
  }

  // IPC Handler
  IpcHandler {
    target: "brightness"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
    function set(val: string) {
      let v = Math.max(0, Math.min(100, parseInt(val) || 0))
      root.applyBrightness(v)
    }
  }

  // Fetch initial brightness via ddcutil
  Process {
    id: fetchBrightnessProc
    command: [root.veyctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: true

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
    running: true
    repeat: true
    onTriggered: {
      if (fetchBrightnessProc.running) return
      fetchBrightnessProc.command = [root.veyctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
      fetchBrightnessProc.running = true
    }
  }

  onBrightnessPercentChanged: {
    if (brightnessInitialized && osd) osd.showBrightness(brightnessPercent)
  }

  // Set brightness via ddcutil process
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
    setBrightnessProc.command = [root.veyctl, "brightness", "set", target.toString(), root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    setBrightnessProc.running = true
  }

  onIsOpenChanged: {
    if (isOpen) {
      fetchBrightnessProc.command = [root.veyctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
      fetchBrightnessProc.running = true
    }
  }

  // Floating Container Box
  Rectangle {
    id: container
    width: Config.brightnessWidth
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: root.rightMargin

    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    color: Config.popupGlassBg
    radius: Config.overlayRadius

    MouseArea {
      anchors.fill: parent
      onClicked: (mouse) => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.popupBorderColor
      border.width: Config.popupBordersEnabled ? 1 : 0
    }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14

      // Header Bar (Left: Icon & Title, Right: Percentage)
      Item {
        width: parent.width
        height: 24

        Row {
          spacing: 8
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
            text: "Яркость экрана"
            color: Config.textWhite
            font.pixelSize: Config.fontSizeLarge
            font.weight: Font.Bold
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
          font.weight: Font.Bold
          font.family: Config.fontMono
        }
      }

      // Slider Control Container
      Item {
        id: sliderBox
        width: parent.width
        height: 24

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
            color: Config.textPrimary
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

      // Quick Preset Pills Row (25%, 50%, 75%, 100%)
      Row {
        width: parent.width
        spacing: 8

        Repeater {
          model: [25, 50, 75, 100]

          Rectangle {
            id: presetBtn
            required property int modelData
            width: (columnLayout.width - 24) / 4
            height: 26
            radius: 7
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
              font.weight: presetBtn.isSelected ? Font.Bold : Font.Medium
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
}
