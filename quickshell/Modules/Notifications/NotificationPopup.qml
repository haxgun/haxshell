// NotificationPopup.qml - Notification center overlay entry point
import Quickshell
import Quickshell.Io
import "../../Common"
import "../../Services"
import "Popup"
import "Center"

Scope {
  id: root

  property bool isOpen: false
  property int rightMargin: Config.scaledSize(16)
  readonly property int notificationCount: NotificationService.notificationCount

  IpcHandler {
    target: "notifications"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
    function clear() { NotificationService.clearCurrent() }
  }

  Variants {
    model: Quickshell.screens
    NotificationPopupManager {
      required property var modelData
      targetScreen: modelData
      rightMargin: root.rightMargin
      centerOpen: root.isOpen
      onCenterRequested: root.isOpen = true
    }
  }

  Variants {
    model: Quickshell.screens
    NotificationCenterPopup {
      required property var modelData
      targetScreen: modelData
      isOpen: root.isOpen
      rightMargin: root.rightMargin
      onCloseRequested: root.isOpen = false
    }
  }
}
