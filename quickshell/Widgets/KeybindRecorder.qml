import QtQuick
import "../Common"

Item {
  id: root

  property string keybind: ""
  property bool recording: false
  property bool rejected: false
  property var apply: null

  width: Config.scaledSize(120)
  height: Config.scaledSize(30)
  focus: recording

  function keyName(event) {
    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z || event.key >= Qt.Key_0 && event.key <= Qt.Key_9) return String.fromCharCode(event.key)
    if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) return "F" + (event.key - Qt.Key_F1 + 1)
    if (event.key === Qt.Key_Space) return "Space"
    if (event.key === Qt.Key_Comma) return ","
    if (event.key === Qt.Key_Tab) return "Tab"
    if (event.key === Qt.Key_Return) return "Return"
    if (event.key === Qt.Key_Enter) return "Enter"
    if (event.key === Qt.Key_Backspace) return "Backspace"
    if (event.key === Qt.Key_Delete) return "Del"
    if (event.key === Qt.Key_Left) return "Left"
    if (event.key === Qt.Key_Right) return "Right"
    if (event.key === Qt.Key_Up) return "Up"
    if (event.key === Qt.Key_Down) return "Down"
    return event.text && event.text.length === 1 ? event.text.toUpperCase() : ""
  }

  function shortcut(event) {
    let key = keyName(event)
    if (!key) return ""
    let parts = []
    if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl")
    if (event.modifiers & Qt.AltModifier) parts.push("Alt")
    if (event.modifiers & Qt.ShiftModifier) parts.push("Shift")
    if (event.modifiers & Qt.MetaModifier) parts.push("Super")
    parts.push(key)
    return parts.join("+")
  }

  Timer { id: rejectTimer; interval: 700; onTriggered: root.rejected = false }

  Rectangle {
    anchors.fill: parent
    radius: Config.popupRadiusPx(8)
    color: root.recording ? Config.selectedBg : Config.searchBg
    border.color: root.rejected ? Config.dangerRed : (root.recording ? Config.activeBorderColor : "transparent")
    border.width: root.recording || root.rejected ? 1 : 0

    Text {
      anchors.fill: parent
      anchors.margins: Config.scaledSize(7)
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
      text: root.recording ? "..." : root.keybind
      color: root.recording ? Config.textWhite : Config.textPrimary
      font.pixelSize: Config.fontSizeTiny
      font.family: Config.fontMono
      elide: Text.ElideRight
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.recording = !root.recording
        if (root.recording) root.forceActiveFocus()
      }
    }
  }

  Keys.onPressed: event => {
    if (!root.recording) return
    event.accepted = true
    if (event.key === Qt.Key_Escape) {
      root.recording = false
      return
    }
    if (event.key === Qt.Key_Control || event.key === Qt.Key_Alt || event.key === Qt.Key_Shift || event.key === Qt.Key_Meta) return
    let value = root.shortcut(event)
    if (!value) return
    if (!root.apply || root.apply(value)) root.recording = false
    else {
      root.rejected = true
      rejectTimer.restart()
    }
  }
}
