// Bar.qml - Quickshell bar window container
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
  property var controlCenterPopup: null
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
  property var osd: null

  function closeBarFlyouts() {
    let popups = [
      root.appDrawer, root.calendarPopup, root.brightnessPopup, root.wifiPopup,
      root.bluetoothPopup, root.audioPopup, root.batteryPopup, root.notificationPopup,
      root.trayMenuPopup, root.keyboardLayoutPopup, root.settingsPopup, root.powerPopup,
      root.systemPopup, root.mediaPopup, root.controlCenterPopup
    ]
    for (let p of popups) {
      if (p && typeof p.isOpen !== "undefined") p.isOpen = false
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      screen: modelData

      readonly property bool posTop: Config.barPosition === "top"
      readonly property bool posBottom: Config.barPosition === "bottom"
      readonly property bool posLeft: Config.barPosition === "left"
      readonly property bool posRight: Config.barPosition === "right"
      readonly property bool vertical: posLeft || posRight
      readonly property int screenWidth: modelData.width || width
      readonly property int screenHeight: modelData.height || height

      // Wayland LayerShell Integration
      WlrLayershell.namespace: "quickshell-bar"
      WlrLayershell.layer: WlrLayer.Top
      BackgroundEffect.blurRegion: Region {
        item: Config.barBlurEnabled ? barSurface : null
        radius: Math.round(barSurface.radius)
      }

      anchors {
        top: window.vertical || window.posTop
        bottom: window.vertical || window.posBottom
        left: !window.vertical || window.posLeft
        right: !window.vertical || window.posRight
      }

      implicitWidth: window.vertical ? Config.barHeight + Config.barMargin : 0
      implicitHeight: window.vertical ? 0 : Config.barHeight + (window.posTop ? Config.scaledBarTopMargin : 0)
      color: "#00000000"

      Rectangle {
        id: barSurface
        readonly property bool vertical: window.vertical
        x: vertical ? (window.posLeft ? Config.barMargin : 0) : Config.barMargin
        y: vertical ? Config.scaledBarTopMargin : (window.posTop ? Config.scaledBarTopMargin : 0)
        width: vertical ? Config.barHeight : parent.width - Config.barMargin * 2
        height: vertical ? parent.height - Config.scaledBarTopMargin : Config.barHeight
        radius: Config.scaledBarRadius
        color: Config.barBackgroundBg

        Rectangle {
          visible: Config.shellShadowsEnabled
          x: 0
          y: Config.shellShadowOffsetY
          width: parent.width
          height: parent.height
          radius: parent.radius
          color: Config.shellShadowColor
          opacity: 0.55
          z: -1
        }

        Rectangle {
          anchors.fill: parent
          anchors.margins: Config.innerBorderMargin
          radius: Math.max(0, barSurface.radius - Config.innerBorderMargin)
          color: "#00000000"
          border.color: Config.borderColor
          border.width: Config.shellBordersEnabled ? 1 : 0
        }

        TapHandler {
          acceptedButtons: Qt.LeftButton
          onTapped: root.closeBarFlyouts()
        }

        // Right-click on empty bar area opens settings near the cursor.
        // Placed below widgets so tray icons handle their own right-click first.
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          onClicked: (mouse) => {
            root.closeBarFlyouts()
            if (!root.settingsPopup) return
            let gap = 16
            let screenW = window.screenWidth
            let popupW = 430
            let windowOffsetX = window.posRight ? (screenW - window.width) : 0
            let cursorX = windowOffsetX + barSurface.x + mouse.x
            root.settingsPopup.rightMargin = Math.max(gap, Math.min(screenW - popupW - gap, screenW - popupW / 2 - cursorX))
            root.settingsPopup.isOpen = true
          }
        }

        Item {
          id: contentStrip
          width: window.vertical ? barSurface.height : barSurface.width
          height: window.vertical ? barSurface.width : barSurface.height
          anchors.centerIn: parent
          rotation: Config.barRotation
          transformOrigin: Item.Center

          WorkspaceWidget {
            id: workspaceWidget
            embeddedInBar: true
            appDrawer: root.appDrawer
            monitorName: modelData.name
            vertical: false
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          ActiveAppWidget {
            vertical: false
            anchors.left: workspaceWidget.right
            anchors.verticalCenter: parent.verticalCenter
          }

          StatusWidget {
            id: statusWidget
            embeddedInBar: true
            calendarPopup: root.calendarPopup
            controlCenterPopup: root.controlCenterPopup
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
            osd: root.osd
            vertical: false
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
