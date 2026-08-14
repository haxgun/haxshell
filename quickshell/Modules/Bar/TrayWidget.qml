// TrayWidget.qml - StatusNotifierItem tray icons
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../Common"

Rectangle {
  id: root

  readonly property var trayItems: {
    let items = SystemTray.items && SystemTray.items.values ? SystemTray.items.values : []
    return items.filter(item => !root.isNetworkManagerItem(item))
  }
  readonly property int trayCount: trayItems.length
  property bool expanded: false
  property var trayMenuPopup: null
  property var closeFlyouts: null
  readonly property bool hovered: trayHover.hovered || arrowMouse.containsMouse || iconMouse.containsMouse

  visible: trayCount > 0
  implicitWidth: visible ? trayRow.implicitWidth + 0 : 0
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: trayMouse.containsMouse ? Config.hoverBg : "#00000000"

  Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function iconSource(icon) {
    if (!icon) return ""
    if (icon === "hwloc" || icon === "preferences-system-network") return ""
    return icon.indexOf("/") >= 0 || icon.indexOf(":") >= 0 ? icon : "image://icon/" + icon
  }

  function isNetworkManagerItem(item) {
    if (!item) return false
    let identity = [item.id, item.title, item.icon].join(" ").toLowerCase()
    return identity.includes("nm_applet") || identity.includes("nm-applet") || identity.includes("networkmanager")
  }

  function openContextMenu(item, itemRect) {
    if (!item || !item.hasMenu) return false
    if (root.closeFlyouts) root.closeFlyouts("trayMenu")
    if (root.trayMenuPopup) {
      let pos = itemRect.mapToItem(null, 0, 0)
      root.trayMenuPopup.openMenu(item.menu, pos.x, pos.y, itemRect.width)
    }
    return true
  }

  onHoveredChanged: {
    if (hovered) {
      closeTimer.stop()
      expanded = true
    } else {
      closeTimer.restart()
    }
  }

  Timer {
    id: closeTimer
    interval: 250
    repeat: false
    onTriggered: if (!root.hovered) root.expanded = false
  }

  HoverHandler {
    id: trayHover
  }

  MouseArea {
    id: trayMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  Row {
    id: trayRow
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 4
    spacing: 2

    Item {
      id: iconClip
      width: root.expanded ? iconRow.implicitWidth : 0
      height: Config.buttonHeight
      clip: true
      opacity: root.expanded ? 1.0 : 0.0

      Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

      MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
      }

      Row {
        id: iconRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
          model: root.trayItems

          Rectangle {
            id: trayItem
            required property var modelData

            width: Config.buttonWidth
            height: Config.buttonHeight
            radius: Config.buttonRadius
            color: itemMouse.containsMouse ? Config.pressedBg : "#00000000"

            IconImage {
              anchors.centerIn: parent
              width: 18
              height: 18
              source: root.iconSource(trayItem.modelData.icon)
              asynchronous: true
            }

            Text {
              anchors.centerIn: parent
                visible: root.iconSource(trayItem.modelData.icon).length === 0
              text: (trayItem.modelData.title || trayItem.modelData.id || "?").charAt(0).toUpperCase()
              color: Config.textPrimary
              font.pixelSize: Config.fontSizeSmall
              font.weight: Font.Bold
              font.family: Config.fontSans
            }

            MouseArea {
              id: itemMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
              cursorShape: Qt.PointingHandCursor

              onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                  root.openContextMenu(trayItem.modelData, trayItem)
                } else if (mouse.button === Qt.MiddleButton) {
                  trayItem.modelData.secondaryActivate()
                } else if (trayItem.modelData.onlyMenu && root.openContextMenu(trayItem.modelData, trayItem)) {
                  return
                } else {
                  trayItem.modelData.activate()
                }
              }

              onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
            }
          }
        }
      }
    }

    Rectangle {
      width: Config.buttonWidth
      height: Config.buttonHeight
      radius: Config.buttonRadius
      color: arrowMouse.containsMouse ? Config.pressedBg : "#00000000"

      Text {
        anchors.centerIn: parent
        text: root.expanded ? Config.iconChevronRight : Config.iconChevronLeft
        color: arrowMouse.containsMouse ? Config.textWhite : Config.textPrimary
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon

        Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      }

      MouseArea {
        id: arrowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.expanded = true
      }
    }
  }
}
