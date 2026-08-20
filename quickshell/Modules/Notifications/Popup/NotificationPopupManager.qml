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
  property bool centerOpen: false
  property bool controlOpen: false
  property int controlHeight: 0
  property string controlScreenName: ""
  property var toastBlurRegion: null
  readonly property int maxVisibleToasts: Config.notificationMaxVisible
  readonly property bool isTargetScreen: NotificationService.isScreenFocused(targetScreen)
  readonly property int toastTimeoutMs: Config.notificationTimeoutMs
  readonly property bool toastAtTop: Config.notificationPosition.indexOf("top-") === 0
  readonly property bool toastAtLeft: Config.notificationPosition.indexOf("left") >= 0
  readonly property bool toastAtCenter: Config.notificationPosition.indexOf("center") >= 0

  signal centerRequested()

  ListModel {
    id: toastModel
    onCountChanged: blurRebuildTimer.restart()
  }

  screen: targetScreen
  visible: toastModel.count > 0
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  mask: Region { item: toastColumn }
  color: "#00000000"
  BackgroundEffect.blurRegion: panel.toastBlurRegion

  Component { id: blurRootComp; Region {} }
  Component {
    id: toastRegionComp
    Region { property Item target; item: target; radius: Config.overlayRadius }
  }

  Timer { id: blurRebuildTimer; interval: 0; repeat: false; onTriggered: panel.rebuildBlur() }

  Connections {
    target: Config
    function onPopupBlurEnabledChanged() { blurRebuildTimer.restart() }
  }

  function rebuildBlur() {
    let old = panel.toastBlurRegion
    let root = null
    if (Config.popupBlurEnabled) {
      root = blurRootComp.createObject(panel)
      let regions = []
      for (let i = 0; i < toastRepeater.count; i++) {
        let toast = toastRepeater.itemAt(i)
        if (!toast) continue
        let r = toastRegionComp.createObject(root, { target: toast })
        if (r) regions.push(r)
      }
      if (regions.length === 0) {
        root.destroy()
        root = null
      } else {
        root.regions = regions
      }
    }
    panel.toastBlurRegion = root
    if (old) old.destroy()
  }

  Connections {
    target: NotificationService
    function onNotificationReceived(notification) {
      if (panel.isTargetScreen && !NotificationService.doNotDisturb) panel.showToast(notification)
    }
    function onDoNotDisturbChanged() {
      if (NotificationService.doNotDisturb) toastModel.clear()
    }
  }

  readonly property bool controlOnThisScreen: controlOpen && controlScreenName.length > 0 && targetScreen && targetScreen.name === controlScreenName
  readonly property int toastTopOffset: controlOnThisScreen && !Config.popupsAtBottom && toastAtTop ? controlHeight + Config.popupGap + 8 : 8
  readonly property int toastBottomOffset: controlOnThisScreen && Config.popupsAtBottom && !toastAtTop ? controlHeight + Config.popupGap + 8 : 8

  onCenterOpenChanged: {
    if (centerOpen) toastModel.clear()
  }

  onMaxVisibleToastsChanged: panel.trimToasts()
  onToastTopOffsetChanged: blurRebuildTimer.restart()
  onToastBottomOffsetChanged: blurRebuildTimer.restart()

  Component.onDestruction: { if (panel.toastBlurRegion) panel.toastBlurRegion.destroy() }

  function trimToasts() {
    while (toastModel.count > maxVisibleToasts) {
      if (Config.popupsAtBottom) toastModel.remove(toastModel.count - 1)
      else toastModel.remove(0)
    }
  }

  function showToast(notification) {
    if (!notification || centerOpen || NotificationService.doNotDisturb) return
    let item = {
      id: notification.id,
      notification: notification,
      summary: notification.summary || notification.appName || I18n.tr("notifications.fallback"),
      body: notification.body || "",
      appName: notification.appName || "",
      imageSource: NotificationService.notificationImageSource(notification),
      iconSource: NotificationService.notificationIconSource(notification),
      timeoutMs: notification.expireTimeout >= 0 ? notification.expireTimeout : panel.toastTimeoutMs
    }
    if (Config.popupsAtBottom) toastModel.insert(0, item)
    else toastModel.append(item)
    panel.trimToasts()
  }

  function removeToast(notificationId) {
    for (let i = 0; i < toastModel.count; i++) {
      if (toastModel.get(i).id === notificationId) {
        toastModel.remove(i)
        return
      }
    }
  }

  Column {
    id: toastColumn
    width: Config.scaledSize(360)
    height: implicitHeight
    anchors.top: panel.toastAtTop ? parent.top : undefined
    anchors.topMargin: panel.toastAtTop ? panel.toastTopOffset : 0
    anchors.bottom: panel.toastAtTop ? undefined : parent.bottom
    anchors.bottomMargin: panel.toastAtTop ? 0 : panel.toastBottomOffset
    anchors.left: panel.toastAtLeft ? parent.left : undefined
    anchors.leftMargin: panel.toastAtLeft ? panel.rightMargin : 0
    anchors.right: panel.toastAtLeft || panel.toastAtCenter ? undefined : parent.right
    anchors.rightMargin: panel.toastAtLeft || panel.toastAtCenter ? 0 : panel.rightMargin
    anchors.horizontalCenter: panel.toastAtCenter ? parent.horizontalCenter : undefined
    spacing: Config.scaledSize(10)

    Repeater {
      id: toastRepeater
      model: toastModel
      NotificationToast {
        timeoutMs: model.timeoutMs
        onRemoveRequested: id => panel.removeToast(id)
        onCenterRequested: panel.centerRequested()
      }
    }
  }
}
