// WorkspaceWidget.qml - Workspace switcher and launcher button
import QtQuick
import Quickshell
import "../../Common"
import "../../Services"

Rectangle {
  id: root

  implicitWidth: root.vertical ? Config.buttonWidth + 16 : rowLayout.implicitWidth + 16
  implicitHeight: root.vertical ? rowLayout.implicitHeight + 16 : Config.barHeight
  property bool embeddedInBar: false
  property bool vertical: false
  property var tooltip: null

  Behavior on implicitWidth {
    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
  }

  // Frosted Glass Tint & Border
  color: embeddedInBar ? "#00000000" : Config.glassBg
  radius: Config.widgetRadius

  Rectangle {
    anchors.fill: parent
    visible: !root.embeddedInBar
    anchors.margins: Config.innerBorderMargin
    radius: Config.innerBorderRadius
    color: "#00000000"
    border.color: Config.borderColor
    border.width: 1
  }

  // Target AppDrawer reference to toggle
  property var appDrawer: null

  // Indicator style configuration for occupied workspaces
  // Options: "dot" (Bottom Dot), "tint" (Soft Translucent Tint), "border" (Subtle Border Ring)
  property string indicatorStyle: Config.workspaceIndicatorStyle

  property string monitorName: ""
  readonly property bool showAllWorkspaces: Config.showWorkspacesOnAllMonitors

  function isOnMonitor(ws) {
    if (!ws) return false
    if (root.monitorName.length === 0) return true
    return ws.output === root.monitorName
  }

  // Only show occupied workspaces and the active workspace on this monitor.
  readonly property var workspaceList: {
    let arr = []
    let list = CompositorService.workspaces
    for (let i = 0; i < list.length; i++) {
      let ws = list[i]
      if (!ws || (!root.showAllWorkspaces && !root.isOnMonitor(ws))) continue
      if (ws.occupied || ws.active) arr.push(ws)
    }
    arr.sort((a, b) => a.sortIndex - b.sortIndex)
    return arr
  }

  Grid {
    id: rowLayout
    anchors.left: parent.left
    anchors.leftMargin: Config.scaledSize(8)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.scaledSize(2)
    rows: root.vertical ? 0 : 1
    columns: root.vertical ? 1 : 0

    // App Launcher Toggle Button
    Rectangle {
      id: launcherBtn
      width: Config.scaledSize(32)
      height: Config.buttonHeight
      radius: Config.buttonRadius
      visible: Config.barLauncherEnabled
      readonly property bool isDrawerActive: (root.appDrawer && root.appDrawer.isOpen)
      color: (isDrawerActive || launcherMouse.containsMouse) ? Config.activeHoverBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Config.iconLauncher
        color: (launcherBtn.isDrawerActive || launcherMouse.containsMouse) ? Config.textWhite : Config.iconColor
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: launcherMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.tooltip) root.tooltip.show(launcherBtn, I18n.tr("Меню приложений"))
        onExited: if (root.tooltip) root.tooltip.hide()
        onClicked: if (root.appDrawer) root.appDrawer.isOpen = !root.appDrawer.isOpen
      }
    }

    // Separator line
    Item {
      width: root.vertical ? 16 : 6
      height: launcherBtn.height
      visible: Config.barLauncherEnabled && Config.barWorkspacesEnabled

      Rectangle {
        anchors.centerIn: parent
        width: root.vertical ? 10 : 1
        height: root.vertical ? 1 : Math.max(12, launcherBtn.height - 12)
        color: Config.separatorColor
      }
    }

    Repeater {
      model: root.workspaceList

      Rectangle {
        id: itemRect
        required property var modelData
        required property int index

        visible: Config.barWorkspacesEnabled
        width: Config.scaledSize(32)
        height: Config.buttonHeight
        radius: Config.buttonRadius

        // Workspace States
        readonly property bool isActive: modelData.active
        readonly property bool isOccupied: modelData.occupied
        readonly property bool isHovered: mouseArea.containsMouse

        // Configurable Background Color
        color: isActive ? Config.selectedBg : (isHovered ? Config.hoverBg : (!isActive && isOccupied && root.indicatorStyle === "tint" ? Config.workspaceOccupiedBg : "#00000000"))

        // Configurable Inset Border
        border.color: (!isActive && isOccupied && root.indicatorStyle === "border") ? Config.workspaceOccupiedBorder : "#00000000"
        border.width: (!isActive && isOccupied && root.indicatorStyle === "border") ? 1 : 0

        Behavior on color {
          ColorAnimation { duration: 150 }
        }

        Text {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: (!itemRect.isActive && itemRect.isOccupied && root.indicatorStyle === "dot") ? -2 : 0
          text: modelData.label
          visible: Config.showWorkspaceNumbers
          color: itemRect.isActive ? Config.textWhite : (itemRect.isOccupied ? Config.textPrimary : (itemRect.isHovered ? Config.textSubtle : Config.textPlaceholder))
          font.pixelSize: Config.fontSizeMedium
          font.weight: itemRect.isActive ? Font.Medium : (itemRect.isOccupied ? Font.Medium : Font.Normal)
          font.family: Config.fontSans
        }

        // Bottom Dot Indicator for Occupied Workspaces
        Rectangle {
          width: 4
          height: 4
          radius: 2
          color: Config.iconColor
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Config.scaledSize(3)
          visible: !itemRect.isActive && itemRect.isOccupied && root.indicatorStyle === "dot"
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: if (root.tooltip) root.tooltip.show(itemRect, I18n.tr("Рабочий стол") + " " + modelData.label)
          onExited: if (root.tooltip) root.tooltip.hide()
          onClicked: {
            CompositorService.switchWorkspace(modelData)
          }
        }
      }
    }
  }
}
