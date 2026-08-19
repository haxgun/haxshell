// QuickControlTile.qml - DMS-style quick control with separate toggle and detail actions
import QtQuick
import "../Common"

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool active: false
  property bool wide: false
  signal toggled()
  signal detailsRequested()

  readonly property color activeBg: Config.themeAccent
  readonly property color activeFg: Config.popupGlassBg
  readonly property color activeMuted: Config.textMuted

  width: wide ? (parent ? parent.width : 250) : (parent ? (parent.width - 8) / 2 : 250)
  height: wide ? 62 : 64
  radius: Config.popupPillRadius(height)
  color: root.active ? root.activeBg : (bodyMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)

  Rectangle {
    id: iconTile
    width: Config.scaledSize(44)
    height: Config.scaledSize(44)
    radius: Config.popupPillRadius(width)
    anchors.left: parent.left
    anchors.leftMargin: Config.scaledSize(10)
    anchors.verticalCenter: parent.verticalCenter
    color: root.active ? root.activeFg : Config.searchBg
    Text { anchors.centerIn: parent; text: root.icon; color: root.active ? root.activeBg : Config.textMuted; font.pixelSize: Config.fontSizeIconLarge; font.family: Config.fontIcon }
    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
  }

  Column {
    anchors.left: iconTile.right
    anchors.leftMargin: Config.scaledSize(9)
    anchors.right: parent.right
    anchors.rightMargin: Config.scaledSize(24)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.scaledSize(2)
    Text { width: parent.width; text: root.title; color: root.active ? root.activeFg : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
    Text { width: parent.width; text: root.subtitle; color: root.active ? root.activeMuted : Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
  }

  Text {
    anchors.right: parent.right
    anchors.rightMargin: Config.scaledSize(10)
    anchors.verticalCenter: parent.verticalCenter
    text: Config.iconChevronRight
    color: root.active ? root.activeFg : Config.textMuted
    font.pixelSize: Config.fontSizeIconSmall
    font.family: Config.fontIcon
    opacity: 0.7
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
