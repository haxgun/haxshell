// AudioPopup.qml - Speaker/microphone volume and device selector overlay
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "."
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: Config.scaledSize(16)
  property var osd: null
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property int sinkVolume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
  readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : false
  readonly property int sourceVolume: source && source.audio ? Math.round(source.audio.volume * 100) : 0
  readonly property bool sourceMuted: source && source.audio ? source.audio.muted : false
  property list<PwNode> sinks: []
  property list<PwNode> sources: []

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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

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

  function rebuildDevices() {
    if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) {
      sinks = []
      sources = []
      return
    }
    let nextSinks = []
    let nextSources = []
    for (let node of Pipewire.nodes.values) {
      if (!node || !node.audio || node.isStream) continue
      if (node.isSink) nextSinks.push(node)
      else nextSources.push(node)
    }
    sinks = nextSinks
    sources = nextSources
  }

  function setSink(node) {
    if (node) Pipewire.preferredDefaultAudioSink = node
  }

  function setSource(node) {
    if (node) Pipewire.preferredDefaultAudioSource = node
  }

  Component.onCompleted: rebuildDevices()

  Connections {
    target: Pipewire.nodes
    function onValuesChanged() { root.rebuildDevices() }
  }

  Connections {
    target: Pipewire
    function onReadyChanged() { root.rebuildDevices() }
  }

  // Keep PipeWire nodes bound while the popup reads and modifies their audio state.
  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(node => node && node.audio && !node.isStream)
  }

  PwNodePeakMonitor {
    id: micPeak
    node: root.source
    enabled: root.isOpen
  }

  Rectangle {
    id: container
    width: Config.scaledSize(360)
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: root.rightMargin

    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    color: Config.popupGlassBg
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
      border.color: Config.popupBorderColor
      border.width: Config.popupBordersEnabled ? 1 : 0
    }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.scaledSize(14)

      Row {
        width: parent.width
        height: Config.scaledSize(28)
        spacing: Config.scaledSize(10)

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
          font.weight: Font.Medium
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
        onApplyValue: val => { if (root.sink && root.sink.audio) { if (root.osd) root.osd.suppressOnce(); root.sink.audio.volume = val / 100 } }
        onToggleMute: if (root.sink && root.sink.audio) { if (root.osd) root.osd.suppressOnce(); root.sink.audio.muted = !root.sink.audio.muted }
      }

      AudioDeviceList {
        width: parent.width
        model: root.sinks
        currentDevice: root.sink
        emptyText: "Устройства вывода не найдены"
        onSelectDevice: node => root.setSink(node)
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
        onApplyValue: val => { if (root.source && root.source.audio) root.source.audio.volume = val / 100 }
        onToggleMute: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
      }

      Rectangle {
        width: parent.width
        height: Config.scaledSize(6)
        radius: Config.popupPillRadius(height)
        color: Config.meterTrack
        clip: true
        visible: root.source != null

        Rectangle {
          height: parent.height
          radius: parent.radius
          width: Math.min(parent.width, parent.width * Math.max(0, Math.min(1, micPeak.peak)))
          color: root.sourceMuted ? Config.dangerRed : Config.themeAccent
          Behavior on width { NumberAnimation { duration: 70; easing.type: Easing.Linear } }
        }
      }

      AudioDeviceList {
        width: parent.width
        model: root.sources
        currentDevice: root.source
        emptyText: "Устройства ввода не найдены"
        onSelectDevice: node => root.setSource(node)
      }
    }
  }
}
