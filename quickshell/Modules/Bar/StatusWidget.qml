// StatusWidget.qml - System Monitor, Audio, Connectivity & Power Controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import "."
import "../../Common"
import "../../Widgets"

Rectangle {
  id: root

  implicitWidth: root.vertical ? Config.buttonWidth + 12 : rowLayout.implicitWidth + 24
  implicitHeight: root.vertical ? rowLayout.implicitHeight + 12 : Config.barHeight
  property bool embeddedInBar: false
  property bool vertical: false
  property var tooltip: null

  // Frosted Glass Tint & Border
  color: embeddedInBar ? "#00000000" : Config.glassBg
  radius: Config.widgetRadius

  Rectangle {
    anchors.fill: parent
    visible: !root.embeddedInBar
    anchors.margins: Config.innerBorderMargin
    radius: Config.innerBorderRadius
    color: "#00000000"
    border.color: Config.borderColor
    border.width: 1
  }

  // Target BrightnessPopup reference to toggle
  property var calendarPopup: null
  property var controlCenterPopup: null
  property var brightnessPopup: null
  property var wifiPopup: null
  property var bluetoothPopup: null
  property var audioPopup: null
  property var batteryPopup: null
  property var notificationPopup: null
  property var trayMenuPopup: null
  property var keyboardLayoutPopup: null
  property var settingsPopup: null
  property var powerPopup: null
  property var systemPopup: null
  property var mediaPopup: null
  property var osd: null
  readonly property int brightnessPercent: brightnessPopup ? brightnessPopup.brightnessPercent : 100
  readonly property int iconButtonPadding: 7
  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool bluetoothEnabled: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled

  function closeFlyouts(exceptName) {
    if (exceptName !== "controlCenter" && root.controlCenterPopup) root.controlCenterPopup.isOpen = false
    if (exceptName !== "audio" && root.audioPopup) root.audioPopup.isOpen = false
    if (exceptName !== "brightness" && root.brightnessPopup) root.brightnessPopup.isOpen = false
    if (exceptName !== "bluetooth" && root.bluetoothPopup) root.bluetoothPopup.isOpen = false
    if (exceptName !== "wifi" && root.wifiPopup) root.wifiPopup.isOpen = false
    if (exceptName !== "battery" && root.batteryPopup) root.batteryPopup.isOpen = false
    if (exceptName !== "notifications" && root.notificationPopup) root.notificationPopup.isOpen = false
    if (exceptName !== "trayMenu" && root.trayMenuPopup) root.trayMenuPopup.isOpen = false
    if (exceptName !== "keyboard" && root.keyboardLayoutPopup) root.keyboardLayoutPopup.isOpen = false
    if (exceptName !== "settings" && root.settingsPopup) root.settingsPopup.isOpen = false
    if (exceptName !== "calendar" && root.calendarPopup) root.calendarPopup.isOpen = false
    if (exceptName !== "power" && root.powerPopup) root.powerPopup.isOpen = false
    if (exceptName !== "system" && root.systemPopup) root.systemPopup.isOpen = false
    if (exceptName !== "media" && root.mediaPopup) root.mediaPopup.isOpen = false
  }

  function positionPopupFor(name, item, popup) {
    if (!item || !popup) return
    if (name !== "system") {
      popup.rightMargin = 16
      return
    }
    popup.rightMargin = Math.max(16, Math.round(root.width - (rowLayout.x + item.x + item.width) + Config.barMargin))
  }

  function openControlCenter(section, item) {
    if (!root.controlCenterPopup) return false
    let sameSection = root.controlCenterPopup.isOpen && root.controlCenterPopup.activeSection === section
    positionPopupFor("controlCenter", item, root.controlCenterPopup)
    closeFlyouts("controlCenter")
    root.controlCenterPopup.activeSection = section
    root.controlCenterPopup.isOpen = !sameSection
    return true
  }

  function toggleAnchoredFlyout(name, popup, item) {
    positionPopupFor(name, item, popup)
    return toggleFlyout(name, popup)
  }

  function toggleFlyout(name, popup) {
    if (!popup) return false
    let shouldOpen = !popup.isOpen
    closeFlyouts(name)
    popup.isOpen = shouldOpen
    return true
  }

  // Brightness scroll wheel debounce timer
  Timer {
    id: brightnessDebounceTimer
    interval: 350
    repeat: false
    onTriggered: {
      if (root.brightnessPopup) {
        root.brightnessPopup.applyBrightness(root.brightnessPercent)
      }
    }
  }

  // Keep the default output bound so the indicator and OSD update together.
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
  readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
  property bool audioReady: false

  // Dynamic Network connection states
  property bool wifiConnected: false
  property bool ethConnected: false
  property bool netConnecting: false
  property bool vpnConnected: false

  // System Resources state properties
  property int sysCpuPercent: 0
  property int sysCpuTemp: 0
  property double sysLoad1: 0.0
  property string sysUptime: "0м"
  property double sysRamUsedGb: 0.0
  property double sysRamTotalGb: 0.0
  property int sysRamPercent: 0

  property string sysNetRx: "0B/s"
  property string sysNetTx: "0B/s"

  property bool sysRootDiskExists: false
  property double sysRootUsedGb: 0.0
  property double sysRootTotalGb: 0.0
  property int sysRootPercent: 0

  property bool sysStorageDiskExists: false
  property double sysStorageUsedGb: 0.0
  property double sysStorageTotalGb: 0.0
  property int sysStoragePercent: 0

  function batteryColor(percent) {
    if (percent <= 20) return Config.dangerRed
    return Config.textPrimary
  }

  function chargingIconColor(percent) {
    if (percent < 50) return Config.textWhite
    return Config.isLightTheme ? "#ffffff" : "#020617"
  }

  // Execute external system monitor python script
  Process {
    id: fetchSysProc
    command: [Config.veyctl, "sys"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (typeof res.cpu !== "undefined") root.sysCpuPercent = res.cpu
          if (typeof res.cpu_temp !== "undefined") root.sysCpuTemp = res.cpu_temp
          if (typeof res.load1 !== "undefined") root.sysLoad1 = res.load1
          if (res.uptime) root.sysUptime = res.uptime
          if (typeof res.ram_pct !== "undefined") {
            root.sysRamUsedGb = res.ram_used
            root.sysRamTotalGb = res.ram_total
            root.sysRamPercent = res.ram_pct
          }
          if (res.net_rx) root.sysNetRx = res.net_rx
          if (res.net_tx) root.sysNetTx = res.net_tx
          if (res.root_disk && res.root_disk.exists) {
            root.sysRootDiskExists = true
            root.sysRootUsedGb = res.root_disk.used_gb
            root.sysRootTotalGb = res.root_disk.total_gb
            root.sysRootPercent = res.root_disk.percent
          }
          if (res.storage_disk && res.storage_disk.exists) {
            root.sysStorageDiskExists = true
            root.sysStorageUsedGb = res.storage_disk.used_gb
            root.sysStorageTotalGb = res.storage_disk.total_gb
            root.sysStoragePercent = res.storage_disk.percent
          }
        } catch(e) {}
      }
    }
  }

  // Periodic System Resource Query Timer
  Timer {
    interval: Config.sysCheckIntervalMs
    running: true
    repeat: true
    onTriggered: if (!fetchSysProc.running) fetchSysProc.running = true
  }

  SystemClock {
    id: statusClock
    precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }

  // Execute external network monitor python script
  Process {
    id: fetchNetProc
    command: [Config.veyctl, "net"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          root.wifiConnected = !!res.wifi
          root.ethConnected = !!res.eth
          root.netConnecting = !!res.connecting
        } catch(e) {}
      }
    }
  }

  Process {
    id: fetchVpnProc
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE connection show --active 2>/dev/null | grep -Eq '^(vpn|tun|wireguard|ip-tunnel):activated$' && echo yes || echo no"]
    running: true

    stdout: SplitParser {
      onRead: data => root.vpnConnected = data.trim() === "yes"
    }
  }

  // Monitor NetworkManager events for real-time status updates
  Process {
    id: nmMonitorProc
    command: ["nmcli", "monitor"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        if (!fetchNetProc.running) fetchNetProc.running = true
        if (!fetchVpnProc.running) fetchVpnProc.running = true
      }
    }
  }

  // Periodic Network Status Query Timer
  Timer {
    interval: Config.netCheckIntervalMs
    running: true
    repeat: true
    onTriggered: {
      if (!fetchNetProc.running) fetchNetProc.running = true
      if (!fetchVpnProc.running) fetchVpnProc.running = true
    }
  }

  // Auto-hide timer for inline volume display
  property bool showVolumeText: false

  Timer {
    id: hideVolumeTimer
    interval: 2500
    repeat: false
    onTriggered: {
      if (!volMouse.containsMouse) {
        showVolumeText = false
      }
    }
  }

  Timer {
    id: audioReadyTimer
    interval: 1000
    repeat: false
    onTriggered: root.audioReady = true
  }

  function showAudioOsd() {
    showVolumeText = true
    hideVolumeTimer.restart()
    if (osd) osd.showVolume(volumePercent, isMuted)
  }

  Connections {
    target: root
    function onSinkChanged() {
      root.audioReady = false
      audioReadyTimer.restart()
    }
  }

  Connections {
    target: root.sink && root.sink.audio ? root.sink.audio : null
    function onVolumeChanged() {
      if (root.audioReady) root.showAudioOsd()
      else audioReadyTimer.restart()
    }
    function onMutedChanged() {
      if (root.audioReady) root.showAudioOsd()
      else audioReadyTimer.restart()
    }
  }

  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(node => node && node.audio && !node.isStream)
  }

  Component.onCompleted: audioReadyTimer.restart()

  // Command Processes for interactable buttons
  Process {
    id: volumeProc
    command: ["setsid", "-f", Config.cmdVolumeControl]
  }

  Process {
    id: bluetoothProc
    command: ["setsid", "-f", Config.cmdBluetoothControl]
  }

  Process {
    id: networkProc
    command: ["setsid", "-f", Config.cmdNetworkControl]
  }

  Process {
    id: pickerProc
    command: ["hyprpicker", "-a"]
  }

  Grid {
    id: rowLayout
    anchors.centerIn: parent
    spacing: 5
    rows: root.vertical ? 0 : 1
    columns: root.vertical ? 1 : 0
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter

    MediaWidget {
      mediaPopup: root.mediaPopup
      closeFlyouts: root.closeFlyouts
      tooltip: root.tooltip
    }

    TrayWidget {
      trayMenuPopup: root.trayMenuPopup
      closeFlyouts: root.closeFlyouts
      tooltip: root.tooltip
    }

    KeyboardLayoutWidget {
      keyboardLayoutPopup: root.keyboardLayoutPopup
      closeFlyouts: root.closeFlyouts
      tooltip: root.tooltip
      visible: Config.barKeyboardLayoutEnabled
    }

    // Expandable System Resources Pill (CPU, RAM, Net Speed, Disks)
    Rectangle {
      id: sysContainer
      visible: Config.barSystemEnabled
      height: Config.buttonHeight
      implicitWidth: root.vertical ? Config.buttonWidth : sysRow.implicitWidth + 12
      radius: Config.buttonRadius
      clip: true
      readonly property bool isSystemActive: root.systemPopup && root.systemPopup.isOpen
      color: (isSystemActive || sysMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

      Text {
        anchors.centerIn: parent
        visible: root.vertical
        text: Config.iconCpu
        color: (sysContainer.isSystemActive || sysMouse.containsMouse) ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      Row {
        id: sysRow
        anchors.centerIn: parent
        spacing: 6
        visible: !root.vertical

        // CONDENSED VIEW: CPU, RAM, and network in one segmented surface.
        Rectangle {
          id: condensedRow
          width: condensedMetrics.implicitWidth + 16
          height: 24
          radius: 8
          color: Config.controlIdleBg
          border.color: Config.borderColor
          border.width: Config.shellBordersEnabled ? 1 : 0
          visible: true
          anchors.verticalCenter: parent.verticalCenter

          Row {
            id: condensedMetrics
            anchors.centerIn: parent
            spacing: 8

            Row {
              spacing: 4
              Text { text: Config.iconCpu; color: root.sysCpuPercent > 85 ? Config.dangerRed : (root.sysCpuPercent > 70 ? Config.warningAmber : Config.iconColor); font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
              Text { text: root.sysCpuPercent + "%"; color: Config.textPrimary; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle { width: 1; height: 14; color: Config.separatorColor; anchors.verticalCenter: parent.verticalCenter }
            Row {
              spacing: 4
              Text { text: Config.iconRam; color: root.sysRamPercent > 85 ? Config.dangerRed : (root.sysRamPercent > 70 ? Config.warningAmber : Config.iconColor); font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
              Text { text: root.sysRamUsedGb.toFixed(1) + "G"; color: Config.textPrimary; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle { width: 1; height: 14; color: Config.separatorColor; anchors.verticalCenter: parent.verticalCenter }
            Row {
              spacing: 4
              Text { text: Config.iconNet; color: Config.iconColor; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
              Text { text: root.sysNetRx.trim(); color: Config.textPrimary; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; anchors.verticalCenter: parent.verticalCenter }
            }
          }
        }

        // EXPANDED VIEW: Detailed metrics
        Row {
          id: expandedRow
          spacing: 6
          visible: false
          anchors.verticalCenter: parent.verticalCenter

          SysMetricPill { icon: Config.iconCpu; value: root.sysCpuPercent + "%"; cardWidth: 52; accent: root.sysCpuPercent > 85 ? Config.dangerRed : (root.sysCpuPercent > 70 ? Config.warningAmber : Config.iconColor); anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { icon: "󰔏"; value: root.sysCpuTemp > 0 ? (root.sysCpuTemp + "C") : "--C"; cardWidth: 58; accent: root.sysCpuTemp > 85 ? Config.dangerRed : (root.sysCpuTemp > 70 ? Config.warningAmber : Config.iconColor); anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { icon: "󰓅"; value: root.sysLoad1.toFixed(2); cardWidth: 58; accent: Config.iconColor; anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { icon: "󰅐"; value: root.sysUptime; cardWidth: 70; accent: Config.iconColor; anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { icon: Config.iconRam; value: root.sysRamUsedGb + "/" + root.sysRamTotalGb + "Г"; cardWidth: 98; accent: root.sysRamPercent > 85 ? Config.dangerRed : (root.sysRamPercent > 70 ? Config.warningAmber : Config.iconColor); anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { icon: Config.iconNet; value: "↓" + root.sysNetRx.trim() + " ↑" + root.sysNetTx.trim(); cardWidth: 118; accent: Config.iconColor; anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { visible: root.sysRootDiskExists; icon: Config.iconDisk; value: "/ " + root.sysRootPercent + "%"; cardWidth: 58; accent: root.sysRootPercent > 85 ? Config.dangerRed : Config.iconColor; anchors.verticalCenter: parent.verticalCenter }
          SysMetricPill { visible: root.sysStorageDiskExists; icon: Config.iconDisk; value: "/mnt " + root.sysStoragePercent + "%"; cardWidth: 76; accent: root.sysStoragePercent > 85 ? Config.dangerRed : Config.iconColor; anchors.verticalCenter: parent.verticalCenter }
        }
      }

      MouseArea {
        id: sysMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(sysContainer, I18n.tr("Мониторинг системы"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: root.toggleAnchoredFlyout("system", root.systemPopup, sysContainer)
      }
    }

    // Partition: System Resources | Status Controls
    Item {
      width: 8
      visible: false
      height: 16

      Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 16
        color: Config.separatorColor
      }
    }

    // Notification Center Button
    Rectangle {
      id: notificationContainer
      visible: Config.barNotificationsEnabled
      height: Config.buttonHeight
      width: Config.buttonWidth
      radius: Config.buttonRadius
      readonly property bool isNotificationActive: (root.notificationPopup && root.notificationPopup.isOpen)
      readonly property int notificationCount: root.notificationPopup ? root.notificationPopup.notificationCount : 0
      color: (isNotificationActive || notificationMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text: notificationContainer.notificationCount > 0 ? Config.iconNotificationsActive : Config.iconNotifications
        color: (notificationContainer.isNotificationActive || notificationMouse.containsMouse) ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      Rectangle {
        width: 9
        height: 9
        radius: height / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 4
        visible: notificationContainer.notificationCount > 0
        color: Config.dangerRed
        border.color: Config.textPrimary
        border.width: 1
      }

      MouseArea {
        id: notificationMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(notificationContainer, I18n.tr("Уведомления"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: root.toggleAnchoredFlyout("notifications", root.notificationPopup, notificationContainer)
      }
    }

    // Volume Control Button
    Rectangle {
      id: volContainer
      visible: Config.barVolumeEnabled
      height: Config.buttonHeight
      implicitWidth: root.vertical ? Config.buttonWidth : volRow.implicitWidth + 12
      radius: Config.buttonRadius
      readonly property bool isAudioActive: (root.audioPopup && root.audioPopup.isOpen)
      color: (isAudioActive || volMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

      Row {
        id: volRow
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: root.isMuted ? Config.iconVolMuted : (root.volumePercent >= 70 ? Config.iconVolHigh : (root.volumePercent >= 30 ? Config.iconVolMedium : Config.iconVolLow))
          color: root.isMuted ? Config.dangerRed : ((volContainer.isAudioActive || volMouse.containsMouse) ? Config.textWhite : Config.iconColor)
          font.pixelSize: Config.fontSizeIconMedium
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: volText
          visible: !root.vertical && opacity > 0.01
          opacity: (root.showVolumeText || volMouse.containsMouse) ? 1.0 : 0.0
          text: root.isMuted ? "Выкл." : (root.volumePercent + "%")
          color: root.isMuted ? Config.dangerRed : Config.textPrimary
          font.pixelSize: Config.fontSizeMedium
          font.weight: Font.Medium
          font.family: Config.fontSans
          anchors.verticalCenter: parent.verticalCenter

          Behavior on opacity { NumberAnimation { duration: 200 } }
        }
      }

      MouseArea {
        id: volMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
          if (mouse.button === Qt.RightButton) {
            if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
          } else {
            if (!root.toggleAnchoredFlyout("audio", root.audioPopup, volContainer)) {
              volumeProc.running = true
            }
          }
        }

        onWheel: (wheel) => {
          if (!root.sink || !root.sink.audio || wheel.angleDelta.y === 0) return
          let nextVolume = Math.max(0, Math.min(150, root.volumePercent + (wheel.angleDelta.y > 0 ? 5 : -5)))
          root.sink.audio.muted = false
          root.sink.audio.volume = nextVolume / 100
        }

        onEntered: if (root.tooltip) root.tooltip.show(volContainer, I18n.tr("Громкость"))
        onExited: if (root.tooltip) root.tooltip.hide()
      }
    }

    // Brightness Control Button
    Rectangle {
      id: brightContainer
      visible: Config.barBrightnessEnabled
      width: Config.buttonWidth
      height: Config.buttonHeight
      radius: Config.buttonRadius
      clip: true
      readonly property bool isBrightnessActive: (root.brightnessPopup && root.brightnessPopup.isOpen)
      color: (isBrightnessActive || brightMouse.containsMouse) ? Config.activeHoverBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text: root.brightnessPercent >= 75 ? Config.iconBrightHigh : (root.brightnessPercent >= 35 ? Config.iconBrightMedium : (root.brightnessPercent > 0 ? Config.iconBrightLow : Config.iconBrightOff))
        color: (brightContainer.isBrightnessActive || brightMouse.containsMouse) ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: brightMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
          root.toggleAnchoredFlyout("brightness", root.brightnessPopup, brightContainer)
        }

        onWheel: (wheel) => {
          if (root.brightnessPopup) {
            let delta = wheel.angleDelta.y > 0 ? 5 : -5
            let newPct = Math.max(0, Math.min(100, root.brightnessPercent + delta))
            root.brightnessPopup.brightnessPercent = newPct
            if (root.osd) root.osd.showBrightness(newPct)
            brightnessDebounceTimer.restart()
          }
        }

        onEntered: if (root.tooltip) root.tooltip.show(brightContainer, I18n.tr("Яркость"))
        onExited: if (root.tooltip) root.tooltip.hide()
      }
    }

    // Battery Status Button
    Rectangle {
      id: batteryContainer
      visible: Config.barBatteryEnabled
      width: Config.buttonWidth
      height: Config.buttonHeight
      radius: Config.buttonRadius
      readonly property bool isBatteryActive: (root.batteryPopup && root.batteryPopup.isOpen)
      readonly property int batteryPercent: root.batteryPopup ? root.batteryPopup.percent() : 0
      color: (isBatteryActive || batteryMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        visible: false
      }

      Item {
        width: 26
        height: 16
        anchors.centerIn: parent

        Rectangle {
          id: batteryBody
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 22
          height: 14
          radius: 3
          color: Config.meterTrack
          clip: true

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 2
            width: Math.max(2, Math.round((parent.width - 4) * batteryContainer.batteryPercent / 100))
            radius: 2
            color: root.batteryColor(batteryContainer.batteryPercent)
            opacity: 0.95
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#00000000"
            border.color: (batteryContainer.isBatteryActive || batteryMouse.containsMouse) ? Config.textWhite : Config.iconColor
            border.width: 1
          }

          Text {
            anchors.centerIn: parent
            visible: root.batteryPopup && (root.batteryPopup.batteryCharging || root.batteryPopup.acOnline)
            text: Config.iconBatteryCharging
            color: root.chargingIconColor(batteryContainer.batteryPercent)
            font.pixelSize: 12
            font.family: Config.fontIcon
          }
        }

        Rectangle {
          width: 3
          height: 7
          radius: 1
          anchors.left: batteryBody.right
          anchors.leftMargin: 1
          anchors.verticalCenter: batteryBody.verticalCenter
          color: (batteryContainer.isBatteryActive || batteryMouse.containsMouse) ? Config.textWhite : Config.iconColor
        }
      }

      MouseArea {
        id: batteryMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(batteryContainer, I18n.tr("Батарея"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: root.toggleAnchoredFlyout("battery", root.batteryPopup, batteryContainer)
      }
    }

    // Bluetooth Icon Button
    Rectangle {
      id: btContainer
      visible: Config.barBluetoothEnabled
      width: btIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      readonly property bool isBluetoothActive: (root.bluetoothPopup && root.bluetoothPopup.isOpen)
      color: (isBluetoothActive || btMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: btIcon
        anchors.centerIn: parent
        text: Config.iconBluetooth
        color: (btContainer.isBluetoothActive || btMouse.containsMouse) ? Config.textWhite : Config.iconColor
        opacity: root.bluetoothEnabled ? 1 : 0.38
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      Rectangle {
        width: btIcon.implicitWidth + 4
        height: 2
        radius: 1
        anchors.centerIn: btIcon
        rotation: -38
        color: (btContainer.isBluetoothActive || btMouse.containsMouse) ? Config.textWhite : Config.iconColor
        opacity: root.bluetoothEnabled ? 0 : 0.45
      }

      MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(btContainer, I18n.tr("Bluetooth"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: {
          if (!root.toggleAnchoredFlyout("bluetooth", root.bluetoothPopup, btContainer)) {
            bluetoothProc.running = true
          }
        }
      }
    }

    // Network Status Button (Ethernet + Wi-Fi merged)
    Rectangle {
      id: netContainer
      width: netIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      visible: Config.barNetworkEnabled
      readonly property bool isNetworkActive: (root.wifiPopup && root.wifiPopup.isOpen)
      color: (isNetworkActive || netMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: netIcon
        anchors.centerIn: parent
        text: root.ethConnected ? Config.iconEthernet : (!root.wifiEnabled ? Config.iconWifiDisconnected : (root.netConnecting && !root.wifiConnected ? Config.iconWifiConnecting : (root.wifiConnected ? Config.iconWifiConnected : Config.iconWifiDisconnected)))
        color: root.ethConnected ? ((netContainer.isNetworkActive || netMouse.containsMouse) ? Config.textWhite : Config.iconColor) : (root.wifiEnabled && root.netConnecting && !root.wifiConnected ? Config.warningAmber : ((netContainer.isNetworkActive || netMouse.containsMouse) ? Config.textWhite : Config.iconColor))
        opacity: root.ethConnected ? 1 : (root.wifiEnabled ? 1 : 0.38)
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      Rectangle {
        width: netIcon.implicitWidth + 4
        height: 2
        radius: 1
        anchors.centerIn: netIcon
        rotation: -38
        visible: !root.ethConnected
        color: (netContainer.isNetworkActive || netMouse.containsMouse) ? Config.textWhite : Config.iconColor
        opacity: root.wifiEnabled ? 0 : 0.45
      }

      MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(netContainer, I18n.tr("Сеть"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: {
          if (!root.toggleAnchoredFlyout("wifi", root.wifiPopup, netContainer)) {
            networkProc.running = true
          }
        }
      }
    }

    // Disconnected Status Button
    Rectangle {
      id: disContainer
      width: disIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      visible: false
      readonly property bool isNetworkActive: (root.wifiPopup && root.wifiPopup.isOpen)
      color: (isNetworkActive || disMouse.containsMouse) ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: disIcon
        anchors.centerIn: parent
        text: Config.iconWifiDisconnected
        color: Config.dangerRed
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: disMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (!root.toggleAnchoredFlyout("wifi", root.wifiPopup, disContainer)) {
            networkProc.running = true
          }
        }
      }
    }

    Rectangle {
      id: controlCenterContainer
      visible: Config.barControlCenterEnabled
      height: Config.buttonHeight
      width: Config.buttonWidth + 4
      radius: Config.buttonRadius
      readonly property bool isControlCenterActive: root.controlCenterPopup && root.controlCenterPopup.isOpen
      color: (isControlCenterActive || controlCenterMouse.containsMouse) ? Config.activeHoverBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text: Config.iconControlCenter
        color: (controlCenterContainer.isControlCenterActive || controlCenterMouse.containsMouse) ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: controlCenterMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(controlCenterContainer, I18n.tr("Центр управления"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: root.openControlCenter("wifi", controlCenterContainer)
      }
    }

    Rectangle {
      id: dateTimeContainer
      height: 24
      implicitWidth: root.vertical ? 58 : dateTimeRow.implicitWidth + 16
      radius: 8
      visible: Config.barDateTimeEnabled || (Config.weatherEnabled && Config.barWeatherEnabled)
      readonly property bool isCalendarActive: root.calendarPopup && root.calendarPopup.isOpen
      color: (isCalendarActive || dateTimeMouse.containsMouse) ? Config.activeHoverBg : Config.controlIdleBg
      border.color: Config.barBorderColor
      border.width: Config.barBordersEnabled ? 1 : 0

      Behavior on color { ColorAnimation { duration: 150 } }

      Row {
        id: dateTimeRow
        anchors.centerIn: parent
        spacing: 8

        Item {
          visible: !root.vertical && Config.barDateTimeEnabled
          width: clockIcon.implicitWidth
          height: 20
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: clockIcon
            anchors.centerIn: parent
            text: Config.iconClock
            color: (dateTimeContainer.isCalendarActive || dateTimeMouse.containsMouse) ? Config.textWhite : Config.iconColor
            font.pixelSize: Config.fontSizeIconSmall
            font.family: Config.fontIcon
          }
        }

        Text {
          visible: Config.barDateTimeEnabled
          height: 20
          text: root.vertical ? Config.formatTime24(statusClock.date) : Config.formatBarDateTimeRu(statusClock.date)
          color: (dateTimeContainer.isCalendarActive || dateTimeMouse.containsMouse) ? Config.textWhite : Config.textPrimary
          font.pixelSize: Config.fontSizeSmall
          font.weight: Font.Medium
          font.family: Config.fontSans
          verticalAlignment: Text.AlignVCenter
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          visible: !root.vertical && Config.barDateTimeEnabled && weatherWidget.visible
          width: 1
          height: 16
          color: Config.separatorColor
          anchors.verticalCenter: parent.verticalCenter
        }

        WeatherWidget {
          id: weatherWidget
          visible: !root.vertical && Config.weatherEnabled && Config.barWeatherEnabled
          embedded: true
          iconOnRight: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        id: dateTimeMouse
        anchors.fill: parent
        enabled: Config.barDateTimeEnabled
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: if (root.tooltip) root.tooltip.show(dateTimeContainer, I18n.tr("Дата и время"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: {
          if (root.calendarPopup) {
            root.positionPopupFor("calendar", dateTimeContainer, root.calendarPopup)
          }
          root.toggleFlyout("calendar", root.calendarPopup)
        }
      }
    }

    Rectangle {
      id: vpnContainer
      width: vpnIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      visible: Config.barVpnEnabled && root.vpnConnected
      color: vpnMouse.containsMouse ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: vpnIcon
        anchors.centerIn: parent
        text: Config.iconVpnShield
        color: vpnMouse.containsMouse ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: vpnMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.tooltip) root.tooltip.show(vpnContainer, I18n.tr("VPN"))
        onExited: if (root.tooltip) root.tooltip.hide()
      }
    }

    Rectangle {
      id: pickerContainer
      width: pickerIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      visible: Config.barColorPickerEnabled
      color: pickerMouse.containsMouse ? Config.pressedBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: pickerIcon
        anchors.centerIn: parent
        text: Config.iconColorPicker
        color: pickerMouse.containsMouse ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: pickerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(pickerContainer, I18n.tr("Пипетка цвета"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: {
          pickerProc.running = false
          pickerProc.running = true
        }
      }
    }

    // Power Button Icon
    Rectangle {
      id: powerContainer
      visible: Config.barPowerEnabled
      width: powerIcon.implicitWidth + root.iconButtonPadding * 2
      height: Config.buttonHeight
      radius: Config.buttonRadius
      readonly property bool isPowerActive: root.powerPopup && root.powerPopup.isOpen
      color: (isPowerActive || pwrMouse.containsMouse) ? "#45f87171" : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        id: powerIcon
        anchors.centerIn: parent
        text: Config.iconPower
        color: (powerContainer.isPowerActive || pwrMouse.containsMouse) ? Config.dangerRed : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: pwrMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(powerContainer, I18n.tr("Питание"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: {
          root.toggleAnchoredFlyout("power", root.powerPopup, powerContainer)
        }
      }
    }
  }
}
