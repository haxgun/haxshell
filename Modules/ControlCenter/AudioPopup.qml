// AudioPopup.qml - Speaker/microphone volume and device selector overlay
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property int sinkVolume: 0
  property bool sinkMuted: false
  property int sourceVolume: 0
  property bool sourceMuted: false
  readonly property string qsctl: Qt.resolvedUrl("../../scripts/qsctl").toString().replace("file://", "")

  visible: isOpen || container.opacity > 0.01

  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "#00000000"

  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: root.isOpen = false
  }

  IpcHandler {
    target: "audio"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  ListModel { id: sinksModel }
  ListModel { id: sourcesModel }

  Process {
    id: fetchAudioProc
    command: [root.qsctl, "audio", "get"]
    running: true

    stdout: SplitParser {
      onRead: data => root.applyState(data)
    }
  }

  Process {
    id: actionProc

    stdout: SplitParser {
      onRead: data => root.applyState(data)
    }
  }

  Process {
    id: pactlSubProc
    command: ["pactl", "subscribe"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        if (data.includes("sink") || data.includes("source") || data.includes("server")) {
          root.refresh()
        }
      }
    }
  }

  onIsOpenChanged: if (isOpen) refresh()

  function refresh() {
    fetchAudioProc.running = false
    fetchAudioProc.command = [root.qsctl, "audio", "get"]
    fetchAudioProc.running = true
  }

  function runAction(action, value) {
    actionProc.running = false
    actionProc.command = [root.qsctl, "audio", action, value.toString()]
    actionProc.running = true
  }

  function replaceModel(model, items) {
    model.clear()
    if (!items) return
    for (let i = 0; i < items.length; i++) model.append(items[i])
  }

  function applyState(data) {
    try {
      let res = JSON.parse(data)
      if (!res.ok) return
      root.sinkVolume = res.sinkVolume || 0
      root.sinkMuted = !!res.sinkMuted
      root.sourceVolume = res.sourceVolume || 0
      root.sourceMuted = !!res.sourceMuted
      replaceModel(sinksModel, res.sinks)
      replaceModel(sourcesModel, res.sources)
    } catch(e) {}
  }

  Rectangle {
    id: container
    width: 360
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin

    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    color: Config.glassBg
    radius: Config.overlayRadius

    MouseArea {
      anchors.fill: parent
      onClicked: mouse => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.borderColor
      border.width: 1
    }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14

      Row {
        width: parent.width
        height: 28
        spacing: 10

        Text {
          text: Config.iconVolHigh
          color: Config.textWhite
          font.pixelSize: Config.fontSizeTitle
          font.family: Config.fontIcon
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          width: parent.width - 38
          text: "Звук"
          color: Config.textWhite
          font.pixelSize: Config.fontSizeLarge
          font.weight: Font.Bold
          font.family: Config.fontSans
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      AudioSlider {
        width: parent.width
        title: "Динамики"
        iconText: root.sinkMuted ? Config.iconVolMuted : Config.iconVolHigh
        value: root.sinkVolume
        muted: root.sinkMuted
        onApplyValue: val => root.runAction("set-sink-volume", val)
        onToggleMute: root.runAction("set-sink-mute", root.sinkMuted ? "0" : "1")
      }

      AudioDeviceList {
        width: parent.width
        model: sinksModel
        emptyText: "Устройства вывода не найдены"
        onSelectDevice: name => root.runAction("set-default-sink", name)
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Config.separatorColor
      }

      AudioSlider {
        width: parent.width
        title: "Микрофон"
        iconText: Config.iconMic
        value: root.sourceVolume
        muted: root.sourceMuted
        onApplyValue: val => root.runAction("set-source-volume", val)
        onToggleMute: root.runAction("set-source-mute", root.sourceMuted ? "0" : "1")
      }

      AudioDeviceList {
        width: parent.width
        model: sourcesModel
        emptyText: "Устройства ввода не найдены"
        onSelectDevice: name => root.runAction("set-default-source", name)
      }
    }
  }
}
