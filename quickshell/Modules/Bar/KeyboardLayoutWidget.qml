// KeyboardLayoutWidget.qml - Hyprland keyboard layout indicator
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

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

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: if (!layoutProc.running) layoutProc.running = true
  }

  Component.onCompleted: layoutProc.running = true

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
