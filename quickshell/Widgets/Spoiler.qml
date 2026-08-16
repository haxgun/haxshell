// Spoiler.qml - Reusable collapsible section
import QtQuick
import "../Common"

Column {
  id: root

  property string title: ""
  property bool expanded: false
  default property alias content: body.data

  width: parent ? parent.width : 0
  spacing: Config.scaledSize(6)

  Rectangle {
    id: header
    width: parent.width
    height: Config.scaledSize(34)
    radius: Config.cardRadius
    color: headerMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
    border.color: Config.borderColor
    border.width: 1

    Row {
      anchors.left: parent.left
      anchors.leftMargin: Config.scaledSize(10)
      anchors.right: parent.right
      anchors.rightMargin: Config.scaledSize(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Config.scaledSize(8)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.expanded ? "󰅀" : "󰅃"
        color: Config.textMuted
        font.pixelSize: Config.fontSizeIconSmall
        font.family: Config.fontIcon
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Config.textPrimary
        font.pixelSize: Config.fontSizeSmall
        font.weight: Font.Medium
        font.family: Config.fontSans
        elide: Text.ElideRight
      }
    }

    MouseArea {
      id: headerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  Item {
    width: parent.width
    height: root.expanded ? body.implicitHeight : 0
    clip: true
    opacity: root.expanded ? 1.0 : 0.0

    Behavior on height { NumberAnimation { duration: Config.reduceMotion ? 0 : 150; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 100 } }

    Column {
      id: body
      width: parent.width
      spacing: Config.scaledSize(8)
    }
  }
}
