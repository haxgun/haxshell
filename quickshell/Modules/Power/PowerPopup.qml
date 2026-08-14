// PowerPopup.qml - Compact session power menu
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common"
import "../../Services"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property string pendingCommand: ""

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "power"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  Process {
    id: actionProc
    command: ["sh", "-c", root.pendingCommand]
  }

  function run(command) {
    root.pendingCommand = command
    root.isOpen = false
    actionProc.running = false
    actionProc.running = true
  }

  Rectangle {
    id: container
    width: 240
    implicitHeight: content.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: 1 }

    Column {
      id: content
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 10

      Row {
        width: parent.width
        height: 28
        spacing: 10
        Text { text: Config.iconPower; color: Config.dangerRed; font.pixelSize: Config.fontSizeTitle; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Питание"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
      }

      Rectangle { width: parent.width; height: 1; color: Config.separatorColor }

      Repeater {
        model: [
          { label: "Заблокировать", icon: Config.iconLock, command: "loginctl lock-session" },
          { label: "Сон", icon: Config.iconSuspend, command: "systemctl suspend" },
          { label: "Выйти", icon: Config.iconLogout, command: CompositorService.exitCommand },
          { label: "Перезагрузка", icon: Config.iconRestart, command: "systemctl reboot" },
          { label: "Выключить", icon: Config.iconPower, command: "systemctl poweroff", danger: true }
        ]

        Rectangle {
          required property var modelData
          width: parent.width
          height: 34
          radius: Config.cardRadius
          color: powerItemMouse.containsMouse ? (modelData.danger ? "#35f87171" : Config.hoverBg) : "#00000000"

          Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 10

            Text { text: parent.parent.modelData.icon; color: parent.parent.modelData.danger ? Config.dangerRed : Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
            Text { text: parent.parent.modelData.label; color: parent.parent.modelData.danger ? Config.dangerRed : Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
          }

          MouseArea {
            id: powerItemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.run(parent.modelData.command)
          }
        }
      }
    }
  }
}
