// ControlCenterPopup.qml - quick controls using the settings surface style
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import "."
import "../../Common"
import "../../Widgets"
import "../../Services"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property var audioPopup: null
  property var osd: null
  property var wifiPopup: null
  property var bluetoothPopup: null
  property var batteryPopup: null
  property var settingsPopup: null
  property var powerPopup: null
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
  readonly property var mediaPlayer: MprisController.activePlayer
  readonly property bool hasMedia: mediaPlayer && !MprisController.isIdle(mediaPlayer)
  readonly property bool isPlaying: mediaPlayer && mediaPlayer.isPlaying
  readonly property string mediaArtist: MprisController.stableArtist
  readonly property string mediaTitle: MprisController.stableTitle

  readonly property string hushctl: Config.hushctl
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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

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
    running: root.isOpen
    repeat: true
    onTriggered: {
      refreshAll()
    }
  }

  Process {
    id: brightnessProc
    command: [root.hushctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: true
    stdout: SplitParser { onRead: data => root.applyBrightnessState(data) }
  }

  Process {
    id: audioProc
    command: [root.hushctl, "audio", "get"]
    running: true
    stdout: SplitParser { onRead: data => root.applyAudioState(data) }
  }

  Process {
    id: batteryProc
    command: [root.hushctl, "battery"]
    running: true
    stdout: SplitParser { onRead: data => root.applyBatteryState(data) }
  }

  Process {
    id: caffeineProc
    command: [root.hushctl, "caffeine", "state"]
    running: true
    stdout: SplitParser { onRead: data => root.applyCaffeineState(data) }
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

  function refreshBrightness() { restart(brightnessProc, [hushctl, "brightness", "get", activeBrightnessBus, Config.brightnessSleepMultiplier]) }
  function refreshAudio() { restart(audioProc, [hushctl, "audio", "get"]) }
  function refreshBattery() { restart(batteryProc, [hushctl, "battery"]) }
  function refreshCaffeine() { restart(caffeineProc, [hushctl, "caffeine", "state"]) }

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

  function run(command) { restart(actionProc, command) }
  function setBrightness(value) {
    let target = Math.max(0, Math.min(100, value))
    brightnessPercent = target
    if (osd) osd.showBrightness(target)
    run([hushctl, "brightness", "set", target.toString(), activeBrightnessBus, Config.brightnessSleepMultiplier])
  }
  function setAudio(action, value) { run([hushctl, "audio", action, value.toString()]) }
  function openAudioPopup() {
    if (!audioPopup) return
    audioPopup.rightMargin = rightMargin
    audioPopup.isOpen = true
    isOpen = false
  }
  function openPopup(popup) {
    if (!popup) return
    popup.rightMargin = rightMargin
    popup.isOpen = true
    isOpen = false
  }
  function toggleCaffeine() { restart(caffeineProc, [hushctl, "caffeine", "toggle"]) }
  function cyclePowerProfile() {
    let profiles = ["power-saver", "balanced", "performance"]
    let next = profiles[(profiles.indexOf(powerProfile) + 1) % profiles.length]
    restart(batteryProc, [hushctl, "battery", "set-profile", next])
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
    width: 550
    height: Math.min(content.implicitHeight + 28, root.height - 32)
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg
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
        Text { text: Config.iconSettings; color: Config.textWhite; font.pixelSize: Config.fontSizeTitle; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Центр управления"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
        Item { width: parent.width - 270; height: 1 }
        Rectangle {
          width: 30; height: 30; radius: 8; color: settingsMouse.containsMouse ? Config.hoverBg : "#151A1A1A"; border.color: Config.borderColor; border.width: 1
          Text { anchors.centerIn: parent; text: Config.iconSettings; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
          MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.settingsPopup) }
        }
        Rectangle {
          width: 30; height: 30; radius: 8; color: powerMouse.containsMouse ? Config.hoverBg : "#151A1A1A"; border.color: Config.borderColor; border.width: 1
          Text { anchors.centerIn: parent; text: Config.iconPower; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
          MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.powerPopup) }
        }
      }

      Row {
        width: parent.width
        height: 76
        spacing: 8
        Repeater {
          model: [{ icon: root.volumeIcon(), title: "Громкость", value: root.sinkVolume, muted: root.sinkMuted, brightness: false }, { icon: root.brightnessIcon(), title: "Яркость", value: root.brightnessPercent, muted: false, brightness: true }]
          Rectangle {
            id: sliderCard
            required property var modelData
            width: (parent.width - 8) / 2; height: parent.height; radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
            Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.top: parent.top; anchors.topMargin: 9; text: sliderCard.modelData.icon; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            Text { anchors.left: parent.left; anchors.leftMargin: 36; anchors.top: parent.top; anchors.topMargin: 10; text: sliderCard.modelData.title; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }
            Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.top: parent.top; anchors.topMargin: 10; text: sliderCard.modelData.muted ? "Выкл." : sliderCard.modelData.value + "%"; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontMono }
            Rectangle {
              id: sliderTrack
              anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; height: 7; radius: 4; color: Config.searchBg
              Rectangle { width: parent.width * Math.min(1, sliderCard.modelData.value / 100); height: parent.height; radius: parent.radius; color: sliderCard.modelData.muted ? Config.textMuted : Config.textPrimary }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mouse => { let value = Math.round(Math.max(0, Math.min(100, mouse.x / width * 100))); if (sliderCard.modelData.brightness) root.setBrightness(value); else root.setAudio("set-sink-volume", value) } }
            }
          }
        }
      }

      Grid {
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8
        QuickControlTile { icon: Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected; title: "Wi-Fi"; subtitle: root.wifiSubtitle(); active: Networking.wifiEnabled; onToggled: root.toggleWifi(); onDetailsRequested: root.openPopup(root.wifiPopup) }
        QuickControlTile { icon: Config.iconBluetooth; title: "Bluetooth"; subtitle: root.bluetoothSubtitle(); active: root.adapter && root.adapter.enabled; onToggled: root.toggleBluetooth(); onDetailsRequested: root.openPopup(root.bluetoothPopup) }
        QuickControlTile { icon: root.volumeIcon(); title: "Звук"; subtitle: root.sinkMuted ? "Выключен" : root.sinkVolume + "%"; active: !root.sinkMuted; onToggled: root.setAudio("set-sink-mute", root.sinkMuted ? "0" : "1"); onDetailsRequested: root.openAudioPopup() }
        QuickControlTile { icon: (root.batteryCharging || root.acOnline) ? Config.iconBatteryCharging : Config.iconBattery; title: "Питание"; subtitle: root.batteryPercent + "% · " + root.profileName(root.powerProfile); active: root.acOnline || root.batteryCharging; onToggled: root.cyclePowerProfile(); onDetailsRequested: root.openPopup(root.batteryPopup) }
        QuickControlTile { icon: Config.iconCoffee; title: "Не спать"; subtitle: root.caffeineEnabled ? "Включено" : "Выключено"; active: root.caffeineEnabled; onToggled: root.toggleCaffeine(); onDetailsRequested: root.toggleCaffeine() }
        QuickControlTile { icon: Config.iconNotificationsActive; title: "Не беспокоить"; subtitle: NotificationService.doNotDisturb ? "Включено" : "Выключено"; active: NotificationService.doNotDisturb; onToggled: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb); onDetailsRequested: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb) }
      }

      Rectangle {
        width: parent.width; height: 62; radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: Config.iconMusic; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconLarge; font.family: Config.fontIcon }
        Column {
          anchors.left: parent.left; anchors.leftMargin: 50; anchors.right: mediaButton.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 3
          Text { width: parent.width; text: root.hasMedia ? (root.mediaTitle || "Музыка") : "Музыка"; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.hasMedia ? (root.mediaArtist || "Неизвестный исполнитель") : "Нет активного плеера"; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight }
        }
        Rectangle {
          id: mediaButton
          width: 36; height: 36; radius: 9; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; color: mediaMouse.containsMouse ? Config.hoverBg : "#151A1A1A"
          Text { anchors.centerIn: parent; text: root.isPlaying ? Config.iconPause : Config.iconPlay; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: mediaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mediaPlayer && root.mediaPlayer.canTogglePlaying) root.mediaPlayer.togglePlaying() }
        }
      }
    }
  }
}
