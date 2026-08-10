// Bar.qml - Quickshell Top Bar Window Container
import Quickshell
import QtQuick
import Quickshell.Wayland
import "."
import "../../Common"

Scope {
  id: root

  // Public Component References
  property var appDrawer: null
  property var calendarPopup: null
  property var brightnessPopup: null
  property var wifiPopup: null
  property var bluetoothPopup: null
  property var audioPopup: null
  property var batteryPopup: null
  property var notificationPopup: null
  property var trayMenuPopup: null
  property var keyboardLayoutPopup: null
  property var settingsPopup: null
  property var powerPopup: null
  property var systemPopup: null
  property var mediaPopup: null

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      screen: modelData

      // Wayland LayerShell Integration
      WlrLayershell.namespace: "quickshell-bar"
      WlrLayershell.layer: WlrLayer.Top

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: Config.barHeight + Config.barMargin
      color: "#00000000"

      Rectangle {
        id: barSurface
        height: Config.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Config.barMargin
        anchors.rightMargin: Config.barMargin
        anchors.verticalCenter: parent.verticalCenter
        radius: Config.widgetRadius
        color: Config.glassBg

        Rectangle {
          anchors.fill: parent
          anchors.margins: Config.innerBorderMargin
          radius: Config.innerBorderRadius
          color: "#00000000"
          border.color: Config.borderColor
          border.width: 1
        }

        // Left Module: Workspace switcher & App Launcher Icon
        WorkspaceWidget {
          id: workspaceWidget
          embeddedInBar: true
          appDrawer: root.appDrawer
          anchors.left: parent.left
          anchors.leftMargin: 0
          anchors.verticalCenter: parent.verticalCenter
        }

        ActiveAppWidget {
          anchors.left: workspaceWidget.right
          anchors.leftMargin: 0
          anchors.verticalCenter: parent.verticalCenter
        }

        // Right Module: System Status, Audio, Connectivity & Power
        StatusWidget {
          id: statusWidget
          embeddedInBar: true
          calendarPopup: root.calendarPopup
          brightnessPopup: root.brightnessPopup
          wifiPopup: root.wifiPopup
          bluetoothPopup: root.bluetoothPopup
          audioPopup: root.audioPopup
          batteryPopup: root.batteryPopup
          notificationPopup: root.notificationPopup
          trayMenuPopup: root.trayMenuPopup
          keyboardLayoutPopup: root.keyboardLayoutPopup
          settingsPopup: root.settingsPopup
          powerPopup: root.powerPopup
          systemPopup: root.systemPopup
          mediaPopup: root.mediaPopup
          anchors.right: parent.right
          anchors.rightMargin: 0
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
