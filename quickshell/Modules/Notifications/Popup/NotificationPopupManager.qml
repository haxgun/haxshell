// NotificationPopupManager.qml - Notification toast lifecycle manager
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../"
import "../../../Common"
import "../../../Services"

PanelWindow {
  id: panel

  property var targetScreen: null
  property int rightMargin: Config.scaledSize(16)
  property var toastItems: []
  readonly property bool isTargetScreen: NotificationService.isScreenFocused(targetScreen)
  readonly property int toastTimeoutMs: Config.notificationTimeoutMs
  readonly property bool toastAtTop: Config.notificationPosition.indexOf("top-") === 0
  readonly property bool toastAtLeft: Config.notificationPosition.indexOf("left") >= 0
  readonly property bool toastAtCenter: Config.notificationPosition.indexOf("center") >= 0

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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? toastColumn : null
    radius: Config.overlayRadius
  }

  Connections {
    target: NotificationService
    function onNotificationReceived(notification) {
      if (panel.isTargetScreen && !NotificationService.doNotDisturb) panel.showToast(notification)
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
    width: Config.scaledSize(360)
    height: implicitHeight
    anchors.top: panel.toastAtTop ? parent.top : undefined
    anchors.topMargin: panel.toastAtTop ? 8 : 0
    anchors.bottom: panel.toastAtTop ? undefined : parent.bottom
    anchors.bottomMargin: panel.toastAtTop ? 0 : 8
    anchors.left: panel.toastAtLeft ? parent.left : undefined
    anchors.leftMargin: panel.toastAtLeft ? panel.rightMargin : 0
    anchors.right: panel.toastAtLeft || panel.toastAtCenter ? undefined : parent.right
    anchors.rightMargin: panel.toastAtLeft || panel.toastAtCenter ? 0 : panel.rightMargin
    anchors.horizontalCenter: panel.toastAtCenter ? parent.horizontalCenter : undefined
    spacing: Config.scaledSize(10)

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
