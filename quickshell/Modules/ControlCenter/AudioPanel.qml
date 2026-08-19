// AudioPanel.qml - Speaker/microphone volume and device selector
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../Common"
import "../../Widgets"

Item {
  id: root

  property bool active: false
  property var osd: null
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property int sinkVolume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
  readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : false
  readonly property int sourceVolume: source && source.audio ? Math.round(source.audio.volume * 100) : 0
  readonly property bool sourceMuted: source && source.audio ? source.audio.muted : false
  property list<PwNode> sinks: []
  property list<PwNode> sources: []

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

  // Keep PipeWire nodes bound while the panel reads and modifies their audio state.
  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(node => node && node.audio && !node.isStream)
  }

  PwNodePeakMonitor {
    id: micPeak
    node: root.source
    enabled: root.active
  }

  Column {
    width: parent.width
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
        text: I18n.tr("audio.title")
        color: Config.textWhite
        font.pixelSize: Config.fontSizeLarge
        font.weight: Font.Medium
        font.family: Config.fontSans
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    AudioSlider {
      width: parent.width
      title: I18n.tr("audio.speakers")
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
      emptyText: I18n.tr("audio.noOutputs")
      onSelectDevice: node => root.setSink(node)
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Config.separatorColor
    }

    AudioSlider {
      width: parent.width
      title: I18n.tr("audio.mic")
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
      emptyText: I18n.tr("audio.noInputs")
      onSelectDevice: node => root.setSource(node)
    }
  }
}
