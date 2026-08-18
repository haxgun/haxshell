// NotificationCard.qml - Individual notification card for the notification center
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../"
import "../../../Common"
import "../../../Services"

Rectangle {
  id: card

  required property var modelData
  readonly property bool isHistory: !modelData.dismiss
  readonly property var actions: modelData.actions || []
  readonly property string summary: modelData.summary || modelData.appName || "Уведомление"
  readonly property string appName: modelData.appName || ""
  readonly property string body: modelData.body || ""
  readonly property string imageSource: modelData.imageSource || NotificationService.notificationImageSource(modelData)
  readonly property string iconSource: modelData.iconSource || NotificationService.notificationIconSource(modelData)

  width: ListView.view ? ListView.view.width : parent.width
  implicitHeight: Math.max(centerThumb.visible ? centerThumb.height : 0, centerText.implicitHeight) + 22
  radius: Config.cardRadius
  color: notifyMouse.containsMouse ? Config.hoverBg : "#00000000"
  border.color: !isHistory && modelData.urgency === NotificationUrgency.Critical ? Config.dangerRed : Config.borderColor
  border.width: 1
  clip: true

  Behavior on color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }

  MouseArea { id: notifyMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: -1 }

  Item {
    anchors.fill: parent
    anchors.margins: Config.scaledSize(11)
    z: 1

    Rectangle {
      id: centerThumb
      width: visible ? 42 : 0
      height: Config.scaledSize(42)
      radius: Config.popupRadiusPx(10)
      color: Config.controlIdleBg
      clip: true
      visible: imageSource.length > 0 || iconSource.length > 0 || appName.length > 0
      anchors.left: parent.left
      anchors.top: parent.top

      ClippingRectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        Image { id: centerImage; anchors.fill: parent; source: imageSource; visible: source.toString().length > 0; fillMode: Image.PreserveAspectCrop; asynchronous: true }
      }
      IconImage { id: centerIcon; anchors.centerIn: parent; width: Config.scaledSize(26); height: Config.scaledSize(26); source: iconSource; visible: !centerImage.visible && iconSource.length > 0 && centerIcon.status !== Image.Error }
      Text { anchors.centerIn: parent; visible: !centerImage.visible && (iconSource.length === 0 || centerIcon.status === Image.Error); text: (appName || "?").charAt(0).toUpperCase(); color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans }
    }

    Column {
      id: centerText
      anchors.left: centerThumb.visible ? centerThumb.right : parent.left
      anchors.leftMargin: centerThumb.visible ? 10 : 0
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Config.scaledSize(5)

      Row {
        width: parent.width
        spacing: Config.scaledSize(8)
        Text { width: parent.width - 34; text: card.summary; color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight; maximumLineCount: 1 }
        Rectangle {
          width: Config.scaledSize(26)
          height: Config.scaledSize(26)
          radius: Config.popupRadiusPx(8)
          color: centerCloseMouse.containsMouse ? "#35f87171" : Config.controlIdleBg
          border.color: centerCloseMouse.containsMouse ? Config.dangerRed : Config.borderColor
          border.width: 1
          Behavior on color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }
          Behavior on border.color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }
          Text { anchors.centerIn: parent; text: "×"; color: centerCloseMouse.containsMouse ? Config.dangerRed : Config.textMuted; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans }
          MouseArea { id: centerCloseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationService.removeNotification(card.modelData) }
        }
      }

      Text { width: parent.width; text: appName; visible: text.length > 0; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; maximumLineCount: 1 }
      Text { width: parent.width; text: body; visible: text.length > 0; color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.WrapAnywhere; maximumLineCount: 6; elide: Text.ElideRight }

      Row {
        width: parent.width
        spacing: Config.scaledSize(6)
        visible: !card.isHistory && card.actions.length > 0
        Repeater {
          model: card.actions
          Rectangle {
            required property var modelData
            height: Config.scaledSize(26)
            implicitWidth: actionText.implicitWidth + 18
            radius: Config.popupRadiusPx(7)
            color: actionMouse.containsMouse ? Config.activeHoverBg : Config.controlIdleBg
            border.color: Config.subtleBorder
            border.width: 1
            Text { id: actionText; anchors.centerIn: parent; text: modelData.text; color: Config.textWhite; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
            MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
          }
        }
      }
    }
  }
}
