// SettingsPopup.qml - Sectioned settings, wallpaper, fonts and weather controls
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../Widgets"
import "../../Common"
import "../../Services"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property string activeSection: "general"
  property string pendingSection: "general"
  property string fontSearch: ""
  property bool languageDropdownOpen: false
  property real languageDropdownX: 0
  property real languageDropdownY: 0
  property real languageDropdownWidth: 194
  property bool wallpaperModeDropdownOpen: false
  property real wallpaperModeDropdownX: 0
  property real wallpaperModeDropdownY: 0
  property real wallpaperModeDropdownWidth: 194
  property bool wallpaperTransitionDropdownOpen: false
  property real wallpaperTransitionDropdownX: 0
  property real wallpaperTransitionDropdownY: 0
  property real wallpaperTransitionDropdownWidth: 194
  readonly property var languages: [
    { key: "ru", label: "RU", name: "Русский" },
    { key: "en", label: "EN", name: "English" },
    { key: "ja", label: "JA", name: "日本語" },
    { key: "zh", label: "ZH", name: "中文" },
    { key: "de", label: "DE", name: "Deutsch" }
  ]
  readonly property var wallpaperFillModes: [
    { key: "stretch", label: "Растянуть" }, { key: "fit", label: "Вместить" },
    { key: "fill", label: "Заполнить" }, { key: "tile", label: "Замостить" },
    { key: "tile-v", label: "Замостить по вертикали" }, { key: "tile-h", label: "Замостить по горизонтали" },
    { key: "pad", label: "С полями" }
  ]
  readonly property var wallpaperTransitions: [
    { key: "none", label: "Без эффекта" }, { key: "fade", label: "Плавное появление" },
    { key: "wipe", label: "Стирание" }, { key: "wave", label: "Волна" },
    { key: "grow", label: "Раскрытие" }, { key: "center", label: "Круг из центра" },
    { key: "outer", label: "Круг к центру" }, { key: "random", label: "Случайный" }
  ]
  readonly property var screenPositions: [
    { key: "top-left", label: "ВЛ" }, { key: "top-center", label: "Верх" }, { key: "top-right", label: "ВП" },
    { key: "bottom-left", label: "НЛ" }, { key: "bottom-center", label: "Низ" }, { key: "bottom-right", label: "НП" }
  ]
  property var allFonts: []
  property string thumbnail: ""
  property string wallName: "Нет обоев"
  property int currentWallpaperIndex: 0
  property real wallpaperGridContentY: 0
  property bool restoringWallpaperScroll: false
  property bool wallpaperSelectionInProgress: false

  function selectSection(section) {
    if (section === root.activeSection || sectionTransition.running) return
    root.pendingSection = section
    sectionTransition.restart()
  }

  SequentialAnimation {
    id: sectionTransition
    NumberAnimation { target: settingsFlickable; property: "opacity"; to: 0; duration: Config.reduceMotion ? 0 : 60; easing.type: Easing.OutCubic }
    ScriptAction {
      script: {
        root.activeSection = root.pendingSection
        settingsFlickable.contentY = 0
      }
    }
    NumberAnimation { target: settingsFlickable; property: "opacity"; to: 1; duration: Config.reduceMotion ? 0 : 90; easing.type: Easing.OutCubic }
  }

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
  readonly property string hushctl: Config.hushctl

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
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

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
  function optionName(options, key) {
    for (let i = 0; i < options.length; i++) if (options[i].key === key) return options[i].label
    return options.length > 0 ? options[0].label : ""
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
  function applyBarThickness(value) {
    let thickness = Math.max(28, Math.min(100, Math.round(value)))
    Config.barThickness = thickness
    saveSetting("barThickness", thickness)
  }
  function applyBarTopMargin(value) {
    let margin = Math.max(0, Math.min(64, Math.round(value)))
    Config.barTopMargin = margin
    saveSetting("barTopMargin", margin)
  }
  function applyBarHorizontalMargin(value) {
    let margin = Math.max(0, Math.min(64, Math.round(value)))
    Config.barHorizontalMargin = margin
    saveSetting("barHorizontalMargin", margin)
  }
  function applyBarRadius(value) {
    let radius = Math.max(0, Math.min(32, Math.round(value)))
    Config.barRadius = radius
    saveSetting("barRadius", radius)
  }
  function applyBarFrostOpacity(value) {
    let opacity = Math.max(0, Math.min(100, Math.round(value)))
    Config.barFrostOpacity = opacity
    saveSetting("barFrostOpacity", opacity)
  }
  function applyPopupRadius(value) {
    let radius = Math.max(0, Math.min(32, Math.round(value)))
    Config.popupRadius = radius
    saveSetting("popupRadius", radius)
  }
  function applyPopupBackgroundOpacity(value) {
    let opacity = Math.max(0, Math.min(100, Math.round(value)))
    Config.popupBackgroundOpacity = opacity
    saveSetting("popupBackgroundOpacity", opacity)
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
    if (key === "showWorkspaceNumbers") Config.showWorkspaceNumbers = value
    if (key === "showWorkspacesOnAllMonitors") Config.showWorkspacesOnAllMonitors = value
    if (key === "barBlurEnabled") Config.barBlurEnabled = value
    if (key === "popupBlurEnabled") Config.popupBlurEnabled = value
    if (key === "wallpaperCyclingEnabled") Config.wallpaperCyclingEnabled = value
    if (key === "blurWallpaperOnOverview") Config.blurWallpaperOnOverview = value
    if (key === "reduceMotion") Config.reduceMotion = value
    if (key === "shellBordersEnabled") Config.shellBordersEnabled = value
    if (key === "shellShadowsEnabled") Config.shellShadowsEnabled = value
    if (key === "weatherEnabled") Config.weatherEnabled = value
    saveSetting(key, value ? "true" : "false")
  }
  function applyChoice(key, value) {
    if (key === "notificationPosition") Config.notificationPosition = value
    if (key === "osdPosition") Config.osdPosition = value
    if (key === "workspaceIndicatorStyle") Config.workspaceIndicatorStyle = value
    saveSetting(key, value)
  }
  function applyNotificationTimeout(value) {
    let timeout = Math.max(1000, Math.min(300000, Math.round(value)))
    Config.notificationTimeoutMs = timeout
    saveSetting("notificationTimeoutMs", timeout)
  }

  component PositionPicker: Grid {
    id: picker
    property string settingKey: ""
    property string currentValue: ""
    width: 194
    columns: 3
    columnSpacing: 4
    rowSpacing: 4
    Repeater {
      model: root.screenPositions
      Rectangle {
        required property var modelData
        width: 62
        height: 28
        radius: 7
        readonly property bool active: picker.currentValue === modelData.key
        color: active ? Config.selectedBg : (positionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
        border.color: active ? Config.activeBorderColor : Config.borderColor
        border.width: 1
        Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: 9; font.weight: Font.Bold; font.family: Config.fontSans }
        MouseArea { id: positionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyChoice(picker.settingKey, parent.modelData.key) }
      }
    }
  }

  function applyWallpaperDir(value) {
    let nextDir = value.trim()
    if (nextDir.length === 0) return
    Config.wallpaperDir = nextDir
    saveSetting("wallpaperDir", nextDir)
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "config", nextDir]
    wallpaperProc.running = true
  }
  function applyWallpaperFillMode(value) { Config.wallpaperFillMode = value; saveSetting("wallpaperFillMode", value); root.wallpaperModeDropdownOpen = false }
  function applyWallpaperTransition(value) { Config.wallpaperTransition = value; saveSetting("wallpaperTransition", value); root.wallpaperTransitionDropdownOpen = false }
  function applyWallpaperCyclingInterval(value) {
    let interval = Math.max(30, Math.min(43200, Math.round(value)))
    Config.wallpaperCyclingInterval = interval
    saveSetting("wallpaperCyclingInterval", interval)
  }

  function refreshFonts() {
    fontProc.running = false
    fontProc.command = [root.hushctl, "fonts"]
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
    folderProc.command = [root.hushctl, "pick-folder", Config.wallpaperDir]
    folderProc.running = true
  }

  function refreshWallpapers() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "get", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "next", Config.wallpaperDir]
    wallpaperProc.running = true
  }

  function setWallpaper(index) {
    wallpaperGridContentY = wallpaperGrid.contentY
    wallpaperSelectionInProgress = true
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "set", index.toString(), Config.wallpaperDir]
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
        if (root.palette.length > 0) {
          Config.applyDynamicPalette(root.palette)
          saveSettingAlt("dynamicAccent", Config.dynamicAccent)
          saveSettingAlt("dynamicPalette", JSON.stringify(Config.dynamicPalette))
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
    width: 620
    height: Math.min(480, root.height - 32)
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.dropdownTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg
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

    Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 100 } }

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
        height: container.height - 70
        spacing: 12

        Column {
          id: sectionNav
          width: 118
          spacing: 5

          Repeater {
            model: [
              { key: "general", icon: Config.iconSettings, title: "Общие" },
              { key: "bar", icon: Config.iconWallpaper, title: "Бар" },
              { key: "notifications", icon: Config.iconNotifications, title: "Уведомления" },
              { key: "osd", icon: Config.iconSettings, title: "OSD" },
              { key: "wallpaper", icon: Config.iconWallpaper, title: "Обои" },
              { key: "location", icon: Config.iconWeather, title: "Локация" },
              { key: "monitoring", icon: Config.iconCpu, title: "Мониторинг" },
              { key: "about", icon: Config.iconInfo, title: "About" }
            ]
            Rectangle {
              required property var modelData
              width: sectionNav.width
              height: 34
              radius: Config.cardRadius
              readonly property bool active: root.activeSection === modelData.key
              color: active ? Config.selectedBg : (sectionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
              border.color: active ? Config.activeBorderColor : Config.subtleBorder
              border.width: 1

              Row {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                Text { text: parent.parent.modelData.icon; color: parent.parent.active ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
                Text { text: I18n.tr(parent.parent.modelData.title); color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: 10; font.family: Config.fontSans; elide: Text.ElideRight; width: 78; anchors.verticalCenter: parent.verticalCenter }
              }
              MouseArea { id: sectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectSection(parent.modelData.key) }
            }
          }
        }

      Flickable {
        id: settingsFlickable
        width: parent.width - sectionNav.width - 12
        height: parent.height
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
            visible: root.activeSection === "general"
            height: visible ? implicitHeight : 0
            clip: true
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
              Behavior on height { NumberAnimation { duration: Config.reduceMotion ? 0 : 120; easing.type: Easing.OutCubic } }
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
              icon: Config.iconSettings
              title: I18n.tr("Границы оболочки")
              subtitle: Config.shellBordersEnabled ? I18n.tr("Включены") : I18n.tr("Выключены")
              ToggleSwitch { checked: Config.shellBordersEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("shellBordersEnabled", !Config.shellBordersEnabled) }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Тени оболочки")
              subtitle: Config.shellShadowsEnabled ? I18n.tr("Включены") : I18n.tr("Выключены")
              last: true
              ToggleSwitch { checked: Config.shellShadowsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("shellShadowsEnabled", !Config.shellShadowsEnabled) }
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
                    color: active ? Config.selectedBg : (timeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
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
                  color: languageButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
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
            height: visible ? implicitHeight : 0
            clip: true
            Row {
              width: parent.width
              height: 32
              spacing: 8
              Rectangle {
                width: 32
                height: 32
                radius: 9
                color: backMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                border.color: Config.borderColor
                border.width: 1
                Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activeSection = "general" }
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
            height: visible ? implicitHeight : 0
            clip: true
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
                    Keys.onEscapePressed: { text = Config.wallpaperDir; focus = false }
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
              icon: Config.iconWallpaper
              title: I18n.tr("Отображение обоев")
              subtitle: I18n.tr("Масштабирование изображения")
              Item {
                width: 194
                height: 30
                Rectangle {
                  id: wallpaperModeButton
                  anchors.fill: parent
                  radius: 9
                  color: wallpaperModeButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: root.wallpaperModeDropdownOpen ? Config.activeBorderColor : Config.borderColor
                  border.width: 1
                  Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; text: root.optionName(root.wallpaperFillModes, Config.wallpaperFillMode); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
                  Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: root.wallpaperModeDropdownOpen ? "󰅃" : "󰅀"; color: Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
                  MouseArea {
                    id: wallpaperModeButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let pos = wallpaperModeButton.mapToItem(container, 0, wallpaperModeButton.height + 6)
                      root.wallpaperModeDropdownX = pos.x
                      root.wallpaperModeDropdownY = pos.y
                      root.wallpaperModeDropdownWidth = wallpaperModeButton.width
                      root.wallpaperTransitionDropdownOpen = false
                      root.wallpaperModeDropdownOpen = !root.wallpaperModeDropdownOpen
                    }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconWallpaper
              title: I18n.tr("Эффект смены")
              subtitle: I18n.tr("Переход при смене обоев")
              Item {
                width: 194
                height: 30
                Rectangle {
                  id: wallpaperTransitionButton
                  anchors.fill: parent
                  radius: 9
                  color: wallpaperTransitionButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: root.wallpaperTransitionDropdownOpen ? Config.activeBorderColor : Config.borderColor
                  border.width: 1
                  Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; text: root.optionName(root.wallpaperTransitions, Config.wallpaperTransition); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
                  Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: root.wallpaperTransitionDropdownOpen ? "󰅃" : "󰅀"; color: Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
                  MouseArea {
                    id: wallpaperTransitionButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let pos = wallpaperTransitionButton.mapToItem(container, 0, wallpaperTransitionButton.height + 6)
                      root.wallpaperTransitionDropdownX = pos.x
                      root.wallpaperTransitionDropdownY = pos.y
                      root.wallpaperTransitionDropdownWidth = wallpaperTransitionButton.width
                      root.wallpaperModeDropdownOpen = false
                      root.wallpaperTransitionDropdownOpen = !root.wallpaperTransitionDropdownOpen
                    }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconWallpaper
              title: I18n.tr("Автоматическая смена")
              subtitle: Config.wallpaperCyclingEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              onClicked: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled)
              ToggleSwitch { z: 1; checked: Config.wallpaperCyclingEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled) }
            }
            SettingsRow {
              visible: Config.wallpaperCyclingEnabled
              icon: Config.iconWallpaper
              title: I18n.tr("Интервал смены")
              subtitle: I18n.tr("Секунды между обоями из текущей папки")
              NumberSlider { value: Config.wallpaperCyclingInterval; from: 30; to: 43200; defaultValue: 300; suffix: "с"; onValueEdited: root.applyWallpaperCyclingInterval(value) }
            }
            SettingsRow {
              visible: CompositorService.backend === "niri"
              icon: Config.iconWallpaper
              title: I18n.tr("Размывать обои в Overview")
              subtitle: Config.blurWallpaperOnOverview ? I18n.tr("Включено") : I18n.tr("Выключено")
              onClicked: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview)
              ToggleSwitch { z: 1; checked: Config.blurWallpaperOnOverview; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview) }
            }
            Text { width: parent.width; visible: wallpapersModel.count === 0; text: I18n.tr("В папке нет поддерживаемых изображений или видео"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap }
            GridView {
              id: wallpaperGrid
              readonly property real tileGap: 6
              readonly property real tileWidth: width / 3
              readonly property real tileHeight: (tileWidth - tileGap) * 9 / 16 + tileGap
              width: parent.width
              height: settingsFlickable.height
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

                  Behavior on scale { NumberAnimation { duration: Config.reduceMotion ? 0 : 80; easing.type: Easing.OutCubic } }

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
                      Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 75 } }
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

                      Behavior on opacity { NumberAnimation { duration: Config.reduceMotion ? 0 : 90 } }

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

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "bar"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Панель"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWallpaper
              title: I18n.tr("Положение панели")
              subtitle: Config.barPosition === "bottom" ? I18n.tr("Снизу") : (Config.barPosition === "left" ? I18n.tr("Слева") : (Config.barPosition === "right" ? I18n.tr("Справа") : I18n.tr("Сверху")))
              Row {
                width: 194
                spacing: 4
                Repeater {
                  model: [{ key: "top", label: "Верх" }, { key: "bottom", label: "Низ" }, { key: "left", label: "Слева" }, { key: "right", label: "Справа" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 4
                    height: 30
                    radius: 8
                    readonly property bool active: Config.barPosition === modelData.key
                    color: active ? Config.selectedBg : (barSectionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: 9; font.family: Config.fontSans }
                    MouseArea { id: barSectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarPosition(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Толщина панели")
              subtitle: I18n.tr("Высота или ширина панели")
              NumberSlider {
                value: Config.barThickness
                from: 28
                to: 100
                defaultValue: 40
                onValueEdited: root.applyBarThickness(value)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Отступ сверху")
              subtitle: I18n.tr("Расстояние от верхнего края")
              NumberSlider {
                value: Config.barTopMargin
                from: 0
                to: 64
                defaultValue: 6
                onValueEdited: root.applyBarTopMargin(value)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Отступы слева и справа")
              subtitle: I18n.tr("Одинаковое расстояние от боковых краёв")
              NumberSlider {
                value: Config.barHorizontalMargin
                from: 0
                to: 64
                defaultValue: 12
                onValueEdited: root.applyBarHorizontalMargin(value)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Закругление бара")
              subtitle: I18n.tr("Радиус углов панели")
              NumberSlider {
                value: Config.barRadius
                from: 0
                to: 32
                defaultValue: 14
                onValueEdited: root.applyBarRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Размытие фона")
              subtitle: Config.barBlurEnabled ? I18n.tr("Включено") : I18n.tr("Выключено")
              onClicked: root.setBoolSetting("barBlurEnabled", !Config.barBlurEnabled)
              ToggleSwitch {
                z: 1
                checked: Config.barBlurEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.setBoolSetting("barBlurEnabled", !Config.barBlurEnabled)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Непрозрачность фона")
              subtitle: I18n.tr("Непрозрачность фона панели")
              NumberSlider {
                value: Config.barFrostOpacity
                from: 0
                to: 100
                defaultValue: 56
                suffix: "%"
                onValueEdited: root.applyBarFrostOpacity(value)
              }
            }
            Text { text: I18n.tr("Всплывающие панели"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Размытие всплывающих панелей")
              subtitle: Config.popupBlurEnabled ? I18n.tr("Включено") : I18n.tr("Выключено")
              onClicked: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled)
              ToggleSwitch { z: 1; checked: Config.popupBlurEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled) }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Закругление панелей")
              subtitle: I18n.tr("Радиус углов выпадающих меню")
              NumberSlider {
                value: Config.popupRadius
                from: 0
                to: 32
                defaultValue: 18
                onValueEdited: root.applyPopupRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Непрозрачность панелей")
              subtitle: I18n.tr("Фон выпадающих меню и уведомлений")
              NumberSlider {
                value: Config.popupBackgroundOpacity
                from: 0
                to: 100
                defaultValue: 56
                suffix: "%"
                onValueEdited: root.applyPopupBackgroundOpacity(value)
              }
            }
            SettingsRow {
              icon: Config.iconMusic
              title: I18n.tr("Визуализация музыки")
              subtitle: Config.musicVisualizerEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              last: true
              ToggleSwitch { checked: Config.musicVisualizerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("musicVisualizerEnabled", !Config.musicVisualizerEnabled) }
            }
            Text { text: I18n.tr("Рабочие столы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Цифры рабочих столов")
              subtitle: Config.showWorkspaceNumbers ? I18n.tr("Показываются") : I18n.tr("Скрыты")
              ToggleSwitch { checked: Config.showWorkspaceNumbers; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showWorkspaceNumbers", !Config.showWorkspaceNumbers) }
            }
            SettingsRow {
              icon: Config.iconWorkspace
              title: I18n.tr("Рабочие столы на всех экранах")
              subtitle: Config.showWorkspacesOnAllMonitors ? I18n.tr("Показываются") : I18n.tr("На своих экранах")
              last: true
              onClicked: root.setBoolSetting("showWorkspacesOnAllMonitors", !Config.showWorkspacesOnAllMonitors)
              ToggleSwitch { z: 1; checked: Config.showWorkspacesOnAllMonitors; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showWorkspacesOnAllMonitors", !Config.showWorkspacesOnAllMonitors) }
            }
            SettingsRow {
              icon: Config.iconWorkspace
              title: I18n.tr("Индикатор занятого стола")
              subtitle: Config.workspaceIndicatorStyle === "dot" ? I18n.tr("Точка") : (Config.workspaceIndicatorStyle === "border" ? I18n.tr("Рамка") : I18n.tr("Подсветка"))
              last: true
              Row {
                width: 194
                height: 30
                spacing: 4
                Repeater {
                  model: [{ key: "tint", label: "Фон" }, { key: "dot", label: "Точка" }, { key: "border", label: "Рамка" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 8) / 3
                    height: parent.height
                    radius: 8
                    readonly property bool active: Config.workspaceIndicatorStyle === modelData.key
                    color: active ? Config.selectedBg : (indicatorMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: 9; font.weight: Font.Bold; font.family: Config.fontSans }
                    MouseArea { id: indicatorMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyChoice("workspaceIndicatorStyle", parent.modelData.key) }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "notifications"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Уведомления"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("Не беспокоить")
              subtitle: Config.doNotDisturb ? I18n.tr("Всплывающие тосты выключены") : I18n.tr("Всплывающие тосты включены")
              ToggleSwitch { checked: Config.doNotDisturb; anchors.verticalCenter: parent.verticalCenter; onToggled: NotificationService.setDoNotDisturb(!Config.doNotDisturb) }
            }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("Положение тостов")
              subtitle: I18n.tr("Место появления уведомлений")
              PositionPicker { settingKey: "notificationPosition"; currentValue: Config.notificationPosition }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("Время показа")
              subtitle: Math.round(Config.notificationTimeoutMs / 1000) + I18n.tr(" сек.")
              last: true
              NumberSlider { value: Config.notificationTimeoutMs / 1000; from: 1; to: 300; defaultValue: 15; suffix: " с"; onValueEdited: root.applyNotificationTimeout(value * 1000) }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "osd"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Экранные индикаторы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconSettings
              title: I18n.tr("Положение OSD")
              subtitle: I18n.tr("Громкость и яркость")
              PositionPicker { settingKey: "osdPosition"; currentValue: Config.osdPosition }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "location"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Локация"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("Погода на панели")
              subtitle: Config.weatherEnabled ? I18n.tr("Показывается") : I18n.tr("Скрыта")
              ToggleSwitch { checked: Config.weatherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("weatherEnabled", !Config.weatherEnabled) }
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
                  Keys.onEscapePressed: { text = Config.weatherLocation; weatherSuggestions.clear(); focus = false }
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
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "monitoring"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Мониторинг системы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Rectangle {
              width: parent.width
              height: 76
              radius: Config.cardRadius
              color: Config.searchBg
              border.color: Config.borderColor
              border.width: 1
              Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 5
                Text { text: I18n.tr("Системные метрики"); color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Bold; font.family: Config.fontSans }
                Text { text: I18n.tr("CPU, память, сеть и накопители отображаются на панели и в системном попапе."); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
              }
            }
          }

          Column {
            width: parent.width
            spacing: 10
            visible: root.activeSection === "about"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("About"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Rectangle {
              width: parent.width
              height: 124
              radius: Config.cardRadius
              color: Config.searchBg
              border.color: Config.borderColor
              border.width: 1
              Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Image {
                  width: 72
                  height: 72
                  source: Qt.resolvedUrl("../../logo.svg")
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                  width: parent.width - 84
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 5
                  Text { text: "hush"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Bold; font.family: Config.fontSans }
                  Text { text: I18n.tr("Hush is a customizable Wayland desktop shell built with Quickshell, QML, and Go."); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
                  Text { text: "Quickshell · QML · Go · Hyprland · Niri"; color: Config.textSubtle; font.pixelSize: 10; font.family: Config.fontMono; width: parent.width; elide: Text.ElideRight }
                }
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
        visible: root.languageDropdownOpen && root.activeSection === "general"

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

      Rectangle {
        id: wallpaperModeDropdown
        z: 50
        x: root.wallpaperModeDropdownX
        y: root.wallpaperModeDropdownY
        width: root.wallpaperModeDropdownWidth
        height: Math.min(root.wallpaperFillModes.length * 32 + 12, 220)
        radius: 10
        color: Config.popupGlassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.wallpaperModeDropdownOpen && root.activeSection === "wallpaper"

        Flickable {
          anchors.fill: parent
          anchors.margins: 6
          contentWidth: width
          contentHeight: wallpaperModeColumn.implicitHeight
          clip: true
          Column {
            id: wallpaperModeColumn
            width: parent.width
            spacing: 4
            Repeater {
              model: root.wallpaperFillModes
              Rectangle {
                required property var modelData
                width: wallpaperModeColumn.width
                height: 28
                radius: 8
                readonly property bool active: Config.wallpaperFillMode === modelData.key
                color: active ? Config.selectedBg : (wallpaperModeMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1
                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: wallpaperModeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaperFillMode(parent.modelData.key) }
              }
            }
          }
        }
      }

      Rectangle {
        id: wallpaperTransitionDropdown
        z: 50
        x: root.wallpaperTransitionDropdownX
        y: root.wallpaperTransitionDropdownY
        width: root.wallpaperTransitionDropdownWidth
        height: Math.min(root.wallpaperTransitions.length * 32 + 12, 220)
        radius: 10
        color: Config.popupGlassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.wallpaperTransitionDropdownOpen && root.activeSection === "wallpaper"

        Flickable {
          anchors.fill: parent
          anchors.margins: 6
          contentWidth: width
          contentHeight: wallpaperTransitionColumn.implicitHeight
          clip: true
          Column {
            id: wallpaperTransitionColumn
            width: parent.width
            spacing: 4
            Repeater {
              model: root.wallpaperTransitions
              Rectangle {
                required property var modelData
                width: wallpaperTransitionColumn.width
                height: 28
                radius: 8
                readonly property bool active: Config.wallpaperTransition === modelData.key
                color: active ? Config.selectedBg : (wallpaperTransitionMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1
                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: wallpaperTransitionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaperTransition(parent.modelData.key) }
              }
            }
          }
        }
      }
  }
}
