// NotificationToast.qml - Timed desktop notification toast
import QtQuick
import Quickshell.Widgets
import "../../../"
import "../../../Common"
import "../../../Services"

Rectangle {
  id: toast

  required property var modelData
  property int timeoutMs: 15000
  readonly property var toastData: modelData || ({})
  readonly property var notification: toastData.notification || null
  readonly property int notificationId: toastData.id || -1
  readonly property string toastSummary: toastData.summary || "Уведомление"
  readonly property string toastBody: toastData.body || ""
  readonly property string toastAppName: toastData.appName || ""
  readonly property string toastImageSource: toastData.imageSource || ""
  readonly property string toastIconSource: toastData.iconSource || ""
  property bool shown: false
  property bool closing: false

  signal removeRequested(int notificationId)
  signal centerRequested()

  width: Config.scaledSize(360)
  implicitHeight: Math.max(toastThumb.visible ? toastThumb.height : 0, toastText.implicitHeight) + 24
  radius: Config.overlayRadius
  color: Config.popupGlassBg
  clip: true
  opacity: shown && !closing ? 1.0 : 0.0
  x: 0

  Rectangle {
    visible: Config.popupShadowsEnabled
    x: 0
    y: Config.shellShadowOffsetY
    width: parent.width
    height: parent.height
    radius: parent.radius
    color: Config.shellShadowColor
    opacity: 0.55
    z: -1
  }

  Component.onCompleted: shown = true

  Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
  Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

  Timer { interval: toast.timeoutMs; running: true; repeat: false; onTriggered: toast.dismiss() }
  Timer { id: destroyTimer; interval: 220; repeat: false; onTriggered: toast.removeRequested(toast.notificationId) }

  function dismiss() {
    if (closing) return
    closing = true
    x = 36
    destroyTimer.restart()
  }

  function activateNotification() {
    if (!NotificationService.invokeDefault(toast.notification)) toast.centerRequested()
    toast.dismiss()
  }

  function closeNotification() {
    let n = toast.notification
    toast.dismiss()
    if (n) n.dismiss()
  }

  Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

  MouseArea {
    id: toastDragArea
    z: 0
    anchors.fill: parent
    anchors.rightMargin: Config.scaledSize(46)
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    drag.target: toast
    drag.axis: Drag.XAxis
    drag.minimumX: -140
    drag.maximumX: 140
    onClicked: mouse => mouse.button === Qt.RightButton ? toast.closeNotification() : toast.activateNotification()
    onReleased: {
      if (toast.x > 90) toast.closeNotification()
      else if (toast.x < -90) toast.activateNotification()
      else if (!toast.closing) toast.x = 0
    }
  }

  Item {
    z: 1
    anchors.fill: parent
    anchors.margins: Config.scaledSize(12)

    Rectangle {
      id: toastThumb
      width: visible ? 44 : 0
      height: Config.scaledSize(44)
      radius: Config.popupRadiusPx(11)
      color: Config.controlIdleBg
      clip: true
      visible: toast.toastImageSource.length > 0 || toast.toastIconSource.length > 0 || toast.toastAppName.length > 0
      anchors.left: parent.left
      anchors.top: parent.top

      ClippingRectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        Image { id: toastImage; anchors.fill: parent; source: toast.toastImageSource; visible: source.toString().length > 0; fillMode: Image.PreserveAspectCrop; asynchronous: true }
      }
      IconImage { anchors.centerIn: parent; width: Config.scaledSize(28); height: Config.scaledSize(28); source: toast.toastIconSource; visible: !toastImage.visible && source.toString().length > 0 }
      Text { anchors.centerIn: parent; visible: !toastImage.visible && toast.toastIconSource.length === 0; text: (toast.toastAppName || "?").charAt(0).toUpperCase(); color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans }
    }

    Column {
      id: toastText
      anchors.left: toastThumb.visible ? toastThumb.right : parent.left
      anchors.leftMargin: toastThumb.visible ? 10 : 0
      anchors.right: toastClose.left
      anchors.rightMargin: Config.scaledSize(10)
      anchors.top: parent.top
      spacing: Config.scaledSize(3)

      Text { width: parent.width; text: toast.toastSummary; color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight; maximumLineCount: 1 }
      Text { width: parent.width; text: toast.toastBody; color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.WrapAnywhere; maximumLineCount: 4; elide: Text.ElideRight; visible: text.length > 0 }
    }

    Rectangle {
      id: toastClose
      z: 10
      width: Config.scaledSize(28)
      height: Config.scaledSize(28)
      radius: Config.popupRadiusPx(9)
      anchors.top: parent.top
      anchors.right: parent.right
      color: toastCloseMouse.containsMouse ? "#35f87171" : "#00000000"

      Text { anchors.centerIn: parent; text: "×"; color: toastCloseMouse.containsMouse ? Config.dangerRed : Config.textMuted; font.pixelSize: Config.fontSizeLarge; font.family: Config.fontSans }
      MouseArea { id: toastCloseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mouse => { mouse.accepted = true; toast.closeNotification() } }
    }
  }
}
