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
  property int rightMargin: Config.scaledSize(16)
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
  readonly property var mediaPlayer: MprisController.activePlayer
  readonly property bool hasMedia: mediaPlayer && !MprisController.isIdle(mediaPlayer)
  readonly property bool isPlaying: mediaPlayer && mediaPlayer.isPlaying
  readonly property string mediaArtist: MprisController.stableArtist
  readonly property string mediaTitle: MprisController.stableTitle
  readonly property string mediaArtUrl: normalizeArtUrl(MprisController.stableArtUrl)

  readonly property string veyctl: Config.veyctl
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

  SystemClock {
    id: clock
    precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }

  Process {
    id: brightnessProc
    command: [root.veyctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: true
    stdout: SplitParser { onRead: data => root.applyBrightnessState(data) }
  }

  Process {
    id: audioProc
    command: [root.veyctl, "audio", "get"]
    running: true
    stdout: SplitParser { onRead: data => root.applyAudioState(data) }
  }

  Process {
    id: batteryProc
    command: [root.veyctl, "battery"]
    running: true
    stdout: SplitParser { onRead: data => root.applyBatteryState(data) }
  }

  Process {
    id: caffeineProc
    command: [root.veyctl, "caffeine", "state"]
    running: true
    stdout: SplitParser { onRead: data => root.applyCaffeineState(data) }
  }

  Process {
    id: actionProc
  }

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

  function refreshBrightness() { restart(brightnessProc, [veyctl, "brightness", "get", activeBrightnessBus, Config.brightnessSleepMultiplier]) }
  function refreshAudio() { restart(audioProc, [veyctl, "audio", "get"]) }
  function refreshBattery() { restart(batteryProc, [veyctl, "battery"]) }
  function refreshCaffeine() { restart(caffeineProc, [veyctl, "caffeine", "state"]) }

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
    if (osd) osd.suppressOnce()
    run([veyctl, "brightness", "set", target.toString(), activeBrightnessBus, Config.brightnessSleepMultiplier])
  }
  function setAudio(action, value) {
    if (osd) osd.suppressOnce()
    if (action === "set-sink-volume") sinkVolume = Math.max(0, Math.min(100, Math.round(value)))
    if (action === "set-sink-mute") sinkMuted = value.toString() === "1"
    run([veyctl, "audio", action, value.toString()])
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
  function toggleCaffeine() { restart(caffeineProc, [veyctl, "caffeine", "toggle"]) }
  function cyclePowerProfile() {
    let profiles = ["power-saver", "balanced", "performance"]
    let next = profiles[(profiles.indexOf(powerProfile) + 1) % profiles.length]
    restart(batteryProc, [veyctl, "battery", "set-profile", next])
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
  function takeScreenshot() {
    let delay = root.isOpen ? "0.5" : "0"
    root.isOpen = false
    if (CompositorService.backend === "niri") {
      run(["sh", "-lc", "sleep " + delay + " && mkdir -p \"$HOME/Pictures\" && niri msg action screenshot --path \"$HOME/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png\""])
    } else {
      run(["sh", "-lc", "sleep " + delay + " && mkdir -p \"$HOME/Pictures\" && grim \"$HOME/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png\""])
    }
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
    width: Config.scaledSize(410)
    height: Math.min(content.implicitHeight + 28, root.height - 32)
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg
    clip: false

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    Column {
      id: content
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.scaledSize(8)

      Row {
        width: parent.width
        height: Config.scaledSize(60)
        spacing: Config.scaledSize(8)

        Column {
          width: parent.width - 138
          anchors.verticalCenter: parent.verticalCenter
          spacing: Config.scaledSize(1)
          Text { text: Config.formatBarTime(clock.date); color: Config.textPrimary; font.pixelSize: Config.scaledFontSize(30); font.weight: Font.Medium; font.family: Config.fontSans }
          Text { text: Config.formatLongDate(clock.date); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
        }
        Rectangle {
          width: Config.scaledSize(38); height: Config.scaledSize(38); radius: Config.popupPillRadius(width); anchors.verticalCenter: parent.verticalCenter; color: settingsMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          Text { anchors.centerIn: parent; text: Config.iconSettings; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.settingsPopup) }
        }
        Rectangle {
          width: Config.scaledSize(38); height: Config.scaledSize(38); radius: Config.popupPillRadius(width); anchors.verticalCenter: parent.verticalCenter; color: themeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          Text { anchors.centerIn: parent; text: Config.iconTheme; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: themeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleTheme() }
        }
        Rectangle {
          width: Config.scaledSize(38); height: Config.scaledSize(38); radius: Config.popupPillRadius(width); anchors.verticalCenter: parent.verticalCenter; color: powerMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          Text { anchors.centerIn: parent; text: Config.iconPower; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPopup(root.powerPopup) }
        }
      }

      Column {
        width: parent.width
        spacing: Config.scaledSize(8)
        Row {
          width: parent.width
          spacing: Config.scaledSize(8)
          QuickControlTile { icon: Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected; title: "Wi-Fi"; subtitle: root.wifiSubtitle(); active: Networking.wifiEnabled; onToggled: root.toggleWifi(); onDetailsRequested: root.openPopup(root.wifiPopup) }
          QuickControlTile { icon: Config.iconBluetooth; title: "Bluetooth"; subtitle: root.bluetoothSubtitle(); active: root.adapter && root.adapter.enabled; onToggled: root.toggleBluetooth(); onDetailsRequested: root.openPopup(root.bluetoothPopup) }
        }
        Row {
          width: parent.width
          spacing: Config.scaledSize(8)
          QuickControlTile { icon: Config.iconNotificationsActive; title: "Не беспокоить"; subtitle: NotificationService.doNotDisturb ? "Включено" : "Выключено"; active: NotificationService.doNotDisturb; onToggled: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb); onDetailsRequested: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb) }
          QuickControlTile { icon: Config.iconCoffee; title: "Не спать"; subtitle: root.caffeineEnabled ? "Включено" : "Выключено"; active: root.caffeineEnabled; onToggled: root.toggleCaffeine(); onDetailsRequested: root.toggleCaffeine() }
        }
        QuickControlTile { wide: true; icon: "󰹑"; title: "Снимок экрана"; subtitle: "Полный снимок экрана"; onToggled: root.takeScreenshot(); onDetailsRequested: root.takeScreenshot() }
      }

      Column {
        width: parent.width
        spacing: Config.scaledSize(8)
        QuickControlSlider { width: parent.width; value: root.sinkMuted ? 0 : root.sinkVolume; minimumIcon: root.volumeIcon(); onValueEdited: value => root.setAudio("set-sink-volume", value) }
        QuickControlSlider { width: parent.width; value: root.brightnessPercent; minimumIcon: root.brightnessIcon(); onValueEdited: value => root.setBrightness(value) }
      }

      Rectangle {
        width: parent.width; height: Config.scaledSize(62); radius: Config.cardRadius; color: Config.searchBg; border.color: Config.borderColor; border.width: 1
        Rectangle {
          width: Config.scaledSize(40); height: Config.scaledSize(40); radius: Config.popupRadiusPx(9); anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(11); anchors.verticalCenter: parent.verticalCenter; clip: true; color: Config.selectedBg
          Image { anchors.fill: parent; source: root.mediaArtUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; visible: root.mediaArtUrl.length > 0 }
          Text { anchors.centerIn: parent; visible: root.mediaArtUrl.length === 0; text: Config.iconMusic; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
        }
        Column {
          anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(62); anchors.right: mediaControls.left; anchors.rightMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; spacing: Config.scaledSize(3)
          Text { width: parent.width; text: root.hasMedia ? (root.mediaTitle || "Музыка") : "Музыка"; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.hasMedia ? (root.mediaArtist || "Неизвестный исполнитель") : "Нет активного плеера"; color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
        }
        Row {
          id: mediaControls
          anchors.right: parent.right; anchors.rightMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; spacing: Config.scaledSize(4)
          Rectangle {
            width: Config.scaledSize(30); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: prevMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
            Text { anchors.centerIn: parent; text: Config.iconPrevTrack; color: root.hasMedia ? Config.textPrimary : Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: MprisController.previousOrRewind() }
          }
          Rectangle {
            width: Config.scaledSize(30); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: mediaMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
            Text { anchors.centerIn: parent; text: root.isPlaying ? Config.iconPause : Config.iconPlay; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: mediaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.mediaPlayer && root.mediaPlayer.canTogglePlaying) root.mediaPlayer.togglePlaying() }
          }
          Rectangle {
            width: Config.scaledSize(30); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: nextMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
            Text { anchors.centerIn: parent; text: Config.iconNextTrack; color: root.hasMedia ? Config.textPrimary : Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: MprisController.next() }
          }
        }
      }
    }
  }
}
