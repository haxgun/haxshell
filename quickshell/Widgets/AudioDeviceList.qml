// AudioDeviceList.qml - Select default audio input/output device
import QtQuick
import Quickshell.Services.Pipewire
import "../Common"

Column {
  id: root

  property alias model: deviceRepeater.model
  property PwNode currentDevice: null
  property string emptyText: ""
  property bool expanded: false
  signal selectDevice(var device)

  spacing: Config.scaledSize(6)

  Text {
    width: parent.width
    visible: !root.currentDevice
    text: root.emptyText
    color: Config.textMuted
    font.pixelSize: Config.fontSizeSmall
    font.family: Config.fontSans
    horizontalAlignment: Text.AlignHCenter
  }

  Rectangle {
    id: currentDeviceButton
    width: root.width
    height: Config.scaledSize(38)
    visible: !!root.currentDevice
    radius: Config.cardRadius
    color: currentMouse.containsMouse || root.expanded ? Config.hoverBg : "#00000000"
    border.color: root.expanded ? Config.activeBorderColor : Config.borderColor
    border.width: 1

    Row {
      anchors.fill: parent
      anchors.leftMargin: Config.scaledSize(12)
      anchors.rightMargin: Config.scaledSize(12)
      spacing: Config.scaledSize(8)

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
        font.weight: Font.Medium
        font.family: Config.fontSans
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        width: Config.scaledSize(44)
        text: root.currentDevice && root.currentDevice.audio ? (Math.round(root.currentDevice.audio.volume * 100) + "%") : ""
        color: root.currentDevice && root.currentDevice.audio && root.currentDevice.audio.muted ? Config.dangerRed : Config.textMuted
        font.pixelSize: Config.fontMonoSizeSmall
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
      spacing: Config.scaledSize(6)

      Repeater {
        id: deviceRepeater

        Rectangle {
          required property PwNode modelData
          readonly property var device: modelData
          readonly property bool isDefault: device === root.currentDevice

          width: root.width
          height: Config.scaledSize(38)
          radius: Config.cardRadius
          color: deviceMouse.containsMouse || isDefault ? Config.hoverBg : "#00000000"
          border.color: isDefault ? Config.activeBorderColor : "#00000000"
          border.width: isDefault ? 1 : 0

          Row {
            anchors.fill: parent
            anchors.leftMargin: Config.scaledSize(12)
            anchors.rightMargin: Config.scaledSize(12)
            spacing: Config.scaledSize(8)

            Text {
              text: parent.parent.isDefault ? "●" : "○"
              color: parent.parent.isDefault ? Config.textWhite : Config.textMuted
              font.pixelSize: Config.fontSizeSmall
              font.family: Config.fontSans
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              width: parent.width - 78
              text: parent.parent.device.description || parent.parent.device.name
              color: parent.parent.isDefault ? Config.textWhite : Config.textPrimary
              font.pixelSize: Config.fontSizeSmall
              font.weight: parent.parent.isDefault ? Font.Medium : Font.Medium
              font.family: Config.fontSans
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              width: Config.scaledSize(44)
              text: parent.parent.device.audio ? (Math.round(parent.parent.device.audio.volume * 100) + "%") : ""
              color: parent.parent.device.audio && parent.parent.device.audio.muted ? Config.dangerRed : Config.textMuted
              font.pixelSize: Config.fontMonoSizeSmall
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
              root.selectDevice(parent.device)
              root.expanded = false
            }
          }
        }
      }
    }
  }
}
