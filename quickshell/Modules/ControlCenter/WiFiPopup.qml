// WiFiPopup.qml - NetworkManager Wi-Fi selector overlay
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import "../../Common"
import "../../Widgets"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: Config.scaledSize(16)
  property bool refreshActive: false
  property var pendingNetwork: null
  property string wifiPassword: ""

  readonly property var wifiDevice: {
    let list = Networking.devices && Networking.devices.values ? Networking.devices.values : []
    for (let i = 0; i < list.length; i++) {
      if (list[i] && list[i].type === DeviceType.Wifi) return list[i]
    }
    return null
  }

  readonly property var wifiNetworks: wifiDevice && wifiDevice.networks && wifiDevice.networks.values ? wifiDevice.networks.values : []
  readonly property var sortedNetworks: {
    let arr = wifiNetworks.slice()
    arr.sort((a, b) => (b.known ? 1 : 0) - (a.known ? 1 : 0))
    return arr
  }
  readonly property string connectedNetworkName: {
    for (let i = 0; i < wifiNetworks.length; i++) {
      if (wifiNetworks[i] && wifiNetworks[i].connected) return wifiNetworks[i].name
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
    target: "wifi"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  onIsOpenChanged: {
    if (isOpen) root.refreshNetworks()
  }

  Timer {
    id: wifiRefreshTimer
    interval: 1800
    repeat: false
    onTriggered: root.refreshActive = false
  }

  function signalPercent(network) {
    let value = network && typeof network.signalStrength !== "undefined" ? network.signalStrength : 0
    return Math.max(0, Math.min(100, Math.round(value <= 1 ? value * 100 : value)))
  }

  function refreshNetworks() {
    if (!root.wifiDevice) return
    root.refreshActive = true
    wifiRefreshTimer.restart()
    root.wifiDevice.scannerEnabled = false
    root.wifiDevice.scannerEnabled = true
  }

  function statusText(network) {
    if (network.connected) return I18n.tr("wifi.connected")
    if (network.state === ConnectionState.Connecting || network.stateChanging) return I18n.tr("wifi.connecting")
    return network.known ? I18n.tr("wifi.saved") : I18n.tr("wifi.available")
  }

  function secured(network) {
    return network && network.security !== WifiSecurityType.Open
  }

  function signalIcon(network) {
    let pct = signalPercent(network)
    if (pct >= 75) return Config.iconWifiConnected
    if (pct >= 50) return Config.iconWifiSignalHigh
    if (pct >= 25) return Config.iconWifiSignalMid
    return Config.iconWifiSignalLow
  }

  function signalColor(network) {
    let pct = signalPercent(network)
    if (network && network.connected) return Config.textWhite
    if (pct >= 50) return Config.textPrimary
    if (pct >= 25) return Config.warningAmber
    return Config.dangerRed
  }

  function connectNetwork(network) {
    if (!network) return
    if (network.connected) {
      network.disconnect()
      return
    }
    if (network.known || network.security === WifiSecurityType.Open) {
      network.connect()
      return
    }
    pendingNetwork = network
    wifiPassword = ""
  }

  function isPending(network) {
    return root.pendingNetwork && network && root.pendingNetwork.name === network.name
  }

  Rectangle {
    id: container
    width: Config.scaledSize(340)
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
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.scaledSize(12)

      Row {
        width: parent.width
        height: Config.scaledSize(28)
        spacing: Config.scaledSize(10)

        Text {
          text: Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected
          color: Networking.wifiEnabled ? Config.textWhite : Config.dangerRed
          font.pixelSize: Config.fontSizeTitle
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          width: parent.width - 126
          anchors.verticalCenter: parent.verticalCenter
          spacing: Config.scaledSize(1)

          Text {
            text: "Wi-Fi"
            color: Config.textWhite
            font.pixelSize: Config.fontSizeLarge
            font.weight: Font.Medium
            font.family: Config.fontSans
          }

          Text {
            text: root.connectedNetworkName || (Networking.wifiEnabled ? I18n.tr("wifi.notConnected") : I18n.tr("wifi.off"))
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
          color: wifiRefreshMouse.containsMouse ? Config.activeHoverBg : "#00000000"

          Text {
            id: wifiRefreshIcon
            anchors.centerIn: parent
            text: Config.iconRefresh
            color: Config.textPrimary
            font.pixelSize: Config.fontSizeIconMedium
            font.family: Config.fontIcon

            RotationAnimation on rotation {
              running: root.refreshActive
              from: 0
              to: 360
              duration: 700
              loops: Animation.Infinite
            }
          }

          MouseArea {
            id: wifiRefreshMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.refreshNetworks()
          }
        }

        ToggleSwitch {
          checked: Networking.wifiEnabled
          anchors.verticalCenter: parent.verticalCenter
          onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Config.separatorColor
      }

      Text {
        width: parent.width
        visible: !root.wifiDevice
        text: I18n.tr("wifi.adapterNotFound")
        color: Config.textMuted
        font.pixelSize: Config.fontSizeNormal
        font.family: Config.fontSans
        horizontalAlignment: Text.AlignHCenter
      }

      ListView {
        id: networkList
        width: parent.width
        height: Math.min(310, contentHeight)
        visible: !!root.wifiDevice
        clip: true
        spacing: Config.scaledSize(6)
        model: root.sortedNetworks

        section.property: "known"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
          width: networkList.width
          height: Config.scaledSize(26)
          color: "#00000000"

          Text {
            text: section === "true" ? I18n.tr("wifi.known") : I18n.tr("wifi.other")
            color: Config.textMuted
            font.pixelSize: Config.fontSizeExtraSmall
            font.weight: Font.Medium
            font.family: Config.fontSans
            font.letterSpacing: 1.2
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        delegate: Rectangle {
          required property var modelData
          readonly property bool passwordOpen: root.isPending(modelData)

          width: networkList.width
          height: passwordOpen ? 142 : 46
          radius: Config.cardRadius
          color: networkMouse.containsMouse || modelData.connected ? Config.hoverBg : "#00000000"
          clip: true

          Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          onPasswordOpenChanged: if (passwordOpen) focusPasswordTimer.restart()

          Timer {
            id: focusPasswordTimer
            interval: 120
            repeat: false
            onTriggered: inlinePasswordInput.forceActiveFocus()
          }

          Row {
            id: networkRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Config.scaledSize(46)
            anchors.leftMargin: Config.scaledSize(12)
            anchors.rightMargin: Config.scaledSize(12)
            spacing: Config.scaledSize(10)

            Text {
              text: root.signalIcon(modelData)
              color: root.signalColor(modelData)
              font.pixelSize: Config.fontSizeIconMedium
              font.family: Config.fontIcon
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              width: parent.width - 54
              anchors.verticalCenter: parent.verticalCenter
              spacing: Config.scaledSize(1)

              Text {
                text: modelData.name || I18n.tr("wifi.hidden")
                color: modelData.connected ? Config.textWhite : Config.textPrimary
                font.pixelSize: Config.fontSizeNormal
                font.weight: modelData.connected ? Font.Medium : Font.Medium
                font.family: Config.fontSans
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: root.statusText(modelData)
                color: Config.textMuted
                font.pixelSize: Config.fontSizeSmall
                font.family: Config.fontSans
              }
            }

            Text {
              width: 18
              text: root.secured(modelData) ? Config.iconLock : Config.iconUnlock
              color: root.secured(modelData) ? Config.textSubtle : Config.textMuted
              font.pixelSize: Config.fontSizeIconSmall
              font.family: Config.fontIcon
              horizontalAlignment: Text.AlignRight
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Column {
            id: passwordPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: networkRow.bottom
            anchors.leftMargin: Config.scaledSize(12)
            anchors.rightMargin: Config.scaledSize(12)
            spacing: Config.scaledSize(8)
            opacity: parent.passwordOpen ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45 }

            Text {
              width: parent.width
              text: I18n.tr("wifi.passwordFor") + (modelData.name || "сети")
              color: Config.textSubtle
              font.pixelSize: Config.fontSizeSmall
              font.family: Config.fontSans
              elide: Text.ElideRight
            }

            Rectangle {
              width: parent.width
              height: Config.scaledSize(34)
              radius: Config.popupRadiusPx(10)
              color: Config.searchBg
              border.color: inlinePasswordInput.activeFocus ? Config.activeBorderColor : Config.borderColor
              border.width: 1

              TextInput {
                id: inlinePasswordInput
                anchors.fill: parent
                anchors.leftMargin: Config.scaledSize(12)
                anchors.rightMargin: Config.scaledSize(12)
                verticalAlignment: TextInput.AlignVCenter
                text: root.wifiPassword
                echoMode: TextInput.Password
                color: Config.textPrimary
                selectedTextColor: Config.textWhite
                selectionColor: Config.selectedBg
                font.pixelSize: Config.fontSizeNormal
                font.family: Config.fontSans
                clip: true
                onTextChanged: if (passwordOpen) root.wifiPassword = text
                Keys.onReturnPressed: connectButton.clicked()
                Keys.onEscapePressed: root.pendingNetwork = null
              }
            }

            Row {
              width: parent.width
              spacing: Config.scaledSize(8)

              Rectangle {
                width: (parent.width - 8) / 2
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                color: cancelMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                border.color: Config.borderColor
                border.width: 1

                Text { anchors.centerIn: parent; text: I18n.tr("wifi.cancel"); color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pendingNetwork = null }
              }

              Rectangle {
                id: connectButton
                width: (parent.width - 8) / 2
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                color: connectMouse.containsMouse ? Config.activeHoverBg : Config.selectedBg
                border.color: Config.activeBorderColor
                border.width: 1

                signal clicked()
                onClicked: {
                  if (root.pendingNetwork) root.pendingNetwork.connectWithPsk(root.wifiPassword)
                  root.pendingNetwork = null
                }

                Text { anchors.centerIn: parent; text: I18n.tr("wifi.connect"); color: Config.textWhite; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
                MouseArea { id: connectMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: connectButton.clicked() }
              }
            }
          }

          MouseArea {
            id: networkMouse
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: networkRow.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.connectNetwork(modelData)
          }
        }
      }
    }
  }
}
