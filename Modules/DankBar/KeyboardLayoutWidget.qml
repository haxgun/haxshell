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
  readonly property string qsctl: Qt.resolvedUrl("../../scripts/qsctl").toString().replace("file://", "")

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
    command: [root.qsctl, "keyboard"]
    running: true

    stdout: SplitParser {
      onRead: data => root.applyState(data)
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: layoutProc.running = true
  }

  Row {
    id: keyRow
    anchors.centerIn: parent
    spacing: 5

    Text {
      text: Config.iconKeyboard
      color: Config.textMuted
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.layout
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Bold
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
