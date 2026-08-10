// ClockWidget.qml - Center Date/Time Clock & MPRIS Media Player
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"

Rectangle {
  id: root

  // Target CalendarPopup reference to toggle
  property var calendarPopup: null
  property bool embeddedInBar: false

  // Configurable Right Extension Mode: "progress" (Progress Bar) or "visualizer" (Animated Soundwave Bars)
  property string rightDisplayMode: Config.mprisRightDisplayMode

  // Configurable Visualizer Bar Count
  property int visualizerBarCount: Config.mprisVisualizerBarCount

  // Reliable widget-wide hover state
  readonly property bool isHovered: widgetHover.hovered || widgetMouse.containsMouse || playPauseMouse.containsMouse || clockMouse.containsMouse || prevTrackMouse.containsMouse || nextTrackMouse.containsMouse

  property var visualizerBars: [4, 4, 4, 4, 4, 4, 4, 4]

  // Media Player State Properties
  property bool hasMedia: false
  property bool isPlaying: false
  property string mediaArtist: ""
  property string mediaTitle: ""
  property int positionSec: 0
  property int durationSec: 0

  // Fixed symmetric width for left and right extensions
  readonly property int targetSideWidth: (hasMedia && (mediaTitle || mediaArtist)) ? Config.mprisTargetSideWidth : 0

  // Formatted Media Track Label
  readonly property string trackLabel: {
    if (mediaArtist && mediaTitle) return mediaArtist + " - " + mediaTitle
    if (mediaTitle) return mediaTitle
    if (mediaArtist) return mediaArtist
    return ""
  }

  // Format seconds to mm:ss
  function formatTime(seconds) {
    if (!seconds || seconds <= 0) return "00:00"
    let m = Math.floor(seconds / 60)
    let s = Math.floor(seconds % 60)
    let mStr = m < 10 ? "0" + m : m.toString()
    let sStr = s < 10 ? "0" + s : s.toString()
    return mStr + ":" + sStr
  }

  // Real-time MPRIS metadata subscriber via playerctl
  Process {
    id: mprisProc
    command: ["playerctl", "metadata", "-F", "--format", "{{status}};;{{artist}};;{{title}};;{{position}};;{{mpris:length}}"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        let parts = data.trim().split(";;")
        if (parts.length >= 5) {
          let statusStr = parts[0]
          let artistStr = parts[1]
          let titleStr = parts[2]
          let posMicro = parseInt(parts[3]) || 0
          let lenMicro = parseInt(parts[4]) || 0

          root.isPlaying = (statusStr === "Playing")
          root.hasMedia = (statusStr === "Playing" || statusStr === "Paused")
          root.mediaArtist = artistStr
          root.mediaTitle = titleStr
          root.positionSec = Math.floor(posMicro / 1000000)
          root.durationSec = Math.floor(lenMicro / 1000000)
        } else {
          root.hasMedia = false
          root.isPlaying = false
        }
      }
    }
  }

  // Media Player Command Processes
  Process {
    id: playPauseProc
    command: ["playerctl", "play-pause"]
  }

  Process {
    id: prevTrackProc
    command: ["playerctl", "previous"]
  }

  Process {
    id: nextTrackProc
    command: ["playerctl", "next"]
  }

  Process {
    id: cavaProc
    running: root.rightDisplayMode === "visualizer"
    command: ["sh", "-c", "printf '[general]\nframerate=30\nbars=" + root.visualizerBarCount + "\n[input]\nmethod=pulse\nsource=auto\n[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=20\n' | cava -p /dev/stdin"]

    stdout: SplitParser {
      onRead: data => {
        let values = data.trim().split(/[;\s]+/).filter(v => v.length > 0).map(v => parseInt(v) || 0)
        if (values.length > 0) root.visualizerBars = values.slice(0, root.visualizerBarCount)
      }
    }
  }

  // Position increment timer when playing
  Timer {
    interval: 1000
    running: root.isPlaying
    repeat: true
    onTriggered: {
      if (root.durationSec > 0 && root.positionSec < root.durationSec) {
        root.positionSec++
      }
    }
  }

  // Soundwave visualizer animation phase
  property int animPhase: 0
  Timer {
    interval: 160
    running: root.isPlaying && root.rightDisplayMode === "visualizer"
    repeat: true
    onTriggered: root.animPhase = (root.animPhase + 1) % 4
  }

  implicitWidth: mainRow.implicitWidth + 36
  implicitHeight: Config.barHeight

  Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

  // Frosted Glass Tint & Border
  color: root.embeddedInBar ? "#00000000" : ((root.isHovered || (root.calendarPopup && root.calendarPopup.isOpen)) ? Config.glassHoverBg : Config.glassBg)
  radius: Config.widgetRadius

  Behavior on color { ColorAnimation { duration: 150 } }

  Rectangle {
    anchors.fill: parent
    visible: !root.embeddedInBar
    anchors.margins: Config.innerBorderMargin
    radius: Config.innerBorderRadius
    color: "#00000000"
    border.color: Config.borderColor
    border.width: 1
  }

  HoverHandler {
    id: widgetHover
  }

  MouseArea {
    id: widgetMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  SystemClock {
    id: clock
    precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }

  Row {
    id: mainRow
    anchors.centerIn: parent
    spacing: 8

    // LEFT EXTENSION: Play/Pause Button & Track Info
    Item {
      id: leftSideItem
      width: root.targetSideWidth
      height: Config.buttonHeight
      clip: true
      visible: width > 1
      anchors.verticalCenter: parent.verticalCenter

      Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        spacing: 6

        // Play / Pause Button
        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: playPauseMouse.containsMouse ? Config.pressedBg : "#00000000"
          anchors.verticalCenter: parent.verticalCenter

          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: root.isPlaying ? Config.iconPause : Config.iconPlay
            color: Config.textWhite
            font.pixelSize: Config.fontSizeIconSmall
            font.family: Config.fontIcon
          }

          MouseArea {
            id: playPauseMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: playPauseProc.running = true
          }
        }

        Text {
          width: leftSideItem.width - 38
          text: root.trackLabel
          color: Config.textPrimary
          font.pixelSize: Config.fontSizeNormal
          font.weight: Font.Medium
          font.family: Config.fontMono
          elide: Text.ElideRight
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Separator line (Left)
    Item {
      width: 8
      height: 16
      visible: leftSideItem.width > 1
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 16
        color: Config.separatorColor
      }
    }

    // CENTER WIDGET: Date & Time Clock
    Rectangle {
      id: centerClockRect
      height: Config.buttonHeight
      implicitWidth: rowLayout.implicitWidth + 12
      radius: Config.buttonRadius
      readonly property bool isCalendarActive: (root.calendarPopup && root.calendarPopup.isOpen)
      color: (isCalendarActive || clockMouse.containsMouse) ? Config.activeHoverBg : "#00000000"
      anchors.verticalCenter: parent.verticalCenter

      Behavior on color { ColorAnimation { duration: 150 } }

      Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 12

        // Date text (Left)
        Text {
          text: Config.formatShortDateRu(clock.date)
          color: (centerClockRect.isCalendarActive || clockMouse.containsMouse) ? Config.textWhite : Config.textPrimary
          font.pixelSize: Config.fontSizeLarge
          font.weight: Font.Medium
          font.family: Config.fontSans
          anchors.verticalCenter: parent.verticalCenter
        }

        // Time text (Right)
        Text {
          text: Config.formatTime24(clock.date)
          color: (centerClockRect.isCalendarActive || clockMouse.containsMouse) ? Config.textWhite : Config.textPrimary
          font.pixelSize: Config.fontSizeLarge
          font.weight: Font.Medium
          font.family: Config.fontSans
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.calendarPopup) {
            root.calendarPopup.isOpen = !root.calendarPopup.isOpen
          }
        }
      }
    }

    // Separator line (Right)
    Item {
      width: 8
      height: 16
      visible: rightSideItem.width > 1
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 16
        color: Config.separatorColor
      }
    }

    // RIGHT EXTENSION: Track Position & Controls
    Item {
      id: rightSideItem
      width: root.targetSideWidth
      height: Config.buttonHeight
      clip: true
      visible: width > 1
      anchors.verticalCenter: parent.verticalCenter

      Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

      Row {
        anchors.centerIn: parent
        spacing: 6

        // Previous Track Button
        Rectangle {
          width: 20
          height: 20
          radius: 5
          color: prevTrackMouse.containsMouse ? Config.pressedBg : "#00000000"
          opacity: root.isHovered ? 1.0 : 0.0
          anchors.verticalCenter: parent.verticalCenter

          Behavior on opacity { NumberAnimation { duration: 180 } }
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: Config.iconPrevTrack
            color: Config.textWhite
            font.pixelSize: Config.fontSizeIconSmall
            font.family: Config.fontIcon
          }

          MouseArea {
            id: prevTrackMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: prevTrackProc.running = true
          }
        }

        // Current Track Position
        Text {
          text: root.formatTime(root.positionSec)
          color: Config.textMuted
          font.pixelSize: Config.fontSizeNormal
          font.family: Config.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }

        // Progress Bar
        Rectangle {
          width: 44
          height: 4
          radius: 2
          color: "#35464646"
          visible: root.rightDisplayMode === "progress"
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            height: parent.height
            radius: 2
            width: Math.min(parent.width, Math.max(0, parent.width * (root.durationSec > 0 ? root.positionSec / root.durationSec : 0)))
            color: Config.textPrimary
          }
        }

        // Soundwave Visualizer Bars
        Row {
          spacing: 2.5
          visible: root.rightDisplayMode === "visualizer"
          anchors.verticalCenter: parent.verticalCenter

          Repeater {
            model: root.visualizerBars

            Rectangle {
              required property int modelData
              required property int index

              width: 2.5
              height: root.isPlaying ? Math.max(4, Math.min(22, 4 + modelData)) : 4
              radius: 1.25
              color: Config.textPrimary
              anchors.verticalCenter: parent.verticalCenter

              Behavior on height { NumberAnimation { duration: 120 } }
            }
          }
        }

        // Total Track Length
        Text {
          text: root.formatTime(root.durationSec)
          color: Config.textMuted
          font.pixelSize: Config.fontSizeNormal
          font.family: Config.fontMono
          anchors.verticalCenter: parent.verticalCenter
        }

        // Next Track Button
        Rectangle {
          width: 20
          height: 20
          radius: 5
          color: nextTrackMouse.containsMouse ? Config.pressedBg : "#00000000"
          opacity: root.isHovered ? 1.0 : 0.0
          anchors.verticalCenter: parent.verticalCenter

          Behavior on opacity { NumberAnimation { duration: 180 } }
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: Config.iconNextTrack
            color: Config.textWhite
            font.pixelSize: Config.fontSizeIconSmall
            font.family: Config.fontIcon
          }

          MouseArea {
            id: nextTrackMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nextTrackProc.running = true
          }
        }
      }
    }
  }
}
