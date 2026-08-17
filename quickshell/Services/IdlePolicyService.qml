pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Common"

Singleton {
  id: root
  readonly property bool enabled: Config.idleTimeoutMinutes > 0
  property bool running: false

  function restart() {
    root.running = false
    if (root.enabled) restartTimer.restart()
  }

  Process {
    command: ["swayidle", "timeout", (Config.idleTimeoutMinutes * 60).toString(), Config.idleAction === "suspend" ? "systemctl suspend" : "loginctl lock-session"]
    running: root.running
  }

  Timer { id: restartTimer; interval: 0; onTriggered: root.running = true }

  Connections {
    target: Config
    function onIdleTimeoutMinutesChanged() { root.restart() }
    function onIdleActionChanged() { root.restart() }
  }
}
