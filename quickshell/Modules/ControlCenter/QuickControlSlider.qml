// QuickControlSlider.qml - Continuous control-center slider without numeric editing
import QtQuick
import "../../Common"

Item {
  id: root

  property int value: 0
  property int from: 0
  property int to: 100
  property string minimumIcon: ""
  property string maximumIcon: ""
  signal valueEdited(int value)

  implicitHeight: 34

  function setFromPosition(position) {
    let ratio = Math.max(0, Math.min(1, position / Math.max(track.width, 1)))
    valueEdited(Math.round(from + ratio * (to - from)))
  }

  Text {
    id: minimumIconText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    horizontalAlignment: Text.AlignHCenter
    text: root.minimumIcon
    color: Config.textMuted
    font.pixelSize: Config.fontSizeIconMedium
    font.family: Config.fontIcon
  }

  Rectangle {
    id: track
    anchors.left: minimumIconText.right
    anchors.leftMargin: 8
    anchors.right: maximumIconText.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    height: 4
    radius: 2
    color: Config.separatorColor

    Rectangle {
      width: Math.max(0, handle.x + handle.width / 2)
      height: parent.height
      radius: parent.radius
      color: Config.themeAccent
    }

    Rectangle {
      id: handle
      width: 12
      height: 12
      radius: 6
      x: (root.value - root.from) / Math.max(root.to - root.from, 1) * (track.width - width)
      anchors.verticalCenter: parent.verticalCenter
      color: Config.textWhite
      border.color: Config.themeAccent
      border.width: 2
    }

    MouseArea {
      anchors.fill: parent
      anchors.margins: -8
      cursorShape: Qt.PointingHandCursor
      onPressed: mouse => root.setFromPosition(mouse.x + anchors.margins)
      onPositionChanged: mouse => { if (pressed) root.setFromPosition(mouse.x + anchors.margins) }
    }
  }

  Text {
    id: maximumIconText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    horizontalAlignment: Text.AlignHCenter
    text: root.maximumIcon
    color: Config.textMuted
    font.pixelSize: Config.fontSizeIconMedium
    font.family: Config.fontIcon
  }
}
