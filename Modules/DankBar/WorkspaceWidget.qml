// WorkspaceWidget.qml - Hyprland Workspace Switcher & Launcher Button
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  implicitWidth: rowLayout.implicitWidth + 16
  implicitHeight: Config.barHeight
  property bool embeddedInBar: false

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

  // Active workspace ID from Hyprland
  readonly property int activeWsId: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1

  // Only show occupied workspaces and the currently focused workspace.
  readonly property var workspaceList: {
    let arr = []
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      let list = Hyprland.workspaces.values
      for (let i = 0; i < list.length; i++) {
        let ws = list[i]
        if (!ws || ws.id <= 0) continue
        let occupied = ws.toplevels ? ws.toplevels.values.length > 0 : true
        if (occupied || ws.id === activeWsId) arr.push(ws.id)
      }
    }
    if (arr.indexOf(activeWsId) < 0) arr.push(activeWsId)
    arr.sort((a, b) => a - b)
    return arr
  }

  // Check if a given workspace ID is occupied
  function isWorkspaceOccupied(wsId) {
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      let list = Hyprland.workspaces.values
      for (let i = 0; i < list.length; i++) {
        if (list[i] && list[i].id === wsId) {
          return list[i].toplevels ? list[i].toplevels.values.length > 0 : true
        }
      }
    }
    return false
  }

  function switchToWorkspace(wsId) {
    if (typeof Hyprland !== "undefined" && Hyprland.dispatch) {
      Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
    }
  }

  Row {
    id: rowLayout
    anchors.centerIn: parent
    spacing: 2

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
      width: 6
      height: 18
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 18
        color: Config.separatorColor
      }
    }

    Repeater {
      model: root.workspaceList

      Rectangle {
        id: itemRect
        required property int modelData
        required property int index

        width: 32
        height: Config.buttonHeight
        radius: Config.buttonRadius

        // Workspace States
        readonly property bool isActive: root.activeWsId === modelData
        readonly property bool isOccupied: root.isWorkspaceOccupied(modelData)
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
          text: modelData.toString()
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
            root.switchToWorkspace(modelData)
          }
        }
      }
    }
  }
}
