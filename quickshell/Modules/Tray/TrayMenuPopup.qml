// TrayMenuPopup.qml - Custom styled tray DBusMenu renderer
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property var menuHandle: null
  property int anchorX: 16
  property int anchorY: 48
  property int anchorWidth: Config.buttonWidth

  visible: isOpen || container.opacity > 0.01

  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  QsMenuOpener {
    id: menuOpener
    menu: root.menuHandle
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: root.isOpen = false
  }

  function clampedX() {
    return Math.min(Math.max(root.anchorX + root.anchorWidth / 2 - container.width / 2, 16), Math.max(16, root.width - container.width - 16))
  }

  function clampedY() {
    return Math.min(Math.max(root.anchorY + 2, Config.popupTopGap), Math.max(Config.popupTopGap, root.height - container.implicitHeight - 16))
  }

  function openMenu(menu, x, y, width) {
    if (!menu) return
    root.anchorX = typeof x === "number" ? x : root.anchorX
    root.anchorY = typeof y === "number" ? y : root.anchorY
    root.anchorWidth = typeof width === "number" ? width : Config.buttonWidth
    root.menuHandle = menu
    root.isOpen = true
  }

  function cleanText(text) {
    return (text || "").replace(/_/g, "")
  }

  function triggerEntry(entry) {
    if (!entry || !entry.enabled) return
    entry.triggered()
    root.isOpen = false
  }

  Rectangle {
    id: container
    width: 280
    implicitHeight: Math.min(menuColumn.implicitHeight + 16, 480)
    x: root.clampedX()
    y: root.isOpen ? root.clampedY() : root.clampedY() - 12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg
    clip: true

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

    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

    MouseArea {
      anchors.fill: parent
      onClicked: mouse => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.borderColor
      border.width: Config.shellBordersEnabled ? 1 : 0
    }

    Flickable {
      width: parent.width - 16
      height: Math.min(menuColumn.implicitHeight, 464)
      anchors.centerIn: parent
      contentWidth: width
      contentHeight: menuColumn.implicitHeight
      clip: true

      Column {
        id: menuColumn
        width: parent.width
        spacing: 4

        Repeater {
          model: menuOpener.children

          Column {
            id: entryBlock
            required property var modelData
            property bool expanded: false

            width: menuColumn.width
            spacing: 3

            Rectangle {
              width: parent.width
              height: entryBlock.modelData.isSeparator ? 9 : 34
              radius: Config.buttonRadius
              color: entryMouse.containsMouse && entryBlock.modelData.enabled && !entryBlock.modelData.isSeparator ? Config.hoverBg : "#00000000"
              opacity: entryBlock.modelData.enabled ? 1.0 : 0.45

              Rectangle {
                visible: entryBlock.modelData.isSeparator
                width: parent.width - 12
                height: 1
                color: Config.separatorColor
                anchors.centerIn: parent
              }

              Row {
                visible: !entryBlock.modelData.isSeparator
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                  width: 16
                  text: entryBlock.modelData.buttonType !== QsMenuButtonType.None ? (entryBlock.modelData.checkState === Qt.Checked ? "●" : "○") : ""
                  color: Config.textMuted
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontSans
                  anchors.verticalCenter: parent.verticalCenter
                }

                IconImage {
                  width: 18
                  height: 18
                  source: entryBlock.modelData.icon
                  visible: entryBlock.modelData.icon.length > 0
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  width: parent.width - 58 - (entryBlock.modelData.icon.length > 0 ? 26 : 0)
                  text: root.cleanText(entryBlock.modelData.text)
                  color: Config.textPrimary
                  font.pixelSize: Config.fontSizeNormal
                  font.family: Config.fontSans
                  elide: Text.ElideRight
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  width: 14
                  text: entryBlock.modelData.hasChildren ? (entryBlock.expanded ? Config.iconChevronRight : Config.iconChevronLeft) : ""
                  color: Config.textMuted
                  font.pixelSize: Config.fontSizeIconSmall
                  font.family: Config.fontIcon
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: entryMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !entryBlock.modelData.isSeparator && entryBlock.modelData.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (entryBlock.modelData.hasChildren) {
                    entryBlock.expanded = !entryBlock.expanded
                  } else {
                    root.triggerEntry(entryBlock.modelData)
                  }
                }
              }
            }

            QsMenuOpener {
              id: childOpener
              menu: entryBlock.modelData.hasChildren ? entryBlock.modelData : null
            }

            Item {
              width: parent.width
              height: entryBlock.expanded ? childColumn.implicitHeight : 0
              clip: true
              opacity: entryBlock.expanded ? 1.0 : 0.0

              Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

              Column {
                id: childColumn
                width: parent.width - 18
                x: 18
                spacing: 3

                Repeater {
                  model: childOpener.children

                  Rectangle {
                    required property var modelData

                    width: childColumn.width
                    height: modelData.isSeparator ? 9 : 30
                    radius: Config.buttonRadius
                    color: childMouse.containsMouse && modelData.enabled && !modelData.isSeparator ? Config.hoverBg : "#00000000"
                    opacity: modelData.enabled ? 1.0 : 0.45

                    Rectangle { visible: modelData.isSeparator; width: parent.width - 12; height: 1; color: Config.separatorColor; anchors.centerIn: parent }
                    Text { visible: !modelData.isSeparator; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: Text.AlignVCenter; text: root.cleanText(modelData.text); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight }

                    MouseArea {
                      id: childMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      enabled: !modelData.isSeparator && modelData.enabled
                      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                      onClicked: root.triggerEntry(modelData)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
