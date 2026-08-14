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

  implicitHeight: 48

  function setFromPosition(position) {
    let ratio = Math.max(0, Math.min(1, position / Math.max(track.width, 1)))
    valueEdited(Math.round(from + ratio * (to - from)))
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: Config.controlIdleBg

    Rectangle {
      id: track
      anchors.left: parent.left
      anchors.leftMargin: 48
      anchors.right: valueText.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      height: parent.height - 10
      radius: height / 2
      color: Config.searchBg

      Rectangle {
        width: Math.max(0, parent.width * (root.value - root.from) / Math.max(root.to - root.from, 1))
        height: parent.height
        radius: parent.radius
        color: Config.selectedBg
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
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      text: root.minimumIcon
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeIconMedium
      font.family: Config.fontIcon
    }

    Text {
      id: valueText
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      text: root.value + "%"
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.weight: Font.Bold
      font.family: Config.fontMono
    }
  }
}
