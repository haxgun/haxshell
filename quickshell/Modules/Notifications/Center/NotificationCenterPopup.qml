// NotificationCenterPopup.qml - Notification history and active notification panel
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../"
import "../../../Common"
import "../../../Services"

PanelWindow {
  id: panel

  property var targetScreen: null
  property bool isOpen: false
  property int rightMargin: 16
  readonly property bool isTargetScreen: NotificationService.isScreenFocused(targetScreen)
  readonly property int notificationCount: NotificationService.notificationCount
  readonly property var centerModel: notificationCount > 0 ? NotificationService.notifications : NotificationService.historyList

  signal closeRequested()

  screen: targetScreen
  visible: isTargetScreen && (isOpen || container.opacity > 0.01)
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen && isTargetScreen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  MouseArea { anchors.fill: parent; enabled: panel.isOpen && panel.isTargetScreen; onClicked: panel.closeRequested() }

  Rectangle {
    id: container
    width: Config.notificationsWidth
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: panel.rightMargin
    y: panel.isOpen && panel.isTargetScreen ? Config.dropdownTopGap : -12
    opacity: panel.isOpen && panel.isTargetScreen ? 1.0 : 0.0
    color: Config.popupGlassBg
    radius: Config.overlayRadius

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

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: Config.shellBordersEnabled ? 1 : 0 }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Row {
        width: parent.width
        height: 30
        spacing: 10

        Text { text: Config.iconNotificationsActive; color: Config.textWhite; font.pixelSize: Config.fontSizeTitle; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { width: parent.width - 86; text: I18n.tr("Уведомления"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }

        Rectangle {
          width: 36
          height: 28
          radius: 8
          color: clearMouse.containsMouse ? "#35f87171" : "#151A1A1A"
          border.color: "#30464646"
          border.width: 1
          opacity: notificationCount > 0 ? 1.0 : 0.45

          Text { anchors.centerIn: parent; text: Config.iconTrash; color: Config.dangerRed; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: notificationCount > 0; onClicked: NotificationService.clearAll() }
        }
      }

      Row {
        width: parent.width
        height: 26
        spacing: 10

        Text { text: Config.iconNotifications; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { width: parent.width - doNotDisturbToggle.width - 28; text: I18n.tr("Не беспокоить"); color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
        ToggleSwitch { id: doNotDisturbToggle; checked: NotificationService.doNotDisturb; anchors.verticalCenter: parent.verticalCenter; onToggled: NotificationService.doNotDisturb = !NotificationService.doNotDisturb }
      }

      Rectangle { width: parent.width; height: 1; color: Config.separatorColor }

      Text {
        width: parent.width
        visible: centerModel.length === 0
        text: I18n.tr("Нет уведомлений")
        color: Config.textMuted
        font.pixelSize: Config.fontSizeNormal
        font.family: Config.fontSans
        horizontalAlignment: Text.AlignHCenter
      }

      ListView {
        width: parent.width
        height: Math.min(460, contentHeight)
        visible: centerModel.length > 0
        clip: true
        spacing: 8
        model: panel.centerModel
        delegate: NotificationCard {}
      }
    }
  }
}
