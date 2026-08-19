import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Common"
import "../Services"

PanelWindow {
  id: root
  property bool isOpen: false
  visible: isOpen
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  IpcHandler {
    target: "clipboard"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }
  MouseArea { anchors.fill: parent; onClicked: root.isOpen = false }
  Rectangle {
    width: Config.scaledSize(420); height: Config.scaledSize(420); anchors.centerIn: parent
    radius: Config.overlayRadius; color: Config.popupGlassBg; border.color: Config.popupBorderColor; border.width: 1
    MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
    Column {
      anchors.fill: parent; anchors.margins: Config.scaledSize(14); spacing: Config.scaledSize(10)
      Item {
        width: parent.width
        height: Config.scaledSize(22)
        Text { text: Config.iconClipboard + "  " + I18n.tr("clipboard.title"); color: Config.textPrimary; font.pixelSize: Config.fontSizeLarge; font.family: Config.fontSans }
        Text { anchors.right: parent.right; text: I18n.tr("clipboard.clear"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; MouseArea { anchors.fill: parent; onClicked: ClipboardService.clear() } }
      }
      ListView {
        width: parent.width; height: parent.height - Config.scaledSize(42); clip: true; spacing: Config.scaledSize(6); model: ClipboardService.entries
        delegate: Rectangle {
          required property var modelData
          width: ListView.view.width; height: Config.scaledSize(48); radius: Config.cardRadius; color: clipMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          Text { anchors.fill: parent; anchors.margins: Config.scaledSize(10); verticalAlignment: Text.AlignVCenter; text: modelData.text.replace(/\n/g, " "); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight }
          MouseArea { id: clipMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { ClipboardService.copy(parent.modelData.text); root.isOpen = false } }
        }
      }
    }
  }
}
