// QuickControlTile.qml - DMS-style quick control with separate toggle and detail actions
import QtQuick
import "../../Common"

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool active: false
  signal toggled()
  signal detailsRequested()

  width: parent ? (parent.width - 8) / 2 : 250
  height: 62
  radius: Config.cardRadius
  color: bodyMouse.containsMouse ? Config.hoverBg : Config.searchBg
  border.color: active ? Config.activeBorderColor : Config.borderColor
  border.width: 1

  Rectangle {
    id: iconTile
    width: 46
    height: 46
    radius: 10
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    color: root.active ? Config.selectedBg : Config.controlIdleBg
    border.color: root.active ? Config.activeBorderColor : Config.borderColor
    border.width: 1
    Text { anchors.centerIn: parent; text: root.icon; color: root.active ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeIconLarge; font.family: Config.fontIcon }
    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
  }

  Column {
    anchors.left: iconTile.right
    anchors.leftMargin: 10
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    Text { width: parent.width; text: root.title; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
    Text { width: parent.width; text: root.subtitle; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight }
  }

  MouseArea {
    id: bodyMouse
    anchors.left: iconTile.right
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.detailsRequested()
  }
}
