pragma Singleton
pragma ComponentBehavior: Bound

// MprisController.qml - Shared active MPRIS player state and controls

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  readonly property list<MprisPlayer> availablePlayers: Mpris.players.values
  property MprisPlayer activePlayer: null
  property real stableLength: 0
  property string stableTitle: ""
  property string stableArtist: ""
  property string stableAlbum: ""
  property string stableArtUrl: ""

  onAvailablePlayersChanged: resolveActivePlayer()
  onActivePlayerChanged: {
    stableArtUrl = ""
    syncMetadata()
  }
  Component.onCompleted: resolveActivePlayer()

  Connections {
    target: root.activePlayer
    function onTrackTitleChanged() { root.syncMetadata() }
    function onTrackArtistChanged() { root.syncMetadata() }
    function onTrackAlbumChanged() { root.syncMetadata() }
    function onTrackArtUrlChanged() { root.syncMetadata() }
    function onLengthChanged() { root.syncMetadata() }
    function onLengthSupportedChanged() { root.syncMetadata() }
    function onPlaybackStateChanged() { root.resolveActivePlayer(); root.syncMetadata() }
  }

  Instantiator {
    model: root.availablePlayers
    delegate: Connections {
      required property MprisPlayer modelData
      target: modelData
      ignoreUnknownSignals: true
      function onIsPlayingChanged() { root.resolveActivePlayer() }
      function onTrackTitleChanged() { root.resolveActivePlayer(); root.syncMetadata() }
      function onTrackArtistChanged() { root.resolveActivePlayer(); root.syncMetadata() }
      function onTrackAlbumChanged() { root.syncMetadata() }
      function onTrackArtUrlChanged() { root.syncMetadata() }
      function onMetadataChanged() { root.resolveActivePlayer(); root.syncMetadata() }
    }
  }

  // MPRIS position does not emit changes while a track plays; poll it for live progress.
  Timer {
    interval: 1000
    repeat: true
    running: root.activePlayer && root.activePlayer.isPlaying && root.activePlayer.positionSupported
    onTriggered: root.activePlayer.positionChanged()
  }

  function isIdle(player) {
    return !player || player.playbackState === MprisPlaybackState.Stopped
  }

  function resolveActivePlayer() {
    let playing = availablePlayers.filter(player => player.isPlaying)
    if (playing.length > 0) {
      let controllable = playing.find(player => player.canControl)
      activePlayer = controllable || playing[0]
      return
    }
    if (activePlayer && availablePlayers.indexOf(activePlayer) >= 0 && !isIdle(activePlayer)) return
    activePlayer = availablePlayers.find(player => player.canControl && !isIdle(player)) || null
  }

  function syncMetadata() {
    let player = activePlayer
    if (!player) {
      stableTitle = ""
      stableArtist = ""
      stableAlbum = ""
      stableArtUrl = ""
      stableLength = 0
      return
    }
    if (player.trackTitle) stableTitle = player.trackTitle
    if (player.trackArtist) stableArtist = player.trackArtist
    if (player.trackAlbum) stableAlbum = player.trackAlbum
    if (player.trackArtUrl) stableArtUrl = player.trackArtUrl
    stableLength = player.lengthSupported && player.length > 1 ? player.length : 0
  }

  function previousOrRewind() {
    if (!activePlayer) return
    if (activePlayer.position > 8 && activePlayer.canSeek) activePlayer.position = 0.1
    else if (activePlayer.canGoPrevious) activePlayer.previous()
  }

  function next() {
    if (activePlayer && activePlayer.canGoNext) activePlayer.next()
  }

}
