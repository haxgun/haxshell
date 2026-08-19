pragma Singleton

import QtQuick
import Quickshell.Io
import "../Common"

Item {
  id: root
  visible: false

  property int batteryPercent: 0
  property string batteryStatus: "Unknown"
  property bool batteryCharging: false
  property bool acOnline: false
  property double batteryRate: 0
  property int batteryCapacity: 0
  property double batteryTimeHours: 0
  property double batteryVoltage: 0
  property double batteryTemp: 0
  property int batteryCycles: 0
  property string powerProfile: "balanced"
  readonly property string natonctl: Config.natonctl

  Process {
    id: batteryProc
    command: [root.natonctl, "battery"]
    running: true

    stdout: SplitParser {
      onRead: data => root.applyBatteryState(data)
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    batteryProc.running = false
    batteryProc.command = [root.natonctl, "battery"]
    batteryProc.running = true
  }

  function setProfile(profile) {
    batteryProc.running = false
    batteryProc.command = [root.natonctl, "battery", "set-profile", profile]
    batteryProc.running = true
  }

  function applyBatteryState(data) {
    try {
      let res = JSON.parse(data)
      root.batteryPercent = res.percentage || 0
      root.batteryStatus = res.status || "Unknown"
      root.batteryCharging = !!res.charging
      root.acOnline = !!res.online
      root.batteryRate = res.rate || 0
      root.batteryCapacity = res.capacity || 0
      root.batteryTimeHours = res.timeHours || 0
      root.batteryVoltage = res.voltage || 0
      root.batteryTemp = res.temp || 0
      root.batteryCycles = res.cycles || 0
      root.powerProfile = res.profile || "balanced"
    } catch(e) {}
  }

  function percent() {
    return root.batteryPercent
  }

  function stateText() {
    if (root.batteryCharging && root.batteryStatus === "Full") return I18n.tr("battery.fullChargedConnected")
    if (root.batteryStatus === "Charging") return I18n.tr("battery.charging")
    if (root.batteryStatus === "Discharging") return I18n.tr("battery.discharging")
    if (root.batteryStatus === "Full") return I18n.tr("battery.full")
    if (root.acOnline) return I18n.tr("battery.onAc")
    return I18n.tr("battery.unknown")
  }

  function timeText() {
    if (!root.batteryTimeHours || root.batteryTimeHours <= 0) return "--"
    let hours = Math.floor(root.batteryTimeHours)
    let minutes = Math.round((root.batteryTimeHours - hours) * 60)
    return I18n.tr("battery.hoursMinutes").replace("{h}", hours).replace("{m}", minutes)
  }

  function profileName(profile) {
    if (profile === "power-saver") return I18n.tr("cc.powerSaver")
    if (profile === "performance") return I18n.tr("cc.performance")
    return I18n.tr("cc.balanced")
  }

  function profileIcon(profile) {
    if (profile === "power-saver") return Config.iconPowerSaver
    if (profile === "performance") return Config.iconPerformance
    return Config.iconBalanced
  }
}
