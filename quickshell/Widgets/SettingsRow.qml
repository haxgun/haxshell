// SettingsRow.qml - Reusable settings list row
import QtQuick
import "../Common"

Item {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool last: false
  property bool hovered: rowMouse.containsMouse
  signal clicked()
  default property alias control: controlSlot.data

  width: parent ? parent.width : 0
  height: Math.max(46, Math.max(textColumn.implicitHeight, controlSlot.childrenRect.height) + 14)

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: 3
    anchors.bottomMargin: 3
    radius: Config.cardRadius
    color: root.hovered ? Config.hoverBg : "#00000000"
    Behavior on color { ColorAnimation { duration: Config.reduceMotion ? 0 : 120 } }
  }

  MouseArea {
    id: rowMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Text {
    id: iconText
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: 18
    horizontalAlignment: Text.AlignHCenter
    text: root.icon
    color: root.hovered ? Config.textWhite : Config.textMuted
    font.pixelSize: Config.fontSizeIconMedium
    font.family: Config.fontIcon
  }

  Column {
    id: textColumn
    anchors.left: iconText.right
    anchors.leftMargin: 12
    anchors.right: controlSlot.left
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Text { width: parent.width; text: root.title; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
    Text { width: parent.width; visible: root.subtitle.length > 0; text: root.subtitle; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight }
  }

  Item {
    id: controlSlot
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: 36
  }

  Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Config.separatorColor; opacity: 0.45; visible: !root.last }
}
