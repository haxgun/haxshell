//@ pragma UseQApplication
// shell.qml - Quickshell Main Entry Point
import Quickshell
import QtQuick
import Quickshell.Io
import "Common"

Scope {
  id: root

  Process {
    id: loadSettingsProc
    command: [Config.hushctl, "settings"]
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
      if (settings.wallpaperDir) Config.wallpaperDir = settings.wallpaperDir
      if (typeof settings.weatherLocation === "string") Config.weatherLocation = settings.weatherLocation
      if (settings.dynamicAccent) Config.dynamicAccent = settings.dynamicAccent
      if (settings.manualAccent) Config.manualAccent = settings.manualAccent
      if (typeof settings.manualDark === "string") Config.manualDark = settings.manualDark === "true"
      if (settings.timeFormat) Config.timeFormat = settings.timeFormat
      if (settings.uiScale) Config.uiScale = parseFloat(settings.uiScale)
      if (settings.language) Config.language = settings.language
      if (typeof settings.showSeconds === "string") Config.showSeconds = settings.showSeconds === "true"
      if (typeof settings.weatherEnabled === "string") Config.weatherEnabled = settings.weatherEnabled === "true"
      if (settings.brightnessMonitorBus) Config.brightnessMonitorBus = settings.brightnessMonitorBus
      if (settings.brightnessSleepMultiplier) Config.brightnessSleepMultiplier = settings.brightnessSleepMultiplier
      if (typeof settings.shellBlurEnabled === "string") Config.shellBlurEnabled = settings.shellBlurEnabled === "true"
      if (typeof settings.shellBordersEnabled === "string") Config.shellBordersEnabled = settings.shellBordersEnabled === "true"
      if (typeof settings.shellShadowsEnabled === "string") Config.shellShadowsEnabled = settings.shellShadowsEnabled === "true"
      if (typeof settings.musicVisualizerEnabled === "string") {
        Config.musicVisualizerEnabled = settings.musicVisualizerEnabled === "true"
        Config.mprisRightDisplayMode = Config.musicVisualizerEnabled ? "visualizer" : "progress"
      }
      if (typeof settings.showWorkspaceNumbers === "string") Config.showWorkspaceNumbers = settings.showWorkspaceNumbers === "true"
      if (typeof settings.showWorkspacesOnAllMonitors === "string") Config.showWorkspacesOnAllMonitors = settings.showWorkspacesOnAllMonitors === "true"
      if (typeof settings.reduceMotion === "string") Config.reduceMotion = settings.reduceMotion === "true"
      if (settings.barPosition) Config.barPosition = settings.barPosition
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
