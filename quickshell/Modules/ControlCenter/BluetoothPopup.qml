// BluetoothPopup.qml - BlueZ device selector overlay
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import "../../Common"
import "../../Widgets"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var bluetoothDevices: adapter && adapter.devices && adapter.devices.values ? adapter.devices.values : []
  readonly property string connectedDeviceName: {
    for (let i = 0; i < bluetoothDevices.length; i++) {
      if (bluetoothDevices[i] && bluetoothDevices[i].connected) return bluetoothDevices[i].name || bluetoothDevices[i].deviceName
    }
    return ""
  }

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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: root.isOpen = false
  }

  IpcHandler {
    target: "bluetooth"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  onIsOpenChanged: {
    if (isOpen && root.adapter && root.adapter.enabled) root.adapter.discovering = true
  }

  function deviceName(device) {
    return device.name || device.deviceName || device.address || "Bluetooth устройство"
  }

  function deviceIcon(device) {
    if (!device || !device.icon) return Config.iconBluetooth
    let icon = device.icon.toLowerCase()
    if (icon.indexOf("head") !== -1) return Config.iconHeadphones
    if (icon.indexOf("speaker") !== -1) return Config.iconSpeaker
    return Config.iconBluetooth
  }

  function toggleScanning() {
    if (!root.adapter) return
    root.adapter.discovering = !root.adapter.discovering
  }

  function deviceStatus(device) {
    if (device.connected) return "Подключено"
    if (device.state === BluetoothDeviceState.Connecting) return "Подключение..."
    if (device.pairing) return "Сопряжение..."
    if (device.paired || device.bonded) return "Сопряжено"
    return "Доступно"
  }

  function toggleDevice(device) {
    if (!device) return
    if (device.connected) {
      device.disconnect()
    } else if (device.paired || device.bonded || device.trusted) {
      device.connect()
    } else {
      device.trusted = true
      device.pair()
    }
  }

  Rectangle {
    id: container
    width: 340
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
      onClicked: mouse => { mouse.accepted = true }
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
      spacing: 12

      Row {
        width: parent.width
        height: 28
        spacing: 10

        Text {
          text: Config.iconBluetooth
          color: root.adapter && root.adapter.enabled ? Config.textWhite : Config.dangerRed
          font.pixelSize: Config.fontSizeTitle
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          width: parent.width - 126
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Text {
            text: "Bluetooth"
            color: Config.textWhite
            font.pixelSize: Config.fontSizeMedium
            font.weight: Font.Bold
            font.family: Config.fontSans
          }

          Text {
            text: root.connectedDeviceName || (root.adapter && root.adapter.enabled ? "Не подключено" : "Выключено")
            color: Config.textMuted
            font.pixelSize: Config.fontSizeSmall
            font.family: Config.fontSans
            elide: Text.ElideRight
            width: parent.width
          }
        }

        Rectangle {
          width: 28
          height: 26
          radius: 8
          color: btRefreshMouse.containsMouse ? Config.activeHoverBg : (root.adapter && root.adapter.discovering ? Config.selectedBg : "#00000000")
          border.color: root.adapter && root.adapter.discovering ? Config.activeBorderColor : "#00000000"
          border.width: 1

          Text {
            id: btRefreshIcon
            anchors.centerIn: parent
            text: Config.iconRefresh
            color: root.adapter && root.adapter.discovering ? Config.textWhite : Config.textPrimary
            font.pixelSize: Config.fontSizeIconMedium
            font.family: Config.fontIcon

            RotationAnimation on rotation {
              running: root.adapter && root.adapter.discovering
              from: 0
              to: 360
              duration: 700
              loops: Animation.Infinite
            }
          }

          MouseArea {
            id: btRefreshMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleScanning()
          }
        }

        ToggleSwitch {
          checked: root.adapter && root.adapter.enabled
          anchors.verticalCenter: parent.verticalCenter
          onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Config.separatorColor
      }

      Text {
        width: parent.width
        visible: !root.adapter
        text: "Bluetooth адаптер не найден"
        color: Config.textMuted
        font.pixelSize: Config.fontSizeNormal
        font.family: Config.fontSans
        horizontalAlignment: Text.AlignHCenter
      }

      ListView {
        id: deviceList
        width: parent.width
        height: Math.min(250, contentHeight)
        visible: !!root.adapter
        clip: true
        spacing: 6
        model: root.bluetoothDevices

        delegate: Rectangle {
          required property var modelData

          width: deviceList.width
          height: 46
          radius: Config.cardRadius
          color: btDeviceMouse.containsMouse || modelData.connected ? Config.hoverBg : "#00000000"

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: root.deviceIcon(modelData)
              color: modelData.connected ? Config.textWhite : Config.textMuted
              font.pixelSize: Config.fontSizeIconMedium
              font.family: Config.fontIcon
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              width: parent.width - 40
              anchors.verticalCenter: parent.verticalCenter
              spacing: 1

              Text {
                text: root.deviceName(modelData)
                color: modelData.connected ? Config.textWhite : Config.textPrimary
                font.pixelSize: Config.fontSizeNormal
                font.weight: modelData.connected ? Font.Bold : Font.Medium
                font.family: Config.fontSans
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: root.deviceStatus(modelData)
                color: Config.textMuted
                font.pixelSize: Config.fontSizeSmall
                font.family: Config.fontSans
              }
            }
          }

          MouseArea {
            id: btDeviceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleDevice(modelData)
          }
        }
      }
    }
  }
}
