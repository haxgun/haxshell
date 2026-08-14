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
  property alias fontFamily: adapter.fontFamily
  property alias wallpaperDir: adapter.wallpaperDir
  property alias wallpaperFillMode: adapter.wallpaperFillMode
  property alias wallpaperTransition: adapter.wallpaperTransition
  property alias wallpaperCyclingEnabled: adapter.wallpaperCyclingEnabled
  property alias wallpaperCyclingInterval: adapter.wallpaperCyclingInterval
  property alias blurWallpaperOnOverview: adapter.blurWallpaperOnOverview
  property alias weatherLocation: adapter.weatherLocation
  property alias dynamicAccent: adapter.dynamicAccent
  property alias manualAccent: adapter.manualAccent
  property alias manualDark: adapter.manualDark
  property alias caffeineEnabled: adapter.caffeineEnabled
  property alias timeFormat: adapter.timeFormat
  property alias showSeconds: adapter.showSeconds
  property alias language: adapter.language
  property alias musicVisualizerEnabled: adapter.musicVisualizerEnabled
  property alias showWorkspaceNumbers: adapter.showWorkspaceNumbers
  property alias showWorkspacesOnAllMonitors: adapter.showWorkspacesOnAllMonitors
  property alias workspaceIndicatorStyle: adapter.workspaceIndicatorStyle
  property alias uiScale: adapter.uiScale
  property alias reduceMotion: adapter.reduceMotion
  property alias weatherEnabled: adapter.weatherEnabled
  property alias brightnessMonitorBus: adapter.brightnessMonitorBus
  property alias brightnessSleepMultiplier: adapter.brightnessSleepMultiplier
  property alias barPosition: adapter.barPosition
  property alias barThickness: adapter.barThickness
  property alias barTopMargin: adapter.barTopMargin
  property alias barHorizontalMargin: adapter.barHorizontalMargin
  property alias barRadius: adapter.barRadius
  property alias barFrostOpacity: adapter.barFrostOpacity
  property alias popupRadius: adapter.popupRadius
  property alias popupBackgroundOpacity: adapter.popupBackgroundOpacity
  property alias barBlurEnabled: adapter.barBlurEnabled
  property alias popupBlurEnabled: adapter.popupBlurEnabled
  property alias shellBlurEnabled: adapter.shellBlurEnabled
  property alias shellBordersEnabled: adapter.shellBordersEnabled
  property alias shellShadowsEnabled: adapter.shellShadowsEnabled
  property alias doNotDisturb: adapter.doNotDisturb
  property alias notificationPosition: adapter.notificationPosition
  property alias notificationTimeoutMs: adapter.notificationTimeoutMs
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
      property string fontFamily: "Geist Mono"
      property string wallpaperDir: "~/wallpapers/animated"
      property string wallpaperFillMode: "fill"
      property string wallpaperTransition: "fade"
      property string wallpaperCyclingEnabled: "false"
      property string wallpaperCyclingInterval: "300"
      property string blurWallpaperOnOverview: "false"
      property string weatherLocation: ""
      property string dynamicAccent: "#e2e8f0"
      property string manualAccent: "#e2e8f0"
      property string manualDark: "true"
      property string caffeineEnabled: "false"
      property string timeFormat: "24"
      property string showSeconds: "false"
      property string language: "ru"
      property string musicVisualizerEnabled: "true"
      property string showWorkspaceNumbers: "true"
      property string showWorkspacesOnAllMonitors: "false"
      property string workspaceIndicatorStyle: "tint"
      property string uiScale: "1.0"
      property string reduceMotion: "false"
      property string weatherEnabled: "true"
      property string brightnessMonitorBus: "auto"
      property string brightnessSleepMultiplier: ".2"
      property string barPosition: "top"
      property string barThickness: "40"
      property string barTopMargin: "6"
      property string barHorizontalMargin: "12"
      property string barRadius: "14"
      property string barFrostOpacity: "56"
      property string popupRadius: "18"
      property string popupBackgroundOpacity: "56"
      property string barBlurEnabled: "true"
      property string popupBlurEnabled: "true"
      property string shellBlurEnabled: "true"
      property string shellBordersEnabled: "true"
      property string shellShadowsEnabled: "true"
      property string doNotDisturb: "false"
      property string notificationPosition: "top-right"
      property string notificationTimeoutMs: "15000"
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
      fontFamily: adapter.fontFamily,
      wallpaperDir: adapter.wallpaperDir,
      wallpaperFillMode: adapter.wallpaperFillMode,
      wallpaperTransition: adapter.wallpaperTransition,
      wallpaperCyclingEnabled: adapter.wallpaperCyclingEnabled,
      wallpaperCyclingInterval: adapter.wallpaperCyclingInterval,
      blurWallpaperOnOverview: adapter.blurWallpaperOnOverview,
      weatherLocation: adapter.weatherLocation,
      dynamicAccent: adapter.dynamicAccent,
      manualAccent: adapter.manualAccent,
      manualDark: adapter.manualDark,
      caffeineEnabled: adapter.caffeineEnabled,
      timeFormat: adapter.timeFormat,
      showSeconds: adapter.showSeconds,
      language: adapter.language,
      musicVisualizerEnabled: adapter.musicVisualizerEnabled,
      showWorkspaceNumbers: adapter.showWorkspaceNumbers,
      showWorkspacesOnAllMonitors: adapter.showWorkspacesOnAllMonitors,
      workspaceIndicatorStyle: adapter.workspaceIndicatorStyle,
      uiScale: adapter.uiScale,
      reduceMotion: adapter.reduceMotion,
      weatherEnabled: adapter.weatherEnabled,
      brightnessMonitorBus: adapter.brightnessMonitorBus,
      brightnessSleepMultiplier: adapter.brightnessSleepMultiplier,
      barPosition: adapter.barPosition,
      barThickness: adapter.barThickness,
      barTopMargin: adapter.barTopMargin,
      barHorizontalMargin: adapter.barHorizontalMargin,
      barRadius: adapter.barRadius,
      barFrostOpacity: adapter.barFrostOpacity,
      popupRadius: adapter.popupRadius,
      popupBackgroundOpacity: adapter.popupBackgroundOpacity,
      barBlurEnabled: adapter.barBlurEnabled,
      popupBlurEnabled: adapter.popupBlurEnabled,
      shellBlurEnabled: adapter.shellBlurEnabled,
      shellBordersEnabled: adapter.shellBordersEnabled,
      shellShadowsEnabled: adapter.shellShadowsEnabled,
      doNotDisturb: adapter.doNotDisturb,
      notificationPosition: adapter.notificationPosition,
      notificationTimeoutMs: adapter.notificationTimeoutMs,
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
