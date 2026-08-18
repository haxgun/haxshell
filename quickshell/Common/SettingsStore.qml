pragma Singleton

// SettingsStore.qml - Persistent shell settings adapter

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/settings.json"
  property bool loaded: false
  property bool parseError: false

  property alias themeName: adapter.themeName
  property alias dynamicDark: adapter.dynamicDark
  property alias fontFamily: adapter.fontFamily
  property alias fontMonoFamily: adapter.fontMonoFamily
  property alias fontScale: adapter.fontScale
  property alias fontMonoScale: adapter.fontMonoScale
  property alias wallpaperDir: adapter.wallpaperDir
  property alias wallpaperFillMode: adapter.wallpaperFillMode
  property alias wallpaperTransition: adapter.wallpaperTransition
  property alias wallpaperPaletteScheme: adapter.wallpaperPaletteScheme
  property alias wallpaperCyclingEnabled: adapter.wallpaperCyclingEnabled
  property alias wallpaperCyclingInterval: adapter.wallpaperCyclingInterval
  property alias blurWallpaperOnOverview: adapter.blurWallpaperOnOverview
  property alias videoWallpaperAudio: adapter.videoWallpaperAudio
  property alias videoWallpaperVolume: adapter.videoWallpaperVolume
  property alias videoWallpaperHwdec: adapter.videoWallpaperHwdec
  property alias videoWallpaperPauseOnOverview: adapter.videoWallpaperPauseOnOverview
  property alias weatherLocation: adapter.weatherLocation
  property alias dynamicAccent: adapter.dynamicAccent
  property alias dynamicPalette: adapter.dynamicPalette
  property alias manualPalette: adapter.manualPalette
  property alias caffeineEnabled: adapter.caffeineEnabled
  property alias timeFormat: adapter.timeFormat
  property alias showSeconds: adapter.showSeconds
  property alias tooltipsEnabled: adapter.tooltipsEnabled
  property alias language: adapter.language
  property alias showWorkspaceNumbers: adapter.showWorkspaceNumbers
  property alias showWorkspacesOnAllMonitors: adapter.showWorkspacesOnAllMonitors
  property alias workspaceIndicatorStyle: adapter.workspaceIndicatorStyle
  property alias uiScale: adapter.uiScale
  property alias reduceMotion: adapter.reduceMotion
  property alias weatherEnabled: adapter.weatherEnabled
  property alias weatherTenths: adapter.weatherTenths
  property alias barDateTimeEnabled: adapter.barDateTimeEnabled
  property alias barWeatherEnabled: adapter.barWeatherEnabled
  property alias barColorPickerEnabled: adapter.barColorPickerEnabled
  property alias barWorkspacesEnabled: adapter.barWorkspacesEnabled
  property alias barLauncherEnabled: adapter.barLauncherEnabled
  property alias barActiveAppEnabled: adapter.barActiveAppEnabled
  property alias barMediaEnabled: adapter.barMediaEnabled
  property alias barTrayEnabled: adapter.barTrayEnabled
  property alias barKeyboardLayoutEnabled: adapter.barKeyboardLayoutEnabled
  property alias barSystemEnabled: adapter.barSystemEnabled
  property alias barSysCpuEnabled: adapter.barSysCpuEnabled
  property alias barSysCpuTempEnabled: adapter.barSysCpuTempEnabled
  property alias barSysGpuEnabled: adapter.barSysGpuEnabled
  property alias barSysGpuTempEnabled: adapter.barSysGpuTempEnabled
  property alias barSysRamEnabled: adapter.barSysRamEnabled
  property alias barSysNetEnabled: adapter.barSysNetEnabled
  property alias barNotificationsEnabled: adapter.barNotificationsEnabled
  property alias barVolumeEnabled: adapter.barVolumeEnabled
  property alias barBrightnessEnabled: adapter.barBrightnessEnabled
  property alias barBatteryEnabled: adapter.barBatteryEnabled
  property alias barBluetoothEnabled: adapter.barBluetoothEnabled
  property alias barNetworkEnabled: adapter.barNetworkEnabled
  property alias barControlCenterEnabled: adapter.barControlCenterEnabled
  property alias barVpnEnabled: adapter.barVpnEnabled
  property alias barPowerEnabled: adapter.barPowerEnabled
  property alias brightnessMonitorBus: adapter.brightnessMonitorBus
  property alias brightnessSleepMultiplier: adapter.brightnessSleepMultiplier
  property alias barPosition: adapter.barPosition
  property alias barStyle: adapter.barStyle
  property alias barAutoHide: adapter.barAutoHide
  property alias barAutoHideDelay: adapter.barAutoHideDelay
  property alias settingsCloseKeybind: adapter.settingsCloseKeybind
  property alias keybindDrawer: adapter.keybindDrawer
  property alias keybindSettings: adapter.keybindSettings
  property alias keybindClipboard: adapter.keybindClipboard
  property alias keybindNotifications: adapter.keybindNotifications
  property alias keybindPower: adapter.keybindPower
  property alias keybindControlCenter: adapter.keybindControlCenter
  property alias keybindCalendar: adapter.keybindCalendar
  property alias keybindMedia: adapter.keybindMedia
  property alias keybindWiFi: adapter.keybindWiFi
  property alias keybindBluetooth: adapter.keybindBluetooth
  property alias keybindBrightness: adapter.keybindBrightness
  property alias keybindKeyboard: adapter.keybindKeyboard
  property alias keybindSystem: adapter.keybindSystem
  property alias barThickness: adapter.barThickness
  property alias barTopMargin: adapter.barTopMargin
  property alias barBottomMargin: adapter.barBottomMargin
  property alias barHorizontalMargin: adapter.barHorizontalMargin
  property alias barRadius: adapter.barRadius
  property alias barRadiusMode: adapter.barRadiusMode
  property alias barWidgetRadius: adapter.barWidgetRadius
  property alias barFrostOpacity: adapter.barFrostOpacity
  property alias popupVerticalAlign: adapter.popupVerticalAlign
  property alias popupRadius: adapter.popupRadius
  property alias popupRadiusMode: adapter.popupRadiusMode
  property alias popupWidgetRadius: adapter.popupWidgetRadius
  property alias popupBackgroundOpacity: adapter.popupBackgroundOpacity
  property alias barAdaptive: adapter.barAdaptive
  property alias barBlurEnabled: adapter.barBlurEnabled
  property alias popupBlurEnabled: adapter.popupBlurEnabled
  property alias shellBlurEnabled: adapter.shellBlurEnabled
  property alias shellBordersEnabled: adapter.shellBordersEnabled
  property alias barBordersEnabled: adapter.barBordersEnabled
  property alias popupBordersEnabled: adapter.popupBordersEnabled
  property alias shellShadowsEnabled: adapter.shellShadowsEnabled
  property alias barShadowsEnabled: adapter.barShadowsEnabled
  property alias popupShadowsEnabled: adapter.popupShadowsEnabled
  property alias doNotDisturb: adapter.doNotDisturb
  property alias notificationPosition: adapter.notificationPosition
  property alias notificationTimeoutMs: adapter.notificationTimeoutMs
  property alias notificationMaxVisible: adapter.notificationMaxVisible
  property alias notificationSoundEnabled: adapter.notificationSoundEnabled
  property alias notificationMutedApps: adapter.notificationMutedApps
  property alias controlCenterTiles: adapter.controlCenterTiles
  property alias idleTimeoutMinutes: adapter.idleTimeoutMinutes
  property alias idleAction: adapter.idleAction
  property alias osdPosition: adapter.osdPosition

  signal reloaded()

  FileView {
    id: settingsFile
    path: root.settingsPath
    blockLoading: true
    blockWrites: true
    atomicWrites: true
    watchChanges: true
    printErrors: false

    onLoaded: {
      root.loaded = true
      root.parseError = false
      root.reloaded()
    }

    onLoadFailed: error => {
      root.loaded = true
      root.parseError = error !== 2
      if (error === 2) saveTimer.restart()
      root.reloaded()
    }

    onSaveFailed: error => root.parseError = true

    JsonAdapter {
      id: adapter
      property string themeName: "dark"
      property string dynamicDark: "true"
      property string fontFamily: "Geist Mono"
      property string fontMonoFamily: "Geist Mono"
      property string fontScale: "1.0"
      property string fontMonoScale: "1.0"
      property string wallpaperDir: "~/wallpapers/animated"
      property string wallpaperFillMode: "fill"
      property string wallpaperTransition: "fade"
      property string wallpaperPaletteScheme: "vibrant"
      property string wallpaperCyclingEnabled: "false"
      property string wallpaperCyclingInterval: "300"
      property string blurWallpaperOnOverview: "false"
      property string videoWallpaperAudio: "false"
      property string videoWallpaperVolume: "100"
      property string videoWallpaperHwdec: "true"
      property string videoWallpaperPauseOnOverview: "true"
      property string weatherLocation: ""
      property string dynamicAccent: "#e2e8f0"
      property string dynamicPalette: "[\"#e2e8f0\",\"#334155\",\"#64748b\",\"#94a3b8\"]"
      property string manualPalette: "[\"#282a36\",\"#ff5555\",\"#50fa7b\",\"#f1fa8c\",\"#bd93f9\",\"#ff79c6\",\"#8be9fd\",\"#f8f8f2\",\"#6272a4\",\"#ff6e6e\",\"#69ff94\",\"#ffffa5\",\"#d6acff\",\"#ff92df\",\"#a4ffff\",\"#ffffff\"]"
      property string caffeineEnabled: "false"
      property string timeFormat: "24"
      property string showSeconds: "false"
      property string tooltipsEnabled: "true"
      property string language: "ru"
      property string showWorkspaceNumbers: "true"
      property string showWorkspacesOnAllMonitors: "false"
      property string workspaceIndicatorStyle: "tint"
      property string uiScale: "1.0"
      property string reduceMotion: "false"
      property string weatherEnabled: "true"
      property string weatherTenths: "false"
      property string barDateTimeEnabled: "true"
      property string barWeatherEnabled: "true"
      property string barColorPickerEnabled: "true"
      property string barWorkspacesEnabled: "true"
      property string barLauncherEnabled: "true"
      property string barActiveAppEnabled: "true"
      property string barMediaEnabled: "true"
      property string barTrayEnabled: "true"
      property string barKeyboardLayoutEnabled: "true"
      property string barSystemEnabled: "true"
      property string barSysCpuEnabled: "true"
      property string barSysCpuTempEnabled: "true"
      property string barSysGpuEnabled: "true"
      property string barSysGpuTempEnabled: "true"
      property string barSysRamEnabled: "true"
      property string barSysNetEnabled: "true"
      property string barNotificationsEnabled: "true"
      property string barVolumeEnabled: "true"
      property string barBrightnessEnabled: "true"
      property string barBatteryEnabled: "true"
      property string barBluetoothEnabled: "true"
      property string barNetworkEnabled: "true"
      property string barControlCenterEnabled: "true"
      property string barVpnEnabled: "true"
      property string barPowerEnabled: "true"
      property string brightnessMonitorBus: "auto"
      property string brightnessSleepMultiplier: ".2"
      property string barPosition: "top"
      property string barStyle: "solid"
      property string barAutoHide: "false"
      property string barAutoHideDelay: "3"
      property string settingsCloseKeybind: "Esc"
      property string keybindDrawer: "Super+Space"
      property string keybindSettings: "Super+,"
      property string keybindClipboard: "Super+V"
      property string keybindNotifications: "Super+N"
      property string keybindPower: "Super+X"
      property string keybindControlCenter: "Super+C"
      property string keybindCalendar: "Super+T"
      property string keybindMedia: "Super+M"
      property string keybindWiFi: "Super+W"
      property string keybindBluetooth: "Super+B"
      property string keybindBrightness: "Super+L"
      property string keybindKeyboard: "Super+K"
      property string keybindSystem: "Super+I"
      property string barThickness: "40"
      property string barTopMargin: "6"
      property string barBottomMargin: "6"
      property string barHorizontalMargin: "12"
      property string barRadius: "35"
      property string barRadiusMode: "linked"
      property string barWidgetRadius: "35"
      property string barFrostOpacity: "56"
      property string popupVerticalAlign: "top"
      property string popupRadius: "45"
      property string popupRadiusMode: "linked"
      property string popupWidgetRadius: "45"
      property string popupBackgroundOpacity: "56"
      property string barAdaptive: "true"
      property string barBlurEnabled: "true"
      property string popupBlurEnabled: "true"
      property string shellBlurEnabled: "true"
      property string shellBordersEnabled: "true"
      property string barBordersEnabled: "true"
      property string popupBordersEnabled: "true"
      property string shellShadowsEnabled: "true"
      property string barShadowsEnabled: "true"
      property string popupShadowsEnabled: "true"
      property string doNotDisturb: "false"
      property string notificationPosition: "top-right"
      property string notificationTimeoutMs: "15000"
      property string notificationMaxVisible: "5"
      property string notificationSoundEnabled: "false"
      property string notificationMutedApps: ""
      property string controlCenterTiles: "wifi,bluetooth,dnd,caffeine,screenshot,nightlight"
      property string idleTimeoutMinutes: "0"
      property string idleAction: "lock"
      property string osdPosition: "bottom-center"
    }
  }

  Timer {
    id: saveTimer
    interval: 120
    repeat: false
    onTriggered: settingsFile.writeAdapter()
  }

  function snapshot() {
    return {
      themeName: adapter.themeName,
      dynamicDark: adapter.dynamicDark,
      fontFamily: adapter.fontFamily,
      fontMonoFamily: adapter.fontMonoFamily,
      fontScale: adapter.fontScale,
      fontMonoScale: adapter.fontMonoScale,
      wallpaperDir: adapter.wallpaperDir,
      wallpaperFillMode: adapter.wallpaperFillMode,
      wallpaperTransition: adapter.wallpaperTransition,
      wallpaperPaletteScheme: adapter.wallpaperPaletteScheme,
      wallpaperCyclingEnabled: adapter.wallpaperCyclingEnabled,
      wallpaperCyclingInterval: adapter.wallpaperCyclingInterval,
      blurWallpaperOnOverview: adapter.blurWallpaperOnOverview,
      videoWallpaperAudio: adapter.videoWallpaperAudio,
      videoWallpaperVolume: adapter.videoWallpaperVolume,
      videoWallpaperHwdec: adapter.videoWallpaperHwdec,
      videoWallpaperPauseOnOverview: adapter.videoWallpaperPauseOnOverview,
      weatherLocation: adapter.weatherLocation,
      dynamicAccent: adapter.dynamicAccent,
      dynamicPalette: adapter.dynamicPalette,
      manualPalette: adapter.manualPalette,
      caffeineEnabled: adapter.caffeineEnabled,
      timeFormat: adapter.timeFormat,
      showSeconds: adapter.showSeconds,
      tooltipsEnabled: adapter.tooltipsEnabled,
      language: adapter.language,
      showWorkspaceNumbers: adapter.showWorkspaceNumbers,
      showWorkspacesOnAllMonitors: adapter.showWorkspacesOnAllMonitors,
      workspaceIndicatorStyle: adapter.workspaceIndicatorStyle,
      uiScale: adapter.uiScale,
      reduceMotion: adapter.reduceMotion,
      weatherEnabled: adapter.weatherEnabled,
      weatherTenths: adapter.weatherTenths,
      barDateTimeEnabled: adapter.barDateTimeEnabled,
      barWeatherEnabled: adapter.barWeatherEnabled,
      barColorPickerEnabled: adapter.barColorPickerEnabled,
      barWorkspacesEnabled: adapter.barWorkspacesEnabled,
      barLauncherEnabled: adapter.barLauncherEnabled,
      barActiveAppEnabled: adapter.barActiveAppEnabled,
      barMediaEnabled: adapter.barMediaEnabled,
      barTrayEnabled: adapter.barTrayEnabled,
      barKeyboardLayoutEnabled: adapter.barKeyboardLayoutEnabled,
      barSystemEnabled: adapter.barSystemEnabled,
      barSysCpuEnabled: adapter.barSysCpuEnabled,
      barSysCpuTempEnabled: adapter.barSysCpuTempEnabled,
      barSysGpuEnabled: adapter.barSysGpuEnabled,
      barSysGpuTempEnabled: adapter.barSysGpuTempEnabled,
      barSysRamEnabled: adapter.barSysRamEnabled,
      barSysNetEnabled: adapter.barSysNetEnabled,
      barNotificationsEnabled: adapter.barNotificationsEnabled,
      barVolumeEnabled: adapter.barVolumeEnabled,
      barBrightnessEnabled: adapter.barBrightnessEnabled,
      barBatteryEnabled: adapter.barBatteryEnabled,
      barBluetoothEnabled: adapter.barBluetoothEnabled,
      barNetworkEnabled: adapter.barNetworkEnabled,
      barControlCenterEnabled: adapter.barControlCenterEnabled,
      barVpnEnabled: adapter.barVpnEnabled,
      barPowerEnabled: adapter.barPowerEnabled,
      brightnessMonitorBus: adapter.brightnessMonitorBus,
      brightnessSleepMultiplier: adapter.brightnessSleepMultiplier,
      barPosition: adapter.barPosition,
      barStyle: adapter.barStyle,
      barAutoHide: adapter.barAutoHide,
      barAutoHideDelay: adapter.barAutoHideDelay,
      settingsCloseKeybind: adapter.settingsCloseKeybind,
      keybindDrawer: adapter.keybindDrawer,
      keybindSettings: adapter.keybindSettings,
      keybindClipboard: adapter.keybindClipboard,
      keybindNotifications: adapter.keybindNotifications,
      keybindPower: adapter.keybindPower,
      keybindControlCenter: adapter.keybindControlCenter,
      keybindCalendar: adapter.keybindCalendar,
      keybindMedia: adapter.keybindMedia,
      keybindWiFi: adapter.keybindWiFi,
      keybindBluetooth: adapter.keybindBluetooth,
      keybindBrightness: adapter.keybindBrightness,
      keybindKeyboard: adapter.keybindKeyboard,
      keybindSystem: adapter.keybindSystem,
      barThickness: adapter.barThickness,
      barTopMargin: adapter.barTopMargin,
      barBottomMargin: adapter.barBottomMargin,
      barHorizontalMargin: adapter.barHorizontalMargin,
      barRadius: adapter.barRadius,
      barRadiusMode: adapter.barRadiusMode,
      barWidgetRadius: adapter.barWidgetRadius,
      barFrostOpacity: adapter.barFrostOpacity,
      popupVerticalAlign: adapter.popupVerticalAlign,
      popupRadius: adapter.popupRadius,
      popupRadiusMode: adapter.popupRadiusMode,
      popupWidgetRadius: adapter.popupWidgetRadius,
      popupBackgroundOpacity: adapter.popupBackgroundOpacity,
      barAdaptive: adapter.barAdaptive,
      barBlurEnabled: adapter.barBlurEnabled,
      popupBlurEnabled: adapter.popupBlurEnabled,
      shellBlurEnabled: adapter.shellBlurEnabled,
      shellBordersEnabled: adapter.shellBordersEnabled,
      barBordersEnabled: adapter.barBordersEnabled,
      popupBordersEnabled: adapter.popupBordersEnabled,
      shellShadowsEnabled: adapter.shellShadowsEnabled,
      barShadowsEnabled: adapter.barShadowsEnabled,
      popupShadowsEnabled: adapter.popupShadowsEnabled,
      doNotDisturb: adapter.doNotDisturb,
      notificationPosition: adapter.notificationPosition,
      notificationTimeoutMs: adapter.notificationTimeoutMs,
      notificationMaxVisible: adapter.notificationMaxVisible,
      notificationSoundEnabled: adapter.notificationSoundEnabled,
      notificationMutedApps: adapter.notificationMutedApps,
      controlCenterTiles: adapter.controlCenterTiles,
      idleTimeoutMinutes: adapter.idleTimeoutMinutes,
      idleAction: adapter.idleAction,
      osdPosition: adapter.osdPosition
      }
  }

  function setValue(key, value) {
    if (adapter[key] === undefined) return
    let next = String(value)
    if (adapter[key] === next) return
    adapter[key] = next
    saveTimer.restart()
  }
}
