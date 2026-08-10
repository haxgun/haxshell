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
    anchors.margins: 11
    z: 1

    Rectangle {
      id: centerThumb
      width: visible ? 42 : 0
      height: 42
      radius: 10
      color: "#151A1A1A"
      clip: true
      visible: imageSource.length > 0 || iconSource.length > 0 || appName.length > 0
      anchors.left: parent.left
      anchors.top: parent.top

      Image { id: centerImage; anchors.fill: parent; source: imageSource; visible: source.toString().length > 0; fillMode: Image.PreserveAspectCrop; asynchronous: true }
      IconImage { anchors.centerIn: parent; width: 26; height: 26; source: iconSource; visible: !centerImage.visible && source.toString().length > 0 }
      Text { anchors.centerIn: parent; visible: !centerImage.visible && iconSource.length === 0; text: (appName || "?").charAt(0).toUpperCase(); color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Bold; font.family: Config.fontSans }
    }

    Column {
      id: centerText
      anchors.left: centerThumb.visible ? centerThumb.right : parent.left
      anchors.leftMargin: centerThumb.visible ? 10 : 0
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 5

      Row {
        width: parent.width
        spacing: 8
        Text { width: parent.width - 34; text: card.summary; color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight; maximumLineCount: 1 }
        Rectangle {
          width: 26
          height: 26
          radius: 8
          color: centerCloseMouse.containsMouse ? "#35f87171" : "#151A1A1A"
          border.color: centerCloseMouse.containsMouse ? Config.dangerRed : Config.borderColor
          border.width: 1
          Behavior on color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }
          Behavior on border.color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }
          Text { anchors.centerIn: parent; text: "×"; color: centerCloseMouse.containsMouse ? Config.dangerRed : Config.textMuted; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans }
          MouseArea { id: centerCloseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationService.removeNotification(card.modelData) }
        }
      }

      Text { width: parent.width; text: appName; visible: text.length > 0; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; maximumLineCount: 1 }
      Text { width: parent.width; text: body; visible: text.length > 0; color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.WrapAnywhere; maximumLineCount: 6; elide: Text.ElideRight }

      Row {
        width: parent.width
        spacing: 6
        visible: !card.isHistory && card.actions.length > 0
        Repeater {
          model: card.actions
          Rectangle {
            required property var modelData
            height: 26
            implicitWidth: actionText.implicitWidth + 18
            radius: 7
            color: actionMouse.containsMouse ? Config.activeHoverBg : "#151A1A1A"
            border.color: "#30464646"
            border.width: 1
            Text { id: actionText; anchors.centerIn: parent; text: modelData.text; color: Config.textWhite; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
            MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
          }
        }
      }
    }
  }
}
