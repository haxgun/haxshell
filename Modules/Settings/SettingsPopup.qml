// SettingsPopup.qml - Sectioned settings, wallpaper, fonts and weather controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Widgets"
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property string activeSection: "appearance"
  property string fontSearch: ""
  property bool languageDropdownOpen: false
  property real languageDropdownX: 0
  property real languageDropdownY: 0
  property real languageDropdownWidth: 194
  readonly property var languages: [
    { key: "ru", label: "RU", name: "Русский" },
    { key: "en", label: "EN", name: "English" },
    { key: "ja", label: "JA", name: "日本語" },
    { key: "zh", label: "ZH", name: "中文" },
    { key: "de", label: "DE", name: "Deutsch" }
  ]
  property var allFonts: []
  property string thumbnail: ""
  property string wallName: "Нет обоев"
  property int currentWallpaperIndex: 0
  property real wallpaperGridContentY: 0
  property bool restoringWallpaperScroll: false
  property bool wallpaperSelectionInProgress: false

  Timer {
    id: wallpaperScrollRestoreTimer
    interval: 0
    repeat: false
    onTriggered: root.restoreWallpaperScroll()
  }
  property var palette: []
  property color manualAccentColor: Config.manualAccent
  readonly property real manualHue: manualAccentColor.hslHue >= 0 ? manualAccentColor.hslHue : 0
  readonly property real manualSat: manualAccentColor.hslSaturation
  readonly property string currentManualHex: colorToHex(manualAccentColor)
  readonly property string qsctl: Qt.resolvedUrl("../../scripts/qsctl").toString().replace("file://", "")

  onIsOpenChanged: if (isOpen) {
    wallpaperDirInput.text = Config.wallpaperDir
    weatherLocationInput.text = Config.weatherLocation
    fontSearchInput.text = root.fontSearch
    manualAccentInput.text = Config.manualAccent
    refreshWallpapers()
    refreshFonts()
  } else {
    weatherSuggestions.clear()
    root.fontSearch = ""
  }

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "settings"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  ListModel { id: wallpapersModel }
  ListModel { id: weatherSuggestions }
  ListModel { id: fontModel }

  Process {
    id: wallpaperProc
    stdout: SplitParser { onRead: data => root.applyWallpaperState(data) }
  }

  Process {
    id: fontProc
    stdout: SplitParser { onRead: data => root.applyFonts(data) }
  }

  Process {
    id: folderProc
    stdout: SplitParser {
      onRead: data => {
        try {
          let res = JSON.parse(data)
          if (res.ok && res.path) {
            wallpaperDirInput.text = res.path
            root.applyWallpaperDir(res.path)
          }
        } catch(e) {}
      }
    }
  }

  Process {
    id: citySearchProc
    stdout: SplitParser { onRead: data => root.applyCitySuggestions(data) }
  }

  Timer { id: citySearchTimer; interval: 350; repeat: false; onTriggered: if (weatherLocationInput.activeFocus) root.searchCities(weatherLocationInput.text) }

  Connections { target: Config; function onWallpaperDirChanged() { root.refreshWallpapers() } }

  function saveSetting(key, value) {
    SettingsStore.setValue(key, value)
  }

  function saveSettingAlt(key, value) { saveSetting(key, value) }

  function languageName(code) {
    for (let i = 0; i < root.languages.length; i++) if (root.languages[i].key === code) return root.languages[i].name
    return "Русский"
  }

  function applyLanguage(value) {
    Config.language = value
    saveSetting("language", value)
    root.languageDropdownOpen = false
  }

  function componentToHex(value) {
    let hex = Math.round(value * 255).toString(16)
    return hex.length === 1 ? "0" + hex : hex
  }

  function colorToHex(color) {
    return ("#" + componentToHex(color.r) + componentToHex(color.g) + componentToHex(color.b)).toUpperCase()
  }

  function applyTheme(value) {
    Config.themeName = value
    saveSetting("themeName", value)
    if (value === "dynamic") refreshWallpapers()
  }
  function applyBarPosition(value) {
    Config.barPosition = value
    saveSetting("barPosition", value)
  }
  function applyFont(value) { Config.fontFamily = value; saveSetting("fontFamily", value) }
  function applyWeatherLocation(value) { let location = value.trim(); Config.weatherLocation = location; saveSetting("weatherLocation", location) }
  function applyTimeFormat(value) { Config.timeFormat = value; saveSetting("timeFormat", value) }
  function applyUiScale(value) { Config.uiScale = parseFloat(value); saveSetting("uiScale", value) }
  function applyManualAccent(value) {
    let color = value.trim()
    if (!/^#[0-9A-Fa-f]{6}$/.test(color)) return
    Config.manualAccent = color
    saveSetting("manualAccent", color)
  }
  function applyManualColor(color) { applyManualAccent(colorToHex(color)) }
  function applyManualTone(value) {
    Config.manualDark = value
    saveSetting("manualDark", value ? "true" : "false")
    let hue = root.manualHue
    let sat = root.manualSat < 0.05 ? 0.5 : root.manualSat
    let color = colorToHex(Qt.hsla(hue, sat, value ? 0.5 : 0.62, 1))
    Config.manualAccent = color
    saveSettingAlt("manualAccent", color)
  }
  function setManualHueFromX(x, width) {
    let hue = Math.max(0, Math.min(1, x / Math.max(width, 1)))
    let sat = root.manualSat < 0.05 ? 0.5 : root.manualSat
    applyManualColor(Qt.hsla(hue, sat, Config.manualDark ? 0.5 : 0.62, 1))
  }
  function setBoolSetting(key, value) {
    if (key === "showSeconds") Config.showSeconds = value
    if (key === "musicVisualizerEnabled") {
      Config.musicVisualizerEnabled = value
      Config.mprisRightDisplayMode = value ? "visualizer" : "progress"
    }
    if (key === "reduceMotion") Config.reduceMotion = value
    saveSetting(key, value ? "true" : "false")
  }

  function applyWallpaperDir(value) {
    let nextDir = value.trim()
    if (nextDir.length === 0) return
    Config.wallpaperDir = nextDir
    saveSetting("wallpaperDir", nextDir)
    wallpaperProc.running = false
    wallpaperProc.command = [root.qsctl, "wallpaper", "config", nextDir]
    wallpaperProc.running = true
  }

  function refreshFonts() {
    fontProc.running = false
    fontProc.command = [root.qsctl, "fonts"]
    fontProc.running = true
  }

  function applyFonts(data) {
    try {
      let res = JSON.parse(data)
      let fonts = res.fonts || []
      root.allFonts = fonts
      if (fonts.length > 0) Config.availableFonts = fonts
      root.filterFonts()
    } catch(e) {}
  }

  function filterFonts() {
    let needle = root.fontSearch.trim().toLowerCase()
    fontModel.clear()
    for (let i = 0; i < root.allFonts.length; i++) {
      let name = root.allFonts[i]
      if (needle.length === 0 || name.toLowerCase().indexOf(needle) >= 0) fontModel.append({ name: name })
    }
  }

  function pickWallpaperDir() {
    folderProc.running = false
    folderProc.command = [root.qsctl, "pick-folder", Config.wallpaperDir]
    folderProc.running = true
  }

  function refreshWallpapers() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.qsctl, "wallpaper", "get", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.qsctl, "wallpaper", "next", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function setWallpaper(index) {
    wallpaperGridContentY = wallpaperGrid.contentY
    wallpaperSelectionInProgress = true
    wallpaperProc.running = false
    wallpaperProc.command = [root.qsctl, "wallpaper", "set", index.toString(), Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function restoreWallpaperScroll() {
    if (!wallpaperGrid) return
    root.restoringWallpaperScroll = true
    let maxContentY = Math.max(0, wallpaperGrid.contentHeight - wallpaperGrid.height)
    wallpaperGrid.contentY = Math.min(root.wallpaperGridContentY, maxContentY)
    root.wallpaperGridContentY = wallpaperGrid.contentY
    root.restoringWallpaperScroll = false
  }

  function applyWallpaperState(data) {
    try {
      let res = JSON.parse(data)
      root.thumbnail = res.thumbnail || ""
      root.wallName = res.name || "Нет обоев"
      root.currentWallpaperIndex = res.index || 0
      root.palette = res.palette || []
      if (root.palette.length > 0 && Config.dynamicAccent !== root.palette[0]) {
        Config.dynamicAccent = root.palette[0]
        saveSettingAlt("dynamicAccent", root.palette[0])
      }
      if (!root.wallpaperSelectionInProgress) {
        wallpapersModel.clear()
        let items = res.items || []
        for (let i = 0; i < items.length; i++) wallpapersModel.append(items[i])
        wallpaperScrollRestoreTimer.restart()
      }
      root.wallpaperSelectionInProgress = false
      root.restoringWallpaperScroll = false
    } catch(e) {}
  }

  function searchCities(query) {
    let text = query.trim()
    if (text.length < 2) { weatherSuggestions.clear(); return }
    citySearchProc.running = false
    citySearchProc.command = ["curl", "-fsS", "--max-time", "5", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(text) + "&count=6&language=ru&format=json"]
    citySearchProc.running = true
  }

  function applyCitySuggestions(data) {
    try {
      let parsed = JSON.parse(data)
      let results = parsed.results || []
      weatherSuggestions.clear()
      for (let i = 0; i < results.length; i++) {
        let city = results[i]
        let parts = [city.name]
        if (city.admin1) parts.push(city.admin1)
        if (city.country) parts.push(city.country)
        weatherSuggestions.append({ label: parts.join(", ") })
      }
    } catch(e) { weatherSuggestions.clear() }
  }

  Rectangle {
    id: container
    width: 430
    height: Math.min(contentRoot.implicitHeight + 28, root.height - 32)
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.glassBg
    clip: false

    Rectangle {
      visible: Config.shellShadowsEnabled
      x: 0
      y: Config.shellShadowOffsetY
      width: parent.width
      height: parent.height
      radius: parent.radius
      color: Config.shellShadowColor
      opacity: 0.55
      z: -1
    }

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: Config.shellBordersEnabled ? 1 : 0 }

    Column {
      id: contentRoot
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Row {
        width: parent.width
        height: 30
        spacing: 10
        Text { text: Config.iconSettings; color: Config.textWhite; font.pixelSize: Config.fontSizeTitle; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
        Text { text: I18n.tr("Настройки"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
      }

      Row {
        width: parent.width
        height: 38
        spacing: 8

        Repeater {
          model: [
            { key: "appearance", icon: Config.iconSettings, title: "Общие" },
            { key: "wallpaper", icon: Config.iconWallpaper, title: "Обои" },
            { key: "system", icon: Config.iconCoffee, title: "Сон" }
          ]
          Rectangle {
            required property var modelData
            width: (parent.width - 16) / 3
            height: 36
            radius: Config.cardRadius
            readonly property bool active: root.activeSection === modelData.key
            color: active ? Config.selectedBg : (sectionMouse.containsMouse ? Config.hoverBg : "#151A1A1A")
            border.color: active ? Config.activeBorderColor : "#30464646"
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: 6
              Text { text: parent.parent.modelData.icon; color: parent.parent.active ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
              Text { text: I18n.tr(parent.parent.modelData.title); color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: sectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activeSection = parent.modelData.key }
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: Config.separatorColor }

      Flickable {
        width: parent.width
        height: Math.min(sectionContent.implicitHeight, root.height - 144)
        contentWidth: width
        contentHeight: sectionContent.implicitHeight
        clip: true

        Column {
          id: sectionContent
          width: parent.width
          spacing: 12

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "appearance"
            Text { text: I18n.tr("Оформление"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconPalette
              title: I18n.tr("Тема")
              subtitle: Config.themeName === "manual" ? I18n.tr("Ручной акцент") : (Config.themeName === "dynamic" ? I18n.tr("Акцент из обоев") : (Config.themeName === "light" ? I18n.tr("Светлая палитра") : I18n.tr("Тёмная палитра")))
              Rectangle {
                id: themeSegment
                width: 226
                height: 34
                radius: 9
                color: "transparent"
                Row {
                  anchors.fill: parent
                  spacing: 2
                  Repeater {
                    model: [{ key: "light", label: "Свет" }, { key: "dark", label: "Тьма" }, { key: "dynamic", label: "Дин." }, { key: "manual", label: "Своя" }]
                    Rectangle {
                      required property var modelData
                      width: (themeSegment.width - 6) / 4
                      height: 34
                      radius: 9
                      readonly property bool active: Config.themeName === modelData.key
                      color: active ? Config.selectedBg : (themeMouse.containsMouse ? Config.hoverBg : "transparent")
                      Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.2 }
                      MouseArea { id: themeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyTheme(parent.modelData.key) }
                    }
                  }
                }
              }
            }

            Item {
              width: parent.width
              height: Config.themeName === "manual" ? manualThemeColumn.implicitHeight : 0
              clip: true
              Behavior on height { NumberAnimation { duration: Config.reduceMotion ? 0 : 180; easing.type: Easing.OutCubic } }
              Column {
                id: manualThemeColumn
                width: parent.width
                spacing: 12
                topPadding: 4
                bottomPadding: 6

                Item {
                  width: parent.width
                  height: 18
                  Rectangle {
                    id: manualHueStrip
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 14
                    radius: 7
                    gradient: Gradient {
                      orientation: Gradient.Horizontal
                      GradientStop { position: 0.0; color: Qt.hsla(0.0, 0.7, 0.5, 1) }
                      GradientStop { position: 1 / 6; color: Qt.hsla(1 / 6, 0.7, 0.5, 1) }
                      GradientStop { position: 2 / 6; color: Qt.hsla(2 / 6, 0.7, 0.5, 1) }
                      GradientStop { position: 3 / 6; color: Qt.hsla(3 / 6, 0.7, 0.5, 1) }
                      GradientStop { position: 4 / 6; color: Qt.hsla(4 / 6, 0.7, 0.5, 1) }
                      GradientStop { position: 5 / 6; color: Qt.hsla(5 / 6, 0.7, 0.5, 1) }
                      GradientStop { position: 1.0; color: Qt.hsla(1.0, 0.7, 0.5, 1) }
                    }
                    Rectangle {
                      width: 18
                      height: 18
                      radius: 9
                      anchors.verticalCenter: parent.verticalCenter
                      x: root.manualHue * (manualHueStrip.width - width)
                      color: Config.manualAccent
                      border.width: 2
                      border.color: Config.textWhite
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onPressed: mouse => root.setManualHueFromX(mouse.x, manualHueStrip.width)
                      onPositionChanged: mouse => root.setManualHueFromX(mouse.x, manualHueStrip.width)
                    }
                  }
                }

                Row {
                  width: parent.width
                  height: 36
                  spacing: 10
                  Rectangle { width: 34; height: 34; radius: 9; color: Config.manualAccent; border.color: Config.borderColor; border.width: 1; anchors.verticalCenter: parent.verticalCenter }
                  Column {
                    width: parent.width - 174
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { width: parent.width; text: I18n.tr("Акцент"); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
                    Text { width: parent.width; text: root.currentManualHex + " · " + (Config.manualDark ? I18n.tr("тёмная") : I18n.tr("светлая")); color: Config.textMuted; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight }
                  }
                  Row {
                    width: 120
                    height: 30
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                      model: [{ key: true, label: "Тьма" }, { key: false, label: "Свет" }]
                      Rectangle {
                        required property var modelData
                        width: 58
                        height: 30
                        radius: 8
                        readonly property bool active: Config.manualDark === modelData.key
                        color: active ? Config.selectedBg : (toneMouse.containsMouse ? Config.hoverBg : "transparent")
                        Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans }
                        MouseArea { id: toneMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyManualTone(parent.modelData.key) }
                      }
                    }
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 34
                  radius: 10
                  color: Config.searchBg
                  border.color: manualAccentInput.activeFocus ? Config.activeBorderColor : Config.borderColor
                  border.width: 1
                  TextInput {
                    id: manualAccentInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    text: Config.manualAccent
                    color: Config.textPrimary
                    selectedTextColor: Config.textWhite
                    selectionColor: Config.selectedBg
                    font.pixelSize: Config.fontSizeSmall
                    font.family: Config.fontMono
                    maximumLength: 7
                    onEditingFinished: root.applyManualAccent(text)
                    Keys.onReturnPressed: focus = false
                    Keys.onEscapePressed: { text = Config.manualAccent; focus = false }
                  }
                }
              }
            }

            SettingsRow {
              icon: Config.iconWallpaper
              title: I18n.tr("Положение панели")
              subtitle: Config.barPosition === "bottom" ? I18n.tr("Снизу") : (Config.barPosition === "left" ? I18n.tr("Слева") : (Config.barPosition === "right" ? I18n.tr("Справа") : I18n.tr("Сверху")))
              Rectangle {
                id: barPosSegment
                width: 226
                height: 34
                radius: 9
                color: "transparent"
                Row {
                  anchors.fill: parent
                  spacing: 2
                  Repeater {
                    model: [{ key: "top", label: "Верх" }, { key: "bottom", label: "Низ" }, { key: "left", label: "Слева" }, { key: "right", label: "Справа" }]
                    Rectangle {
                      required property var modelData
                      width: (barPosSegment.width - 6) / 4
                      height: 34
                      radius: 9
                      readonly property bool active: Config.barPosition === modelData.key
                      color: active ? Config.selectedBg : (barPosMouse.containsMouse ? Config.hoverBg : "transparent")
                      Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.2 }
                      MouseArea { id: barPosMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarPosition(parent.modelData.key) }
                    }
                  }
                }
              }
            }

            SettingsRow {
              icon: Config.iconWallpaper
              title: I18n.tr("Папка обоев")
              subtitle: Config.wallpaperDir
              Item {
                width: 194
                height: 34
                Rectangle {
                  anchors.left: parent.left
                  anchors.right: folderButton.left
                  anchors.rightMargin: 6
                  height: 34
                  radius: 10
                  color: Config.searchBg
                  border.color: wallpaperDirInput.activeFocus ? Config.activeBorderColor : "#00000000"
                  border.width: wallpaperDirInput.activeFocus ? 1 : 0
                  TextInput {
                    id: wallpaperDirInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: Config.wallpaperDir
                    color: Config.textPrimary
                    selectedTextColor: Config.textWhite
                    selectionColor: Config.selectedBg
                    font.pixelSize: 10
                    font.family: Config.fontSans
                    clip: true
                    onEditingFinished: root.applyWallpaperDir(text)
                    Keys.onReturnPressed: focus = false
                    Keys.onEscapePressed: {
                      text = Config.wallpaperDir
                      focus = false
                    }
                  }
                }
                Rectangle {
                  id: folderButton
                  anchors.right: parent.right
                  width: 34
                  height: 34
                  radius: 10
                  color: folderMouse.containsMouse ? Config.hoverBg : "#00000000"
                  Text { anchors.centerIn: parent; text: Config.iconFolder; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
                  MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pickWallpaperDir() }
                }
              }
            }

            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("Город погоды")
              subtitle: Config.weatherLocation.length > 0 ? Config.weatherLocation : I18n.tr("Автоматически по IP")
              Rectangle {
                width: 210
                height: 34
                radius: 10
                color: Config.searchBg
                border.color: weatherLocationInput.activeFocus ? Config.activeBorderColor : "#00000000"
                border.width: weatherLocationInput.activeFocus ? 1 : 0
                TextInput {
                  id: weatherLocationInput
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  verticalAlignment: TextInput.AlignVCenter
                  text: Config.weatherLocation
                  color: Config.textPrimary
                  selectedTextColor: Config.textWhite
                  selectionColor: Config.selectedBg
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontSans
                  clip: true
                  Text { text: I18n.tr("авто по IP"); color: Config.textPlaceholder; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; visible: !weatherLocationInput.text && !weatherLocationInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                  onTextChanged: if (activeFocus) citySearchTimer.restart()
                  onEditingFinished: root.applyWeatherLocation(text)
                  Keys.onReturnPressed: focus = false
                  Keys.onEscapePressed: {
                    text = Config.weatherLocation
                    weatherSuggestions.clear()
                    focus = false
                  }
                }
              }
            }
            Column {
              width: parent.width
              spacing: 4
              visible: weatherSuggestions.count > 0
              Repeater {
                model: weatherSuggestions
                Rectangle {
                  required property string label
                  width: parent.width
                  height: 32
                  radius: 8
                  color: cityMouse.containsMouse ? Config.hoverBg : "#00000000"
                  Text { anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: Text.AlignVCenter; text: label; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight }
                  MouseArea {
                    id: cityMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      weatherLocationInput.text = parent.label
                      root.applyWeatherLocation(parent.label)
                      weatherSuggestions.clear()
                      weatherLocationInput.focus = false
                      citySearchTimer.stop()
                    }
                  }
                }
              }
            }

            Text { text: I18n.tr("Часы и медиа"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

            SettingsRow {
              icon: Config.iconClock
              title: I18n.tr("Формат времени")
              subtitle: Config.timeFormat === "12" ? I18n.tr("12-часовой формат") : I18n.tr("24-часовой формат")
              Row {
                width: 154
                height: 30
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                  model: [{ key: "24", label: "24ч" }, { key: "12", label: "12ч" }]
                  Rectangle {
                    required property var modelData
                    width: 74
                    height: 30
                    radius: Config.cardRadius
                    readonly property bool active: Config.timeFormat === modelData.key
                    color: active ? Config.selectedBg : (timeMouse.containsMouse ? Config.hoverBg : "#151A1A1A")
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }
                    MouseArea { id: timeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyTimeFormat(parent.modelData.key) }
                  }
                }
              }
            }

            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("Секунды в часах")
              subtitle: Config.showSeconds ? I18n.tr("Показываются") : I18n.tr("Скрыты")
              ToggleSwitch { checked: Config.showSeconds; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showSeconds", !Config.showSeconds) }
            }

            SettingsRow {
              icon: Config.iconMusic
              title: I18n.tr("Визуализация музыки")
              subtitle: Config.musicVisualizerEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              ToggleSwitch { checked: Config.musicVisualizerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("musicVisualizerEnabled", !Config.musicVisualizerEnabled) }
            }

            SettingsRow {
              icon: Config.iconMotion
              title: I18n.tr("Меньше анимаций")
              subtitle: Config.reduceMotion ? I18n.tr("Анимации сокращены") : I18n.tr("Обычные анимации")
              ToggleSwitch { checked: Config.reduceMotion; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("reduceMotion", !Config.reduceMotion) }
            }

            Text { text: I18n.tr("Интерфейс"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }

            SettingsRow {
              icon: Config.iconLanguage
              title: I18n.tr("Язык")
              subtitle: root.languageName(Config.language)
              Item {
                width: 194
                height: 30

                Rectangle {
                  id: languageButton
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: 30
                  radius: 9
                  color: languageButtonMouse.containsMouse ? Config.hoverBg : "#151A1A1A"
                  border.color: root.languageDropdownOpen ? Config.activeBorderColor : Config.borderColor
                  border.width: 1

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.languageName(Config.language)
                    color: Config.textPrimary
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Bold
                    font.family: Config.fontSans
                    elide: Text.ElideRight
                    width: parent.width - 38
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.languageDropdownOpen ? "󰅃" : "󰅀"
                    color: Config.textMuted
                    font.pixelSize: Config.fontSizeIconSmall
                    font.family: Config.fontIcon
                  }

                  MouseArea {
                    id: languageButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let pos = languageButton.mapToItem(container, 0, languageButton.height + 6)
                      root.languageDropdownX = pos.x
                      root.languageDropdownY = pos.y
                      root.languageDropdownWidth = languageButton.width
                      root.languageDropdownOpen = !root.languageDropdownOpen
                    }
                  }
                }
              }
            }

            SettingsRow {
              icon: Config.iconFont
              title: I18n.tr("Шрифт интерфейса")
              subtitle: Config.fontFamily
              onClicked: root.activeSection = "fontPicker"
              Text { text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            }

            SettingsRow {
              icon: Config.iconScale
              title: I18n.tr("Масштаб интерфейса")
              subtitle: Math.round(Config.uiScale * 100) + "%"
              last: true
              Row {
                width: 194
                spacing: 6
                Repeater {
                  model: [{ key: "0.9", label: "90" }, { key: "1.0", label: "100" }, { key: "1.1", label: "110" }, { key: "1.25", label: "125" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 18) / 4
                    height: 30
                    radius: 8
                    readonly property bool active: Math.abs(Config.uiScale - parseFloat(modelData.key)) < 0.01
                    color: active ? Config.selectedBg : (scaleMouse.containsMouse ? Config.hoverBg : "#00000000")
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans }
                    MouseArea { id: scaleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyUiScale(parent.modelData.key) }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "fontPicker"
            Row {
              width: parent.width
              height: 32
              spacing: 8
              Rectangle {
                width: 32
                height: 32
                radius: 9
                color: backMouse.containsMouse ? Config.hoverBg : "#151A1A1A"
                border.color: Config.borderColor
                border.width: 1
                Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activeSection = "appearance" }
              }
              Text { text: I18n.tr("Шрифт интерфейса"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
            }
            Text { text: I18n.tr("Текущий") + ": " + Config.fontFamily; color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; width: parent.width }

            Rectangle {
              width: parent.width
              height: 36
              radius: 10
              color: Config.searchBg
              border.color: fontSearchInput.activeFocus ? Config.activeBorderColor : Config.borderColor
              border.width: 1

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Config.iconSearch
                color: Config.textMuted
                font.pixelSize: Config.fontSizeIconSmall
                font.family: Config.fontIcon
              }

              TextInput {
                id: fontSearchInput
                anchors.fill: parent
                anchors.leftMargin: 36
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Config.textPrimary
                selectedTextColor: Config.textWhite
                selectionColor: Config.selectedBg
                font.pixelSize: Config.fontSizeSmall
                font.family: Config.fontSans
                clip: true
                onTextChanged: {
                  root.fontSearch = text
                  root.filterFonts()
                }
                Text { text: I18n.tr("Поиск шрифта"); color: Config.textPlaceholder; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; visible: !fontSearchInput.text && !fontSearchInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
              }
            }

            ListView {
              width: parent.width
              height: 310
              clip: true
              spacing: 6
              model: fontModel
              delegate: Rectangle {
                required property string name
                width: ListView.view.width
                height: 44
                radius: Config.cardRadius
                readonly property bool active: Config.fontFamily === name
                color: active ? Config.selectedBg : (fontMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : Config.borderColor
                border.width: 1
                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 1
                  Text { width: parent.width; text: name; color: active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: name; elide: Text.ElideRight }
                  Text { width: parent.width; text: I18n.tr("19:37 пн, июл. 20  ·  Быстрая лиса 123"); color: Config.textMuted; font.pixelSize: 10; font.family: name; elide: Text.ElideRight }
                }
                MouseArea { id: fontMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyFont(parent.name) }
              }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "wallpaper"
            Text { width: parent.width; visible: wallpapersModel.count === 0; text: I18n.tr("В папке нет поддерживаемых изображений или видео"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap }
            GridView {
              id: wallpaperGrid
              readonly property real tileGap: 6
              readonly property real tileWidth: width / 3
              readonly property real tileHeight: (tileWidth - tileGap) * 9 / 16 + tileGap
              width: parent.width
              height: Math.min(300, Math.ceil(wallpapersModel.count / 3) * tileHeight)
              anchors.horizontalCenter: parent.horizontalCenter
              visible: wallpapersModel.count > 0
              clip: true
              cellWidth: tileWidth
              cellHeight: tileHeight
              model: wallpapersModel
              onContentYChanged: {
                if (!root.restoringWallpaperScroll) root.wallpaperGridContentY = contentY
              }
              onContentHeightChanged: if (root.restoringWallpaperScroll) wallpaperScrollRestoreTimer.restart()

              delegate: Item {
                id: tile
                required property int wallIndex
                required property string name
                required property string thumbnail
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                readonly property bool isSelected: wallIndex === root.currentWallpaperIndex
                readonly property bool isHovered: wallItemMouse.containsMouse

                Rectangle {
                  id: wallpaperFrame
                  anchors.fill: parent
                  anchors.margins: wallpaperGrid.tileGap / 2
                  radius: Config.cardRadius
                  color: Config.searchBg
                  clip: true
                  scale: tile.isHovered ? 1.03 : 1.0
                  border.color: tile.isSelected ? Config.activeBorderColor : "#00000000"
                  border.width: tile.isSelected ? 2 : 0

                  Behavior on scale { NumberAnimation { duration: Config.reduceMotion ? 0 : 120; easing.type: Easing.OutCubic } }

                  ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Config.overlayRadius - 4
                    color: Config.searchBg

                    Image {
                      anchors.fill: parent
                      source: thumbnail
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      cache: true
                      sourceSize.width: 220
                      sourceSize.height: 150
                      visible: thumbnail.length > 0
                    }

                    Rectangle {
                      anchors.fill: parent
                      color: Config.textWhite
                      opacity: tile.isHovered ? 0.06 : 0
                      Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 115 } }
                    }

                    Rectangle {
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.bottom: parent.bottom
                      height: 34
                      opacity: tile.isHovered || tile.isSelected ? 1 : 0
                      gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#cc000000" }
                      }

                      Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 140 } }

                      Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        text: name
                        color: Config.textWhite
                        font.pixelSize: Config.fontSizeSmall
                        font.weight: tile.isSelected ? Font.Bold : Font.Medium
                        font.family: Config.fontSans
                        elide: Text.ElideMiddle
                      }
                    }
                  }
                }

                MouseArea {
                  id: wallItemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setWallpaper(wallIndex)
                }
              }
            }
          }

        }
      }
    }

      Rectangle {
        id: languageDropdown
        z: 50
        x: root.languageDropdownX
        y: root.languageDropdownY
        width: root.languageDropdownWidth
        height: Math.min(root.languages.length * 32 + 12, 180)
        radius: 10
        color: Config.glassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.languageDropdownOpen && root.activeSection === "appearance"

        Flickable {
          id: languageList
          anchors.fill: parent
          anchors.margins: 6
          contentWidth: width
          contentHeight: languageListColumn.implicitHeight
          clip: true

          Column {
            id: languageListColumn
            width: languageList.width
            spacing: 4

            Repeater {
              model: root.languages
              Rectangle {
                required property var modelData
                width: languageListColumn.width
                height: 28
                radius: 8
                readonly property bool active: Config.language === modelData.key
                color: active ? Config.selectedBg : (languageMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1

                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 8
                  Text { text: parent.parent.modelData.label; color: parent.parent.active ? Config.textWhite : Config.textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; width: 22 }
                  Text { text: parent.parent.modelData.name; color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                }

                MouseArea { id: languageMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyLanguage(parent.modelData.key) }
              }
            }
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.rightMargin: 3
          y: 6 + (languageList.visibleArea.yPosition * (parent.height - 12))
          width: 3
          height: Math.max(18, languageList.visibleArea.heightRatio * (parent.height - 12))
          radius: 2
          color: Config.textMuted
          opacity: languageList.contentHeight > languageList.height ? 0.55 : 0
        }
      }
  }
}
