//@ pragma UseQApplication
// shell.qml - Quickshell Main Entry Point
import Quickshell
import QtQuick
import Quickshell.Io
import "Common"
import "Services"
import "Widgets"

Scope {
  id: root

  Process {
    id: loadSettingsProc
    command: [Config.natonctl, "settings"]
    running: true

    stdout: SplitParser {
      onRead: data => root.applySettings(data)
    }
  }

  Connections {
    target: SettingsStore
    function onReloaded() {
      if (!SettingsStore.parseError) root.applySettings(SettingsStore.snapshot())
    }
  }

  IpcHandler {
    target: "shell"
    function reload() { Quickshell.reload(false) }
  }

  function applySettings(data) {
    try {
      let settings = typeof data === "string" ? JSON.parse(data) : data
      if (settings.themeName) Config.themeName = settings.themeName
      if (typeof settings.dynamicDark === "string") Config.dynamicDark = settings.dynamicDark === "true"
      if (settings.fontFamily) Config.fontFamily = settings.fontFamily
      if (settings.fontMonoFamily) Config.fontMonoFamily = settings.fontMonoFamily
      if (settings.fontScale) Config.fontScale = parseFloat(settings.fontScale)
      if (settings.fontMonoScale) Config.fontMonoScale = parseFloat(settings.fontMonoScale)
      if (settings.wallpaperDir) Config.wallpaperDir = settings.wallpaperDir
      if (settings.wallpaperFillMode) Config.wallpaperFillMode = settings.wallpaperFillMode
      if (settings.wallpaperTransition) Config.wallpaperTransition = settings.wallpaperTransition
      if (settings.wallpaperPaletteScheme) Config.wallpaperPaletteScheme = settings.wallpaperPaletteScheme
      if (typeof settings.wallpaperCyclingEnabled === "string") Config.wallpaperCyclingEnabled = settings.wallpaperCyclingEnabled === "true"
      if (settings.wallpaperCyclingInterval) Config.wallpaperCyclingInterval = parseInt(settings.wallpaperCyclingInterval)
      if (typeof settings.blurWallpaperOnOverview === "string") Config.blurWallpaperOnOverview = settings.blurWallpaperOnOverview === "true"
      if (typeof settings.videoWallpaperAudio === "string") Config.videoWallpaperAudio = settings.videoWallpaperAudio === "true"
      if (settings.videoWallpaperVolume) Config.videoWallpaperVolume = parseInt(settings.videoWallpaperVolume)
      if (typeof settings.videoWallpaperHwdec === "string") Config.videoWallpaperHwdec = settings.videoWallpaperHwdec === "true"
      if (typeof settings.videoWallpaperPauseOnOverview === "string") Config.videoWallpaperPauseOnOverview = settings.videoWallpaperPauseOnOverview === "true"
      if (typeof settings.weatherLocation === "string") Config.weatherLocation = settings.weatherLocation
      if (settings.dynamicAccent) Config.dynamicAccent = settings.dynamicAccent
      if (settings.dynamicPalette) {
        try { Config.applyDynamicPalette(JSON.parse(settings.dynamicPalette)) } catch(e) {}
      }
      if (settings.manualPalette) {
        try { Config.manualPalette = JSON.parse(settings.manualPalette) } catch(e) {}
      }
      if (Config.themeName === "manual") Config.applyManualPalette()
      if (settings.activeTheme) {
        try {
          let theme = JSON.parse(settings.activeTheme)
          Config.activePresetFile = settings.activePresetFile || ""
          Config.activeTheme = theme
          Config.applyTheme(theme)
        } catch(e) {}
      }
      if (settings.timeFormat) Config.timeFormat = settings.timeFormat
      if (settings.uiScale) Config.uiScale = parseFloat(settings.uiScale)
      if (settings.language) Config.language = settings.language
      if (typeof settings.showSeconds === "string") Config.showSeconds = settings.showSeconds === "true"
      if (typeof settings.tooltipsEnabled === "string") Config.tooltipsEnabled = settings.tooltipsEnabled === "true"
      if (typeof settings.weatherEnabled === "string") Config.weatherEnabled = settings.weatherEnabled === "true"
      if (typeof settings.weatherTenths === "string") Config.weatherTenths = settings.weatherTenths === "true"
      if (typeof settings.barDateTimeEnabled === "string") Config.barDateTimeEnabled = settings.barDateTimeEnabled === "true"
      if (typeof settings.barDateEnabled === "string") Config.barDateEnabled = settings.barDateEnabled === "true"
      if (typeof settings.barWeatherEnabled === "string") Config.barWeatherEnabled = settings.barWeatherEnabled === "true"
      if (typeof settings.barColorPickerEnabled === "string") Config.barColorPickerEnabled = settings.barColorPickerEnabled === "true"
      if (typeof settings.barWorkspacesEnabled === "string") Config.barWorkspacesEnabled = settings.barWorkspacesEnabled === "true"
      if (typeof settings.barLauncherEnabled === "string") Config.barLauncherEnabled = settings.barLauncherEnabled === "true"
      if (typeof settings.launcherIconSvg === "string") Config.launcherIconSvg = settings.launcherIconSvg
      if (typeof settings.barActiveAppEnabled === "string") Config.barActiveAppEnabled = settings.barActiveAppEnabled === "true"
      if (typeof settings.barMediaEnabled === "string") Config.barMediaEnabled = settings.barMediaEnabled === "true"
      if (typeof settings.barTrayEnabled === "string") Config.barTrayEnabled = settings.barTrayEnabled === "true"
      if (typeof settings.barKeyboardLayoutEnabled === "string") Config.barKeyboardLayoutEnabled = settings.barKeyboardLayoutEnabled === "true"
      if (typeof settings.barSystemEnabled === "string") Config.barSystemEnabled = settings.barSystemEnabled === "true"
      if (typeof settings.barSysCpuEnabled === "string") Config.barSysCpuEnabled = settings.barSysCpuEnabled === "true"
      if (typeof settings.barSysCpuTempEnabled === "string") Config.barSysCpuTempEnabled = settings.barSysCpuTempEnabled === "true"
      if (typeof settings.barSysGpuEnabled === "string") Config.barSysGpuEnabled = settings.barSysGpuEnabled === "true"
      if (typeof settings.barSysGpuTempEnabled === "string") Config.barSysGpuTempEnabled = settings.barSysGpuTempEnabled === "true"
      if (typeof settings.barSysRamEnabled === "string") Config.barSysRamEnabled = settings.barSysRamEnabled === "true"
      if (typeof settings.barSysNetEnabled === "string") Config.barSysNetEnabled = settings.barSysNetEnabled === "true"
      if (typeof settings.barNotificationsEnabled === "string") Config.barNotificationsEnabled = settings.barNotificationsEnabled === "true"
      if (typeof settings.barVolumeEnabled === "string") Config.barVolumeEnabled = settings.barVolumeEnabled === "true"
      if (typeof settings.barBrightnessEnabled === "string") Config.barBrightnessEnabled = settings.barBrightnessEnabled === "true"
      if (typeof settings.barBatteryEnabled === "string") Config.barBatteryEnabled = settings.barBatteryEnabled === "true"
      if (typeof settings.barBluetoothEnabled === "string") Config.barBluetoothEnabled = settings.barBluetoothEnabled === "true"
      if (typeof settings.barNetworkEnabled === "string") Config.barNetworkEnabled = settings.barNetworkEnabled === "true"
      else if (typeof settings.barEthernetEnabled === "string" || typeof settings.barWifiEnabled === "string") Config.barNetworkEnabled = (settings.barEthernetEnabled !== "false" || settings.barWifiEnabled !== "false")
      if (typeof settings.barControlCenterEnabled === "string") Config.barControlCenterEnabled = settings.barControlCenterEnabled === "true"
      if (typeof settings.barVpnEnabled === "string") Config.barVpnEnabled = settings.barVpnEnabled === "true"
      if (typeof settings.barPowerEnabled === "string") Config.barPowerEnabled = settings.barPowerEnabled === "true"
      if (settings.brightnessMonitorBus) Config.brightnessMonitorBus = settings.brightnessMonitorBus
      if (settings.brightnessSleepMultiplier) Config.brightnessSleepMultiplier = settings.brightnessSleepMultiplier
      if (typeof settings.shellBlurEnabled === "string") Config.shellBlurEnabled = settings.shellBlurEnabled === "true"
      if (typeof settings.barBlurEnabled === "string") Config.barBlurEnabled = settings.barBlurEnabled === "true"
      else if (typeof settings.shellBlurEnabled === "string") Config.barBlurEnabled = settings.shellBlurEnabled === "true"
      if (typeof settings.barAdaptive === "string") Config.barAdaptive = settings.barAdaptive === "true"
      if (typeof settings.popupBlurEnabled === "string") Config.popupBlurEnabled = settings.popupBlurEnabled === "true"
      else if (typeof settings.shellBlurEnabled === "string") Config.popupBlurEnabled = settings.shellBlurEnabled === "true"
      if (typeof settings.shellBordersEnabled === "string") Config.shellBordersEnabled = settings.shellBordersEnabled === "true"
      if (typeof settings.barBordersEnabled === "string") Config.barBordersEnabled = settings.barBordersEnabled === "true"
      if (typeof settings.popupBordersEnabled === "string") Config.popupBordersEnabled = settings.popupBordersEnabled === "true"
      if (typeof settings.shellShadowsEnabled === "string") Config.shellShadowsEnabled = settings.shellShadowsEnabled === "true"
      if (typeof settings.barShadowsEnabled === "string") Config.barShadowsEnabled = settings.barShadowsEnabled === "true"
      else if (typeof settings.shellShadowsEnabled === "string") Config.barShadowsEnabled = settings.shellShadowsEnabled === "true"
      if (typeof settings.popupShadowsEnabled === "string") Config.popupShadowsEnabled = settings.popupShadowsEnabled === "true"
      else if (typeof settings.shellShadowsEnabled === "string") Config.popupShadowsEnabled = settings.shellShadowsEnabled === "true"
      if (typeof settings.doNotDisturb === "string") Config.doNotDisturb = settings.doNotDisturb === "true"
      if (settings.notificationPosition) Config.notificationPosition = settings.notificationPosition
      if (settings.notificationTimeoutMs) Config.notificationTimeoutMs = parseInt(settings.notificationTimeoutMs)
      if (settings.notificationMaxVisible) Config.notificationMaxVisible = parseInt(settings.notificationMaxVisible)
      if (typeof settings.notificationSoundEnabled === "string") Config.notificationSoundEnabled = settings.notificationSoundEnabled === "true"
      if (typeof settings.notificationMutedApps === "string") Config.notificationMutedApps = settings.notificationMutedApps
      if (settings.controlCenterTiles) Config.controlCenterTiles = settings.controlCenterTiles
      if (settings.idleTimeoutMinutes) Config.idleTimeoutMinutes = parseInt(settings.idleTimeoutMinutes)
      if (settings.idleAction) Config.idleAction = settings.idleAction
      if (settings.osdPosition) Config.osdPosition = settings.osdPosition
      if (typeof settings.showWorkspaceNumbers === "string") Config.showWorkspaceNumbers = settings.showWorkspaceNumbers === "true"
      if (typeof settings.showWorkspacesOnAllMonitors === "string") Config.showWorkspacesOnAllMonitors = settings.showWorkspacesOnAllMonitors === "true"
      if (settings.workspaceIndicatorStyle) Config.workspaceIndicatorStyle = settings.workspaceIndicatorStyle
      if (typeof settings.reduceMotion === "string") Config.reduceMotion = settings.reduceMotion === "true"
      if (settings.barPosition) Config.barPosition = settings.barPosition
      if (settings.barStyle) Config.barStyle = settings.barStyle
      if (typeof settings.barAutoHide === "string") Config.barAutoHide = settings.barAutoHide === "true"
      if (settings.barAutoHideDelay) Config.barAutoHideDelay = parseInt(settings.barAutoHideDelay)
      if (settings.settingsCloseKeybind) Config.settingsCloseKeybind = settings.settingsCloseKeybind
      if (settings.keybindDrawer) Config.keybindDrawer = settings.keybindDrawer
      if (settings.keybindSettings) Config.keybindSettings = settings.keybindSettings
      if (settings.keybindClipboard) Config.keybindClipboard = settings.keybindClipboard
      if (settings.keybindNotifications) Config.keybindNotifications = settings.keybindNotifications
      if (settings.keybindPower) Config.keybindPower = settings.keybindPower
      if (settings.keybindControlCenter) Config.keybindControlCenter = settings.keybindControlCenter
      if (settings.keybindCalendar) Config.keybindCalendar = settings.keybindCalendar
      if (settings.keybindMedia) Config.keybindMedia = settings.keybindMedia
      if (settings.keybindWiFi) Config.keybindWiFi = settings.keybindWiFi
      if (settings.keybindBluetooth) Config.keybindBluetooth = settings.keybindBluetooth
      if (settings.keybindBrightness) Config.keybindBrightness = settings.keybindBrightness
      if (settings.keybindKeyboard) Config.keybindKeyboard = settings.keybindKeyboard
      if (settings.keybindSystem) Config.keybindSystem = settings.keybindSystem
      if (settings.barThickness) Config.barThickness = parseInt(settings.barThickness)
      if (typeof settings.barTopMargin === "string") Config.barTopMargin = parseInt(settings.barTopMargin)
      if (typeof settings.barBottomMargin === "string") Config.barBottomMargin = parseInt(settings.barBottomMargin)
      if (settings.barHorizontalMargin) Config.barHorizontalMargin = parseInt(settings.barHorizontalMargin)
      if (settings.barRadius) Config.barRadius = parseInt(settings.barRadius)
      if (settings.barRadiusMode) Config.barRadiusMode = settings.barRadiusMode
      if (settings.barWidgetRadius) Config.barWidgetRadius = parseInt(settings.barWidgetRadius)
      if (settings.barFrostOpacity) Config.barFrostOpacity = parseInt(settings.barFrostOpacity)
      if (settings.popupVerticalAlign) Config.popupVerticalAlign = settings.popupVerticalAlign
      if (settings.popupRadius) Config.popupRadius = parseInt(settings.popupRadius)
      if (settings.popupRadiusMode) Config.popupRadiusMode = settings.popupRadiusMode
      if (settings.popupWidgetRadius) Config.popupWidgetRadius = parseInt(settings.popupWidgetRadius)
      if (settings.popupBackgroundOpacity) Config.popupBackgroundOpacity = parseInt(settings.popupBackgroundOpacity)
    } catch(e) {}
  }

  function closePopups() {
    drawer.isOpen = false
    calendar.isOpen = false
    controlCenter.isOpen = false
    brightness.isOpen = false
    wifi.isOpen = false
    bluetooth.isOpen = false
    audio.isOpen = false
    battery.isOpen = false
    notifications.isOpen = false
    trayMenu.isOpen = false
    keyboardLayout.isOpen = false
    power.isOpen = false
    system.isOpen = false
    media.isOpen = false
    clipboard.isOpen = false
  }

  Shortcut {
    sequence: "Esc"
    enabled: (drawer.isOpen || calendar.isOpen || controlCenter.isOpen || brightness.isOpen || wifi.isOpen || bluetooth.isOpen || audio.isOpen || battery.isOpen || notifications.isOpen || trayMenu.isOpen || keyboardLayout.isOpen || power.isOpen || system.isOpen || media.isOpen || clipboard.isOpen) && !(controlCenter.isOpen && controlCenter.settingsView)
    onActivated: root.closePopups()
  }


  // Main Top Bar Panel
  Bar {
    appDrawer: drawer
    calendarPopup: calendar
    controlCenterPopup: controlCenter
    brightnessPopup: brightness
    wifiPopup: wifi
    bluetoothPopup: bluetooth
    audioPopup: audio
    batteryPopup: battery
    notificationPopup: notifications
    trayMenuPopup: trayMenu
    keyboardLayoutPopup: keyboardLayout
    powerPopup: power
    systemPopup: system
    mediaPopup: media
    osd: osd
  }

  WallpaperCyclingService { }
  WallpaperOverviewService { }
  Component.onCompleted: IdlePolicyService.restart()
  ClipboardPopup { id: clipboard }

  // Application Drawer Overlay
  AppDrawer {
    id: drawer
  }

  // Calendar Overlay
  CalendarPopup {
    id: calendar
    tooltip: calendarTooltip
  }

  Tooltip {
    id: calendarTooltip
    screenInfo: calendar.screen
  }

  // Display Brightness Control Overlay
  ControlCenterPopup {
    id: controlCenter
    audioPopup: audio
    osd: osd
    wifiPopup: wifi
    bluetoothPopup: bluetooth
    batteryPopup: battery
    powerPopup: power
  }

  BrightnessPopup {
    id: brightness
    osd: osd
  }

  WiFiPopup {
    id: wifi
  }

  BluetoothPopup {
    id: bluetooth
  }

  AudioPopup {
    id: audio
    osd: osd
  }

  BatteryPopup {
    id: battery
  }

  NotificationPopup {
    id: notifications
  }

  TrayMenuPopup {
    id: trayMenu
  }

  KeyboardLayoutPopup {
    id: keyboardLayout
  }

  PowerPopup {
    id: power
  }

  SystemPopup {
    id: system
  }

  MediaPopup {
    id: media
  }

  Osd {
    id: osd
  }
}
