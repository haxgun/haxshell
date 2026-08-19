// ControlCenterPopup.qml - quick controls using the settings surface style
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import "../../Common"
import "../../Widgets"
import "../../Services"
import "../../"

PanelWindow {
  id: root

  property bool isOpen: false
  property bool settingsView: false
  property int rightMargin: Config.scaledSize(16)
  property var osd: null
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

  readonly property string natonctl: Config.natonctl
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
    function toggle() { root.isOpen = !root.isOpen; root.settingsView = false }
    function open() { root.isOpen = true; root.settingsView = false }
    function close() { root.isOpen = false; root.settingsView = false }
    function focus(section: string) { root.activeSection = section || "wifi"; root.isOpen = true; root.settingsView = false }
  }

  IpcHandler {
    target: "settings"
    function toggle() {
      root.settingsView = !root.settingsView
      root.isOpen = true
    }
    function open() { root.settingsView = true; root.isOpen = true }
    function close() { root.settingsView = false; root.isOpen = false }
  }

  IpcHandler {
    target: "wifi"
    function toggle() { root.openSettingsSection("wifi") }
    function open() { root.openSettingsSection("wifi") }
    function close() { root.isOpen = false }
  }

  IpcHandler {
    target: "bluetooth"
    function toggle() { root.openSettingsSection("bluetooth") }
    function open() { root.openSettingsSection("bluetooth") }
    function close() { root.isOpen = false }
  }

  IpcHandler {
    target: "brightness"
    function toggle() { root.openSettingsSection("brightness") }
    function open() { root.openSettingsSection("brightness") }
    function close() { root.isOpen = false }
  }

  IpcHandler {
    target: "audio"
    function toggle() { root.openSettingsSection("audio") }
    function open() { root.openSettingsSection("audio") }
    function close() { root.isOpen = false }
  }

  IpcHandler {
    target: "battery"
    function toggle() { root.openSettingsSection("battery") }
    function open() { root.openSettingsSection("battery") }
    function close() { root.isOpen = false }
  }

  Shortcut {
    sequence: Config.settingsCloseKeybind
    enabled: root.isOpen && root.settingsView
    onActivated: root.isOpen = false
  }

  Shortcut { sequence: "Ctrl+Tab"; enabled: root.isOpen && root.settingsView; onActivated: settingsEmbedded.selectRelativeCategory(1) }
  Shortcut { sequence: "Ctrl+Shift+Tab"; enabled: root.isOpen && root.settingsView; onActivated: settingsEmbedded.selectRelativeCategory(-1) }
  Shortcut { sequence: "Alt+Right"; enabled: root.isOpen && root.settingsView; onActivated: settingsEmbedded.selectRelativePage(1) }
  Shortcut { sequence: "Alt+Left"; enabled: root.isOpen && root.settingsView; onActivated: settingsEmbedded.selectRelativePage(-1) }

  onIsOpenChanged: if (isOpen) {
    refreshAll()
    if (wifiDevice) wifiDevice.scannerEnabled = true
    if (adapter && adapter.enabled) adapter.discovering = true
  } else {
    root.settingsView = false
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
    command: [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: root.isOpen
    stdout: SplitParser { onRead: data => root.applyBrightnessState(data) }
  }

  Process {
    id: audioProc
    command: [root.natonctl, "audio", "get"]
    running: root.isOpen
    stdout: SplitParser { onRead: data => root.applyAudioState(data) }
  }

  Process {
    id: batteryProc
    command: [root.natonctl, "battery"]
    running: root.isOpen
    stdout: SplitParser { onRead: data => root.applyBatteryState(data) }
  }

  Process {
    id: caffeineProc
    command: [root.natonctl, "caffeine", "state"]
    running: root.isOpen
    stdout: SplitParser { onRead: data => root.applyCaffeineState(data) }
  }

  Process {
    id: actionProc
  }

  Process {
    id: screenshotProc
  }

  Process {
    id: nightLightDetectProc
    command: ["sh", "-lc", "command -v wlsunset >/dev/null && printf wlsunset"]
    running: root.isOpen
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

  function refreshBrightness() { restart(brightnessProc, [natonctl, "brightness", "get", activeBrightnessBus, Config.brightnessSleepMultiplier]) }
  function refreshAudio() { restart(audioProc, [natonctl, "audio", "get"]) }
  function refreshBattery() { restart(batteryProc, [natonctl, "battery"]) }
  function refreshCaffeine() { restart(caffeineProc, [natonctl, "caffeine", "state"]) }

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
    run([natonctl, "brightness", "set", target.toString(), activeBrightnessBus, Config.brightnessSleepMultiplier])
  }
  function setAudio(action, value) {
    if (osd) osd.suppressOnce()
    if (action === "set-sink-volume") sinkVolume = Math.max(0, Math.min(100, Math.round(value)))
    if (action === "set-sink-mute") sinkMuted = value.toString() === "1"
    run([natonctl, "audio", action, value.toString()])
  }
  function openPopup(popup) {
    if (!popup) return
    popup.rightMargin = rightMargin
    popup.isOpen = true
    isOpen = false
  }
  function openSettings() {
    root.settingsView = true
    settingsEmbedded.openSectionList()
  }
  function openSettingsSection(section) {
    root.settingsView = true
    root.activeSection = section
    root.isOpen = true
    settingsEmbedded.openSectionList()
    settingsEmbedded.sectionListVisible = false
    settingsEmbedded.selectSection(section)
  }
  function closeSettings() {
    root.settingsView = false
  }
  function toggleCaffeine() { restart(caffeineProc, [natonctl, "caffeine", "toggle"]) }
  function cyclePowerProfile() {
    let profiles = ["power-saver", "balanced", "performance"]
    let next = profiles[(profiles.indexOf(powerProfile) + 1) % profiles.length]
    restart(batteryProc, [natonctl, "battery", "set-profile", next])
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
    run(["sh", "-lc", nightLightEnabled ? "pkill wlsunset; wlsunset -t 3500" : "pkill wlsunset"])
  }
  function toggleTheme() {
    let theme = Config.isLightTheme ? "dark" : "light"
    Config.themeName = theme
    SettingsStore.setValue("themeName", theme)
  }
  function takeScreenshot() {
    root.isOpen = false
    screenshotProc.running = false
    screenshotProc.command = [
      "sh", "-c",
      "sleep 0.25; region=$(slurp) || exit 0; [ -n \"$region\" ] || exit 0; dir=${XDG_PICTURES_DIR:-$HOME/Pictures}; mkdir -p \"$dir\"; file=\"$dir/Screenshot-$(date +%Y%m%d-%H%M%S).png\"; grim -g \"$region\" \"$file\" && wl-copy --type image/png < \"$file\""
    ]
    screenshotProc.running = true
  }
  function normalizeArtUrl(value) {
    let url = (value || "").trim()
    if (url.length === 0) return ""
    return url.indexOf("/") === 0 ? "file://" + url : url
  }
  function wifiSubtitle() { return !Networking.wifiEnabled ? I18n.tr("cc.off") : (connectedNetworkName || I18n.tr("cc.notConnected")) }
  function bluetoothSubtitle() { return !adapter || !adapter.enabled ? I18n.tr("cc.off") : (connectedDeviceName || I18n.tr("cc.on")) }
  function profileName(profile) { return profile === "power-saver" ? I18n.tr("cc.powerSaver") : (profile === "performance" ? I18n.tr("cc.performance") : I18n.tr("cc.balanced")) }
  function profileIcon(profile) { return profile === "power-saver" ? Config.iconPowerSaver : (profile === "performance" ? Config.iconPerformance : Config.iconBalanced) }
  function volumeIcon() { return sinkMuted ? Config.iconVolMuted : (sinkVolume >= 70 ? Config.iconVolHigh : (sinkVolume >= 30 ? Config.iconVolMedium : Config.iconVolLow)) }
  function brightnessIcon() { return brightnessPercent >= 75 ? Config.iconBrightHigh : (brightnessPercent >= 35 ? Config.iconBrightMedium : (brightnessPercent > 0 ? Config.iconBrightLow : Config.iconBrightOff)) }
  function visibleTiles() { return Config.controlCenterTiles.split(",").map(tile => tile.trim()).filter(tile => ["wifi", "bluetooth", "airplane", "dnd", "caffeine", "screenshot", "power", "nightlight"].indexOf(tile) >= 0) }
  function tileIcon(tile) { return tile === "wifi" ? (Networking.wifiEnabled ? Config.iconWifiConnected : Config.iconWifiDisconnected) : (tile === "bluetooth" ? Config.iconBluetooth : (tile === "airplane" ? Config.iconAirplane : (tile === "dnd" ? Config.iconNotificationsActive : (tile === "caffeine" ? Config.iconCoffee : (tile === "power" ? profileIcon(powerProfile) : (tile === "nightlight" ? Config.iconNightLight : "󰹑")))))) }
  function tileTitle(tile) { return tile === "wifi" ? "Wi-Fi" : (tile === "bluetooth" ? "Bluetooth" : (tile === "airplane" ? I18n.tr("cc.airplane") : (tile === "dnd" ? I18n.tr("cc.dnd") : (tile === "caffeine" ? I18n.tr("cc.caffeine") : (tile === "power" ? I18n.tr("cc.powerProfile") : (tile === "nightlight" ? I18n.tr("cc.nightLight") : I18n.tr("cc.screenshot"))))))) }
  function tileSubtitle(tile) { return tile === "wifi" ? wifiSubtitle() : (tile === "bluetooth" ? bluetoothSubtitle() : (tile === "airplane" ? (airplaneModeEnabled ? I18n.tr("cc.on") : I18n.tr("common.off")) : (tile === "dnd" ? (NotificationService.doNotDisturb ? I18n.tr("cc.on") : I18n.tr("common.off")) : (tile === "caffeine" ? (caffeineEnabled ? I18n.tr("cc.on") : I18n.tr("common.off")) : (tile === "power" ? profileName(powerProfile) : (tile === "nightlight" ? (nightLightEnabled ? I18n.tr("cc.on") : I18n.tr("common.off")) : I18n.tr("cc.selectRegion"))))))) }
  function tileActive(tile) { return tile === "wifi" ? Networking.wifiEnabled : (tile === "bluetooth" ? !!(adapter && adapter.enabled) : (tile === "airplane" ? airplaneModeEnabled : (tile === "dnd" ? NotificationService.doNotDisturb : (tile === "caffeine" ? caffeineEnabled : (tile === "power" ? true : (tile === "nightlight" ? nightLightEnabled : false)))))) }
  function activateTile(tile) { if (tile === "wifi") toggleWifi(); else if (tile === "bluetooth") toggleBluetooth(); else if (tile === "airplane") toggleAirplaneMode(); else if (tile === "dnd") NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb); else if (tile === "caffeine") toggleCaffeine(); else if (tile === "power") cyclePowerProfile(); else if (tile === "nightlight") toggleNightLight(); else takeScreenshot() }
  function tileDetailsRequested(tile) {
    if (tile === "wifi" || tile === "bluetooth" || tile === "battery") {
      root.openSettingsSection(tile)
    } else {
      root.activateTile(tile)
    }
  }

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
    clip: true

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    SettingsPopup {
      id: settingsEmbedded
      width: parent.width
      height: parent.height
      x: root.settingsView ? 0 : parent.width
      isOpen: root.isOpen
      rightMargin: 0
      opacity: root.isOpen ? 1.0 : 0.0
      Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      onBackRequested: root.closeSettings()
      onHideRequested: root.isOpen = false
      onShowRequested: root.isOpen = true
    }

    Column {
      id: content
      width: parent.width - 28
      x: Config.scaledSize(14) - (root.settingsView ? parent.width : 0)
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      spacing: Config.scaledSize(8)
      Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

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
          MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openSettings() }
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

      Flow {
        width: parent.width
        spacing: Config.scaledSize(8)
        Repeater { model: root.visibleTiles(); QuickControlTile { required property string modelData; icon: root.tileIcon(modelData); title: root.tileTitle(modelData); subtitle: root.tileSubtitle(modelData); active: root.tileActive(modelData); showChevron: modelData === "wifi" || modelData === "bluetooth"; onToggled: root.activateTile(modelData); onDetailsRequested: root.tileDetailsRequested(modelData) } }
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
          Text { width: parent.width; text: root.hasMedia ? (root.mediaTitle || I18n.tr("cc.music")) : I18n.tr("cc.music"); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
          Text { width: parent.width; text: root.hasMedia ? (root.mediaArtist || I18n.tr("cc.unknownArtist")) : I18n.tr("cc.noPlayer"); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
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
