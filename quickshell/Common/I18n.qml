pragma Singleton

// I18n.qml - Minimal translation lookup service

import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
  id: root

  property var strings: ({})

  Component.onCompleted: reload()

  Connections {
    target: Config
    function onLanguageChanged() { root.reload() }
  }

  Process {
    id: loadProc
    stdout: SplitParser { onRead: data => root.apply(data) }
  }

  function reload() {
    loadProc.running = false
    loadProc.command = [Config.hushctl, "i18n", Config.language]
    loadProc.running = true
  }

  function apply(data) {
    try {
      let res = JSON.parse(data)
      root.strings = res.strings || {}
    } catch(e) {}
  }

  function tr(key) {
    let value = root.strings[key]
    return value === undefined ? key : value
  }
}
