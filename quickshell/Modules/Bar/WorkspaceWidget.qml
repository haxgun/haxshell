// WorkspaceWidget.qml - Workspace switcher and launcher button
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"
import "../../Services"

Rectangle {
  id: root

  implicitWidth: root.vertical ? Config.buttonWidth + 16 : rowLayout.implicitWidth + 16
  implicitHeight: root.vertical ? rowLayout.implicitHeight + 16 : Config.barHeight
  property bool embeddedInBar: false
  property bool vertical: false

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

  Process {
    id: launcherProc
    command: ["setsid", "-f", "sh", "-c", Config.cmdLauncher + " >/dev/null 2>&1"]
  }

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
    anchors.centerIn: parent
    spacing: 2
    rows: root.vertical ? 0 : 1
    columns: root.vertical ? 1 : 0

    // App Launcher Toggle Button
    Rectangle {
      id: launcherBtn
      width: 32
      height: Config.buttonHeight
      radius: Config.buttonRadius
      readonly property bool isDrawerActive: (root.appDrawer && root.appDrawer.isOpen)
      color: (isDrawerActive || launcherMouse.containsMouse) ? Config.activeHoverBg : "#00000000"

      Behavior on color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Config.iconLauncher
        color: (launcherBtn.isDrawerActive || launcherMouse.containsMouse) ? Config.textWhite : Config.textPrimary
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: launcherMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          launcherProc.running = false
          launcherProc.running = true
        }
      }
    }

    // Separator line
    Item {
      width: root.vertical ? 16 : 6
      height: launcherBtn.height

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

        width: 32
        height: Config.buttonHeight
        radius: Config.buttonRadius

        // Workspace States
        readonly property bool isActive: modelData.active
        readonly property bool isOccupied: modelData.occupied
        readonly property bool isHovered: mouseArea.containsMouse

        // Configurable Background Color
        color: isActive ? Config.selectedBg : (isHovered ? Config.hoverBg : (!isActive && isOccupied && root.indicatorStyle === "tint" ? "#18e2e8f0" : "#00000000"))

        // Configurable Inset Border
        border.color: (!isActive && isOccupied && root.indicatorStyle === "border") ? "#50e2e8f0" : "#00000000"
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
          font.weight: itemRect.isActive ? Font.Bold : (itemRect.isOccupied ? Font.Medium : Font.Normal)
          font.family: Config.fontSans
        }

        // Bottom Dot Indicator for Occupied Workspaces
        Rectangle {
          width: 4
          height: 4
          radius: 2
          color: Config.textPrimary
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 3
          visible: !itemRect.isActive && itemRect.isOccupied && root.indicatorStyle === "dot"
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            CompositorService.switchWorkspace(modelData)
          }
        }
      }
    }
  }
}
