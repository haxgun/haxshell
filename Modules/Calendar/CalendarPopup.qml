// CalendarPopup.qml - Interactive Calendar Overlay Window
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16

  visible: isOpen || container.opacity > 0.01

  // Wayland LayerShell Configuration
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

  // Background dismiss handler
  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: {
      root.isOpen = false
    }
  }

  // IPC Handler
  IpcHandler {
    target: "calendar"

    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  // Today's real-time date
  readonly property date today: new Date()

  // Displayed month and year (interactive)
  property int displayYear: today.getFullYear()
  property int displayMonth: today.getMonth()
  property string weatherIcon: Config.iconWeather
  property string weatherTemp: "--"
  property string weatherCondition: "Погода недоступна"
  property string weatherDetails: "Погода недоступна"
  property string weatherHumidity: "--"
  property bool weatherLoading: false

  onIsOpenChanged: {
    if (isOpen) {
      displayYear = today.getFullYear()
      displayMonth = today.getMonth()
      updateCalendarGrid()
      refreshWeather()
    }
  }

  Process {
    id: weatherProc
    command: [Qt.resolvedUrl("../../core/hushctl").toString().replace("file://", ""), "weather"]

    stdout: SplitParser {
      onRead: data => root.applyWeather(data)
    }

    onExited: root.weatherLoading = false
  }

  function refreshWeather() {
    if (!Config.weatherEnabled) return
    root.weatherLoading = true
    weatherProc.running = false
    weatherProc.command = [Qt.resolvedUrl("../../core/hushctl").toString().replace("file://", ""), "weather", "refresh"]
    weatherProc.running = true
  }

  function applyWeather(data) {
    try {
      let res = JSON.parse(data)
      if (!res.ok) return
      root.weatherTemp = Math.round(res.temperature) + "°"
      root.weatherHumidity = res.humidity + "%"
      root.weatherCondition = res.condition || "Погода"
      root.weatherDetails = (res.name || Config.weatherLocation || "Текущий город") + " · влажность " + root.weatherHumidity
      forecastModel.clear()
      let days = res.days || []
      for (let i = 0; i < Math.min(4, days.length); i++) {
        let day = days[i]
        forecastModel.append({
          dayLabel: root.forecastDayLabel(day.date, i),
          temp: Math.round(day.min) + "…" + Math.round(day.max) + "°",
          humidity: "",
          desc: day.condition || "Прогноз"
        })
      }
      for (let i = days.length; i < 4; i++) {
        forecastModel.append({
          dayLabel: root.forecastDayLabel(root.addDays(new Date(), i), i),
          temp: "--",
          humidity: "--",
          desc: "Нет данных"
        })
      }
    } catch(e) {}
    root.weatherLoading = false
  }

  function forecastDayLabel(rawDate, index) {
    if (index === 0) return "Сегодня"
    let d = rawDate instanceof Date ? rawDate : new Date(rawDate + "T00:00:00")
    return Config.weekdayBarNamesRu[d.getDay()]
  }

  function addDays(date, days) {
    let copy = new Date(date)
    copy.setDate(copy.getDate() + days)
    return copy
  }

  // Calendar Days Grid Model
  ListModel {
    id: calendarModel
  }

  ListModel {
    id: forecastModel
  }

  function updateCalendarGrid() {
    calendarModel.clear()

    let realYear = today.getFullYear()
    let realMonth = today.getMonth()
    let realDate = today.getDate()

    let firstDay = (new Date(displayYear, displayMonth, 1).getDay() + 6) % 7
    let daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
    let daysInPrevMonth = new Date(displayYear, displayMonth, 0).getDate()

    // 1. Previous month trailing days
    for (let i = firstDay - 1; i >= 0; i--) {
      let dayNum = daysInPrevMonth - i
      calendarModel.append({
        dayNumber: dayNum,
        inMonth: false,
        isToday: false
      })
    }

    // 2. Current month days
    for (let d = 1; d <= daysInMonth; d++) {
      let isToday = (displayYear === realYear && displayMonth === realMonth && d === realDate)
      calendarModel.append({
        dayNumber: d,
        inMonth: true,
        isToday: isToday
      })
    }

    // 3. Next month leading days
    let remaining = 42 - calendarModel.count
    for (let n = 1; n <= remaining; n++) {
      calendarModel.append({
        dayNumber: n,
        inMonth: false,
        isToday: false
      })
    }
  }

  Component.onCompleted: {
    updateCalendarGrid()
  }

  function prevMonth() {
    if (displayMonth === 0) {
      displayMonth = 11
      displayYear--
    } else {
      displayMonth--
    }
    updateCalendarGrid()
  }

  function nextMonth() {
    if (displayMonth === 11) {
      displayMonth = 0
      displayYear++
    } else {
      displayMonth++
    }
    updateCalendarGrid()
  }

  // Floating Compact Container Box
  Rectangle {
    id: container
    width: Config.calendarWidth
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
      onClicked: (mouse) => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.borderColor
      border.width: 1
    }

    Row {
      id: columnLayout
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14

      Item {
        width: 170
        height: calendarColumn.implicitHeight

        Column {
          id: weatherColumn
          width: parent.width
          spacing: 10

          Row {
            width: parent.width
            height: 48
            spacing: 10

            Text {
              text: root.weatherLoading ? Config.iconRefresh : Config.iconWeather
              color: Config.activeBorderColor
              font.pixelSize: 28
              font.family: Config.fontIcon
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              width: parent.width - 42
              anchors.verticalCenter: parent.verticalCenter
              spacing: 1

              Text { width: parent.width; text: root.weatherTemp; color: Config.textWhite; font.pixelSize: 28; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
              Text { width: parent.width; text: root.weatherCondition; color: Config.textMuted; font.pixelSize: 11; font.family: Config.fontSans; elide: Text.ElideRight }
            }
          }

          Row {
            width: parent.width
            height: 24
            spacing: 6
            Text { width: parent.width - 52; text: Config.weatherLocation || "Погода"; color: Config.textSubtle; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            Text { width: 46; text: "◌ " + root.weatherHumidity; color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
          }

          Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45 }

          Row {
            width: parent.width
            height: 76
            spacing: 4

            Repeater {
              model: forecastModel
              Column {
                width: (weatherColumn.width - 12) / 4
                spacing: 4
                Text { width: parent.width; text: dayLabel; color: Config.textMuted; font.pixelSize: 9; font.weight: Font.Bold; font.family: Config.fontSans; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                Text { width: parent.width; text: Config.iconWeather; color: Config.textSubtle; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width; text: temp; color: Config.textWhite; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width; text: "◌ " + humidity; color: Config.textMuted; font.pixelSize: 9; font.family: Config.fontSans; horizontalAlignment: Text.AlignHCenter }
              }
            }
          }
        }

      }

      Rectangle { width: 1; height: calendarColumn.implicitHeight; color: Config.separatorColor; opacity: 0.7 }

      Column {
        id: calendarColumn
        width: parent.width - 185
        spacing: 10

        Item {
          width: parent.width
          height: 28

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 7
            color: prevMouse.containsMouse ? Config.selectedBg : "#00000000"
            Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 7
            color: nextMouse.containsMouse ? Config.selectedBg : "#00000000"
            Text { anchors.centerIn: parent; text: Config.iconChevronRight; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
          }

          Text {
            anchors.centerIn: parent
            text: Config.monthNamesRu[root.displayMonth].toUpperCase() + " " + root.displayYear
            color: Config.textMuted
            font.pixelSize: 10
            font.weight: Font.Bold
            font.family: Config.fontSans
            font.letterSpacing: 1.6
          }
        }

        Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45 }

        Row {
          width: parent.width
          spacing: 0

          Repeater {
            model: Config.calendarWeekdayNamesRu

            Item {
              width: calendarColumn.width / 7
              height: 22

              Text { anchors.centerIn: parent; text: modelData; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }
            }
          }
        }

        Grid {
          width: parent.width
          columns: 7
          spacing: 0

          Repeater {
            model: calendarModel

            Item {
              required property int dayNumber
              required property bool inMonth
              required property bool isToday

              width: calendarColumn.width / 7
              height: 30

              Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 8
                color: isToday ? Config.selectedBg : "#00000000"
                border.color: isToday ? Config.activeBorderColor : "#00000000"
                border.width: isToday ? 1 : 0
              }

              Text { anchors.centerIn: parent; text: dayNumber.toString(); color: isToday ? Config.textWhite : (inMonth ? Config.textSubtle : Config.textDark); font.pixelSize: Config.fontSizeNormal; font.weight: isToday ? Font.Bold : Font.Normal; font.family: Config.fontSans }
            }
          }
        }
      }
    }
  }
}
