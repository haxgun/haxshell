// BatteryPopup.qml - UPower battery details and power profile switcher
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property int batteryPercent: 0
  property string batteryStatus: "Unknown"
  property bool batteryCharging: false
  property bool acOnline: false
  property double batteryRate: 0
  property int batteryCapacity: 0
  property double batteryTimeHours: 0
  property string powerProfile: "balanced"
  readonly property string qsctl: Qt.resolvedUrl("../../scripts/qsctl").toString().replace("file://", "")

  visible: isOpen || container.opacity > 0.01

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

  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: root.isOpen = false
  }

  IpcHandler {
    target: "battery"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  Process {
    id: batteryProc
    command: [root.qsctl, "battery"]
    running: true
    stdout: SplitParser { onRead: data => root.applyBatteryState(data) }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  onIsOpenChanged: if (isOpen) refresh()

  function refresh() {
    batteryProc.running = false
    batteryProc.command = [root.qsctl, "battery"]
    batteryProc.running = true
  }

  function setProfile(profile) {
    batteryProc.running = false
    batteryProc.command = [root.qsctl, "battery", "set-profile", profile]
    batteryProc.running = true
  }

  function applyBatteryState(data) {
    try {
      let res = JSON.parse(data)
      root.batteryPercent = res.percentage || 0
      root.batteryStatus = res.status || "Unknown"
      root.batteryCharging = !!res.charging
      root.acOnline = !!res.online
      root.batteryRate = res.rate || 0
      root.batteryCapacity = res.capacity || 0
      root.batteryTimeHours = res.timeHours || 0
      root.powerProfile = res.profile || "balanced"
    } catch(e) {}
  }

  function percent() {
    return root.batteryPercent
  }

  function stateText() {
    if (root.batteryCharging && root.batteryStatus === "Full") return "Полностью заряжена, подключена"
    if (root.batteryStatus === "Charging") return "Заряжается"
    if (root.batteryStatus === "Discharging") return "Разряжается"
    if (root.batteryStatus === "Full") return "Полностью заряжена"
    if (root.acOnline) return "Подключена к сети"
    return "Неизвестно"
  }

  function timeText() {
    if (!root.batteryTimeHours || root.batteryTimeHours <= 0) return "--"
    let hours = Math.floor(root.batteryTimeHours)
    let minutes = Math.round((root.batteryTimeHours - hours) * 60)
    return hours + "ч " + minutes + "м"
  }

  function profileName(profile) {
    if (profile === "power-saver") return "Экономия"
    if (profile === "performance") return "Производительность"
    return "Баланс"
  }

  function profileIcon(profile) {
    if (profile === "power-saver") return Config.iconPowerSaver
    if (profile === "performance") return Config.iconPerformance
    return Config.iconBalanced
  }

  function chargingIconColor() {
    if (root.batteryPercent < 50) return Config.textWhite
    return Config.isLightTheme ? "#ffffff" : "#020617"
  }

  Rectangle {
    id: container
    width: 320
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin

    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    color: Config.glassBg
    radius: Config.overlayRadius

    MouseArea {
      anchors.fill: parent
      onClicked: mouse => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.borderColor
      border.width: 1
    }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Row {
        width: parent.width
        height: 32
        spacing: 10

        Text {
          text: root.batteryCharging ? Config.iconBatteryCharging : Config.iconBattery
          color: root.batteryCharging ? root.chargingIconColor() : Config.textWhite
          font.pixelSize: Config.fontSizeTitle
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          width: parent.width - 44
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Text {
            text: "Батарея"
            color: Config.textWhite
            font.pixelSize: Config.fontSizeLarge
            font.weight: Font.Bold
            font.family: Config.fontSans
          }

          Text {
            text: root.stateText()
            color: Config.textMuted
            font.pixelSize: Config.fontSizeSmall
            font.family: Config.fontSans
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: Config.separatorColor }

      Rectangle {
        width: parent.width
        height: 52
        radius: Config.cardRadius
        color: "#151A1A1A"
        border.color: Config.borderColor
        border.width: 1

        Column {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 8

          Row {
            width: parent.width
            Text {
              width: parent.width / 2
              text: root.batteryCharging ? "Заряд" : "Остаток"
              color: Config.textMuted
              font.pixelSize: 10
              font.weight: Font.Bold
              font.family: Config.fontSans
              font.letterSpacing: 1.2
            }
            Text {
              width: parent.width / 2
              text: root.percent() + "%"
              color: Config.textWhite
              horizontalAlignment: Text.AlignRight
              font.pixelSize: Config.fontSizeSmall
              font.weight: Font.Bold
              font.family: Config.fontMono
            }
          }

          Rectangle {
            width: parent.width
            height: 10
            radius: height / 2
            color: Config.isLightTheme ? "#3094a3b8" : "#30464646"
            clip: true

            Rectangle {
              width: Math.max(parent.height, Math.round(parent.width * root.percent() / 100))
              height: parent.height
              radius: parent.radius
              color: root.percent() <= 20 ? Config.dangerRed : (root.percent() <= 45 ? Config.warningAmber : Config.activeBorderColor)

              Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
          }
        }
      }

      Grid {
        width: parent.width
        columns: 2
        rowSpacing: 8
        columnSpacing: 10

        BatteryInfoRow { label: "Осталось"; value: root.timeText(); width: (parent.width - 10) / 2 }
        BatteryInfoRow { label: "RATE"; value: root.batteryRate.toFixed(2) + " W"; width: (parent.width - 10) / 2 }
        BatteryInfoRow { label: "CAPACITY"; value: root.batteryCapacity + "%"; width: (parent.width - 10) / 2 }
        BatteryInfoRow { label: "STATUS"; value: root.acOnline ? "AC" : "BAT"; width: (parent.width - 10) / 2 }
      }

      Text {
        text: "Профиль питания"
        color: Config.textSubtle
        font.pixelSize: Config.fontSizeSmall
        font.weight: Font.Bold
        font.family: Config.fontSans
      }

      Row {
        width: parent.width
        spacing: 10

        Repeater {
          model: ["power-saver", "balanced", "performance"]

          Rectangle {
            required property string modelData
            readonly property bool available: true
            readonly property bool active: root.powerProfile === modelData

            width: (parent.width - 20) / 3
            height: 42
            radius: Config.cardRadius
            opacity: available ? 1.0 : 0.35
            color: active ? Config.selectedBg : (profileMouse.containsMouse && available ? Config.hoverBg : "#151A1A1A")
            border.color: active ? Config.activeBorderColor : "#30464646"
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: 1

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.profileIcon(modelData)
                color: active ? Config.textWhite : Config.textSubtle
                font.pixelSize: Config.fontSizeIconLarge
                font.family: Config.fontIcon
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.profileName(modelData)
                color: active ? Config.textWhite : Config.textMuted
                font.pixelSize: 9
                font.weight: active ? Font.Bold : Font.Medium
                font.family: Config.fontSans
              }
            }

            MouseArea {
              id: profileMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: parent.available ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: if (parent.available) root.setProfile(parent.modelData)
            }
          }
        }
      }
    }
  }
}
