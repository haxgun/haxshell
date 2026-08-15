// KeyboardLayoutPopup.qml - Hyprland keyboard layout selector
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property string currentLayout: "??"
  property string currentName: "Unknown"
  readonly property string hushctl: Config.hushctl

  signal layoutChanged(var state)

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

  onIsOpenChanged: if (isOpen) refresh()

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "keyboard"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  ListModel { id: layoutModel }

  Process {
    id: keyboardProc
    stdout: SplitParser { onRead: data => root.applyState(data, false) }
  }

  Process {
    id: setLayoutProc
    stdout: SplitParser { onRead: data => root.applyState(data, true) }
  }

  function refresh() {
    keyboardProc.running = false
    keyboardProc.command = [root.hushctl, "keyboard"]
    keyboardProc.running = true
  }

  function setLayout(index) {
    setLayoutProc.running = false
    setLayoutProc.command = [root.hushctl, "keyboard", "set", index.toString()]
    setLayoutProc.running = true
  }

  function applyState(data, closeAfter) {
    try {
      let state = JSON.parse(data)
      root.currentLayout = state.layout || "??"
      root.currentName = state.name || "Unknown"
      layoutModel.clear()
      let layouts = state.layouts || []
      for (let i = 0; i < layouts.length; i++) layoutModel.append(layouts[i])
      root.layoutChanged(state)
      if (closeAfter) root.isOpen = false
    } catch(e) {}
  }

  Rectangle {
    id: container
    width: 210
    implicitHeight: content.implicitHeight + 24
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    Column {
      id: content
      width: parent.width - 24
      anchors.top: parent.top
      anchors.topMargin: 12
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      Row {
        width: parent.width
        height: 24
        spacing: 8
        Text { text: Config.iconKeyboard; color: Config.textWhite; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { width: parent.width - 28; text: "Раскладка"; color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
      }

      Repeater {
        model: layoutModel
        Rectangle {
          required property int index
          required property string layout
          required property string name
          required property bool active
          width: parent.width
          height: 34
          radius: Config.cardRadius
          color: active ? Config.selectedBg : (layoutMouse.containsMouse ? Config.hoverBg : "#00000000")
          border.color: active ? Config.activeBorderColor : "#00000000"
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            Text { width: 28; text: parent.parent.layout; color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontMonoSizeSmall; font.weight: Font.Bold; font.family: Config.fontMono; anchors.verticalCenter: parent.verticalCenter }
            Text { width: parent.width - 38; text: parent.parent.name; color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
          }

          MouseArea { id: layoutMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setLayout(parent.index) }
        }
      }
    }
  }
}
