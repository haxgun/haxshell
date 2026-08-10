import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../"
import "../../../Common"
import "../../../Services"

PanelWindow {
  id: panel

  property var targetScreen: null
  property int rightMargin: 16
  property var toastItems: []
  readonly property bool isTargetScreen: NotificationService.isScreenFocused(targetScreen)
  readonly property int toastTimeoutMs: 15000

  signal centerRequested()

  screen: targetScreen
  visible: toastItems.length > 0
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  mask: Region { item: toastColumn }
  color: "#00000000"

  Connections {
    target: NotificationService
    function onNotificationReceived(notification) {
      if (panel.isTargetScreen) panel.showToast(notification)
    }
  }

  function showToast(notification) {
    if (!notification) return
    panel.toastItems = [{
      id: notification.id,
      notification: notification,
      summary: notification.summary || notification.appName || "Уведомление",
      body: notification.body || "",
      appName: notification.appName || "",
      imageSource: NotificationService.notificationImageSource(notification),
      iconSource: NotificationService.notificationIconSource(notification)
    }].concat(panel.toastItems)
  }

  function removeToast(notificationId) {
    let list = panel.toastItems.slice()
    for (let i = 0; i < list.length; i++) {
      if (list[i] && list[i].id === notificationId) {
        list.splice(i, 1)
        panel.toastItems = list
        return
      }
    }
  }

  Column {
    id: toastColumn
    width: 360
    height: implicitHeight
    anchors.top: parent.top
    anchors.topMargin: 8
    anchors.right: parent.right
    anchors.rightMargin: panel.rightMargin
    spacing: 10

    Repeater {
      model: panel.toastItems
      NotificationToast {
        timeoutMs: panel.toastTimeoutMs
        onRemoveRequested: id => panel.removeToast(id)
        onCenterRequested: panel.centerRequested()
      }
    }
  }
}
