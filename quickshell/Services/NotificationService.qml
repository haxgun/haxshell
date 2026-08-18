pragma Singleton

// NotificationService.qml - Notification storage, actions, and image resolution

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../Common"

Singleton {
  id: root

  readonly property var notifications: notificationServer.trackedNotifications && notificationServer.trackedNotifications.values ? notificationServer.trackedNotifications.values : []
  readonly property int notificationCount: notifications.length
  property var historyList: []
  readonly property int historyLimit: 80
  property bool doNotDisturb: Config.doNotDisturb

  signal notificationReceived(var notification)
  Process { id: soundProc }

  NotificationServer {
    id: notificationServer
    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: true
    inlineReplySupported: true

    onNotification: notification => {
      notification.tracked = true
      root.addToHistory(notification)
      if (!root.isMuted(notification)) {
        root.notificationReceived(notification)
        root.playSound()
      }
    }
  }

  function isScreenFocused(screen) {
    return CompositorService.isScreenFocused(screen)
  }

  function setDoNotDisturb(enabled) {
    Config.doNotDisturb = enabled
    SettingsStore.setValue("doNotDisturb", enabled ? "true" : "false")
  }

  function isMuted(notification) {
    let app = (notification.appName || notification.desktopEntry || "").toLowerCase()
    let muted = Config.notificationMutedApps.toLowerCase().split(",").map(name => name.trim())
    return muted.indexOf(app) >= 0
  }

  function playSound() {
    if (!Config.notificationSoundEnabled || Config.doNotDisturb) return
    soundProc.running = false
    soundProc.command = ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]
    soundProc.running = true
  }

  function notificationImageSource(notification) {
    let image = notification && notification.image ? notification.image : ""
    if (!image) return ""
    return image.indexOf("/") === 0 ? "file://" + image : image
  }

  function historyImageSource(notification) {
    return notificationImageSource(notification)
  }

  function notificationIconSource(notification) {
    let icon = notification && notification.appIcon ? notification.appIcon : ""
    if (!icon && notification && notification.desktopEntry) icon = notification.desktopEntry
    if (!icon) return ""
    if (icon.indexOf("/") === 0) return "file://" + icon
    if (icon.indexOf(":") >= 0) return icon
    return "image://icon/" + icon.replace(/\.desktop$/, "")
  }

  function hasThumbnail(notification) {
    return notificationImageSource(notification).length > 0 || notificationIconSource(notification).length > 0 || !!(notification && notification.appName)
  }

  function clearCurrent() {
    let list = notifications.slice()
    for (let i = 0; i < list.length; i++) list[i].dismiss()
  }

  function clearHistory() {
    historyList = []
  }

  function clearAll() {
    clearCurrent()
    clearHistory()
  }

  function removeNotification(notification) {
    if (!notification) return
    let id = notification.id
    if (notification.dismiss) notification.dismiss()
    if (typeof id !== "undefined") removeFromHistory(id)
  }

  function removeFromHistory(notificationId) {
    let next = []
    for (let i = 0; i < historyList.length; i++) {
      if (historyList[i] && historyList[i].id !== notificationId) next.push(historyList[i])
    }
    historyList = next
  }

  function addToHistory(notification) {
    if (!notification) return
    let item = {
      id: notification.id,
      summary: notification.summary || notification.appName || "Уведомление",
      body: notification.body || "",
      appName: notification.appName || "",
      appIcon: notification.appIcon || "",
      desktopEntry: notification.desktopEntry || "",
      imageSource: historyImageSource(notification),
      iconSource: notificationIconSource(notification),
      urgency: notification.urgency || 0,
      timestamp: Date.now()
    }
    historyList = [item].concat(historyList).slice(0, historyLimit)
  }

  function invokeDefault(notification) {
    let actions = notification && notification.actions ? notification.actions : []
    for (let i = 0; i < actions.length; i++) {
      if (actions[i] && actions[i].identifier === "default") {
        actions[i].invoke()
        return true
      }
    }
    for (let j = 0; j < actions.length; j++) {
      if (actions[j]) {
        actions[j].invoke()
        return true
      }
    }
    return false
  }
}
