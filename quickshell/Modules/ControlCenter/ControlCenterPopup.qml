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
  property string nightLightBackend: ""
  property bool nightLightEnabled: false
  readonly property string userName: Quickshell.env("USER") || "Пользователь"
  readonly property var mediaPlayer: MprisController.activePlayer
  readonly property bool hasMedia: mediaPlayer && !MprisController.isIdle(mediaPlayer)
  readonly property bool isPlaying: mediaPlayer && mediaPlayer.isPlaying
  readonly property string mediaArtist: MprisController.stableArtist
  readonly property string mediaTitle: MprisController.stableTitle
  readonly property string mediaArtUrl: normalizeArtUrl(mediaPlayer && mediaPlayer.trackArtUrl ? mediaPlayer.trackArtUrl : "")

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
  readonly property bool nightLightAvailable: nightLightBackend.length > 0
  readonly property bool airplaneModeEnabled: !Networking.wifiEnabled && (!adapter || !adapter.enabled)

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

  Process {
    id: nightLightDetectProc
    command: ["sh", "-lc", "command -v gammastep >/dev/null && printf gammastep"]
    running: true
    stdout: SplitParser { onRead: data => root.nightLightBackend = data.trim() }
  }

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
  function setAudio(action, value) {
    if (action === "set-sink-volume") sinkVolume = Math.max(0, Math.min(100, Math.round(value)))
    if (action === "set-sink-mute") sinkMuted = value.toString() === "1"
    run([hushctl, "audio", action, value.toString()])
  }
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
  function toggleAirplaneMode() {
    let enable = !airplaneModeEnabled
    Networking.wifiEnabled = !enable
    if (adapter) adapter.enabled = !enable
  }
  function toggleNightLight() {
    if (!nightLightAvailable) return
    nightLightEnabled = !nightLightEnabled
    run(["sh", "-lc", nightLightEnabled ? "gammastep -P -O 3500" : "gammastep -x"])
  }
  function toggleTheme() {
    let theme = Config.isLightTheme ? "dark" : "light"
    Config.themeName = theme
    SettingsStore.setValue("themeName", theme)
  }
  function normalizeArtUrl(value) {
    let url = (value || "").trim()
    if (url.length === 0) return ""
    return url.indexOf("/") === 0 ? "file://" + url : url
  }
  function wifiSubtitle() { return !Networking.wifiEnabled ? "Выключен" : (connectedNetworkName || "Не подключено") }
  function bluetoothSubtitle() { return !adapter || !adapter.enabled ? "Выключен" : (connectedDeviceName || "Включен") }
  function batterySubtitle() { return (batteryCharging ? "Заряжается" : (acOnline ? "От сети" : "Аккумулятор")) + " · " + profileName(powerProfile) }
  function profileName(profile) { return profile === "power-saver" ? "Экономия" : (profile === "performance" ? "Производительность" : "Баланс") }
  function volumeIcon() { return sinkMuted ? Config.iconVolMuted : (sinkVolume >= 70 ? Config.iconVolHigh : (sinkVolume >= 30 ? Config.iconVolMedium : Config.iconVolLow)) }
  function brightnessIcon() { return brightnessPercent >= 75 ? Config.iconBrightHigh : (brightnessPercent >= 35 ? Config.iconBrightMedium : (brightnessPercent > 0 ? Config.iconBrightLow : Config.iconBrightOff)) }

  Rectangle {
    id: container
    width: 410
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
      spacing: 8

      Row {
        width: parent.width
        height: 42
        spacing: 8
        Rectangle {
          width: 40; height: 40; radius: 20; color: Config.selectedBg; border.color: Config.activeBorderColor; border.width: 1
          Text { anchors.centerIn: parent; text: root.userName.charAt(0).toUpperCase(); color: Config.textWhite; font.pixelSize: Config.fontSizeMedium; font.weight: Font.Bold; font.family: Config.fontSans }
        }
        Text { width: 180; text: root.userName; color: Config.textWhite; font.pixelSize: Config.fontSizeMedium; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
        Item { width: parent.width - 328; height: 1 }
        Rectangle {
          width: 38; height: 38; radius: 10; color: settingsMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg; border.color: Config.borderColor; border.width: 1
          Text { anchors.centerIn: parent; text: Config.iconSettings; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.settingsPopup) }
        }
        Rectangle {
          width: 38; height: 38; radius: 10; color: powerMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg; border.color: Config.borderColor; border.width: 1
          Text { anchors.centerIn: parent; text: Config.iconPower; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.powerPopup) }
        }
      }

      Rectangle {
        width: parent.width; height: 62; radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
        Rectangle {
          width: 40; height: 40; radius: 9; anchors.left: parent.left; anchors.leftMargin: 11; anchors.verticalCenter: parent.verticalCenter; clip: true; color: Config.selectedBg
          Image { anchors.fill: parent; source: root.mediaArtUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.mediaArtUrl.length > 0 }
          Text { anchors.centerIn: parent; visible: root.mediaArtUrl.length === 0; text: Config.iconMusic; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
        }
        Column {
          anchors.left: parent.left; anchors.leftMargin: 62; anchors.right: mediaButton.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 3
          Text { width: parent.width; text: root.hasMedia ? (root.mediaTitle || "Музыка") : "Музыка"; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.hasMedia ? (root.mediaArtist || "Неизвестный исполнитель") : "Нет активного плеера"; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight }
        }
        Rectangle {
          id: mediaButton
          width: 36; height: 36; radius: 9; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; color: mediaMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          Text { anchors.centerIn: parent; text: root.isPlaying ? Config.iconPause : Config.iconPlay; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: mediaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mediaPlayer && root.mediaPlayer.canTogglePlaying) root.mediaPlayer.togglePlaying() }
        }
      }

      Grid {
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8
        QuickControlTile { icon: Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected; title: "Wi-Fi"; subtitle: root.wifiSubtitle(); active: Networking.wifiEnabled; onToggled: root.toggleWifi(); onDetailsRequested: root.openPopup(root.wifiPopup) }
        QuickControlTile { icon: Config.iconBluetooth; title: "Bluetooth"; subtitle: root.bluetoothSubtitle(); active: root.adapter && root.adapter.enabled; onToggled: root.toggleBluetooth(); onDetailsRequested: root.openPopup(root.bluetoothPopup) }
        QuickControlTile { icon: Config.iconCoffee; title: "Не спать"; subtitle: root.caffeineEnabled ? "Включено" : "Выключено"; active: root.caffeineEnabled; onToggled: root.toggleCaffeine(); onDetailsRequested: root.toggleCaffeine() }
        QuickControlTile { icon: Config.iconNotificationsActive; title: "Не беспокоить"; subtitle: NotificationService.doNotDisturb ? "Включено" : "Выключено"; active: NotificationService.doNotDisturb; onToggled: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb); onDetailsRequested: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb) }
        QuickControlTile { visible: root.nightLightAvailable; icon: Config.iconMoon; title: "Ночной свет"; subtitle: root.nightLightEnabled ? "Включён" : "Выключен"; active: root.nightLightEnabled; onToggled: root.toggleNightLight(); onDetailsRequested: root.toggleNightLight() }
        QuickControlTile { visible: root.wifiDevice || root.adapter; icon: Config.iconAirplane; title: "Авиарежим"; subtitle: root.airplaneModeEnabled ? "Включён" : "Выключен"; active: root.airplaneModeEnabled; onToggled: root.toggleAirplaneMode(); onDetailsRequested: root.toggleAirplaneMode() }
        QuickControlTile { icon: Config.isLightTheme ? Config.iconSun : Config.iconMoon; title: "Тема"; subtitle: Config.isLightTheme ? "Светлая" : "Тёмная"; active: Config.isLightTheme; onToggled: root.toggleTheme(); onDetailsRequested: root.toggleTheme() }
        QuickControlTile { icon: root.powerProfile === "performance" ? Config.iconPerformance : (root.powerProfile === "power-saver" ? Config.iconPowerSaver : Config.iconBalanced); title: "Режим питания"; subtitle: root.profileName(root.powerProfile); active: root.powerProfile !== "balanced"; onToggled: root.cyclePowerProfile(); onDetailsRequested: root.cyclePowerProfile() }
      }

      Column {
        width: parent.width
        spacing: 8
        Rectangle {
          width: parent.width; height: 68; radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
          Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.top: parent.top; anchors.topMargin: 10; text: "Громкость"; color: Config.textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.7 }
          Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.top: parent.top; anchors.topMargin: 10; text: root.sinkMuted ? "Выкл." : root.sinkVolume + "%"; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontMono }
          QuickControlSlider { anchors.left: parent.left; anchors.leftMargin: 12; anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 9; value: root.sinkVolume; minimumIcon: Config.iconVolLow; maximumIcon: Config.iconVolHigh; onValueEdited: value => root.setAudio("set-sink-volume", value) }
        }
        Rectangle {
          width: parent.width; height: 68; radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
          Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.top: parent.top; anchors.topMargin: 10; text: "Яркость"; color: Config.textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.7 }
          Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.top: parent.top; anchors.topMargin: 10; text: root.brightnessPercent + "%"; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontMono }
          QuickControlSlider { anchors.left: parent.left; anchors.leftMargin: 12; anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 9; value: root.brightnessPercent; minimumIcon: Config.iconBrightLow; maximumIcon: Config.iconBrightHigh; onValueEdited: value => root.setBrightness(value) }
        }
      }
    }
  }
}
