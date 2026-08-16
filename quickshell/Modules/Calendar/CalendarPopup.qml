// CalendarPopup.qml - Interactive Calendar Overlay Window
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: Config.scaledSize(16)
  property var tooltip: null

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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

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
  property int weatherCode: -1
  property bool weatherOk: false
  property real weatherTempRaw: 0
  readonly property string weatherTemp: !weatherOk ? "--" : Config.tempText(weatherTempRaw, Config.weatherTenths)
  property string weatherCondition: "Погода недоступна"
  property string weatherDetails: "Погода недоступна"
  property string weatherHumidity: "--"
  property var holidaysMap: ({})

  onIsOpenChanged: {
    if (isOpen) {
      displayYear = today.getFullYear()
      displayMonth = today.getMonth()
      updateCalendarGrid()
      refreshWeather()
      refreshHolidays()
    }
  }

  Process {
    id: weatherProc
    command: [Config.veyctl, "weather"]

    stdout: SplitParser {
      onRead: data => root.applyWeather(data)
    }

  }

  Process {
    id: holidaysProc
    stdout: SplitParser { onRead: data => root.applyHolidays(data) }
  }

  function refreshHolidays() {
    holidaysProc.running = false
    holidaysProc.command = [Config.veyctl, "holidays", root.displayYear.toString()]
    holidaysProc.running = true
  }

  function applyHolidays(data) {
    try {
      let res = JSON.parse(data)
      let map = {}
      let list = res.holidays || []
      for (let i = 0; i < list.length; i++) {
        let h = list[i]
        if (h.date) map[h.date] = h.name || ""
      }
      root.holidaysMap = map
      root.updateCalendarGrid()
    } catch(e) {}
  }

  function refreshWeather() {
    if (!Config.weatherEnabled) return
    weatherProc.running = false
    weatherProc.command = [Config.veyctl, "weather", "refresh"]
    weatherProc.running = true
  }

  function applyWeather(data) {
    try {
      let res = JSON.parse(data)
      if (!res.ok) return
      root.weatherOk = true
      root.weatherTempRaw = res.temperature
      root.weatherCode = res.code
      root.weatherHumidity = res.humidity + "%"
      root.weatherCondition = res.condition || "Погода"
      root.weatherDetails = (res.name || Config.weatherLocation || "Текущий город") + " · влажность " + root.weatherHumidity
      forecastModel.clear()
      let days = res.days || []
      for (let i = 0; i < Math.min(4, days.length); i++) {
        let day = days[i]
        forecastModel.append({
          dayLabel: root.forecastDayLabel(day.date, i),
          tempRaw: day.temperature,
          humidity: day.humidity + "%",
          code: day.code,
          desc: day.condition || "Прогноз"
        })
      }
      for (let i = days.length; i < 4; i++) {
        forecastModel.append({
          dayLabel: root.forecastDayLabel(root.addDays(new Date(), i), i),
          tempRaw: -999,
          humidity: "--",
          desc: "Нет данных"
        })
      }
      hourlyModel.clear()
      let hours = res.hours || []
      for (let i = 0; i < Math.min(4, hours.length); i++) {
        hourlyModel.append({
          hourLabel: hours[i].time,
          tempRaw: hours[i].temperature,
          code: hours[i].code
        })
      }
    } catch(e) {}
  }

  function forecastDayLabel(rawDate, index) {
    if (index === 0) return "Сегодня"
    let d = rawDate instanceof Date ? rawDate : new Date(rawDate + "T00:00:00")
    return Config.weekdayBarNamesRu[d.getDay()]
  }

  function weatherIcon(code) {
    if (code === 0) return "󰖙"
    if (code === 1 || code === 2) return "󰖕"
    if (code === 3) return "󰖐"
    if (code === 45 || code === 48) return "󰖑"
    if (code >= 51 && code <= 57) return "󰖗"
    if (code >= 61 && code <= 67) return "󰖖"
    if (code >= 71 && code <= 77) return "󰖘"
    if (code >= 80 && code <= 82) return "󰖖"
    if (code >= 95) return "󰖓"
    return Config.iconWeather
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

  ListModel {
    id: hourlyModel
  }

  function holidayKey(y, m, d) {
    return y + "-" + String(m + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0")
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
        isToday: false,
        holidayName: ""
      })
    }

    // 2. Current month days
    for (let d = 1; d <= daysInMonth; d++) {
      let isToday = (displayYear === realYear && displayMonth === realMonth && d === realDate)
      calendarModel.append({
        dayNumber: d,
        inMonth: true,
        isToday: isToday,
        holidayName: root.holidaysMap[root.holidayKey(displayYear, displayMonth, d)] || ""
      })
    }

    // 3. Next month leading days
    let remaining = 42 - calendarModel.count
    for (let n = 1; n <= remaining; n++) {
      calendarModel.append({
        dayNumber: n,
        inMonth: false,
        isToday: false,
        holidayName: ""
      })
    }
  }

  Component.onCompleted: {
    updateCalendarGrid()
  }

  function prevMonth() {
    let yearChanged = displayMonth === 0
    if (displayMonth === 0) {
      displayMonth = 11
      displayYear--
    } else {
      displayMonth--
    }
    updateCalendarGrid()
    if (yearChanged) refreshHolidays()
  }

  function nextMonth() {
    let yearChanged = displayMonth === 11
    if (displayMonth === 11) {
      displayMonth = 0
      displayYear++
    } else {
      displayMonth++
    }
    updateCalendarGrid()
    if (yearChanged) refreshHolidays()
  }

  function showHolidayTip(target, name) {
    if (root.tooltip) root.tooltip.show(target, name)
  }

  function hideHolidayTip() {
    if (root.tooltip) root.tooltip.hide()
  }

  // Floating Compact Container Box
  Rectangle {
    id: container
    width: Config.calendarWidth
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
      onClicked: (mouse) => { mouse.accepted = true }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: Config.innerBorderMargin
      radius: Config.overlayRadius - 2
      color: "#00000000"
      border.color: Config.popupBorderColor
      border.width: Config.popupBordersEnabled ? 1 : 0
    }

    Row {
      id: columnLayout
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.scaledSize(14)

      Item {
        width: Config.scaledSize(170)
        height: calendarColumn.implicitHeight

        Column {
          id: weatherColumn
          width: parent.width
          spacing: Config.scaledSize(10)

          Row {
            width: parent.width
            height: Config.scaledSize(48)
            spacing: Config.scaledSize(10)

            Text {
              text: root.weatherIcon(root.weatherCode)
              color: Config.activeBorderColor
              font.pixelSize: Config.fontSizeIconHuge
              font.family: Config.fontIcon
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              width: parent.width - 42
              anchors.verticalCenter: parent.verticalCenter
              spacing: Config.scaledSize(1)

              Text { width: parent.width; text: root.weatherTemp; color: Config.textWhite; font.pixelSize: Config.fontSizeIconHuge; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
              Text { width: parent.width; text: root.weatherCondition; color: Config.textMuted; font.pixelSize: Config.scaledFontSize(11); font.family: Config.fontSans; elide: Text.ElideRight }
            }
          }

          Row {
            width: parent.width
            height: Config.scaledSize(24)
            spacing: Config.scaledSize(6)
            Text { width: parent.width - 52; text: Config.weatherLocation || "Погода"; color: Config.textSubtle; font.pixelSize: Config.fontSizeExtraSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            Text { width: Config.scaledSize(46); text: Config.iconHumidity + " " + root.weatherHumidity; color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontIcon; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
          }

          Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45 }

          Row {
            width: parent.width
            height: Config.scaledSize(58)
            spacing: Config.scaledSize(4)
            visible: hourlyModel.count > 0

            Repeater {
              model: hourlyModel
              Column {
                width: (weatherColumn.width - 12) / 4
                spacing: Config.scaledSize(4)
                Text { width: parent.width; text: hourLabel; color: Config.textMuted; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontSans; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                Text { width: parent.width; text: root.weatherIcon(code); color: Config.textSubtle; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width; text: Config.iconTemperature + " " + (tempRaw > -999 ? Config.tempText(tempRaw, Config.weatherTenths) : "--"); color: Config.textWhite; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
              }
            }
          }

          Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45; visible: hourlyModel.count > 0 }

          Row {
            width: parent.width
            height: Config.scaledSize(88)
            spacing: Config.scaledSize(4)

            Repeater {
              model: forecastModel
              Column {
                width: (weatherColumn.width - 12) / 4
                spacing: Config.scaledSize(4)
                Text { width: parent.width; text: dayLabel; color: Config.textMuted; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontSans; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                Text { width: parent.width; text: root.weatherIcon(code); color: Config.textSubtle; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width; text: Config.iconTemperature + " " + (tempRaw > -999 ? Config.tempText(tempRaw, Config.weatherTenths) : "--"); color: Config.textWhite; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
                Text { width: parent.width; text: Config.iconHumidity + " " + humidity; color: Config.textMuted; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontIcon; horizontalAlignment: Text.AlignHCenter }
              }
            }
          }
        }

      }

      Rectangle { width: 1; height: calendarColumn.implicitHeight; color: Config.separatorColor; opacity: 0.7 }

      Column {
        id: calendarColumn
        width: parent.width - 199
        spacing: Config.scaledSize(10)

        Item {
          width: parent.width
          height: Config.scaledSize(28)

          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Config.scaledSize(28)
            height: Config.scaledSize(28)
            radius: Config.popupRadiusPx(7)
            color: prevMouse.containsMouse ? Config.selectedBg : "#00000000"
            Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Config.scaledSize(28)
            height: Config.scaledSize(28)
            radius: Config.popupRadiusPx(7)
            color: nextMouse.containsMouse ? Config.selectedBg : "#00000000"
            Text { anchors.centerIn: parent; text: Config.iconChevronRight; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
          }

          Text {
            anchors.centerIn: parent
            text: Config.monthNamesRu[root.displayMonth].toUpperCase() + " " + root.displayYear
            color: Config.textMuted
            font.pixelSize: Config.fontSizeExtraSmall
            font.weight: Font.Medium
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
              height: Config.scaledSize(22)

              Text { anchors.centerIn: parent; text: modelData; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
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
              id: dayCell
              required property int dayNumber
              required property bool inMonth
              required property bool isToday
              required property string holidayName

              width: calendarColumn.width / 7
              height: Config.scaledSize(30)

              Rectangle {
                anchors.centerIn: parent
                width: Config.scaledSize(26)
                height: Config.scaledSize(26)
                radius: Config.popupRadiusPx(8)
                color: isToday ? Config.selectedBg : "#00000000"
                border.color: isToday ? Config.activeBorderColor : "#00000000"
                border.width: isToday ? 1 : 0
              }

              Text { anchors.centerIn: parent; text: dayNumber.toString(); color: isToday ? Config.textWhite : (inMonth ? Config.textSubtle : Config.textDark); font.pixelSize: Config.fontSizeNormal; font.weight: isToday ? Font.Medium : Font.Normal; font.family: Config.fontSans }

              Rectangle {
                visible: holidayName.length > 0
                width: 4
                height: 4
                radius: 2
                color: Config.activeBorderColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.scaledSize(2)
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: holidayName.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: if (holidayName.length > 0) root.showHolidayTip(dayCell, holidayName)
                onExited: root.hideHolidayTip()
              }
            }
          }
        }
      }
    }

  }
}
