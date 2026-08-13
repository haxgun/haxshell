// ControlCenterPopup.qml - quick controls using the settings surface style
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import "../../Common"
import "../../Widgets"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property string activeSection: "wifi"
  property int brightnessPercent: 100
  property string activeBrightnessBus: Config.brightnessMonitorBus
  property int sinkVolume: 0
  property bool sinkMuted: false
  property int batteryPercent: 0
  property bool batteryCharging: false
  property bool acOnline: false
  property string powerProfile: "balanced"
  property bool caffeineEnabled: false
  property bool hasMedia: false
  property bool isPlaying: false
  property string mediaArtist: ""
  property string mediaTitle: ""

  readonly property string qsctl: Qt.resolvedUrl("../../scripts/qsctl").toString().replace("file://", "")
  readonly property string mediaSeparator: "\u001f"
  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var bluetoothDevices: adapter && adapter.devices && adapter.devices.values ? adapter.devices.values : []
  readonly property var wifiDevice: {
    let list = Networking.devices && Networking.devices.values ? Networking.devices.values : []
    for (let i = 0; i < list.length; i++) if (list[i] && list[i].type === DeviceType.Wifi) return list[i]
    return null
  }
  readonly property var wifiNetworks: wifiDevice && wifiDevice.networks && wifiDevice.networks.values ? wifiDevice.networks.values : []
  readonly property string connectedNetworkName: {
    for (let i = 0; i < wifiNetworks.length; i++) if (wifiNetworks[i] && wifiNetworks[i].connected) return wifiNetworks[i].name
    return ""
  }
  readonly property string connectedDeviceName: {
    for (let i = 0; i < bluetoothDevices.length; i++) if (bluetoothDevices[i] && bluetoothDevices[i].connected) return bluetoothDevices[i].name || bluetoothDevices[i].deviceName || "Bluetooth"
    return ""
  }

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "control-center"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
    function focus(section: string) { root.activeSection = section || "wifi"; root.isOpen = true }
  }

  onIsOpenChanged: if (isOpen) {
    refreshAll()
    if (wifiDevice) wifiDevice.scannerEnabled = true
    if (adapter && adapter.enabled) adapter.discovering = true
  }

  Timer {
    interval: 12000
    running: true
    repeat: true
    onTriggered: {
      refreshBattery()
      if (root.isOpen) refreshAll()
    }
  }

  Process {
    id: brightnessProc
    command: [root.qsctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: true
    stdout: SplitParser { onRead: data => root.applyBrightnessState(data) }
  }

  Process {
    id: audioProc
    command: [root.qsctl, "audio", "get"]
    running: true
    stdout: SplitParser { onRead: data => root.applyAudioState(data) }
  }

  Process {
    id: batteryProc
    command: [root.qsctl, "battery"]
    running: true
    stdout: SplitParser { onRead: data => root.applyBatteryState(data) }
  }

  Process {
    id: caffeineProc
    command: [root.qsctl, "caffeine", "state"]
    running: true
    stdout: SplitParser { onRead: data => root.applyCaffeineState(data) }
  }

  Process {
    id: mediaProc
    command: ["playerctl", "metadata", "-F", "--format", "{{status}}" + root.mediaSeparator + "{{artist}}" + root.mediaSeparator + "{{title}}"]
    running: true
    stdout: SplitParser { onRead: data => root.applyMediaState(data) }
  }

  Process { id: actionProc }

  function refreshAll() {
    refreshBrightness()
    refreshAudio()
    refreshBattery()
    refreshCaffeine()
  }

  function restart(process, command) {
    process.running = false
    process.command = command
    process.running = true
  }

  function refreshBrightness() { restart(brightnessProc, [qsctl, "brightness", "get", activeBrightnessBus, Config.brightnessSleepMultiplier]) }
  function refreshAudio() { restart(audioProc, [qsctl, "audio", "get"]) }
  function refreshBattery() { restart(batteryProc, [qsctl, "battery"]) }
  function refreshCaffeine() { restart(caffeineProc, [qsctl, "caffeine", "state"]) }

  function applyBrightnessState(data) {
    try {
      let state = JSON.parse(data)
      if (state.ok && typeof state.brightness !== "undefined") brightnessPercent = state.brightness
      if (state.bus) activeBrightnessBus = state.bus.toString()
      if (state.device) activeBrightnessBus = state.device.toString()
    } catch(e) {}
  }

  function applyAudioState(data) {
    try {
      let state = JSON.parse(data)
      if (!state.ok) return
      sinkVolume = state.sinkVolume || 0
      sinkMuted = !!state.sinkMuted
    } catch(e) {}
  }

  function applyBatteryState(data) {
    try {
      let state = JSON.parse(data)
      batteryPercent = state.percentage || 0
      batteryCharging = !!state.charging
      acOnline = !!state.online
      powerProfile = state.profile || "balanced"
    } catch(e) {}
  }

  function applyCaffeineState(data) {
    try { caffeineEnabled = !!JSON.parse(data).enabled } catch(e) {}
  }

  function applyMediaState(data) {
    let parts = data.trim().split(mediaSeparator)
    hasMedia = parts.length >= 3 && (parts[0] === "Playing" || parts[0] === "Paused")
    isPlaying = parts[0] === "Playing"
    mediaArtist = parts.length >= 3 ? parts[1] : ""
    mediaTitle = parts.length >= 3 ? parts[2] : ""
  }

  function run(command) { restart(actionProc, command) }
  function setBrightness(value) { run([qsctl, "brightness", "set", Math.max(0, Math.min(100, value)).toString(), activeBrightnessBus, Config.brightnessSleepMultiplier]) }
  function setAudio(action, value) { run([qsctl, "audio", action, value.toString()]) }
  function toggleCaffeine() { restart(caffeineProc, [qsctl, "caffeine", "toggle"]) }
  function cyclePowerProfile() {
    let profiles = ["power-saver", "balanced", "performance"]
    let next = profiles[(profiles.indexOf(powerProfile) + 1) % profiles.length]
    restart(batteryProc, [qsctl, "battery", "set-profile", next])
  }
  function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled }
  function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled }
  function wifiSubtitle() { return !Networking.wifiEnabled ? "Выключен" : (connectedNetworkName || "Не подключено") }
  function bluetoothSubtitle() { return !adapter || !adapter.enabled ? "Выключен" : (connectedDeviceName || "Включен") }
  function batterySubtitle() { return (batteryCharging ? "Заряжается" : (acOnline ? "От сети" : "Аккумулятор")) + " · " + profileName(powerProfile) }
  function profileName(profile) { return profile === "power-saver" ? "Экономия" : (profile === "performance" ? "Производительность" : "Баланс") }
  function volumeIcon() { return sinkMuted ? Config.iconVolMuted : (sinkVolume >= 70 ? Config.iconVolHigh : (sinkVolume >= 30 ? Config.iconVolMedium : Config.iconVolLow)) }
  function brightnessIcon() { return brightnessPercent >= 75 ? Config.iconBrightHigh : (brightnessPercent >= 35 ? Config.iconBrightMedium : (brightnessPercent > 0 ? Config.iconBrightLow : Config.iconBrightOff)) }

  Rectangle {
    id: container
    width: 430
    height: Math.min(content.implicitHeight + 28, root.height - 32)
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.glassBg
    clip: false

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: 1 }

    Column {
      id: content
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 0

      Row {
        width: parent.width
        height: 30
        spacing: 10
        Text { text: "☷"; color: Config.textWhite; font.pixelSize: Config.fontSizeTitle; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Центр управления"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
      }

      Text { width: parent.width; height: 28; verticalAlignment: Text.AlignBottom; text: "Подключения"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

      SettingsRow {
        icon: Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected
        title: "Wi-Fi"
        subtitle: root.wifiSubtitle()
        onClicked: { root.activeSection = "wifi"; root.toggleWifi() }
        ToggleSwitch { checked: Networking.wifiEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.toggleWifi() }
      }

      SettingsRow {
        icon: Config.iconBluetooth
        title: "Bluetooth"
        subtitle: root.bluetoothSubtitle()
        onClicked: { root.activeSection = "bluetooth"; root.toggleBluetooth() }
        ToggleSwitch { checked: root.adapter && root.adapter.enabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.toggleBluetooth() }
      }

      Text { width: parent.width; height: 28; verticalAlignment: Text.AlignBottom; text: "Устройство"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

      SettingsRow {
        icon: root.brightnessIcon()
        title: "Яркость"
        subtitle: root.brightnessPercent + "%"
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          Rectangle {
            width: 28
            height: 28
            radius: 8
            color: minusMouse.containsMouse ? Config.hoverBg : Config.searchBg
            Text { anchors.centerIn: parent; text: "−"; color: Config.textPrimary; font.pixelSize: Config.fontSizeLarge; font.family: Config.fontSans }
            MouseArea { id: minusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setBrightness(root.brightnessPercent - 5) }
          }
          Rectangle {
            width: 28
            height: 28
            radius: 8
            color: plusMouse.containsMouse ? Config.hoverBg : Config.searchBg
            Text { anchors.centerIn: parent; text: "+"; color: Config.textPrimary; font.pixelSize: Config.fontSizeLarge; font.family: Config.fontSans }
            MouseArea { id: plusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setBrightness(root.brightnessPercent + 5) }
          }
        }
      }

      SettingsRow {
        icon: root.volumeIcon()
        title: "Звук"
        subtitle: root.sinkMuted ? "Выключен" : (root.sinkVolume + "%")
        onClicked: root.setAudio("set-sink-mute", root.sinkMuted ? "0" : "1")
        ToggleSwitch { checked: !root.sinkMuted; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setAudio("set-sink-mute", root.sinkMuted ? "0" : "1") }
      }

      SettingsRow {
        icon: root.batteryCharging ? Config.iconBatteryCharging : Config.iconBattery
        title: "Питание"
        subtitle: root.batteryPercent + "% · " + root.batterySubtitle()
        last: true
        onClicked: root.cyclePowerProfile()
      }

      Text { width: parent.width; height: 28; verticalAlignment: Text.AlignBottom; text: "Система"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

      SettingsRow {
        icon: Config.iconCoffee
        title: "Не спать"
        subtitle: root.caffeineEnabled ? "Сон и idle заблокированы" : "Обычный режим сна"
        last: true
        onClicked: root.toggleCaffeine()
        ToggleSwitch { checked: root.caffeineEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.toggleCaffeine() }
      }

      Text { width: parent.width; height: 28; verticalAlignment: Text.AlignBottom; text: "Медиа"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

      SettingsRow {
        icon: Config.iconMusic
        title: root.hasMedia ? (root.mediaTitle || "Музыка") : "Музыка"
        subtitle: root.hasMedia ? (root.mediaArtist || "Неизвестный исполнитель") : "Нет активного плеера"
        last: true
        onClicked: root.run(["playerctl", "play-pause"])
        Rectangle {
          width: 32
          height: 30
          radius: 8
          color: mediaMouse.containsMouse ? Config.hoverBg : Config.searchBg
          Text { anchors.centerIn: parent; text: root.isPlaying ? Config.iconPause : Config.iconPlay; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: mediaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["playerctl", "play-pause"]) }
        }
      }
    }
  }
}
