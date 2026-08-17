// SettingsPopup.qml - Sectioned settings, wallpaper, fonts and weather controls
import QtQuick
import Qt5Compat.GraphicalEffects
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
  property int rightMargin: Config.scaledSize(16)
  property string activeSection: "general"
  property string pendingSection: "general"
  property string fontSearch: ""
  property string fontPickerTarget: "sans"
  property bool languageDropdownOpen: false
  property real languageDropdownX: 0
  property real languageDropdownY: 0
  property real languageDropdownWidth: 194
  property bool wallpaperModeDropdownOpen: false
  property real wallpaperModeDropdownX: 0
  property real wallpaperModeDropdownY: 0
  property real wallpaperModeDropdownWidth: 194
  property bool wallpaperPaletteDropdownOpen: false
  property real wallpaperPaletteDropdownX: 0
  property real wallpaperPaletteDropdownY: 0
  property real wallpaperPaletteDropdownWidth: 194
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
    { key: "none", label: "Без эффекта" }, { key: "simple", label: "Простой" },
    { key: "fade", label: "Плавное появление" }, { key: "left", label: "Слева" },
    { key: "right", label: "Справа" }, { key: "top", label: "Сверху" },
    { key: "bottom", label: "Снизу" }, { key: "wipe", label: "Стирание" },
    { key: "wave", label: "Волна" }, { key: "grow", label: "Раскрытие" },
    { key: "center", label: "Круг из центра" }, { key: "any", label: "Круг из случайной точки" },
    { key: "outer", label: "Круг к центру" }, { key: "random", label: "Случайный" }
  ]
  readonly property var wallpaperPaletteSchemes: [
    { key: "vibrant", label: "Яркий" }, { key: "faithful", label: "Точный" },
    { key: "dysfunctional", label: "Диссонансный" }, { key: "muted", label: "Приглушённый" },
    { key: "soft", label: "Мягкий" }, { key: "material", label: "Material" },
    { key: "monochrome", label: "Монохромный" }
  ]
  readonly property var screenPositions: [
    { key: "top-left", label: "ВЛ" }, { key: "top-center", label: "Верх" }, { key: "top-right", label: "ВП" },
    { key: "bottom-left", label: "НЛ" }, { key: "bottom-center", label: "Низ" }, { key: "bottom-right", label: "НП" }
  ]
  readonly property var sectionCategories: [
    { key: "appearance", icon: Config.iconTheme, title: "Оформление", pages: [{ key: "general", title: "Интерфейс" }, { key: "palette", title: "Цветовая палитра" }, { key: "fontPicker", hidden: true }] },
    { key: "bar", icon: Config.iconPanel, title: "Бар", pages: [{ key: "bar", title: "Панель" }, { key: "monitoring", title: "Мониторинг" }] },
    { key: "desktop", icon: Config.iconWallpaper, title: "Обои", pages: [{ key: "wallpaper", title: "Обои" }, { key: "location", title: "Время и локация" }] },
    { key: "notifications", icon: Config.iconNotifications, title: "Уведомления", pages: [{ key: "popups", title: "Попапы" }, { key: "notifications", title: "Уведомления" }, { key: "osd", title: "OSD" }] },
    { key: "system", icon: Config.iconKeyboard, title: "Система", pages: [{ key: "system", title: "Сочетания клавиш" }] },
    { key: "advanced", icon: Config.iconMonitor, title: "Дополнительно", pages: [{ key: "advanced", title: "Яркость" }] },
    { key: "about", icon: Config.iconInfo, title: "О программе", pages: [{ key: "about", title: "О программе" }] }
  ]
  readonly property var currentCategory: categoryForSection(activeSection)
  property var allFonts: []
  property string thumbnail: ""
  property string wallName: "Нет обоев"
  property int currentWallpaperIndex: 0
  property real wallpaperGridContentY: 0
  property bool restoringWallpaperScroll: false
  property bool wallpaperSelectionInProgress: false
  property var wallpapersAll: []
  property string wallpaperFilterText: ""

  function selectSection(section) {
    if (section === root.activeSection || sectionTransition.running) return
    root.pendingSection = section
    sectionTransition.restart()
  }

  function categoryForSection(section) {
    for (let i = 0; i < sectionCategories.length; i++) {
      let category = sectionCategories[i]
      for (let j = 0; j < category.pages.length; j++) {
        if (category.pages[j].key === section) return category
      }
    }
    return sectionCategories[0]
  }

  function selectCategory(category) { selectSection(category.pages[0].key) }

  function visiblePageCount(category) {
    let count = 0
    for (let i = 0; i < category.pages.length; i++) {
      if (!category.pages[i].hidden) count++
    }
    return count
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
  property int manualSlot: 1
  readonly property color manualSlotColor: (Config.manualPalette && Config.manualPalette.length > manualSlot) ? Config.manualPalette[manualSlot] : "#888888"
  readonly property real manualHue: manualSlotColor.hslHue >= 0 ? manualSlotColor.hslHue : 0
  readonly property real manualSat: manualSlotColor.hslSaturation
  readonly property string currentManualHex: colorToHex(manualSlotColor)
  readonly property string veyctl: Config.veyctl
  property string aboutVersion: ""
  property string aboutLatest: ""
  property var aboutContributors: []
  property var presets: []

  onActiveSectionChanged: if (root.activeSection === "about") root.refreshAbout()

  Component.onCompleted: {
    root.refreshAbout()
    root.refreshPresets()
  }

  onIsOpenChanged: if (isOpen) {
    wallpaperDirInput.text = Config.wallpaperDir
    weatherLocationInput.text = Config.weatherLocation
    fontSearchInput.text = root.fontSearch
    manualAccentInput.text = root.currentManualHex
    refreshWallpapers()
    refreshFonts()
  } else {
    weatherSuggestions.clear()
    root.fontSearch = ""
    container.moved = false
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

  Shortcut {
    sequence: Config.settingsCloseKeybind
    enabled: root.isOpen
    onActivated: root.isOpen = false
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

  Process {
    id: aboutProc
    stdout: SplitParser { onRead: data => root.applyAbout(data) }
  }

  Process {
    id: presetsProc
    command: [root.veyctl, "presets"]
    stdout: SplitParser { onRead: data => root.applyPresets(data) }
  }

  Process {
    id: screenColorProc
    command: [root.veyctl, "color", "pick", Config.fontMono]
    stdout: SplitParser {
      onRead: data => {
        try {
          let result = JSON.parse(data)
          if (result.ok && result.hex) root.applyManualSlot(result.hex)
        } catch (_) {}
      }
    }
    onExited: root.isOpen = true
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
  function applyBarStyle(value) {
    Config.barStyle = value
    saveSetting("barStyle", value)
  }
  function applyBarThickness(value) {
    let thickness = Math.max(28, Math.min(100, Math.round(value)))
    Config.barThickness = thickness
    saveSetting("barThickness", thickness)
  }
  function applyBarAutoHideDelay(value) {
    let delay = Math.max(0, Math.min(60, Math.round(value)))
    Config.barAutoHideDelay = delay
    saveSetting("barAutoHideDelay", delay)
  }
  function applyCloseKeybind(value) {
    let key = value.trim()
    if (key.length === 0) return
    Config.settingsCloseKeybind = key
    saveSetting("settingsCloseKeybind", key)
  }
  function applyBarTopMargin(value) {
    let margin = Math.max(0, Math.min(64, Math.round(value)))
    Config.barTopMargin = margin
    saveSetting("barTopMargin", margin)
  }
  function applyBarBottomMargin(value) {
    let margin = Math.max(0, Math.min(64, Math.round(value)))
    Config.barBottomMargin = margin
    saveSetting("barBottomMargin", margin)
  }
  function applyPopupVerticalAlign(value) {
    Config.popupVerticalAlign = value
    saveSetting("popupVerticalAlign", value)
  }
  function applyBarHorizontalMargin(value) {
    let margin = Math.max(0, Math.min(64, Math.round(value)))
    Config.barHorizontalMargin = margin
    saveSetting("barHorizontalMargin", margin)
  }
  function applyBarRadius(value) {
    let radius = Math.max(0, Math.min(100, Math.round(value)))
    Config.barRadius = radius
    saveSetting("barRadius", radius)
  }
  function applyBarFrostOpacity(value) {
    let opacity = Math.max(0, Math.min(100, Math.round(value)))
    Config.barFrostOpacity = opacity
    saveSetting("barFrostOpacity", opacity)
  }
  function applyPopupRadius(value) {
    let radius = Math.max(0, Math.min(100, Math.round(value)))
    Config.popupRadius = radius
    saveSetting("popupRadius", radius)
  }
  function applyPopupBackgroundOpacity(value) {
    let opacity = Math.max(0, Math.min(100, Math.round(value)))
    Config.popupBackgroundOpacity = opacity
    saveSetting("popupBackgroundOpacity", opacity)
  }
  function applyFont(value) {
    if (root.fontPickerTarget === "mono") {
      Config.fontMonoFamily = value
      saveSetting("fontMonoFamily", value)
    } else {
      Config.fontFamily = value
      saveSetting("fontFamily", value)
    }
  }
  function applyWeatherLocation(value) { let location = value.trim(); Config.weatherLocation = location; saveSetting("weatherLocation", location) }
  function applyTimeFormat(value) { Config.timeFormat = value; saveSetting("timeFormat", value) }
  function applyUiScale(value) { Config.uiScale = parseFloat(value); saveSetting("uiScale", value) }
  function applyBrightnessMonitorBus(value) {
    let bus = value.trim()
    if (bus.length === 0) return
    Config.brightnessMonitorBus = bus
    saveSetting("brightnessMonitorBus", bus)
  }
  function applyBrightnessSleepMultiplier(value) {
    let multiplier = parseFloat(value)
    if (!isFinite(multiplier) || multiplier <= 0) return
    multiplier = Math.max(0.01, Math.min(5, multiplier))
    Config.brightnessSleepMultiplier = String(multiplier)
    saveSetting("brightnessSleepMultiplier", multiplier)
  }
  function slotLabel(index) {
    let names = ["BG", "Red", "Grn", "Ylw", "Blu", "Mgn", "Cyn", "FG", "Dim", "Rd+", "Gr+", "Yl+", "Bl+", "Mg+", "Cy+", "FG+"]
    return names[index] || String(index)
  }
  function slotTextColor(hex) {
    let c = hex || "#000000"
    let r = parseInt(c.slice(1, 3), 16)
    let g = parseInt(c.slice(3, 5), 16)
    let b = parseInt(c.slice(5, 7), 16)
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) > 132 ? "#0f172a" : "#ffffff"
  }
  function applyManualSlot(value) {
    let color = value.trim()
    if (!/^#[0-9A-Fa-f]{6}$/.test(color)) return
    let arr = Config.manualPalette.slice()
    arr[root.manualSlot] = color
    Config.manualPalette = arr
    Config.applyManualPalette()
    saveSetting("manualPalette", JSON.stringify(arr))
  }
  function setManualHueFromX(x, width) {
    let hue = Math.max(0, Math.min(1, x / Math.max(width, 1)))
    let sat = root.manualSat < 0.05 ? 0.5 : root.manualSat
    applyManualSlot(colorToHex(Qt.hsla(hue, sat, 0.5, 1)))
  }
  function pickManualColor() {
    root.isOpen = false
    screenColorProc.running = true
  }
  function setBoolSetting(key, value) {
    if (key === "showSeconds") Config.showSeconds = value
    if (key === "tooltipsEnabled") Config.tooltipsEnabled = value
    if (key === "dynamicDark") Config.dynamicDark = value
    if (key === "showWorkspaceNumbers") Config.showWorkspaceNumbers = value
    if (key === "showWorkspacesOnAllMonitors") Config.showWorkspacesOnAllMonitors = value
    if (key === "barBlurEnabled") Config.barBlurEnabled = value
    if (key === "popupBlurEnabled") Config.popupBlurEnabled = value
    if (key === "wallpaperCyclingEnabled") Config.wallpaperCyclingEnabled = value
    if (key === "blurWallpaperOnOverview") Config.blurWallpaperOnOverview = value
    if (key === "reduceMotion") Config.reduceMotion = value
    if (key === "shellBordersEnabled") Config.shellBordersEnabled = value
    if (key === "barBordersEnabled") Config.barBordersEnabled = value
    if (key === "popupBordersEnabled") Config.popupBordersEnabled = value
    if (key === "shellShadowsEnabled") Config.shellShadowsEnabled = value
    if (key === "barShadowsEnabled") Config.barShadowsEnabled = value
    if (key === "popupShadowsEnabled") Config.popupShadowsEnabled = value
    if (key === "weatherEnabled") Config.weatherEnabled = value
    if (key === "weatherTenths") Config.weatherTenths = value
    if (key === "barDateTimeEnabled") Config.barDateTimeEnabled = value
    if (key === "barWeatherEnabled") Config.barWeatherEnabled = value
    if (key === "barColorPickerEnabled") Config.barColorPickerEnabled = value
    if (key === "barWorkspacesEnabled") Config.barWorkspacesEnabled = value
    if (key === "barLauncherEnabled") Config.barLauncherEnabled = value
    if (key === "barActiveAppEnabled") Config.barActiveAppEnabled = value
    if (key === "barMediaEnabled") Config.barMediaEnabled = value
    if (key === "barTrayEnabled") Config.barTrayEnabled = value
    if (key === "barKeyboardLayoutEnabled") Config.barKeyboardLayoutEnabled = value
    if (key === "barSystemEnabled") Config.barSystemEnabled = value
    if (key === "barSysCpuEnabled") Config.barSysCpuEnabled = value
    if (key === "barSysCpuTempEnabled") Config.barSysCpuTempEnabled = value
    if (key === "barSysGpuEnabled") Config.barSysGpuEnabled = value
    if (key === "barSysGpuTempEnabled") Config.barSysGpuTempEnabled = value
    if (key === "barSysRamEnabled") Config.barSysRamEnabled = value
    if (key === "barSysNetEnabled") Config.barSysNetEnabled = value
    if (key === "barNotificationsEnabled") Config.barNotificationsEnabled = value
    if (key === "barVolumeEnabled") Config.barVolumeEnabled = value
    if (key === "barBrightnessEnabled") Config.barBrightnessEnabled = value
    if (key === "barBatteryEnabled") Config.barBatteryEnabled = value
    if (key === "barBluetoothEnabled") Config.barBluetoothEnabled = value
    if (key === "barNetworkEnabled") Config.barNetworkEnabled = value
    if (key === "barControlCenterEnabled") Config.barControlCenterEnabled = value
    if (key === "barVpnEnabled") Config.barVpnEnabled = value
    if (key === "barPowerEnabled") Config.barPowerEnabled = value
    if (key === "barAutoHide") Config.barAutoHide = value
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
  function applyNotificationMaxVisible(value) {
    let maximum = Math.max(1, Math.min(10, Math.round(value)))
    Config.notificationMaxVisible = maximum
    saveSetting("notificationMaxVisible", maximum)
  }

  component PositionPicker: Grid {
    id: picker
    property string settingKey: ""
    property string currentValue: ""
    width: Config.scaledSize(194)
    columns: 3
    columnSpacing: Config.scaledSize(4)
    rowSpacing: Config.scaledSize(4)
    Repeater {
      model: root.screenPositions
      Rectangle {
        required property var modelData
        width: Config.scaledSize(62)
        height: Config.scaledSize(28)
        radius: Config.popupRadiusPx(7)
        readonly property bool active: picker.currentValue === modelData.key
        color: active ? Config.selectedBg : (positionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
        border.color: active ? Config.activeBorderColor : Config.borderColor
        border.width: 1
        Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontSans }
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
    wallpaperProc.command = [root.veyctl, "wallpaper", "config", nextDir]
    wallpaperProc.running = true
  }
  function applyWallpaperFillMode(value) { Config.wallpaperFillMode = value; saveSetting("wallpaperFillMode", value); root.wallpaperModeDropdownOpen = false }
  function applyWallpaperTransition(value) { Config.wallpaperTransition = value; saveSetting("wallpaperTransition", value); root.wallpaperTransitionDropdownOpen = false }
  function applyWallpaperPaletteScheme(value) { Config.wallpaperPaletteScheme = value; saveSetting("wallpaperPaletteScheme", value); root.wallpaperPaletteDropdownOpen = false; root.refreshWallpapers() }
  function applyWallpaperCyclingInterval(value) {
    let interval = Math.max(30, Math.min(43200, Math.round(value)))
    Config.wallpaperCyclingInterval = interval
    saveSetting("wallpaperCyclingInterval", interval)
  }

  function refreshFonts() {
    fontProc.running = false
    fontProc.command = [root.veyctl, "fonts"]
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
    folderProc.command = [root.veyctl, "pick-folder", Config.wallpaperDir]
    folderProc.running = true
  }

  function refreshWallpapers() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.veyctl, "wallpaper", "get", Config.wallpaperDir, Config.wallpaperPaletteScheme]
    wallpaperProc.running = true
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.veyctl, "wallpaper", "next", Config.wallpaperDir, Config.wallpaperPaletteScheme]
    wallpaperProc.running = true
  }

  function setWallpaper(index) {
    wallpaperGridContentY = wallpaperGrid.contentY
    wallpaperSelectionInProgress = true
    wallpaperProc.running = false
    wallpaperProc.command = [root.veyctl, "wallpaper", "set", index.toString(), Config.wallpaperDir, Config.wallpaperPaletteScheme]
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
        if (root.palette.length > 0 && Config.themeName === "dynamic") {
          Config.applyDynamicPalette(root.palette)
          saveSettingAlt("dynamicAccent", Config.dynamicAccent)
          saveSettingAlt("dynamicPalette", JSON.stringify(Config.dynamicPalette))
      }
      if (!root.wallpaperSelectionInProgress) {
        root.wallpapersAll = res.items || []
        root.applyWallpaperFilter()
        wallpaperScrollRestoreTimer.restart()
      }
      root.wallpaperSelectionInProgress = false
      root.restoringWallpaperScroll = false
    } catch(e) {}
  }

  function applyWallpaperFilter() {
    wallpapersModel.clear()
    let needle = root.wallpaperFilterText.trim().toLowerCase()
    for (let i = 0; i < root.wallpapersAll.length; i++) {
      let item = root.wallpapersAll[i]
      if (!needle || (item.name && item.name.toLowerCase().indexOf(needle) !== -1)) {
        wallpapersModel.append(item)
      }
    }
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

  function applyAbout(data) {
    try {
      let res = JSON.parse(data)
      root.aboutVersion = res.version || ""
      root.aboutLatest = res.latest || ""
      root.aboutContributors = res.contributors || []
    } catch(e) {}
  }

  function refreshAbout() {
    aboutProc.running = false
    aboutProc.command = [root.veyctl, "about"]
    aboutProc.running = true
  }

  function applyPresets(data) {
    try {
      root.presets = JSON.parse(data) || []
    } catch(e) { root.presets = [] }
  }

  function refreshPresets() {
    presetsProc.running = false
    presetsProc.command = [root.veyctl, "presets"]
    presetsProc.running = true
  }

  function applyPreset(name, colors) {
    if (!colors || colors.length < 16) return
    Config.manualPalette = colors.slice(0, 16)
    Config.applyManualPalette()
    Config.themeName = "manual"
    saveSetting("themeName", "manual")
    saveSetting("manualPalette", JSON.stringify(Config.manualPalette))
  }

  function commitsLabel(n) {
    let m10 = n % 10, m100 = n % 100
    if (m10 === 1 && m100 !== 11) return n + " коммит"
    if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return n + " коммита"
    return n + " коммитов"
  }

  Rectangle {
    id: container
    width: Math.min(Config.scaledSize(620), root.width - Config.scaledSize(8))
    height: Math.min(480, root.height - 32)
    property bool moved: false
    property real dragX: 0
    property real dragY: 0
    x: moved ? dragX : (parent.width - width) / 2
    y: moved ? dragY : (parent.height - height) / 2
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.popupGlassBg
    clip: false

    Rectangle {
      visible: Config.popupShadowsEnabled
      x: 0
      y: Config.shellShadowOffsetY
      width: parent.width
      height: parent.height
      radius: parent.radius
      color: Config.shellShadowColor
      opacity: 0.55
      z: -1
    }

    Behavior on opacity { NumberAnimation { duration: 100 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    Rectangle {
      id: settingsClose
      width: Config.scaledSize(28)
      height: Config.scaledSize(28)
      radius: Config.popupRadiusPx(9)
      z: 2
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.right: parent.right
      anchors.rightMargin: Config.scaledSize(14)
      color: settingsCloseMouse.containsMouse ? Config.hoverBg : "#00000000"
      Text { anchors.centerIn: parent; text: "×"; color: settingsCloseMouse.containsMouse ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeLarge; font.family: Config.fontSans }
      MouseArea { id: settingsCloseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mouse => { mouse.accepted = true; root.isOpen = false } }
    }

    Column {
      id: contentRoot
      width: parent.width - 28
      anchors.top: parent.top
      anchors.topMargin: Config.scaledSize(14)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.scaledSize(12)

      Item {
        width: parent.width
        height: Config.scaledSize(30)

        Text { id: settingsTitleIcon; text: Config.iconSettings; color: Config.textWhite; font.pixelSize: Config.fontSizeTitle; font.family: Config.fontIcon; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
        Text { text: I18n.tr("Настройки"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans; anchors.left: settingsTitleIcon.right; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter }

        MouseArea {
          id: settingsDragArea
          anchors.fill: parent
          cursorShape: Qt.ClosedHandCursor
          property point pressPoint: Qt.point(0, 0)
          property real pressX: 0
          property real pressY: 0
          onPressed: (mouse) => {
            pressX = container.x
            pressY = container.y
            container.dragX = pressX
            container.dragY = pressY
            pressPoint = Qt.point(mouse.x, mouse.y)
            container.moved = true
          }
          onPositionChanged: (mouse) => {
            if (!pressed) return
            container.dragX = pressX + mouse.x - pressPoint.x
            container.dragY = pressY + mouse.y - pressPoint.y
            container.dragX = Math.max(0, Math.min(container.parent.width - container.width, container.dragX))
            container.dragY = Math.max(0, Math.min(container.parent.height - container.height, container.dragY))
          }
        }
      }

      Row {
        width: parent.width
        height: container.height - 70
        spacing: Config.scaledSize(12)

        Column {
          id: sectionNav
          width: Config.scaledSize(118)
          spacing: Config.scaledSize(5)

          Repeater {
            model: root.sectionCategories
            Rectangle {
              required property var modelData
              width: sectionNav.width
              height: Config.scaledSize(34)
              radius: Config.cardRadius
              readonly property bool active: root.currentCategory.key === modelData.key
              color: active ? Config.selectedBg : (sectionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
              border.color: active ? Config.activeBorderColor : Config.subtleBorder
              border.width: 1

              Row {
                anchors.left: parent.left
                anchors.leftMargin: Config.scaledSize(9)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.scaledSize(7)
                Text { text: parent.parent.modelData.icon; color: parent.parent.active ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
                Text { text: I18n.tr(parent.parent.modelData.title); color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight; width: Config.scaledSize(78); anchors.verticalCenter: parent.verticalCenter }
              }
              MouseArea { id: sectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectCategory(parent.modelData) }
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
          spacing: Config.scaledSize(12)

          Row {
            id: sectionTabs
            width: parent.width
            height: visible ? Config.scaledSize(30) : 0
            spacing: Config.scaledSize(4)
            visible: root.visiblePageCount(root.currentCategory) > 1

            Repeater {
              model: root.currentCategory.pages
              Rectangle {
                required property var modelData
                visible: !modelData.hidden
                width: visible ? (sectionTabs.width - Config.scaledSize(4) * (root.visiblePageCount(root.currentCategory) - 1)) / root.visiblePageCount(root.currentCategory) : 0
                height: sectionTabs.height
                radius: Config.popupRadiusPx(8)
                readonly property bool active: root.activeSection === modelData.key
                color: active ? Config.selectedBg : (sectionTabMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                border.color: active ? Config.activeBorderColor : Config.borderColor
                border.width: 1
                Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.title || ""); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans; elide: Text.ElideRight; width: parent.width - Config.scaledSize(12); horizontalAlignment: Text.AlignHCenter }
                MouseArea { id: sectionTabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectSection(parent.modelData.key) }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "general"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Оформление"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconMotion
              title: I18n.tr("Меньше анимаций")
              subtitle: Config.reduceMotion ? I18n.tr("Анимации сокращены") : I18n.tr("Обычные анимации")
              ToggleSwitch { checked: Config.reduceMotion; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("reduceMotion", !Config.reduceMotion) }
            }

            SettingsRow {
              icon: Config.iconInfo
              title: I18n.tr("Подсказки")
              subtitle: Config.tooltipsEnabled ? I18n.tr("Показываются") : I18n.tr("Скрыты")
              ToggleSwitch { checked: Config.tooltipsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("tooltipsEnabled", !Config.tooltipsEnabled) }
            }

            Text { text: I18n.tr("Интерфейс"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }

            SettingsRow {
              icon: Config.iconFont
              title: I18n.tr("Основной шрифт")
              subtitle: Config.fontFamily
              onClicked: {
                root.fontPickerTarget = "sans"
                root.activeSection = "fontPicker"
              }
              Text { text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            }

            SettingsRow {
              icon: Config.iconFont
              title: I18n.tr("Моноширинный шрифт")
              subtitle: Config.fontMonoFamily
              onClicked: {
                root.fontPickerTarget = "mono"
                root.activeSection = "fontPicker"
              }
              Text { text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            }

            SettingsRow {
              icon: Config.iconScale
              title: I18n.tr("Размер текста")
              subtitle: Math.round(Config.uiScale * 100) + "%"
              last: true
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ v: 75 }, { v: 90 }, { v: 100 }, { v: 125 }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 4
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Math.round(Config.uiScale * 100) === modelData.v
                    color: active ? Config.selectedBg : (uiScaleMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: parent.modelData.v + "%"; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: uiScaleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyUiScale(parent.modelData.v / 100) }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "fontPicker"
            height: visible ? implicitHeight : 0
            clip: true
            Row {
              width: parent.width
              height: Config.scaledSize(32)
              spacing: Config.scaledSize(8)
              Rectangle {
                width: Config.scaledSize(32)
                height: Config.scaledSize(32)
                radius: Config.popupRadiusPx(9)
                color: backMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                border.color: Config.borderColor
                border.width: 1
                Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activeSection = "general" }
              }
              Text { text: root.fontPickerTarget === "mono" ? I18n.tr("Моноширинный шрифт") : I18n.tr("Основной шрифт"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
            }
            Text { text: I18n.tr("Текущий") + ": " + (root.fontPickerTarget === "mono" ? Config.fontMonoFamily : Config.fontFamily); color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; width: parent.width }

            Rectangle {
              width: parent.width
              height: Config.scaledSize(36)
              radius: Config.popupRadiusPx(10)
              color: Config.searchBg
              border.color: fontSearchInput.activeFocus ? Config.activeBorderColor : Config.borderColor
              border.width: 1

              Text {
                anchors.left: parent.left
                anchors.leftMargin: Config.scaledSize(12)
                anchors.verticalCenter: parent.verticalCenter
                text: Config.iconSearch
                color: Config.textMuted
                font.pixelSize: Config.fontSizeIconSmall
                font.family: Config.fontIcon
              }

              TextInput {
                id: fontSearchInput
                anchors.fill: parent
                anchors.leftMargin: Config.scaledSize(36)
                anchors.rightMargin: Config.scaledSize(12)
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
              height: Config.scaledSize(310)
              clip: true
              spacing: Config.scaledSize(6)
              model: fontModel
              delegate: Rectangle {
                required property string name
                width: ListView.view.width
                height: Config.scaledSize(44)
                radius: Config.cardRadius
                readonly property bool active: root.fontPickerTarget === "mono" ? Config.fontMonoFamily === name : Config.fontFamily === name
                color: active ? Config.selectedBg : (fontMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : Config.borderColor
                border.width: 1
                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.rightMargin: Config.scaledSize(10)
                  spacing: Config.scaledSize(1)
                  Text { width: parent.width; text: name; color: active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: name; elide: Text.ElideRight }
                  Text { width: parent.width; text: I18n.tr("19:37 пн, июл. 20  ·  Быстрая лиса 123"); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: name; elide: Text.ElideRight }
                }
                MouseArea { id: fontMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyFont(parent.name) }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "palette"
            height: visible ? implicitHeight : 0
            clip: true
            SettingsRow {
              icon: Config.iconPalette
              title: I18n.tr("Тема")
              subtitle: Config.themeName === "manual" ? I18n.tr("Ручной акцент") : (Config.themeName === "dynamic" ? I18n.tr("Акцент из обоев") : (Config.themeName === "light" ? I18n.tr("Светлая палитра") : I18n.tr("Тёмная палитра")))
              Rectangle {
                id: themeSegment
                width: Config.scaledSize(226)
                height: Config.scaledSize(34)
                radius: Config.popupRadiusPx(9)
                color: "transparent"
                Row {
                  anchors.fill: parent
                  spacing: Config.scaledSize(2)
                  Repeater {
                    model: [{ key: "light", label: "Свет" }, { key: "dark", label: "Тьма" }, { key: "dynamic", label: "Дин." }, { key: "manual", label: "Своя" }]
                    Rectangle {
                      required property var modelData
                      width: (themeSegment.width - 6) / 4
                      height: Config.scaledSize(34)
                      radius: Config.popupRadiusPx(9)
                      readonly property bool active: Config.themeName === modelData.key
                      color: active ? Config.selectedBg : (themeMouse.containsMouse ? Config.hoverBg : "transparent")
                      Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: Config.fontSizeExtraSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.2 }
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
                spacing: Config.scaledSize(12)
                topPadding: 4
                bottomPadding: 6

                Grid {
                  width: parent.width
                  columns: 8
                  columnSpacing: Config.scaledSize(4)
                  rowSpacing: Config.scaledSize(4)
                  Repeater {
                    model: 16
                    Rectangle {
                      required property int modelData
                      width: (parent.width - 7 * Config.scaledSize(4)) / 8
                      height: Config.scaledSize(30)
                      radius: Config.popupRadiusPx(8)
                      color: Config.manualPalette[modelData] || "#000000"
                      border.color: root.manualSlot === modelData ? Config.textWhite : Config.subtleBorder
                      border.width: root.manualSlot === modelData ? 2 : 1
                      Text {
                        anchors.centerIn: parent
                        text: root.slotLabel(modelData)
                        color: root.slotTextColor(Config.manualPalette[modelData])
                        font.pixelSize: Config.fontSizeTiny
                        font.weight: Font.Medium
                        font.family: Config.fontSans
                      }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.manualSlot = modelData }
                    }
                  }
                }

                Row {
                  width: parent.width
                  height: Config.scaledSize(34)
                  spacing: Config.scaledSize(10)
                  Rectangle { width: Config.scaledSize(34); height: Config.scaledSize(34); radius: Config.popupRadiusPx(9); color: root.manualSlotColor; border.color: Config.borderColor; border.width: 1; anchors.verticalCenter: parent.verticalCenter }
                  Column {
                    width: parent.width - 44
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Config.scaledSize(2)
                    Text { width: parent.width; text: root.slotLabel(root.manualSlot) + " · " + root.currentManualHex; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
                    Text { width: parent.width; text: I18n.tr("Кликни по цвету, чтобы выбрать его"); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
                  }
                }

                ColorPicker {
                  width: parent.width
                  height: Config.scaledSize(170)
                  selectedColor: root.manualSlotColor
                  onColorEdited: color => root.applyManualSlot(root.colorToHex(color))
                }

                Rectangle {
                  width: parent.width
                  height: Config.scaledSize(34)
                  radius: Config.popupRadiusPx(10)
                  color: screenColorMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: Config.borderColor
                  border.width: 1
                  Text { anchors.centerIn: parent; text: Config.iconColorPicker + "  " + I18n.tr("Выбрать цвет с экрана"); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                  MouseArea { id: screenColorMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pickManualColor() }
                }

                Item {
                  width: parent.width
                  height: 18
                  Rectangle {
                    id: manualHueStrip
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 14
                    radius: Config.popupRadiusPx(7)
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
                      radius: Config.popupRadiusPx(9)
                      anchors.verticalCenter: parent.verticalCenter
                      x: root.manualHue * (manualHueStrip.width - width)
                      color: root.manualSlotColor
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

                Rectangle {
                  width: parent.width
                  height: Config.scaledSize(34)
                  radius: Config.popupRadiusPx(10)
                  color: Config.searchBg
                  border.color: manualAccentInput.activeFocus ? Config.activeBorderColor : Config.borderColor
                  border.width: 1
                  TextInput {
                    id: manualAccentInput
                    anchors.fill: parent
                    anchors.leftMargin: Config.scaledSize(12)
                    anchors.rightMargin: Config.scaledSize(12)
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.currentManualHex
                    color: Config.textPrimary
                    selectedTextColor: Config.textWhite
                    selectionColor: Config.selectedBg
                    font.pixelSize: Config.fontMonoSizeSmall
                    font.family: Config.fontMono
                    maximumLength: 7
                    onEditingFinished: root.applyManualSlot(text)
                    Keys.onReturnPressed: focus = false
                    Keys.onEscapePressed: { text = root.currentManualHex; focus = false }
                  }
                }
              }
            }

            SettingsRow {
              visible: Config.themeName === "dynamic"
              icon: Config.iconPalettePreset
              title: I18n.tr("Пресет палитры")
              subtitle: I18n.tr("Как извлекать цвета из обоев")
              Item {
                width: Config.scaledSize(194)
                height: Config.scaledSize(30)
                Rectangle {
                  id: wallpaperPaletteButton
                  anchors.fill: parent
                  radius: Config.popupRadiusPx(9)
                  color: wallpaperPaletteButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: root.wallpaperPaletteDropdownOpen ? Config.activeBorderColor : Config.borderColor
                  border.width: 1
                  Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; text: root.optionName(root.wallpaperPaletteSchemes, Config.wallpaperPaletteScheme); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
                  Text { anchors.right: parent.right; anchors.rightMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: root.wallpaperPaletteDropdownOpen ? "󰅃" : "󰅀"; color: Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
                  MouseArea {
                    id: wallpaperPaletteButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let pos = wallpaperPaletteButton.mapToItem(container, 0, wallpaperPaletteButton.height + 6)
                      root.wallpaperPaletteDropdownX = pos.x
                      root.wallpaperPaletteDropdownY = pos.y
                      root.wallpaperPaletteDropdownWidth = wallpaperPaletteButton.width
                      root.wallpaperModeDropdownOpen = false
                      root.wallpaperTransitionDropdownOpen = false
                      root.wallpaperPaletteDropdownOpen = !root.wallpaperPaletteDropdownOpen
                    }
                  }
                }
              }
            }

            SettingsRow {
              visible: Config.themeName === "dynamic"
              icon: Config.iconTheme
              title: I18n.tr("Тёмная тема")
              subtitle: Config.dynamicDark ? I18n.tr("Тёмные цвета из обоев") : I18n.tr("Светлые цвета из обоев")
              onClicked: root.setBoolSetting("dynamicDark", !Config.dynamicDark)
              ToggleSwitch { z: 1; checked: Config.dynamicDark; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("dynamicDark", !Config.dynamicDark) }
            }

            Text { text: I18n.tr("Пресеты"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Grid {
              id: presetsGrid
              width: parent.width
              columns: 3
              columnSpacing: Config.scaledSize(10)
              rowSpacing: Config.scaledSize(10)
              Repeater {
                model: root.presets
                delegate: Rectangle {
                  required property var modelData
                  width: (presetsGrid.width - 20) / 3
                  height: Config.scaledSize(52)
                  radius: Config.cardRadius
                  color: presetMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: Config.subtleBorder
                  border.width: 1

                  Column {
                    anchors.fill: parent
                    anchors.margins: Config.scaledSize(8)
                    spacing: Config.scaledSize(6)

                    Text { width: parent.width; text: modelData.name; color: Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans; elide: Text.ElideRight }

                    Row {
                      width: parent.width
                      height: Config.scaledSize(12)
                      spacing: 1
                      Repeater {
                        model: modelData.colors.slice(0, 8)
                        Rectangle {
                          required property var modelData
                          width: (parent.width - 7) / 8
                          height: parent.height
                          radius: 2
                          color: modelData
                        }
                      }
                    }
                  }

                  MouseArea { id: presetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPreset(modelData.name, modelData.colors) }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "wallpaper"
            height: visible ? implicitHeight : 0
            clip: true
            Spoiler {
              title: I18n.tr("Настройки обоев")
              expanded: false
              SettingsRow {
                icon: Config.iconFolder
                title: I18n.tr("Папка обоев")
                subtitle: Config.wallpaperDir
                Item {
                  width: Config.scaledSize(194)
                  height: Config.scaledSize(34)
                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: folderButton.left
                    anchors.rightMargin: Config.scaledSize(6)
                    height: Config.scaledSize(34)
                    radius: Config.popupRadiusPx(10)
                    color: Config.searchBg
                    border.color: wallpaperDirInput.activeFocus ? Config.activeBorderColor : "#00000000"
                    border.width: wallpaperDirInput.activeFocus ? 1 : 0
                    TextInput {
                      id: wallpaperDirInput
                      anchors.fill: parent
                      anchors.leftMargin: Config.scaledSize(10)
                      anchors.rightMargin: Config.scaledSize(10)
                      verticalAlignment: TextInput.AlignVCenter
                      text: Config.wallpaperDir
                      color: Config.textPrimary
                      selectedTextColor: Config.textWhite
                      selectionColor: Config.selectedBg
                      font.pixelSize: Config.fontSizeExtraSmall
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
                    width: Config.scaledSize(34)
                    height: Config.scaledSize(34)
                    radius: Config.popupRadiusPx(10)
                    color: folderMouse.containsMouse ? Config.hoverBg : "#00000000"
                    Text { anchors.centerIn: parent; text: Config.iconFolder; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
                    MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pickWallpaperDir() }
                  }
                }
              }
              SettingsRow {
                icon: Config.iconFitToScreen
                title: I18n.tr("Отображение обоев")
                subtitle: I18n.tr("Масштабирование изображения")
                Item {
                  width: Config.scaledSize(194)
                  height: Config.scaledSize(30)
                  Rectangle {
                    id: wallpaperModeButton
                    anchors.fill: parent
                    radius: Config.popupRadiusPx(9)
                    color: wallpaperModeButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                    border.color: root.wallpaperModeDropdownOpen ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; text: root.optionName(root.wallpaperFillModes, Config.wallpaperFillMode); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
                    Text { anchors.right: parent.right; anchors.rightMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: root.wallpaperModeDropdownOpen ? "󰅃" : "󰅀"; color: Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
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
                icon: Config.iconTransition
                title: I18n.tr("Эффект смены")
                subtitle: I18n.tr("Переход при смене обоев")
                Item {
                  width: Config.scaledSize(194)
                  height: Config.scaledSize(30)
                  Rectangle {
                    id: wallpaperTransitionButton
                    anchors.fill: parent
                    radius: Config.popupRadiusPx(9)
                    color: wallpaperTransitionButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                    border.color: root.wallpaperTransitionDropdownOpen ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; text: root.optionName(root.wallpaperTransitions, Config.wallpaperTransition); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
                    Text { anchors.right: parent.right; anchors.rightMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: root.wallpaperTransitionDropdownOpen ? "󰅃" : "󰅀"; color: Config.textMuted; font.pixelSize: Config.fontSizeIconSmall; font.family: Config.fontIcon }
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
                icon: Config.iconRefreshAuto
                title: I18n.tr("Автоматическая смена")
                subtitle: Config.wallpaperCyclingEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
                onClicked: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled)
                ToggleSwitch { z: 1; checked: Config.wallpaperCyclingEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled) }
              }
              SettingsRow {
                visible: Config.wallpaperCyclingEnabled
                icon: Config.iconStopwatch
                title: I18n.tr("Интервал смены")
                subtitle: I18n.tr("Секунды между обоями из текущей папки")
                NumberSlider { value: Config.wallpaperCyclingInterval; from: 30; to: 43200; defaultValue: 300; suffix: "с"; onValueEdited: root.applyWallpaperCyclingInterval(value) }
              }
              SettingsRow {
                visible: CompositorService.backend === "niri"
                icon: Config.iconBlur
                title: I18n.tr("Размывать обои в Overview")
                subtitle: Config.blurWallpaperOnOverview ? I18n.tr("Включено") : I18n.tr("Выключено")
                onClicked: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview)
                ToggleSwitch { z: 1; checked: Config.blurWallpaperOnOverview; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview) }
              }
            }
            Rectangle {
              width: parent.width
              height: Config.scaledSize(34)
              radius: Config.popupRadiusPx(9)
              color: Config.searchBg
              border.color: wallpaperFilterInput.activeFocus ? Config.activeBorderColor : "#00000000"
              border.width: wallpaperFilterInput.activeFocus ? 1 : 0
              Row {
                anchors.fill: parent
                anchors.leftMargin: Config.scaledSize(10)
                anchors.rightMargin: Config.scaledSize(10)
                spacing: Config.scaledSize(8)
                Text {
                  text: Config.iconSearch
                  color: Config.textMuted
                  font.pixelSize: Config.fontSizeIconSmall
                  font.family: Config.fontIcon
                  anchors.verticalCenter: parent.verticalCenter
                }
                TextInput {
                  id: wallpaperFilterInput
                  width: parent.width - 22
                  anchors.verticalCenter: parent.verticalCenter
                  verticalAlignment: TextInput.AlignVCenter
                  text: root.wallpaperFilterText
                  color: Config.textPrimary
                  selectedTextColor: Config.textWhite
                  selectionColor: Config.selectedBg
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontSans
                  clip: true
                  onTextChanged: {
                    root.wallpaperFilterText = text
                    root.applyWallpaperFilter()
                  }
                  Text {
                    text: I18n.tr("Поиск обоев")
                    color: Config.textPlaceholder
                    font.pixelSize: Config.fontSizeSmall
                    font.family: Config.fontSans
                    visible: !wallpaperFilterInput.text && !wallpaperFilterInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
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
                    anchors.margins: Config.scaledSize(2)
                    radius: Config.overlayRadius - 4
                    color: Config.searchBg

                    Image {
                      anchors.fill: parent
                      source: thumbnail
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      cache: true
                      sourceSize.width: Config.scaledSize(220)
                      sourceSize.height: Config.scaledSize(150)
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
                      height: Config.scaledSize(34)
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
                        anchors.margins: Config.scaledSize(8)
                        text: name
                        color: Config.textWhite
                        font.pixelSize: Config.fontSizeSmall
                        font.weight: tile.isSelected ? Font.Medium : Font.Medium
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
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "bar"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Панель"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconPanelPosition
              title: I18n.tr("Положение панели")
              subtitle: Config.barPosition === "bottom" ? I18n.tr("Снизу") : (Config.barPosition === "left" ? I18n.tr("Слева") : (Config.barPosition === "right" ? I18n.tr("Справа") : I18n.tr("Сверху")))
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "top", label: "Верх" }, { key: "bottom", label: "Низ" }, { key: "left", label: "Слева" }, { key: "right", label: "Справа" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 4
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.barPosition === modelData.key
                    color: active ? Config.selectedBg : (barSectionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: barSectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarPosition(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconTheme
              title: I18n.tr("Дизайн панели")
              subtitle: Config.barStyle === "islands" ? I18n.tr("Островки") : I18n.tr("Сплошной")
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "solid", label: "Сплошной" }, { key: "islands", label: "Островки" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 4) / 2
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.barStyle === modelData.key
                    color: active ? Config.selectedBg : (barStyleMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: barStyleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarStyle(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconScale
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
              icon: Config.iconStopwatch
              title: I18n.tr("Автоскрытие")
              subtitle: Config.barAutoHide ? I18n.tr("Скрывается автоматически") : I18n.tr("Всегда отображается")
              onClicked: root.setBoolSetting("barAutoHide", !Config.barAutoHide)
              ToggleSwitch { z: 1; checked: Config.barAutoHide; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barAutoHide", !Config.barAutoHide) }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("Задержка скрытия")
              subtitle: I18n.tr("Через сколько секунд скрывать панель")
              NumberSlider {
                value: Config.barAutoHideDelay
                from: 0
                to: 60
                defaultValue: 3
                suffix: " с"
                onValueEdited: root.applyBarAutoHideDelay(value)
              }
            }
            SettingsRow {
              icon: Config.iconArrowUp
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
              icon: Config.iconArrowDown
              title: I18n.tr("Отступ снизу")
              subtitle: I18n.tr("Расстояние от нижнего края")
              NumberSlider {
                value: Config.barBottomMargin
                from: 0
                to: 64
                defaultValue: 6
                onValueEdited: root.applyBarBottomMargin(value)
              }
            }
            SettingsRow {
              icon: Config.iconArrowLeftRight
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
              icon: Config.iconRoundedCorner
              title: I18n.tr("Закругление бара")
              subtitle: I18n.tr("Радиус углов панели")
              NumberSlider {
                value: Config.barRadius
                from: 0
                to: 100
                defaultValue: 35
                suffix: "%"
                onValueEdited: root.applyBarRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconBlur
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
              icon: Config.iconBorder
              title: I18n.tr("Обводка бара")
              subtitle: Config.barBordersEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              onClicked: root.setBoolSetting("barBordersEnabled", !Config.barBordersEnabled)
              ToggleSwitch {
                z: 1
                checked: Config.barBordersEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.setBoolSetting("barBordersEnabled", !Config.barBordersEnabled)
              }
            }
            SettingsRow {
              icon: Config.iconShadow
              title: I18n.tr("Тень бара")
              subtitle: Config.barShadowsEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              onClicked: root.setBoolSetting("barShadowsEnabled", !Config.barShadowsEnabled)
              ToggleSwitch {
                z: 1
                checked: Config.barShadowsEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.setBoolSetting("barShadowsEnabled", !Config.barShadowsEnabled)
              }
            }
            SettingsRow {
              icon: Config.iconOpacity
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
            Text { text: I18n.tr("Виджеты панели"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWorkspace
              title: I18n.tr("Рабочие столы")
              subtitle: Config.barWorkspacesEnabled ? I18n.tr("Показываются в панели") : I18n.tr("Скрыты из панели")
              onClicked: root.setBoolSetting("barWorkspacesEnabled", !Config.barWorkspacesEnabled)
              ToggleSwitch { z: 1; checked: Config.barWorkspacesEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barWorkspacesEnabled", !Config.barWorkspacesEnabled) }
            }
            SettingsRow {
              icon: Config.iconLauncher
              title: I18n.tr("Меню приложений")
              subtitle: Config.barLauncherEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыто из панели")
              onClicked: root.setBoolSetting("barLauncherEnabled", !Config.barLauncherEnabled)
              ToggleSwitch { z: 1; checked: Config.barLauncherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barLauncherEnabled", !Config.barLauncherEnabled) }
            }
            SettingsRow {
              icon: Config.iconApplication
              title: I18n.tr("Активное приложение")
              subtitle: Config.barActiveAppEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыто из панели")
              onClicked: root.setBoolSetting("barActiveAppEnabled", !Config.barActiveAppEnabled)
              ToggleSwitch { z: 1; checked: Config.barActiveAppEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barActiveAppEnabled", !Config.barActiveAppEnabled) }
            }
            SettingsRow {
              icon: Config.iconMusic
              title: I18n.tr("Медиа-плеер")
              subtitle: Config.barMediaEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыт из панели")
              onClicked: root.setBoolSetting("barMediaEnabled", !Config.barMediaEnabled)
              ToggleSwitch { z: 1; checked: Config.barMediaEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barMediaEnabled", !Config.barMediaEnabled) }
            }
            SettingsRow {
              icon: Config.iconTray
              title: I18n.tr("Системный трей")
              subtitle: Config.barTrayEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыт из панели")
              onClicked: root.setBoolSetting("barTrayEnabled", !Config.barTrayEnabled)
              ToggleSwitch { z: 1; checked: Config.barTrayEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barTrayEnabled", !Config.barTrayEnabled) }
            }
            SettingsRow {
              icon: Config.iconKeyboard
              title: I18n.tr("Раскладка клавиатуры")
              subtitle: Config.barKeyboardLayoutEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barKeyboardLayoutEnabled", !Config.barKeyboardLayoutEnabled)
              ToggleSwitch { z: 1; checked: Config.barKeyboardLayoutEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barKeyboardLayoutEnabled", !Config.barKeyboardLayoutEnabled) }
            }
            SettingsRow {
              icon: Config.iconCpu
              title: I18n.tr("Мониторинг системы")
              subtitle: Config.barSystemEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыт из панели")
              onClicked: root.setBoolSetting("barSystemEnabled", !Config.barSystemEnabled)
              ToggleSwitch { z: 1; checked: Config.barSystemEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSystemEnabled", !Config.barSystemEnabled) }
            }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("Уведомления")
              subtitle: Config.barNotificationsEnabled ? I18n.tr("Показываются в панели") : I18n.tr("Скрыты из панели")
              onClicked: root.setBoolSetting("barNotificationsEnabled", !Config.barNotificationsEnabled)
              ToggleSwitch { z: 1; checked: Config.barNotificationsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barNotificationsEnabled", !Config.barNotificationsEnabled) }
            }
            SettingsRow {
              icon: Config.iconVolHigh
              title: I18n.tr("Громкость")
              subtitle: Config.barVolumeEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barVolumeEnabled", !Config.barVolumeEnabled)
              ToggleSwitch { z: 1; checked: Config.barVolumeEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barVolumeEnabled", !Config.barVolumeEnabled) }
            }
            SettingsRow {
              icon: Config.iconBrightHigh
              title: I18n.tr("Яркость")
              subtitle: Config.barBrightnessEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barBrightnessEnabled", !Config.barBrightnessEnabled)
              ToggleSwitch { z: 1; checked: Config.barBrightnessEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBrightnessEnabled", !Config.barBrightnessEnabled) }
            }
            SettingsRow {
              icon: Config.iconBattery
              title: I18n.tr("Батарея")
              subtitle: Config.barBatteryEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barBatteryEnabled", !Config.barBatteryEnabled)
              ToggleSwitch { z: 1; checked: Config.barBatteryEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBatteryEnabled", !Config.barBatteryEnabled) }
            }
            SettingsRow {
              icon: Config.iconBluetooth
              title: I18n.tr("Bluetooth")
              subtitle: Config.barBluetoothEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыт из панели")
              onClicked: root.setBoolSetting("barBluetoothEnabled", !Config.barBluetoothEnabled)
              ToggleSwitch { z: 1; checked: Config.barBluetoothEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBluetoothEnabled", !Config.barBluetoothEnabled) }
            }
            SettingsRow {
              icon: Config.iconEthernet
              title: I18n.tr("Сеть")
              subtitle: Config.barNetworkEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barNetworkEnabled", !Config.barNetworkEnabled)
              ToggleSwitch { z: 1; checked: Config.barNetworkEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barNetworkEnabled", !Config.barNetworkEnabled) }
            }
            SettingsRow {
              icon: Config.iconClock
              title: I18n.tr("Дата и время")
              subtitle: Config.barDateTimeEnabled ? I18n.tr("Показываются в панели") : I18n.tr("Скрыты из панели")
              onClicked: root.setBoolSetting("barDateTimeEnabled", !Config.barDateTimeEnabled)
              ToggleSwitch { z: 1; checked: Config.barDateTimeEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barDateTimeEnabled", !Config.barDateTimeEnabled) }
            }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("Погода")
              subtitle: Config.barWeatherEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barWeatherEnabled", !Config.barWeatherEnabled)
              ToggleSwitch { z: 1; checked: Config.barWeatherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barWeatherEnabled", !Config.barWeatherEnabled) }
            }
            SettingsRow {
              icon: Config.iconVpnShield
              title: I18n.tr("VPN")
              subtitle: Config.barVpnEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыт из панели")
              onClicked: root.setBoolSetting("barVpnEnabled", !Config.barVpnEnabled)
              ToggleSwitch { z: 1; checked: Config.barVpnEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barVpnEnabled", !Config.barVpnEnabled) }
            }
            SettingsRow {
              icon: Config.iconColorPicker
              title: I18n.tr("Пипетка цвета")
              subtitle: Config.barColorPickerEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыта из панели")
              onClicked: root.setBoolSetting("barColorPickerEnabled", !Config.barColorPickerEnabled)
              ToggleSwitch { z: 1; checked: Config.barColorPickerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barColorPickerEnabled", !Config.barColorPickerEnabled) }
            }
            SettingsRow {
              icon: Config.iconPower
              title: I18n.tr("Питание")
              subtitle: Config.barPowerEnabled ? I18n.tr("Показывается в панели") : I18n.tr("Скрыто из панели")
              last: true
              onClicked: root.setBoolSetting("barPowerEnabled", !Config.barPowerEnabled)
              ToggleSwitch { z: 1; checked: Config.barPowerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barPowerEnabled", !Config.barPowerEnabled) }
            }
            Text { text: I18n.tr("Рабочие столы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWorkspaceNumber
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
              icon: Config.iconControlCenter
              title: I18n.tr("Индикатор занятого стола")
              subtitle: Config.workspaceIndicatorStyle === "dot" ? I18n.tr("Точка") : (Config.workspaceIndicatorStyle === "border" ? I18n.tr("Рамка") : I18n.tr("Подсветка"))
              last: true
              Row {
                width: Config.scaledSize(194)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "tint", label: "Фон" }, { key: "dot", label: "Точка" }, { key: "border", label: "Рамка" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 8) / 3
                    height: parent.height
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.workspaceIndicatorStyle === modelData.key
                    color: active ? Config.selectedBg : (indicatorMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textSubtle; font.pixelSize: Config.fontSizeTiny; font.weight: Font.Medium; font.family: Config.fontSans }
                    MouseArea { id: indicatorMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyChoice("workspaceIndicatorStyle", parent.modelData.key) }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "popups"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Всплывающие панели"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconPopupPosition
              title: I18n.tr("Положение всплывающих панелей")
              subtitle: I18n.tr("Выбор для левой и правой панели")
              Row {
                width: Config.scaledSize(154)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(6)
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                  model: [{ key: "top", label: "Верх" }, { key: "bottom", label: "Низ" }]
                  Rectangle {
                    required property var modelData
                    width: Config.scaledSize(74)
                    height: Config.scaledSize(30)
                    radius: Config.cardRadius
                    readonly property bool active: Config.popupVerticalAlign === modelData.key
                    color: active ? Config.selectedBg : (popupSideMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
                    MouseArea { id: popupSideMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPopupVerticalAlign(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconBlur
              title: I18n.tr("Размытие всплывающих панелей")
              subtitle: Config.popupBlurEnabled ? I18n.tr("Включено") : I18n.tr("Выключено")
              onClicked: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled)
              ToggleSwitch { z: 1; checked: Config.popupBlurEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled) }
            }
            SettingsRow {
              icon: Config.iconBorder
              title: I18n.tr("Обводка всплывающих панелей")
              subtitle: Config.popupBordersEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              onClicked: root.setBoolSetting("popupBordersEnabled", !Config.popupBordersEnabled)
              ToggleSwitch { z: 1; checked: Config.popupBordersEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupBordersEnabled", !Config.popupBordersEnabled) }
            }
            SettingsRow {
              icon: Config.iconShadow
              title: I18n.tr("Тень всплывающих панелей")
              subtitle: Config.popupShadowsEnabled ? I18n.tr("Включена") : I18n.tr("Выключена")
              onClicked: root.setBoolSetting("popupShadowsEnabled", !Config.popupShadowsEnabled)
              ToggleSwitch { z: 1; checked: Config.popupShadowsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupShadowsEnabled", !Config.popupShadowsEnabled) }
            }
            SettingsRow {
              icon: Config.iconRoundedCorner
              title: I18n.tr("Закругление панелей")
              subtitle: I18n.tr("Радиус углов выпадающих меню")
              NumberSlider {
                value: Config.popupRadius
                from: 0
                to: 100
                defaultValue: 45
                suffix: "%"
                onValueEdited: root.applyPopupRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconOpacity
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
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "notifications"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Уведомления"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("Не беспокоить")
              subtitle: Config.doNotDisturb ? I18n.tr("Всплывающие тосты выключены") : I18n.tr("Всплывающие тосты включены")
              ToggleSwitch { checked: Config.doNotDisturb; anchors.verticalCenter: parent.verticalCenter; onToggled: NotificationService.setDoNotDisturb(!Config.doNotDisturb) }
            }
            SettingsRow {
              icon: Config.iconToastPosition
              title: I18n.tr("Положение тостов")
              subtitle: I18n.tr("Место появления уведомлений")
              PositionPicker { settingKey: "notificationPosition"; currentValue: Config.notificationPosition }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("Время показа")
              subtitle: Math.round(Config.notificationTimeoutMs / 1000) + I18n.tr(" сек.")
              NumberSlider { value: Config.notificationTimeoutMs / 1000; from: 1; to: 300; defaultValue: 15; suffix: " с"; onValueEdited: root.applyNotificationTimeout(value * 1000) }
            }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("Максимум тостов")
              subtitle: I18n.tr("Одновременно на экране")
              last: true
              NumberSlider { value: Config.notificationMaxVisible; from: 1; to: 10; defaultValue: 5; suffix: ""; onValueEdited: root.applyNotificationMaxVisible(value) }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "osd"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Экранные индикаторы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconOsd
              title: I18n.tr("Положение OSD")
              subtitle: I18n.tr("Громкость и яркость")
              PositionPicker { settingKey: "osdPosition"; currentValue: Config.osdPosition }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "location"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Время и локация"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconClock
              title: I18n.tr("Формат времени")
              subtitle: Config.timeFormat === "12" ? I18n.tr("12-часовой формат") : I18n.tr("24-часовой формат")
              Row {
                width: Config.scaledSize(154)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(6)
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                  model: [{ key: "24", label: "24ч" }, { key: "12", label: "12ч" }]
                  Rectangle {
                    required property var modelData
                    width: Config.scaledSize(74)
                    height: Config.scaledSize(30)
                    radius: Config.cardRadius
                    readonly property bool active: Config.timeFormat === modelData.key
                    color: active ? Config.selectedBg : (timeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
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
              icon: Config.iconWeather
              title: I18n.tr("Погода на панели")
              subtitle: Config.weatherEnabled ? I18n.tr("Показывается") : I18n.tr("Скрыта")
              ToggleSwitch { checked: Config.weatherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("weatherEnabled", !Config.weatherEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("Точность до десятых")
              subtitle: Config.weatherTenths ? I18n.tr("С десятыми") : I18n.tr("Целые градусы")
              onClicked: root.setBoolSetting("weatherTenths", !Config.weatherTenths)
              ToggleSwitch { z: 1; checked: Config.weatherTenths; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("weatherTenths", !Config.weatherTenths) }
            }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("Город погоды")
              subtitle: Config.weatherLocation.length > 0 ? Config.weatherLocation : I18n.tr("Автоматически по IP")
              Rectangle {
                width: Config.scaledSize(210)
                height: Config.scaledSize(34)
                radius: Config.popupRadiusPx(10)
                color: Config.searchBg
                border.color: weatherLocationInput.activeFocus ? Config.activeBorderColor : "#00000000"
                border.width: weatherLocationInput.activeFocus ? 1 : 0
                TextInput {
                  id: weatherLocationInput
                  anchors.fill: parent
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.rightMargin: Config.scaledSize(10)
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
              spacing: Config.scaledSize(4)
              visible: weatherSuggestions.count > 0
              Repeater {
                model: weatherSuggestions
                Rectangle {
                  required property string label
                  width: parent.width
                  height: Config.scaledSize(32)
                  radius: Config.popupRadiusPx(8)
                  color: cityMouse.containsMouse ? Config.hoverBg : "#00000000"
                  Text { anchors.fill: parent; anchors.leftMargin: Config.scaledSize(10); anchors.rightMargin: Config.scaledSize(10); verticalAlignment: Text.AlignVCenter; text: label; color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight }
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
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "monitoring"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Мониторинг системы"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Rectangle {
              width: parent.width
              height: Config.scaledSize(76)
              radius: Config.cardRadius
              color: Config.searchBg
              border.color: Config.borderColor
              border.width: 1
              Column {
                anchors.fill: parent
                anchors.margins: Config.scaledSize(12)
                spacing: Config.scaledSize(5)
                Text { text: I18n.tr("Системные метрики"); color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans }
                Text { text: I18n.tr("CPU, память, сеть и накопители отображаются на панели и в системном попапе."); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
              }
            }

            Text { text: I18n.tr("Метрики в панели"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconCpu
              title: I18n.tr("Загрузка CPU")
              subtitle: I18n.tr("Процент использования процессора")
              onClicked: root.setBoolSetting("barSysCpuEnabled", !Config.barSysCpuEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysCpuEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysCpuEnabled", !Config.barSysCpuEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("Температура CPU")
              subtitle: I18n.tr("Температура процессора")
              onClicked: root.setBoolSetting("barSysCpuTempEnabled", !Config.barSysCpuTempEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysCpuTempEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysCpuTempEnabled", !Config.barSysCpuTempEnabled) }
            }
            SettingsRow {
              icon: Config.iconGpu
              title: I18n.tr("Загрузка GPU")
              subtitle: I18n.tr("Процент использования видеокарты")
              onClicked: root.setBoolSetting("barSysGpuEnabled", !Config.barSysGpuEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysGpuEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysGpuEnabled", !Config.barSysGpuEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("Температура GPU")
              subtitle: I18n.tr("Температура видеокарты")
              onClicked: root.setBoolSetting("barSysGpuTempEnabled", !Config.barSysGpuTempEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysGpuTempEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysGpuTempEnabled", !Config.barSysGpuTempEnabled) }
            }
            SettingsRow {
              icon: Config.iconRam
              title: I18n.tr("Оперативная память")
              subtitle: I18n.tr("Использование RAM")
              onClicked: root.setBoolSetting("barSysRamEnabled", !Config.barSysRamEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysRamEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysRamEnabled", !Config.barSysRamEnabled) }
            }
            SettingsRow {
              icon: Config.iconNet
              title: I18n.tr("Сеть")
              subtitle: I18n.tr("Скорость загрузки")
              onClicked: root.setBoolSetting("barSysNetEnabled", !Config.barSysNetEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysNetEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysNetEnabled", !Config.barSysNetEnabled) }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "system"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Система"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconLanguage
              title: I18n.tr("Язык")
              subtitle: root.languageName(Config.language)
              Item {
                width: Config.scaledSize(194)
                height: Config.scaledSize(30)

                Rectangle {
                  id: languageButton
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: Config.scaledSize(30)
                  radius: Config.popupRadiusPx(9)
                  color: languageButtonMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: root.languageDropdownOpen ? Config.activeBorderColor : Config.borderColor
                  border.width: 1

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Config.scaledSize(10)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.languageName(Config.language)
                    color: Config.textPrimary
                    font.pixelSize: Config.fontSizeSmall
                    font.weight: Font.Medium
                    font.family: Config.fontSans
                    elide: Text.ElideRight
                    width: parent.width - 38
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Config.scaledSize(10)
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
            Text { text: I18n.tr("Сочетания клавиш"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconKeyboard
              title: I18n.tr("Закрыть настройки")
              subtitle: I18n.tr("Сочетание клавиш для закрытия окна настроек")
              Rectangle {
                width: Config.scaledSize(120)
                height: Config.scaledSize(34)
                radius: Config.popupRadiusPx(10)
                color: Config.searchBg
                border.color: closeKeybindInput.activeFocus ? Config.activeBorderColor : "#00000000"
                border.width: closeKeybindInput.activeFocus ? 1 : 0
                TextInput {
                  id: closeKeybindInput
                  anchors.fill: parent
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.rightMargin: Config.scaledSize(10)
                  verticalAlignment: TextInput.AlignVCenter
                  horizontalAlignment: TextInput.AlignHCenter
                  text: Config.settingsCloseKeybind
                  color: Config.textPrimary
                  selectedTextColor: Config.textWhite
                  selectionColor: Config.selectedBg
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontSans
                  clip: true
                  onEditingFinished: root.applyCloseKeybind(text)
                  Keys.onEscapePressed: { text = Config.settingsCloseKeybind; focus = false }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "advanced"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("Дополнительно"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconBrightHigh
              title: I18n.tr("Шина монитора")
              subtitle: Config.brightnessMonitorBus
              Rectangle {
                width: Config.scaledSize(120)
                height: Config.scaledSize(34)
                radius: Config.popupRadiusPx(10)
                color: Config.searchBg
                border.color: brightnessBusInput.activeFocus ? Config.activeBorderColor : "#00000000"
                border.width: brightnessBusInput.activeFocus ? 1 : 0
                TextInput {
                  id: brightnessBusInput
                  anchors.fill: parent
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.rightMargin: Config.scaledSize(10)
                  verticalAlignment: TextInput.AlignVCenter
                  text: Config.brightnessMonitorBus
                  color: Config.textPrimary
                  selectedTextColor: Config.textWhite
                  selectionColor: Config.selectedBg
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontMono
                  onEditingFinished: root.applyBrightnessMonitorBus(text)
                  Keys.onEscapePressed: { text = Config.brightnessMonitorBus; focus = false }
                }
              }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("Задержка DDC/CI")
              subtitle: I18n.tr("Множитель паузы между командами")
              Rectangle {
                width: Config.scaledSize(120)
                height: Config.scaledSize(34)
                radius: Config.popupRadiusPx(10)
                color: Config.searchBg
                border.color: brightnessDelayInput.activeFocus ? Config.activeBorderColor : "#00000000"
                border.width: brightnessDelayInput.activeFocus ? 1 : 0
                TextInput {
                  id: brightnessDelayInput
                  anchors.fill: parent
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.rightMargin: Config.scaledSize(10)
                  verticalAlignment: TextInput.AlignVCenter
                  text: Config.brightnessSleepMultiplier
                  color: Config.textPrimary
                  selectedTextColor: Config.textWhite
                  selectionColor: Config.selectedBg
                  font.pixelSize: Config.fontSizeSmall
                  font.family: Config.fontMono
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  onEditingFinished: root.applyBrightnessSleepMultiplier(text)
                  Keys.onEscapePressed: { text = Config.brightnessSleepMultiplier; focus = false }
                }
              }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "about"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("О программе"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Rectangle {
              width: parent.width
              height: Config.scaledSize(140)
              radius: Config.cardRadius
              color: Config.searchBg
              border.color: Config.borderColor
              border.width: 1
              Row {
                anchors.fill: parent
                anchors.margins: Config.scaledSize(12)
                spacing: Config.scaledSize(12)
                Image {
                  width: Config.scaledSize(72)
                  height: Config.scaledSize(72)
                  source: Qt.resolvedUrl("../../logo.svg")
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                  width: parent.width - 84
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Config.scaledSize(4)
                  Text { text: "vey"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans }
                  Text { text: I18n.tr("Vey is a customizable Wayland desktop shell built with Quickshell, QML, and Go."); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
                  Text { text: I18n.tr("Установленная версия") + ": " + root.aboutVersion; color: Config.textSubtle; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; width: parent.width; elide: Text.ElideRight }
                  Text { text: I18n.tr("Последняя версия") + ": " + root.aboutLatest; color: Config.textSubtle; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; width: parent.width; elide: Text.ElideRight }
                }
              }
            }

            Column {
              width: parent.width
              spacing: Config.scaledSize(8)
              visible: root.aboutContributors.length > 0
              Text { text: I18n.tr("Контрибьюторы") + " (" + root.aboutContributors.length + ")"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
              Grid {
                id: contributorsGrid
                width: parent.width
                columns: 3
                columnSpacing: Config.scaledSize(10)
                rowSpacing: Config.scaledSize(10)
                Repeater {
                  model: root.aboutContributors
                  delegate: Rectangle {
                    required property var modelData
                    width: (contributorsGrid.width - 20) / 3
                    height: contributorColumn.implicitHeight
                    radius: Config.cardRadius
                    color: contributorMouse.containsMouse ? Config.hoverBg : "#00000000"

                    Column {
                      id: contributorColumn
                      width: parent.width
                      spacing: Config.scaledSize(4)

                      Image {
                        id: avatarImage
                        width: Config.scaledSize(48)
                        height: Config.scaledSize(48)
                        source: modelData.avatar || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: modelData.avatar && modelData.avatar.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        layer.enabled: true
                        layer.effect: OpacityMask {
                          maskSource: Rectangle {
                            width: avatarImage.width
                            height: avatarImage.height
                            radius: Config.scaledSize(999)
                          }
                        }
                      }

                      Text { text: modelData.name || ""; color: Config.textPrimary; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter }
                      Text { text: root.commitsLabel(modelData.commits || 0); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; width: parent.width; horizontalAlignment: Text.AlignHCenter }
                    }

                    MouseArea {
                      id: contributorMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: if (modelData.url) Qt.openUrlExternally(modelData.url)
                    }
                  }
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
        radius: Config.popupRadiusPx(10)
        color: Config.glassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.languageDropdownOpen && root.activeSection === "system"

        Flickable {
          id: languageList
          anchors.fill: parent
          anchors.margins: Config.scaledSize(6)
          contentWidth: width
          contentHeight: languageListColumn.implicitHeight
          clip: true

          Column {
            id: languageListColumn
            width: languageList.width
            spacing: Config.scaledSize(4)

            Repeater {
              model: root.languages
              Rectangle {
                required property var modelData
                width: languageListColumn.width
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                readonly property bool active: Config.language === modelData.key
                color: active ? Config.selectedBg : (languageMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1

                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: Config.scaledSize(10)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Config.scaledSize(8)
                  Text { text: parent.parent.modelData.label; color: parent.parent.active ? Config.textWhite : Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.weight: Font.Medium; font.family: Config.fontSans; width: Config.scaledSize(22) }
                  Text { text: parent.parent.modelData.name; color: parent.parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                }

                MouseArea { id: languageMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyLanguage(parent.modelData.key) }
              }
            }
          }
        }

        Rectangle {
          anchors.right: parent.right
          anchors.rightMargin: Config.scaledSize(3)
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
        radius: Config.popupRadiusPx(10)
        color: Config.popupGlassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.wallpaperModeDropdownOpen && root.activeSection === "wallpaper"

        Flickable {
          anchors.fill: parent
          anchors.margins: Config.scaledSize(6)
          contentWidth: width
          contentHeight: wallpaperModeColumn.implicitHeight
          clip: true
          Column {
            id: wallpaperModeColumn
            width: parent.width
            spacing: Config.scaledSize(4)
            Repeater {
              model: root.wallpaperFillModes
              Rectangle {
                required property var modelData
                width: wallpaperModeColumn.width
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                readonly property bool active: Config.wallpaperFillMode === modelData.key
                color: active ? Config.selectedBg : (wallpaperModeMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
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
        radius: Config.popupRadiusPx(10)
        color: Config.popupGlassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.wallpaperTransitionDropdownOpen && root.activeSection === "wallpaper"

        Flickable {
          anchors.fill: parent
          anchors.margins: Config.scaledSize(6)
          contentWidth: width
          contentHeight: wallpaperTransitionColumn.implicitHeight
          clip: true
          Column {
            id: wallpaperTransitionColumn
            width: parent.width
            spacing: Config.scaledSize(4)
            Repeater {
              model: root.wallpaperTransitions
              Rectangle {
                required property var modelData
                width: wallpaperTransitionColumn.width
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                readonly property bool active: Config.wallpaperTransition === modelData.key
                color: active ? Config.selectedBg : (wallpaperTransitionMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: wallpaperTransitionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaperTransition(parent.modelData.key) }
              }
            }
          }
        }
      }

      Rectangle {
        id: wallpaperPaletteDropdown
        z: 50
        x: root.wallpaperPaletteDropdownX
        y: root.wallpaperPaletteDropdownY
        width: root.wallpaperPaletteDropdownWidth
        height: Math.min(root.wallpaperPaletteSchemes.length * 32 + 12, 220)
        radius: Config.popupRadiusPx(10)
        color: Config.popupGlassBg
        border.color: Config.activeBorderColor
        border.width: 1
        clip: true
        visible: root.wallpaperPaletteDropdownOpen && root.activeSection === "palette"

        Flickable {
          anchors.fill: parent
          anchors.margins: Config.scaledSize(6)
          contentWidth: width
          contentHeight: wallpaperPaletteColumn.implicitHeight
          clip: true
          Column {
            id: wallpaperPaletteColumn
            width: parent.width
            spacing: Config.scaledSize(4)
            Repeater {
              model: root.wallpaperPaletteSchemes
              Rectangle {
                required property var modelData
                width: wallpaperPaletteColumn.width
                height: Config.scaledSize(28)
                radius: Config.popupRadiusPx(8)
                readonly property bool active: Config.wallpaperPaletteScheme === modelData.key
                color: active ? Config.selectedBg : (wallpaperPaletteMouse.containsMouse ? Config.hoverBg : "#00000000")
                border.color: active ? Config.activeBorderColor : "#00000000"
                border.width: 1
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.label; color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: wallpaperPaletteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaperPaletteScheme(parent.modelData.key) }
              }
            }
          }
        }
      }
  }
}
