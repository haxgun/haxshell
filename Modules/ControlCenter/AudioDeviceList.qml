// AudioDeviceList.qml - Select default audio input/output device
import QtQuick
import "../../Common"

Column {
  id: root

  property alias model: deviceRepeater.model
  property string emptyText: ""
  property bool expanded: false
  signal selectDevice(string name)

  spacing: 6

  readonly property var currentDevice: {
    let model = deviceRepeater.model
    if (!model || typeof model.count === "undefined" || model.count === 0) return null
    for (let i = 0; i < model.count; i++) {
      let item = model.get(i)
      if (item && item.isDefault) return item
    }
    return model.get(0)
  }

  Text {
    width: parent.width
    visible: deviceRepeater.count === 0
    text: root.emptyText
    color: Config.textMuted
    font.pixelSize: Config.fontSizeSmall
    font.family: Config.fontSans
    horizontalAlignment: Text.AlignHCenter
  }

  Rectangle {
    id: currentDeviceButton
    width: root.width
    height: 38
    visible: !!root.currentDevice
    radius: Config.cardRadius
    color: currentMouse.containsMouse || root.expanded ? Config.hoverBg : "#00000000"
    border.color: root.expanded ? Config.activeBorderColor : Config.borderColor
    border.width: 1

    Row {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      spacing: 8

      Text {
        text: root.expanded ? Config.iconChevronRight : Config.iconChevronLeft
        color: currentMouse.containsMouse || root.expanded ? Config.textWhite : Config.textMuted
        font.pixelSize: Config.fontSizeIconSmall
        font.family: Config.fontIcon
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        width: parent.width - 78
        text: root.currentDevice ? (root.currentDevice.description || root.currentDevice.name) : ""
        color: Config.textWhite
        font.pixelSize: Config.fontSizeSmall
        font.weight: Font.Bold
        font.family: Config.fontSans
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        width: 44
        text: root.currentDevice ? (root.currentDevice.volume + "%") : ""
        color: root.currentDevice && root.currentDevice.muted ? Config.dangerRed : Config.textMuted
        font.pixelSize: Config.fontSizeSmall
        font.family: Config.fontMono
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      id: currentMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  Item {
    width: root.width
    height: root.expanded ? deviceColumn.implicitHeight : 0
    clip: true
    opacity: root.expanded ? 1.0 : 0.0

    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

    Column {
      id: deviceColumn
      width: parent.width
      spacing: 6

      Repeater {
        id: deviceRepeater

        Rectangle {
          required property string name
          required property string description
          required property int volume
          required property bool muted
          required property bool isDefault

          width: root.width
          height: 38
          radius: Config.cardRadius
          color: deviceMouse.containsMouse || isDefault ? Config.hoverBg : "#00000000"
          border.color: isDefault ? Config.activeBorderColor : "#00000000"
          border.width: isDefault ? 1 : 0

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
              text: isDefault ? "●" : "○"
              color: isDefault ? Config.textWhite : Config.textMuted
              font.pixelSize: Config.fontSizeSmall
              font.family: Config.fontSans
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              width: parent.width - 78
              text: description || name
              color: isDefault ? Config.textWhite : Config.textPrimary
              font.pixelSize: Config.fontSizeSmall
              font.weight: isDefault ? Font.Bold : Font.Medium
              font.family: Config.fontSans
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              width: 44
              text: volume + "%"
              color: muted ? Config.dangerRed : Config.textMuted
              font.pixelSize: Config.fontSizeSmall
              font.family: Config.fontMono
              horizontalAlignment: Text.AlignRight
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: deviceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectDevice(name)
              root.expanded = false
            }
          }
        }
      }
    }
  }
}
