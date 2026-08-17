// AudioSlider.qml - Shared audio volume slider row
import QtQuick
import "../Common"

Column {
  id: root

  property string title: ""
  property string iconText: ""
  property int value: 0
  property bool muted: false
  signal applyValue(int value)
  signal toggleMute()

  spacing: Config.scaledSize(8)

  Row {
    width: parent.width
    height: Config.scaledSize(24)
    spacing: Config.scaledSize(8)

    Rectangle {
      width: Config.scaledSize(28)
      height: Config.scaledSize(24)
      radius: Config.popupRadiusPx(8)
      color: muteMouse.containsMouse ? Config.activeHoverBg : (root.muted ? Qt.rgba(Config.dangerRed.r, Config.dangerRed.g, Config.dangerRed.b, 0.19) : "#00000000")

      Text {
        anchors.centerIn: parent
        text: root.iconText
        color: root.muted ? Config.dangerRed : Config.textPrimary
        font.pixelSize: Config.fontSizeIconMedium
        font.family: Config.fontIcon
      }

      MouseArea {
        id: muteMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMute()
      }
    }

    Text {
      width: parent.width - 86
      text: root.title
      color: Config.textWhite
      font.pixelSize: Config.fontSizeMedium
      font.weight: Font.Medium
      font.family: Config.fontSans
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      width: Config.scaledSize(42)
      text: root.value + "%"
      color: root.muted ? Config.dangerRed : Config.textMuted
      font.pixelSize: Config.fontMonoSizeMedium
      font.weight: Font.Medium
      font.family: Config.fontMono
      horizontalAlignment: Text.AlignRight
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Item {
    id: sliderBox
    width: parent.width
    height: Config.scaledSize(24)

    Rectangle {
      width: parent.width
      height: 6
      radius: 3
      color: Config.searchBg
      border.color: Config.subtleBorder
      border.width: 1
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        height: parent.height
        radius: 3
        width: Math.min(parent.width, Math.max(0, parent.width * (sliderArea.tempValue / 100.0)))
        color: root.muted ? Config.dangerRed : Config.textPrimary
      }
    }

    MouseArea {
      id: sliderArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      property int tempValue: root.value

      Connections {
        target: root
        function onValueChanged() {
          if (!sliderArea.pressed) sliderArea.tempValue = root.value
        }
      }

      function updateTemp(mouse) {
        let posX = Math.max(0, Math.min(width, mouse.x))
        tempValue = Math.round((posX / width) * 100)
      }

      onPressed: mouse => updateTemp(mouse)
      onPositionChanged: mouse => { if (pressed) updateTemp(mouse) }
      onReleased: mouse => {
        updateTemp(mouse)
        root.applyValue(tempValue)
      }
    }
  }
}
