import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Common"
import "../Services"

Scope {
  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      visible: Config.dockEnabled
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.exclusiveZone: 0
      anchors { bottom: true; left: true; right: true }
      implicitHeight: Config.scaledSize(62)
      color: "#00000000"
      mask: Region { item: dockContent }
      Row {
        id: dockContent
        anchors.centerIn: parent; spacing: Config.scaledSize(6)
        Repeater {
          model: CompositorService.toplevelsForOutput(modelData.name)
          Rectangle {
            required property var modelData
            width: Config.scaledSize(46); height: Config.scaledSize(46); radius: Config.popupPillRadius(height)
            color: modelData.focused ? Config.selectedBg : (dockMouse.containsMouse ? Config.hoverBg : Config.popupGlassBg)
            Text { anchors.centerIn: parent; text: (modelData.title || modelData.appId || "?").charAt(0).toUpperCase(); color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans }
            MouseArea { id: dockMouse; anchors.fill: parent; hoverEnabled: true; onClicked: CompositorService.focusToplevel(parent.modelData) }
          }
        }
      }
    }
  }
}
