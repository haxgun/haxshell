// StepSlider.qml - Discrete slider that snaps to a fixed list of values
import QtQuick
import "../Common"

Item {
  id: root

  // Fixed list of allowed values (any numeric order; sorted internally).
  property var steps: []
  property real value: 0
  property string suffix: ""
  signal valueEdited(real value)

  implicitWidth: 194
  implicitHeight: 30

  readonly property var sortedSteps: {
    let s = steps.slice().sort((a, b) => a - b)
    return s
  }
  readonly property int currentIndex: {
    let best = 0
    let bestDist = Infinity
    for (let i = 0; i < sortedSteps.length; i++) {
      let d = Math.abs(sortedSteps[i] - value)
      if (d < bestDist) {
        bestDist = d
        best = i
      }
    }
    return best
  }

  function snapFromPosition(position) {
    if (sortedSteps.length === 0)
      return
    let ratio = Math.max(0, Math.min(1, position / Math.max(track.width, 1)))
    let idx = Math.round(ratio * (sortedSteps.length - 1))
    idx = Math.max(0, Math.min(sortedSteps.length - 1, idx))
    let v = sortedSteps[idx]
    if (v !== value)
      valueEdited(v)
  }

  Rectangle {
    id: track
    height: 4
    radius: Config.popupPillRadius(height)
    anchors.left: parent.left
    anchors.right: valueField.left
    anchors.rightMargin: Config.scaledSize(12)
    anchors.verticalCenter: parent.verticalCenter
    color: Config.separatorColor

    Rectangle {
      width: Math.max(0, handle.x + handle.width / 2)
      height: parent.height
      radius: Config.popupPillRadius(height)
      color: Config.themeAccent
    }

    Rectangle {
      id: handle
      width: 12
      height: 12
      radius: Config.popupPillRadius(width)
      x: root.currentIndex / Math.max(root.sortedSteps.length - 1, 1) * (track.width - width)
      anchors.verticalCenter: parent.verticalCenter
      color: Config.textWhite
      border.color: Config.themeAccent
      border.width: 2
    }

    MouseArea {
      anchors.fill: parent
      anchors.margins: -8
      cursorShape: Qt.PointingHandCursor
      onPressed: mouse => root.snapFromPosition(mouse.x + anchors.margins)
      onPositionChanged: mouse => {
        if (pressed)
          root.snapFromPosition(mouse.x + anchors.margins)
      }
    }
  }

  Rectangle {
    id: valueField
    width: Config.scaledSize(48)
    height: parent.height
    radius: Config.popupRadiusPx(8)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: Config.popupInputBg
    border.color: Config.borderColor
    border.width: 1

    Text {
      anchors.fill: parent
      anchors.margins: Config.scaledSize(6)
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: root.sortedSteps.length > 0 ? root.sortedSteps[root.currentIndex] + root.suffix : ""
      color: Config.textPrimary
      font.pixelSize: Config.fontMonoSizeSmall
      font.family: Config.fontMono
    }
  }
}
