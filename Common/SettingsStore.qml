pragma Singleton

// SettingsStore.qml - Persistent shell settings adapter

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string settingsPath: Qt.resolvedUrl("../settings.json").toString().replace("file://", "")
  property bool loaded: false
  property bool parseError: false

  property alias themeName: adapter.themeName
  property alias fontFamily: adapter.fontFamily
  property alias wallpaperDir: adapter.wallpaperDir
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
  property alias uiScale: adapter.uiScale
  property alias reduceMotion: adapter.reduceMotion
  property alias weatherEnabled: adapter.weatherEnabled
  property alias brightnessMonitorBus: adapter.brightnessMonitorBus
  property alias brightnessSleepMultiplier: adapter.brightnessSleepMultiplier
  property alias barPosition: adapter.barPosition
  property alias shellBlurEnabled: adapter.shellBlurEnabled
  property alias shellBordersEnabled: adapter.shellBordersEnabled
  property alias shellShadowsEnabled: adapter.shellShadowsEnabled

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
      property string uiScale: "1.0"
      property string reduceMotion: "false"
      property string weatherEnabled: "true"
      property string brightnessMonitorBus: "auto"
      property string brightnessSleepMultiplier: ".2"
      property string barPosition: "top"
      property string shellBlurEnabled: "true"
      property string shellBordersEnabled: "true"
      property string shellShadowsEnabled: "true"
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
      uiScale: adapter.uiScale,
      reduceMotion: adapter.reduceMotion,
      weatherEnabled: adapter.weatherEnabled,
      brightnessMonitorBus: adapter.brightnessMonitorBus,
      brightnessSleepMultiplier: adapter.brightnessSleepMultiplier,
      barPosition: adapter.barPosition,
      shellBlurEnabled: adapter.shellBlurEnabled,
      shellBordersEnabled: adapter.shellBordersEnabled,
      shellShadowsEnabled: adapter.shellShadowsEnabled
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
