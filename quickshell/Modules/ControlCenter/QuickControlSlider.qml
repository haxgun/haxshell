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

  readonly property bool fillCoversIcon: fill.width >= minimumIconText.mapToItem(track, 0, 0).x
  readonly property bool fillCoversText: fill.width >= valueText.mapToItem(track, 0, 0).x

  function setFromPosition(position) {
    let ratio = Math.max(0, Math.min(1, position / Math.max(track.width, 1)))
    valueEdited(Math.round(from + ratio * (to - from)))
  }

  Rectangle {
    anchors.fill: parent
    radius: Config.popupPillRadius(height)
    color: Config.controlIdleBg

    Rectangle {
      id: track
      anchors.left: parent.left
      anchors.leftMargin: Config.scaledSize(8)
      anchors.right: parent.right
      anchors.rightMargin: Config.scaledSize(8)
      anchors.verticalCenter: parent.verticalCenter
      height: parent.height - 10
      radius: Config.popupPillRadius(height)
      color: Config.searchBg

      Rectangle {
        id: fill
        width: Math.min(parent.width, Math.max(0, parent.width * (root.value - root.from) / Math.max(root.to - root.from, 1)))
        height: parent.height
        radius: parent.radius
        color: Config.iconColor
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
      id: minimumIconText
      z: 1
      anchors.left: parent.left
      anchors.leftMargin: Config.scaledSize(16)
      anchors.verticalCenter: parent.verticalCenter
      text: root.minimumIcon
      color: root.fillCoversIcon ? Config.textDark : Config.iconColor
      font.pixelSize: Config.fontSizeIconMedium
      font.family: Config.fontIcon
    }

    Text {
      id: valueText
      z: 1
      anchors.right: parent.right
      anchors.rightMargin: Config.scaledSize(16)
      anchors.verticalCenter: parent.verticalCenter
      text: root.value + "%"
      color: root.fillCoversText ? Config.textDark : Config.textPrimary
      font.pixelSize: Config.fontMonoSizeSmall
      font.weight: Font.Medium
      font.family: Config.fontMono
    }
  }
}
