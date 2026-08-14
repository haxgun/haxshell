// QuickControlTile.qml - DMS-style quick control with separate toggle and detail actions
import QtQuick
import "../../Common"

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool active: false
  property bool wide: false
  signal toggled()
  signal detailsRequested()

  width: wide ? (parent ? parent.width : 250) : (parent ? (parent.width - 8) / 2 : 250)
  height: wide ? 62 : 64
  radius: height / 2
  color: root.active ? Config.selectedBg : (bodyMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)

  Rectangle {
    id: iconTile
    width: 44
    height: 44
    radius: width / 2
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    color: root.active ? Config.glassBg : Config.searchBg
    Text { anchors.centerIn: parent; text: root.icon; color: root.active ? Config.themeAccent : Config.textMuted; font.pixelSize: Config.fontSizeIconLarge; font.family: Config.fontIcon }
    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
  }

  Column {
    anchors.left: iconTile.right
    anchors.leftMargin: 9
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2
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
