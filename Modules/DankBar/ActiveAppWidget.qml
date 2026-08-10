// ActiveAppWidget.qml - Focused Hyprland application indicator
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../Common"

Rectangle {
  id: root

  readonly property var activeWindow: Hyprland.activeToplevel
  readonly property var ipc: activeWindow ? activeWindow.lastIpcObject : ({})
  readonly property string appClass: (ipc.class || ipc.initialClass || ipc.initialTitle || "").toString()
  readonly property string appTitle: activeWindow ? (activeWindow.title || ipc.title || "") : ""
  readonly property var desktopEntry: lookupDesktopEntry()
  readonly property string appName: desktopEntry ? desktopEntry.name : prettyAppName(appClass)
  readonly property bool hasApp: !!activeWindow

  visible: hasApp
  implicitWidth: Math.min(appRow.implicitWidth + 14, 360)
  implicitHeight: Config.buttonHeight
  radius: Config.buttonRadius
  color: appMouse.containsMouse ? Config.hoverBg : "#00000000"

  function lookupDesktopEntry() {
    let names = []
    if (root.appClass) {
      names.push(root.appClass)
      names.push(root.appClass.toLowerCase())
      names.push(root.appClass + ".desktop")
      names.push(root.appClass.toLowerCase() + ".desktop")
    }
    if (root.ipc.initialClass) names.push(root.ipc.initialClass)
    if (root.ipc.title) names.push(root.ipc.title)

    for (let i = 0; i < names.length; i++) {
      let entry = DesktopEntries.byId(names[i]) || DesktopEntries.heuristicLookup(names[i])
      if (entry) return entry
    }

    let apps = DesktopEntries.applications && DesktopEntries.applications.values ? DesktopEntries.applications.values : []
    let needle = root.appClass.toLowerCase()
    for (let j = 0; j < apps.length; j++) {
      let app = apps[j]
      if (!app) continue
      let id = (app.id || "").toLowerCase()
      let startup = (app.startupClass || "").toLowerCase()
      if (id === needle + ".desktop" || id === needle || startup === needle) return app
    }
    return null
  }

  function prettyAppName(value) {
    if (!value) return "Рабочий стол"
    let part = value.split(".").filter(p => p.length > 0).pop() || value
    if (part.toLowerCase() === "desktop" && value.toLowerCase().includes("telegram")) return "Telegram"
    return part.charAt(0).toUpperCase() + part.slice(1)
  }

  function iconSource() {
    let icon = root.desktopEntry ? root.desktopEntry.icon : root.appClass
    if (!icon) return ""
    if (icon.indexOf("/") === 0) return "file://" + icon
    return icon.indexOf(":") >= 0 ? icon : "image://icon/" + icon
  }

  function labelText() {
    if (!root.appTitle) return root.appName
    return root.appName + " - " + root.appTitle
  }

  Row {
    id: appRow
    anchors.centerIn: parent
    spacing: 6

    IconImage {
      width: 18
      height: 18
      source: root.iconSource()
      asynchronous: true
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      width: Math.min(300, implicitWidth)
      text: root.labelText()
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontSans
      elide: Text.ElideRight
      maximumLineCount: 1
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: appMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
