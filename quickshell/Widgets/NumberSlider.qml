// NumberSlider.qml - Integer slider with direct numeric input
import QtQuick
import "../Common"

Item {
  id: root

  property int value: 0
  property int from: 0
  property int to: 64
  property int defaultValue: 0
  property string suffix: "px"
  signal valueEdited(int value)

  implicitWidth: 194
  implicitHeight: 30

  function clamp(value) {
    return Math.max(from, Math.min(to, Math.round(value)))
  }

  function setFromPosition(position) {
    let ratio = Math.max(0, Math.min(1, position / Math.max(track.width, 1)))
    valueEdited(clamp(from + ratio * (to - from)))
  }

  Rectangle {
    id: track
    height: 4
    radius: height / 2
    anchors.left: parent.left
    anchors.right: valueField.left
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    color: Config.separatorColor

    Rectangle {
      width: Math.max(0, handle.x + handle.width / 2)
      height: parent.height
      radius: height / 2
      color: Config.themeAccent
    }

    Rectangle {
      id: handle
      width: 12
      height: 12
      radius: width / 2
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
      onPositionChanged: mouse => {
        if (pressed) root.setFromPosition(mouse.x + anchors.margins)
      }
    }
  }

  Rectangle {
    id: valueField
    width: 48
    height: parent.height
    radius: Config.buttonRadius
    anchors.right: unit.left
    anchors.rightMargin: 5
    color: Config.searchBg
    border.color: valueInput.activeFocus ? Config.themeAccent : Config.borderColor
    border.width: 1

    TextInput {
      id: valueInput
      anchors.fill: parent
      anchors.margins: 6
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: root.value.toString()
      color: Config.textPrimary
      font.pixelSize: Config.fontSizeSmall
      font.family: Config.fontMono
      inputMethodHints: Qt.ImhDigitsOnly
      selectByMouse: true
      validator: IntValidator { bottom: root.from; top: root.to }
      onEditingFinished: root.valueEdited(root.clamp(parseInt(text)))
    }
  }

  Text {
    id: unit
    anchors.right: resetButton.left
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    text: root.suffix
    color: Config.textMuted
    font.pixelSize: Config.fontSizeSmall
    font.family: Config.fontMono
  }

  Rectangle {
    id: resetButton
    width: 28
    height: parent.height
    radius: Config.buttonRadius
    anchors.right: parent.right
    color: resetMouse.containsMouse ? Config.hoverBg : "#00000000"

    Text {
      anchors.centerIn: parent
      text: Config.iconRefresh
      color: resetMouse.containsMouse ? Config.textWhite : Config.textMuted
      font.pixelSize: Config.fontSizeIconSmall
      font.family: Config.fontIcon
    }

    MouseArea {
      id: resetMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.valueEdited(root.clamp(root.defaultValue))
    }
  }
}
