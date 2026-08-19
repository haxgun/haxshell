// KeyboardLayoutWidget.qml - Keyboard layout indicator
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"
import "../../Services"

Rectangle {
  id: root

  property string layout: "??"
  property string layoutName: "Unknown"
  property var keyboardLayoutPopup: null
  property var closeFlyouts: null
  property var tooltip: null

  Connections {
    target: keyboardLayoutPopup
    function onLayoutChanged(state) {
      root.layout = state.layout || "??"
      root.layoutName = state.name || "Unknown"
    }
  }
  implicitWidth: keyRow.implicitWidth + 12
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: keyMouse.containsMouse ? Config.hoverBg : "#00000000"

  // niri: reactive, event-driven from qml-niri via CompositorService — instant.
  // Hyprland: fall back to polling natonctl (no live layout signal available).
  Connections {
    target: CompositorService
    function onKeyboardCurrentNameChanged() { root.syncFromCompositor() }
    function onKeyboardLayoutNamesChanged() { root.syncFromCompositor() }
  }

  function syncFromCompositor() {
    if (!CompositorService.keyboardLayoutLive) return
    let names = CompositorService.keyboardLayoutNames
    let idx = CompositorService.keyboardCurrentIndex
    let name = CompositorService.keyboardCurrentName
    root.layoutName = name || "Unknown"
    root.layout = CompositorService.keyboardShortName(name)
  }

  function applyState(data) {
    try {
      let res = JSON.parse(data)
      root.layout = res.layout || "??"
      root.layoutName = res.name || "Unknown"
    } catch(e) {}
  }

  Process {
    id: layoutProc
    command: [Config.natonctl, "keyboard"]
    running: false

    stdout: SplitParser {
      onRead: data => root.applyState(data)
    }
  }

  // Polling only runs on Hyprland. On niri, qml-niri pushes instant updates.
  Timer {
    interval: 10000
    running: !CompositorService.keyboardLayoutLive
    repeat: true
    onTriggered: if (!layoutProc.running) layoutProc.running = true
  }

  Component.onCompleted: {
    if (CompositorService.keyboardLayoutLive) root.syncFromCompositor()
    else layoutProc.running = true
  }

  Row {
    id: keyRow
    anchors.centerIn: parent
    spacing: Config.scaledSize(5)

    Text {
      text: Config.iconKeyboard
      color: Config.iconColor
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.layout
      color: Config.textPrimary
      font.pixelSize: Config.fontMonoSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontMono
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: keyMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.tooltip) root.tooltip.show(root, root.layoutName)
    onExited: if (root.tooltip) root.tooltip.hide()
    onClicked: {
      if (!root.keyboardLayoutPopup) return
      let statusRoot = root.parent ? root.parent.parent : null
      let row = root.parent
      if (statusRoot && row) root.keyboardLayoutPopup.rightMargin = Math.max(16, Math.round(statusRoot.width - (row.x + root.x + root.width) + Config.barMargin))
      if (root.closeFlyouts) root.closeFlyouts("keyboard")
      root.keyboardLayoutPopup.isOpen = !root.keyboardLayoutPopup.isOpen
    }
  }
}
