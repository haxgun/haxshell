//@ pragma UseQApplication
// shell.qml - Quickshell Main Entry Point
import Quickshell
import QtQuick
import Quickshell.Io
import "Common"
import "Services"

Scope {
  id: root

  Process {
    id: loadSettingsProc
    command: [Config.veyctl, "settings"]
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

  function applySettings(data) {
    try {
      let settings = typeof data === "string" ? JSON.parse(data) : data
      if (settings.themeName) Config.themeName = settings.themeName
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
      if (typeof settings.weatherLocation === "string") Config.weatherLocation = settings.weatherLocation
      if (settings.dynamicAccent) Config.dynamicAccent = settings.dynamicAccent
      if (settings.dynamicPalette) {
        try { Config.applyDynamicPalette(JSON.parse(settings.dynamicPalette)) } catch(e) {}
      }
      if (settings.manualAccent) Config.manualAccent = settings.manualAccent
      if (typeof settings.manualDark === "string") Config.manualDark = settings.manualDark === "true"
      if (settings.timeFormat) Config.timeFormat = settings.timeFormat
      if (settings.uiScale) Config.uiScale = parseFloat(settings.uiScale)
      if (settings.language) Config.language = settings.language
      if (typeof settings.showSeconds === "string") Config.showSeconds = settings.showSeconds === "true"
      if (typeof settings.weatherEnabled === "string") Config.weatherEnabled = settings.weatherEnabled === "true"
      if (typeof settings.barDateTimeEnabled === "string") Config.barDateTimeEnabled = settings.barDateTimeEnabled === "true"
      if (typeof settings.barWeatherEnabled === "string") Config.barWeatherEnabled = settings.barWeatherEnabled === "true"
      if (typeof settings.barColorPickerEnabled === "string") Config.barColorPickerEnabled = settings.barColorPickerEnabled === "true"
      if (typeof settings.barWorkspacesEnabled === "string") Config.barWorkspacesEnabled = settings.barWorkspacesEnabled === "true"
      if (typeof settings.barLauncherEnabled === "string") Config.barLauncherEnabled = settings.barLauncherEnabled === "true"
      if (typeof settings.barActiveAppEnabled === "string") Config.barActiveAppEnabled = settings.barActiveAppEnabled === "true"
      if (typeof settings.barMediaEnabled === "string") Config.barMediaEnabled = settings.barMediaEnabled === "true"
      if (typeof settings.barTrayEnabled === "string") Config.barTrayEnabled = settings.barTrayEnabled === "true"
      if (typeof settings.barKeyboardLayoutEnabled === "string") Config.barKeyboardLayoutEnabled = settings.barKeyboardLayoutEnabled === "true"
      if (typeof settings.barSystemEnabled === "string") Config.barSystemEnabled = settings.barSystemEnabled === "true"
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
      if (settings.osdPosition) Config.osdPosition = settings.osdPosition
      if (typeof settings.showWorkspaceNumbers === "string") Config.showWorkspaceNumbers = settings.showWorkspaceNumbers === "true"
      if (typeof settings.showWorkspacesOnAllMonitors === "string") Config.showWorkspacesOnAllMonitors = settings.showWorkspacesOnAllMonitors === "true"
      if (settings.workspaceIndicatorStyle) Config.workspaceIndicatorStyle = settings.workspaceIndicatorStyle
      if (typeof settings.reduceMotion === "string") Config.reduceMotion = settings.reduceMotion === "true"
      if (settings.barPosition) Config.barPosition = settings.barPosition
      if (settings.barThickness) Config.barThickness = parseInt(settings.barThickness)
      if (typeof settings.barTopMargin === "string") Config.barTopMargin = parseInt(settings.barTopMargin)
      if (typeof settings.barBottomMargin === "string") Config.barBottomMargin = parseInt(settings.barBottomMargin)
      if (settings.barHorizontalMargin) Config.barHorizontalMargin = parseInt(settings.barHorizontalMargin)
      if (settings.barRadius) Config.barRadius = parseInt(settings.barRadius)
      if (settings.barFrostOpacity) Config.barFrostOpacity = parseInt(settings.barFrostOpacity)
      if (settings.popupVerticalAlign) Config.popupVerticalAlign = settings.popupVerticalAlign
      if (settings.popupRadius) Config.popupRadius = parseInt(settings.popupRadius)
      if (settings.popupBackgroundOpacity) Config.popupBackgroundOpacity = parseInt(settings.popupBackgroundOpacity)
    } catch(e) {}
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
    settingsPopup: settings
    powerPopup: power
    systemPopup: system
    mediaPopup: media
    osd: osd
  }

  WallpaperCyclingService { }
  WallpaperOverviewService { }

  // Application Drawer Overlay
  AppDrawer {
    id: drawer
  }

  // Calendar Overlay
  CalendarPopup {
    id: calendar
  }

  // Display Brightness Control Overlay
  ControlCenterPopup {
    id: controlCenter
    audioPopup: audio
    osd: osd
    wifiPopup: wifi
    bluetoothPopup: bluetooth
    batteryPopup: battery
    settingsPopup: settings
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

  SettingsPopup {
    id: settings
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
