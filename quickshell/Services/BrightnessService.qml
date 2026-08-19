pragma Singleton

import QtQuick
import Quickshell.Io
import "../Common"

Item {
  id: root
  visible: false

  property int brightnessPercent: 100
  property string activeBrightnessBus: Config.brightnessMonitorBus
  property int lastAppliedBrightness: -1
  property bool brightnessInitialized: false
  readonly property string natonctl: Config.natonctl

  Process {
    id: fetchBrightnessProc
    command: [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    running: true

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (res.ok && typeof res.brightness !== "undefined") root.brightnessPercent = res.brightness
          if (res.ok && res.bus) root.activeBrightnessBus = res.bus.toString()
          if (res.ok && res.device) root.activeBrightnessBus = res.device.toString()
          if (res.ok) root.brightnessInitialized = true
        } catch(e) {}
      }
    }
  }

  Process {
    id: setBrightnessProc

    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (res.ok && typeof res.brightness !== "undefined") root.brightnessPercent = res.brightness
          if (res.ok && res.bus) root.activeBrightnessBus = res.bus.toString()
          if (res.ok && res.device) root.activeBrightnessBus = res.device.toString()
        } catch(e) {}
      }
    }
  }

  function applyBrightness(val) {
    let target = Math.max(0, Math.min(100, Math.round(val)))
    if (target === root.lastAppliedBrightness && setBrightnessProc.running) return
    root.lastAppliedBrightness = target
    root.brightnessPercent = target
    setBrightnessProc.running = false
    setBrightnessProc.command = [root.natonctl, "brightness", "set", target.toString(), root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    setBrightnessProc.running = true
  }

  function refresh() {
    fetchBrightnessProc.running = false
    fetchBrightnessProc.command = [root.natonctl, "brightness", "get", root.activeBrightnessBus, Config.brightnessSleepMultiplier]
    fetchBrightnessProc.running = true
  }
}
