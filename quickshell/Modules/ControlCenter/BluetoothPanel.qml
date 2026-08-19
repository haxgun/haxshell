// BluetoothPanel.qml - BlueZ device selector
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../../Common"
import "../../Widgets"

Item {
  id: root

  property bool active: false
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var bluetoothDevices: adapter && adapter.devices && adapter.devices.values ? adapter.devices.values : []
  readonly property string connectedDeviceName: {
    for (let i = 0; i < bluetoothDevices.length; i++) {
      if (bluetoothDevices[i] && bluetoothDevices[i].connected) return bluetoothDevices[i].name || bluetoothDevices[i].deviceName
    }
    return ""
  }

  onActiveChanged: {
    if (active && root.adapter && root.adapter.enabled) root.adapter.discovering = true
  }

  function deviceName(device) {
    return device.name || device.deviceName || device.address || I18n.tr("bt.device")
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
    if (device.connected) return I18n.tr("bt.connected")
    if (device.state === BluetoothDeviceState.Connecting) return I18n.tr("bt.connecting")
    if (device.pairing) return I18n.tr("bt.pairing")
    if (device.paired || device.bonded) return I18n.tr("bt.paired")
    return I18n.tr("bt.available")
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

  Column {
    width: parent.width
    spacing: Config.scaledSize(12)

    Row {
      width: parent.width
      height: Config.scaledSize(28)
      spacing: Config.scaledSize(10)

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
        spacing: Config.scaledSize(1)

        Text {
          text: "Bluetooth"
          color: Config.textWhite
          font.pixelSize: Config.fontSizeMedium
          font.weight: Font.Medium
          font.family: Config.fontSans
        }

        Text {
          text: root.connectedDeviceName || (root.adapter && root.adapter.enabled ? I18n.tr("bt.notConnected") : I18n.tr("bt.off"))
          color: Config.textMuted
          font.pixelSize: Config.fontSizeSmall
          font.family: Config.fontSans
          elide: Text.ElideRight
          width: parent.width
        }
      }

      Rectangle {
        width: Config.scaledSize(28)
        height: Config.scaledSize(26)
        radius: Config.popupRadiusPx(8)
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
      text: I18n.tr("bt.adapterNotFound")
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
      spacing: Config.scaledSize(6)
      model: root.bluetoothDevices

      delegate: Rectangle {
        required property var modelData

        width: deviceList.width
        height: Config.scaledSize(46)
        radius: Config.cardRadius
        color: btDeviceMouse.containsMouse || modelData.connected ? Config.hoverBg : "#00000000"

        Row {
          anchors.fill: parent
          anchors.leftMargin: Config.scaledSize(12)
          anchors.rightMargin: Config.scaledSize(12)
          spacing: Config.scaledSize(10)

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
            spacing: Config.scaledSize(1)

            Text {
              text: root.deviceName(modelData)
              color: modelData.connected ? Config.textWhite : Config.textPrimary
              font.pixelSize: Config.fontSizeNormal
              font.weight: modelData.connected ? Font.Medium : Font.Medium
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
