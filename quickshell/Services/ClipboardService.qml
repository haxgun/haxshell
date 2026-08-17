pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property var entries: []
  property string lastText: ""
  readonly property int limit: 50
  Process { id: pasteProc; stdout: SplitParser { onRead: data => root.add(data) } }
  Process { id: copyProc }
  Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.readClipboard() }
  function readClipboard() { pasteProc.running = false; pasteProc.command = ["wl-paste", "--no-newline"]; pasteProc.running = true }
  function add(text) {
    let value = (text || "").trim()
    if (!value || value === lastText) return
    lastText = value
    entries = [{ text: value, timestamp: Date.now() }].concat(entries.filter(item => item.text !== value)).slice(0, limit)
  }
  function copy(text) { if (!text) return; copyProc.running = false; copyProc.command = ["wl-copy", text]; copyProc.running = true; add(text) }
  function clear() { entries = [] }
}
