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

Item {
  id: root

  property bool isOpen: false
  property bool sectionListVisible: true
  signal backRequested()
  signal hideRequested()
  signal showRequested()
  property int rightMargin: Config.scaledSize(16)
  property string activeSection: "general"
  property string pendingSection: "general"
  property string fontSearch: ""
  property string fontPickerTarget: "sans"
  property string settingsSearch: ""
  property string pendingHighlight: ""
  property string lastSearchQuery: ""
  property bool flickingToHighlight: false
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
    { key: "stretch", label: "settings.dropdown.stretch" }, { key: "fit", label: "settings.dropdown.fit" },
    { key: "fill", label: "settings.dropdown.fill" }, { key: "tile", label: "settings.dropdown.tile" },
    { key: "tile-v", label: "settings.dropdown.tileV" }, { key: "tile-h", label: "settings.dropdown.tileH" },
    { key: "pad", label: "settings.dropdown.pad" }
  ]
  readonly property var wallpaperTransitions: [
    { key: "none", label: "settings.dropdown.noEffect" }, { key: "simple", label: "settings.dropdown.simple" },
    { key: "fade", label: "settings.dropdown.fade" }, { key: "left", label: "settings.popups.left" },
    { key: "right", label: "settings.popups.right" }, { key: "top", label: "settings.popups.top" },
    { key: "bottom", label: "settings.popups.bottom" }, { key: "wipe", label: "settings.dropdown.wipe" },
    { key: "wave", label: "settings.dropdown.wave" }, { key: "grow", label: "settings.dropdown.grow" },
    { key: "center", label: "settings.dropdown.center" }, { key: "any", label: "settings.dropdown.any" },
    { key: "outer", label: "settings.dropdown.outer" }, { key: "random", label: "settings.dropdown.random" }
  ]
  readonly property var wallpaperPaletteSchemes: [
    { key: "vibrant", label: "settings.dropdown.vibrant" }, { key: "faithful", label: "settings.dropdown.faithful" },
    { key: "dysfunctional", label: "settings.dropdown.dysfunctional" }, { key: "muted", label: "settings.dropdown.muted" },
    { key: "soft", label: "settings.dropdown.soft" }, { key: "material", label: "settings.dropdown.material" },
    { key: "monochrome", label: "settings.dropdown.monochrome" }
  ]
  readonly property var screenPositions: [
    { key: "top-left", label: "settings.dropdown.tl" }, { key: "top-center", label: "settings.dropdown.tc" }, { key: "top-right", label: "settings.dropdown.tr" },
    { key: "bottom-left", label: "settings.dropdown.bl" }, { key: "bottom-center", label: "settings.dropdown.bc" }, { key: "bottom-right", label: "settings.dropdown.br" }
  ]
  readonly property var sectionCategories: [
    { key: "appearance", icon: Config.iconTheme, title: "settings.sections.appearance", pages: [{ key: "general", title: "settings.pages.general" }, { key: "palette", title: "settings.pages.palette" }, { key: "fontPicker", hidden: true }] },
    { key: "bar", icon: Config.iconPanel, title: "settings.sections.bar", pages: [{ key: "bar", title: "settings.pages.barPage" }, { key: "popups", title: "settings.pages.popups" }, { key: "monitoring", title: "settings.pages.monitoring" }] },
    { key: "desktop", icon: Config.iconWallpaper, title: "settings.sections.desktop", pages: [{ key: "wallpaper", title: "settings.pages.wallpaper" }] },
    { key: "time", icon: Config.iconClock, title: "settings.sections.time", pages: [{ key: "location", title: "settings.pages.location" }] },
    { key: "notifications", icon: Config.iconNotifications, title: "settings.sections.notifications", pages: [{ key: "notifications", title: "notifications.title" }, { key: "osd", title: "settings.pages.osd" }] },
    { key: "system", icon: Config.iconKeyboard, title: "settings.sections.system", pages: [{ key: "system", title: "settings.pages.systemPage" }] },
    { key: "advanced", icon: Config.iconMonitor, title: "settings.sections.advanced", pages: [{ key: "advanced", title: "settings.pages.advancedPage" }] },
    { key: "about", icon: Config.iconInfo, title: "settings.sections.about", pages: [{ key: "about", title: "settings.pages.aboutPage" }] }
  ]
  readonly property var searchableSettings: [
    { section: "general", title: "settings.pages.general" }, { section: "general", title: "settings.sections.appearance" },
    { section: "general", title: "settings.general.reduceMotion" }, { section: "general", title: "settings.general.tooltips" },
    { section: "general", title: "settings.general.sansFont" }, { section: "general", title: "settings.general.monoFont" },
    { section: "general", title: "settings.general.uiScale" }, { section: "general", title: "settings.general.notificationSound" },
    { section: "general", title: "settings.general.mutedApps" }, { section: "general", title: "settings.general.tileOrder" },
    { section: "general", title: "settings.general.idlePolicy" },
    { section: "palette", title: "settings.pages.palette" }, { section: "palette", title: "settings.palette.theme" },
    { section: "palette", title: "settings.palette.palettePreset" }, { section: "palette", title: "settings.palette.darkTheme" },
    { section: "wallpaper", title: "settings.pages.wallpaper" }, { section: "wallpaper", title: "settings.wallpaper.folder" },
    { section: "wallpaper", title: "settings.wallpaper.display" }, { section: "wallpaper", title: "settings.wallpaper.effect" },
    { section: "wallpaper", title: "settings.wallpaper.autoChange" }, { section: "wallpaper", title: "settings.wallpaper.interval" },
    { section: "wallpaper", title: "settings.wallpaper.blurOverview" }, { section: "wallpaper", title: "settings.wallpaper.videoSound" },
    { section: "wallpaper", title: "settings.wallpaper.videoVolume" }, { section: "wallpaper", title: "settings.wallpaper.hwDecode" },
    { section: "wallpaper", title: "settings.wallpaper.pauseOverview" },
    { section: "bar", title: "settings.pages.barPage" }, { section: "bar", title: "settings.popups.positionOfPanel" },
    { section: "bar", title: "settings.barPage.design" }, { section: "bar", title: "settings.barPage.adaptive" },
    { section: "bar", title: "settings.barPage.thickness" }, { section: "bar", title: "settings.barPage.autoHide" },
    { section: "bar", title: "settings.barPage.hideDelay" }, { section: "bar", title: "settings.popups.topPadding" },
    { section: "bar", title: "settings.popups.bottomPadding" }, { section: "bar", title: "settings.popups.sidePadding" },
    { section: "bar", title: "settings.barPage.radius" }, { section: "bar", title: "settings.barPage.radiusMode" },
    { section: "bar", title: "settings.barPage.widgetRadius" }, { section: "bar", title: "settings.barPage.blur" },
    { section: "bar", title: "settings.barPage.outline" }, { section: "bar", title: "settings.barPage.shadow" },
    { section: "bar", title: "settings.popups.backgroundOpacity" }, { section: "bar", title: "bar.workspaces" },
    { section: "bar", title: "bar.appMenu" }, { section: "bar", title: "bar.activeApp" },
    { section: "bar", title: "bar.mediaPlayerHyphen" }, { section: "bar", title: "bar.tray" },
    { section: "bar", title: "bar.keyboardLayout" }, { section: "bar", title: "bar.systemMonitor" },
    { section: "bar", title: "bar.notifications" }, { section: "bar", title: "bar.volume" },
    { section: "bar", title: "bar.brightness" }, { section: "bar", title: "bar.battery" },
    { section: "bar", title: "bar.bluetooth" }, { section: "bar", title: "bar.network" },
    { section: "bar", title: "bar.clock" }, { section: "bar", title: "settings.location.weather" },
    { section: "bar", title: "bar.vpn" }, { section: "bar", title: "bar.colorPicker" },
    { section: "bar", title: "bar.power" }, { section: "bar", title: "bar.workspaceNumbers" },
    { section: "bar", title: "bar.workspacesAllScreens" }, { section: "bar", title: "bar.workspaceIndicator" },
    { section: "popups", title: "settings.pages.popups" }, { section: "popups", title: "settings.popups.position" },
    { section: "popups", title: "settings.popups.blur" }, { section: "popups", title: "settings.popups.outline" },
    { section: "popups", title: "settings.popups.shadow" }, { section: "popups", title: "settings.popups.radius" },
    { section: "popups", title: "settings.barPage.radiusMode" }, { section: "popups", title: "settings.barPage.popupElementRadius" },
    { section: "popups", title: "settings.popups.opacity" },
    { section: "notifications", title: "notifications.title" }, { section: "notifications", title: "notifications.dnd" },
    { section: "notifications", title: "settings.popups.toastPosition" }, { section: "notifications", title: "settings.general.showTime" },
    { section: "notifications", title: "notifications.maxToasts" },
    { section: "osd", title: "settings.pages.osd" }, { section: "osd", title: "settings.popups.osdPosition" },
    { section: "location", title: "settings.pages.location" }, { section: "location", title: "settings.location.timeFormat" },
    { section: "location", title: "settings.location.showSeconds" }, { section: "location", title: "bar.date" },
    { section: "location", title: "settings.location.weatherInBar" }, { section: "location", title: "settings.palette.tenths" },
    { section: "location", title: "settings.location.weatherCity" },
    { section: "monitoring", title: "settings.pages.monitoring" }, { section: "monitoring", title: "settings.monitoring.cpuUsage" },
    { section: "monitoring", title: "settings.monitoring.cpuTemp" }, { section: "monitoring", title: "settings.monitoring.gpuUsage" },
    { section: "monitoring", title: "settings.monitoring.gpuTemp" }, { section: "monitoring", title: "settings.monitoring.memory" },
    { section: "monitoring", title: "bar.network" },
    { section: "system", title: "settings.pages.systemPage" }, { section: "system", title: "settings.general.language" },
    { section: "system", title: "settings.system.closeSettings" }, { section: "system", title: "settings.system.nextSection" },
    { section: "system", title: "settings.system.prevSection" }, { section: "system", title: "settings.system.nextTab" },
    { section: "system", title: "settings.system.prevTab" },
    { section: "advanced", title: "settings.pages.advancedPage" }, { section: "advanced", title: "settings.system.monitorBus" },
    { section: "advanced", title: "settings.system.ddcDelay" }
  ]
  readonly property bool hasSearchText: settingsSearch.trim().length > 0
  readonly property var searchResults: {
    let needle = settingsSearch.trim().toLowerCase()
    if (!needle) return []
    return searchableSettings.filter(entry => {
      let title = I18n.tr(entry.title).toLowerCase()
      let crumb = root.sectionBreadcrumb(entry.section).toLowerCase()
      return title.indexOf(needle) >= 0 || crumb.indexOf(needle) >= 0
    })
  }
  readonly property var currentCategory: categoryForSection(activeSection)
  property var allFonts: []
  property string thumbnail: ""
  property string wallName: I18n.tr("wallpaper.none")
  property int currentWallpaperIndex: 0
  property real wallpaperGridContentY: 0
  property bool restoringWallpaperScroll: false
  property bool wallpaperSelectionInProgress: false
  property var wallpapersAll: []
  property string wallpaperFilterText: ""

  function selectSection(section) {
    if (section === root.activeSection) {
      settingsFlickable.opacity = 1.0
      if (root.pendingHighlight.length > 0) {
        let title = root.pendingHighlight
        root.pendingHighlight = ""
        root.highlightSetting(title)
      }
      return
    }
    if (sectionTransition.running) return
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

  function selectRelativeCategory(step) {
    let index = 0
    for (let i = 0; i < sectionCategories.length; i++) {
      if (sectionCategories[i].key === currentCategory.key) { index = i; break }
    }
    index = (index + step + sectionCategories.length) % sectionCategories.length
    selectCategory(sectionCategories[index])
  }

  function selectRelativePage(step) {
    let pages = currentCategory.pages.filter(page => !page.hidden)
    if (pages.length < 2) return
    let index = pages.findIndex(page => page.key === activeSection)
    index = index < 0 ? 0 : (index + step + pages.length) % pages.length
    selectSection(pages[index].key)
  }

  function sectionBreadcrumb(section) {
    for (let i = 0; i < sectionCategories.length; i++) {
      let category = sectionCategories[i]
      for (let j = 0; j < category.pages.length; j++) {
        if (category.pages[j].key === section) {
          return I18n.tr(category.title) + " › " + I18n.tr(category.pages[j].title)
        }
      }
    }
    return ""
  }

  function searchSettings() {
    if (searchResults.length) selectSearchResult(searchResults[0])
  }

  function selectSearchResult(result) {
    root.lastSearchQuery = settingsSearchInput.text.trim()
    settingsSearchInput.text = ""
    root.settingsSearch = ""
    root.pendingHighlight = result.title
    root.sectionListVisible = false
    selectSection(result.section)
  }

  function findSettingsRow(item, title) {
    let wanted = I18n.tr(title)
    for (let i = 0; i < item.children.length; i++) {
      let child = item.children[i]
      if (typeof child.highlighted === "boolean") {
        if (child.title === wanted) return child
      } else {
        let found = root.findSettingsRow(child, title)
        if (found) return found
      }
    }
    return null
  }

  function expandAncestorSpoilers(item) {
    let p = item.parent
    while (p && p !== sectionContent) {
      if (typeof p.expanded === "boolean" && p.title !== undefined) {
        if (!p.expanded) {
          p.expanded = true
          return true
        }
      }
      p = p.parent
    }
    return false
  }

  function highlightSetting(title) {
    root.pendingHighlight = ""
    let row = root.findSettingsRow(sectionContent, title)
    if (!row) return
    if (root.expandAncestorSpoilers(row)) {
      highlightRetryTimer.title = title
      highlightRetryTimer.start()
      return
    }
    root.clearHighlight()
    root.flickingToHighlight = true
    let pos = row.mapToItem(settingsFlickable.contentItem, 0, 0)
    settingsFlickable.contentY = Math.max(0, pos.y - settingsFlickable.height / 3)
    root.flickingToHighlight = false
    row.highlighted = true
    highlightTimer.restart()
  }

  function clearHighlight() {
    for (let i = 0; i < sectionContent.children.length; i++) {
      let child = sectionContent.children[i]
      if (typeof child.highlighted === "boolean" && child.highlighted) {
        child.highlighted = false
      }
    }
  }

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
    ScriptAction {
      script: {
        if (root.pendingHighlight.length > 0) {
          let title = root.pendingHighlight
          root.pendingHighlight = ""
          root.highlightSetting(title)
        }
      }
    }
  }

  SequentialAnimation {
    id: backTransition
    NumberAnimation { target: settingsFlickable; property: "opacity"; to: 0; duration: Config.reduceMotion ? 0 : 80; easing.type: Easing.OutCubic }
    ScriptAction {
      script: {
        root.sectionListVisible = true
        root.activeSection = "general"
        if (root.lastSearchQuery.length > 0) {
          settingsSearchInput.text = root.lastSearchQuery
          root.settingsSearch = root.lastSearchQuery
        }
        sectionListFlickable.contentY = 0
        root.clearHighlight()
      }
    }
    NumberAnimation { target: sectionListFlickable; property: "opacity"; to: 1; duration: Config.reduceMotion ? 0 : 100; easing.type: Easing.OutCubic }
  }

  Timer {
    id: highlightTimer
    interval: 5000
    repeat: false
    onTriggered: root.clearHighlight()
  }

  Timer {
    id: highlightRetryTimer
    interval: 300
    repeat: false
    property string title: ""
    onTriggered: root.highlightSetting(title)
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
  readonly property string natonctl: Config.natonctl
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
    refreshPresets()
  } else {
    weatherSuggestions.clear()
    root.fontSearch = ""
  }

  visible: isOpen || container.opacity > 0.01

  function openSectionList() {
    root.sectionListVisible = true
    root.activeSection = "general"
    settingsSearchInput.text = ""
    root.settingsSearch = ""
    root.pendingHighlight = ""
    root.lastSearchQuery = ""
    root.clearHighlight()
    sectionListFlickable.opacity = 1.0
    settingsFlickable.opacity = 1.0
  }

  function handleBack() {
    if (!root.sectionListVisible) {
      root.pendingSection = "general"
      backTransition.restart()
    } else {
      root.backRequested()
    }
  }

  ListModel { id: wallpapersModel }
  ListModel { id: weatherSuggestions }
  ListModel { id: fontModel }

  Process {
    id: wallpaperProc
    stdout: SplitParser { onRead: data => root.applyWallpaperState(data) }
  }

  Timer {
    id: reapplyTimer
    interval: 250
    repeat: false
    onTriggered: root.reapplyWallpaper()
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
    command: [root.natonctl, "presets"]
    stdout: SplitParser { onRead: data => root.applyPresets(data) }
  }

  Process {
    id: screenColorProc
    command: [root.natonctl, "color", "pick", Config.fontMono]
    stdout: SplitParser {
      onRead: data => {
        try {
          let result = JSON.parse(data)
          if (result.ok && result.hex) root.applyManualSlot(result.hex)
        } catch (_) {}
      }
    }
    onExited: root.showRequested()
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
    for (let i = 0; i < options.length; i++) if (options[i].key === key) return I18n.tr(options[i].label)
    return options.length > 0 ? I18n.tr(options[0].label) : ""
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
    if (value !== "manual" && Config.activeTheme) {
      Config.activeTheme = null
      Config.activePresetFile = ""
      saveSetting("activeTheme", "")
      saveSetting("activePresetFile", "")
    }
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
  function applyBarWidgetRadius(value) {
    let radius = Math.max(0, Math.min(100, Math.round(value)))
    Config.barWidgetRadius = radius
    saveSetting("barWidgetRadius", radius)
  }
  function applyBarRadiusMode(value) {
    Config.barRadiusMode = value
    saveSetting("barRadiusMode", value)
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
  function applyPopupWidgetRadius(value) {
    let radius = Math.max(0, Math.min(100, Math.round(value)))
    Config.popupWidgetRadius = radius
    saveSetting("popupWidgetRadius", radius)
  }
  function applyPopupRadiusMode(value) {
    Config.popupRadiusMode = value
    saveSetting("popupRadiusMode", value)
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
    if (Config.activeTheme) {
      Config.activeTheme = null
      Config.activePresetFile = ""
      saveSetting("activeTheme", "")
      saveSetting("activePresetFile", "")
    }
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
    root.hideRequested()
    screenColorProc.running = true
  }
  function setBoolSetting(key, value) {
    if (key === "showSeconds") Config.showSeconds = value
    if (key === "tooltipsEnabled") Config.tooltipsEnabled = value
    if (key === "dynamicDark") {
      Config.dynamicDark = value
      root.refreshWallpapers()
    }
    if (key === "showWorkspaceNumbers") Config.showWorkspaceNumbers = value
    if (key === "showWorkspacesOnAllMonitors") Config.showWorkspacesOnAllMonitors = value
    if (key === "barAdaptive") Config.barAdaptive = value
    if (key === "barBlurEnabled") Config.barBlurEnabled = value
    if (key === "popupBlurEnabled") Config.popupBlurEnabled = value
    if (key === "wallpaperCyclingEnabled") Config.wallpaperCyclingEnabled = value
    if (key === "blurWallpaperOnOverview") Config.blurWallpaperOnOverview = value
    if (key === "videoWallpaperAudio") Config.videoWallpaperAudio = value
    if (key === "videoWallpaperHwdec") Config.videoWallpaperHwdec = value
    if (key === "videoWallpaperPauseOnOverview") Config.videoWallpaperPauseOnOverview = value
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
    if (key === "barDateEnabled") Config.barDateEnabled = value
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
    anchors.verticalCenter: parent.verticalCenter
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
    wallpaperProc.command = [root.natonctl, "wallpaper", "config", nextDir]
    wallpaperProc.running = true
  }
  function applyWallpaperFillMode(value) { Config.wallpaperFillMode = value; saveSetting("wallpaperFillMode", value); root.wallpaperModeDropdownOpen = false; reapplyTimer.restart() }
  function applyWallpaperTransition(value) { Config.wallpaperTransition = value; saveSetting("wallpaperTransition", value); root.wallpaperTransitionDropdownOpen = false }
  function applyWallpaperPaletteScheme(value) { Config.wallpaperPaletteScheme = value; saveSetting("wallpaperPaletteScheme", value); root.wallpaperPaletteDropdownOpen = false; root.refreshWallpapers() }
  function applyWallpaperCyclingInterval(value) {
    let interval = Math.max(30, Math.min(43200, Math.round(value)))
    Config.wallpaperCyclingInterval = interval
    saveSetting("wallpaperCyclingInterval", interval)
  }
  function applyVideoWallpaperVolume(value) {
    let volume = Math.max(0, Math.min(100, Math.round(value)))
    Config.videoWallpaperVolume = volume
    saveSetting("videoWallpaperVolume", volume)
    reapplyTimer.restart()
  }

  function refreshFonts() {
    fontProc.running = false
    fontProc.command = [root.natonctl, "fonts"]
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
    folderProc.command = [root.natonctl, "pick-folder", Config.wallpaperDir]
    folderProc.running = true
  }

  function wallpaperPaletteArg() {
    return Config.wallpaperPaletteScheme + (Config.dynamicDark ? ":dark" : ":light")
  }

  function refreshWallpapers() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.natonctl, "wallpaper", "get", Config.wallpaperDir, root.wallpaperPaletteArg()]
    wallpaperProc.running = true
  }

  function reapplyWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.natonctl, "wallpaper", "apply"]
    wallpaperProc.running = true
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.natonctl, "wallpaper", "next", Config.wallpaperDir, root.wallpaperPaletteArg()]
    wallpaperProc.running = true
  }

  function setWallpaper(index) {
    wallpaperGridContentY = wallpaperGrid.contentY
    wallpaperSelectionInProgress = true
    wallpaperProc.running = false
    wallpaperProc.command = [root.natonctl, "wallpaper", "set", index.toString(), Config.wallpaperDir, root.wallpaperPaletteArg()]
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
      root.wallName = res.name || I18n.tr("wallpaper.none")
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
    aboutProc.command = [root.natonctl, "about"]
    aboutProc.running = true
  }

  function applyPresets(data) {
    try {
      root.presets = JSON.parse(data) || []
    } catch(e) { root.presets = [] }
  }

  function refreshPresets() {
    presetsProc.running = false
    presetsProc.command = [root.natonctl, "presets"]
    presetsProc.running = true
  }

  function applyPreset(name, theme) {
    if (!theme) return
    Config.activeTheme = theme
    Config.activePresetFile = theme.file || ""
    Config.themeName = "manual"
    Config.applyTheme(theme)
    saveSetting("themeName", "manual")
    saveSetting("activeTheme", JSON.stringify(theme))
    saveSetting("activePresetFile", theme.file || "")
    saveSetting("manualPalette", JSON.stringify(Config.manualPalette))
  }

  function commitsLabel(n) {
    let m10 = n % 10, m100 = n % 100
    if (m10 === 1 && m100 !== 11) return n + " " + I18n.tr("settings.about.commitSuffix")
    if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return n + " " + I18n.tr("settings.about.commitSuffixGen")
    return n + " " + I18n.tr("settings.about.commitSuffixPlural")
  }

  Rectangle {
    id: container
    anchors.fill: parent
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

        Rectangle {
          id: settingsBackButton
          width: Config.scaledSize(30)
          height: Config.scaledSize(30)
          radius: Config.popupRadiusPx(9)
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          color: settingsBackMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
          border.color: Config.borderColor
          border.width: 1
          Text { anchors.centerIn: parent; text: Config.iconChevronLeft; color: Config.textPrimary; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
          MouseArea { id: settingsBackMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.handleBack() }
        }
        Text { text: I18n.tr("settings.title"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans; anchors.left: settingsBackButton.right; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter }
      }

      Rectangle {
        id: settingsSearchBox
        visible: root.sectionListVisible
        width: parent.width
        height: Config.scaledSize(38)
        radius: Config.cardRadius
        color: Config.searchBg
        border.color: Config.subtleBorder
        border.width: 1
        Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(12); anchors.verticalCenter: parent.verticalCenter; text: Config.iconSearch; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
        TextInput {
          id: settingsSearchInput
          anchors.left: parent.left
          anchors.leftMargin: Config.scaledSize(40)
          anchors.right: parent.right
          anchors.rightMargin: Config.scaledSize(12)
          anchors.verticalCenter: parent.verticalCenter
          color: Config.textPrimary
          font.pixelSize: Config.fontSizeSmall
          font.family: Config.fontSans
          onTextChanged: root.settingsSearch = text
          onAccepted: root.searchSettings()
          Text { anchors.verticalCenter: parent.verticalCenter; text: I18n.tr("settings.searchPlaceholder"); visible: !parent.text; color: Config.textPlaceholder; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
        }
      }

      Flickable {
        id: sectionListFlickable
        visible: root.sectionListVisible
        width: parent.width
        height: container.height - 120
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        Column {
          id: contentColumn
          width: parent.width
          spacing: Config.scaledSize(6)

          Repeater {
            model: root.hasSearchText ? root.searchResults : root.sectionCategories
            Rectangle {
              required property var modelData
              width: parent.width
              height: root.hasSearchText ? Config.scaledSize(46) : Config.scaledSize(46)
              radius: Config.cardRadius
              color: listRowMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
              border.color: Config.subtleBorder
              border.width: 1

              Text { text: root.hasSearchText ? Config.iconSearch : parent.modelData.icon; anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(12); anchors.verticalCenter: parent.verticalCenter; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
              Column {
                anchors.left: parent.left
                anchors.leftMargin: Config.scaledSize(40)
                anchors.right: parent.right
                anchors.rightMargin: Config.scaledSize(34)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.scaledSize(1)
                Text { width: parent.width; text: I18n.tr(parent.parent.modelData.title); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
                Text { width: parent.width; visible: parent.parent.modelData.section !== undefined; text: root.sectionBreadcrumb(parent.parent.modelData.section); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
              }
              Text { anchors.right: parent.right; anchors.rightMargin: Config.scaledSize(12); anchors.verticalCenter: parent.verticalCenter; text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
              MouseArea {
                id: listRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.hasSearchText) {
                    root.selectSearchResult(parent.modelData)
                  } else {
                    root.sectionListVisible = false
                    root.selectCategory(parent.modelData)
                  }
                }
              }
            }
          }

          Text {
            visible: root.hasSearchText && root.searchResults.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: I18n.tr("common.nothingFound")
            color: Config.textMuted
            font.pixelSize: Config.fontSizeSmall
            font.family: Config.fontSans
            topPadding: Config.scaledSize(18)
          }
        }
      }

      Row {
        visible: !root.sectionListVisible
        width: parent.width
        height: container.height - 70
        spacing: Config.scaledSize(12)

      Flickable {
        id: settingsFlickable
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: sectionContent.implicitHeight
        clip: true
        onContentYChanged: if (!root.flickingToHighlight) root.clearHighlight()

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
            Text { text: I18n.tr("settings.sections.appearance"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconMotion
              title: I18n.tr("settings.general.reduceMotion")
              subtitle: Config.reduceMotion ? I18n.tr("settings.general.reduced") : I18n.tr("settings.general.normal")
              ToggleSwitch { checked: Config.reduceMotion; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("reduceMotion", !Config.reduceMotion) }
            }

            SettingsRow {
              icon: Config.iconInfo
              title: I18n.tr("settings.general.tooltips")
              subtitle: Config.tooltipsEnabled ? I18n.tr("common.shownPlural") : I18n.tr("common.hiddenPlural")
              ToggleSwitch { checked: Config.tooltipsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("tooltipsEnabled", !Config.tooltipsEnabled) }
            }

            Text { text: I18n.tr("settings.pages.general"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }

            SettingsRow {
              icon: Config.iconFont
              title: I18n.tr("settings.general.sansFont")
              subtitle: Config.fontFamily
              onClicked: {
                root.fontPickerTarget = "sans"
                root.activeSection = "fontPicker"
              }
              Text { text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            }

            SettingsRow {
              icon: Config.iconFont
              title: I18n.tr("settings.general.monoFont")
              subtitle: Config.fontMonoFamily
              onClicked: {
                root.fontPickerTarget = "mono"
                root.activeSection = "fontPicker"
              }
              Text { text: Config.iconChevronRight; color: Config.textMuted; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon }
            }

            SettingsRow {
              icon: Config.iconScale
              title: I18n.tr("settings.general.uiScale")
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
            SettingsRow { icon: Config.iconNotifications; title: I18n.tr("settings.general.notificationSound"); subtitle: Config.notificationSoundEnabled ? I18n.tr("common.on") : I18n.tr("common.off"); ToggleSwitch { checked: Config.notificationSoundEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: { Config.notificationSoundEnabled = !Config.notificationSoundEnabled; root.saveSetting("notificationSoundEnabled", Config.notificationSoundEnabled) } } }
            SettingsRow { icon: Config.iconNotifications; title: I18n.tr("settings.general.mutedApps"); subtitle: I18n.tr("settings.general.mutedAppsHint"); Rectangle { width: Config.scaledSize(194); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: Config.searchBg; TextInput { anchors.fill: parent; anchors.margins: Config.scaledSize(7); text: Config.notificationMutedApps; color: Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontMono; onEditingFinished: { Config.notificationMutedApps = text; root.saveSetting("notificationMutedApps", text) } } } }
            SettingsRow { icon: Config.iconClipboard; title: I18n.tr("settings.general.tileOrder"); subtitle: I18n.tr("settings.general.tileOrderHint"); Rectangle { width: Config.scaledSize(194); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: Config.searchBg; TextInput { anchors.fill: parent; anchors.margins: Config.scaledSize(7); text: Config.controlCenterTiles; color: Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontMono; onEditingFinished: { Config.controlCenterTiles = text; root.saveSetting("controlCenterTiles", text) } } } }
            SettingsRow { icon: Config.iconMoon; title: I18n.tr("settings.general.idlePolicy"); subtitle: I18n.tr("settings.general.idleHint"); Row { width: Config.scaledSize(194); spacing: Config.scaledSize(4); Rectangle { width: Config.scaledSize(52); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: Config.searchBg; TextInput { anchors.fill: parent; anchors.margins: Config.scaledSize(7); text: Config.idleTimeoutMinutes.toString(); inputMethodHints: Qt.ImhDigitsOnly; color: Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontMono; onEditingFinished: { Config.idleTimeoutMinutes = parseInt(text) || 0; root.saveSetting("idleTimeoutMinutes", Config.idleTimeoutMinutes) } } } Repeater { model: [{ key: "lock", title: "Блокировка" }, { key: "suspend", title: "Сон" }]; Rectangle { required property var modelData; width: Config.scaledSize(67); height: Config.scaledSize(30); radius: Config.popupRadiusPx(8); color: Config.idleAction === modelData.key ? Config.selectedBg : (idleActionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg); Text { anchors.centerIn: parent; width: parent.width - Config.scaledSize(8); text: I18n.tr(parent.modelData.title); color: Config.idleAction === parent.modelData.key ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter } MouseArea { id: idleActionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.idleAction = parent.modelData.key; root.saveSetting("idleAction", Config.idleAction) } } } } } }
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
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.handleBack() }
              }
              Text { text: root.fontPickerTarget === "mono" ? I18n.tr("settings.general.monoFont") : I18n.tr("settings.general.sansFont"); color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans; anchors.verticalCenter: parent.verticalCenter }
            }
            Text { text: I18n.tr("settings.palette.current") + ": " + (root.fontPickerTarget === "mono" ? Config.fontMonoFamily : Config.fontFamily); color: Config.textSubtle; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; elide: Text.ElideRight; width: parent.width }

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
                Text { text: I18n.tr("settings.general.fontSearch"); color: Config.textPlaceholder; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; visible: !fontSearchInput.text && !fontSearchInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
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
                  Text { width: parent.width; text: I18n.tr("settings.fontPreview"); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: name; elide: Text.ElideRight }
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
              title: I18n.tr("settings.palette.theme")
              subtitle: Config.themeName === "manual" ? I18n.tr("settings.palette.manualAccent") : (Config.themeName === "dynamic" ? I18n.tr("settings.palette.wallpaperAccent") : (Config.themeName === "light" ? I18n.tr("settings.palette.lightPalette") : I18n.tr("settings.palette.darkPalette")))
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
                    model: [{ key: "light", label: "settings.palette.light" }, { key: "dark", label: "settings.palette.dark" }, { key: "dynamic", label: "settings.palette.dynamic" }, { key: "manual", label: "settings.palette.custom" }]
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
                    Text { width: parent.width; text: I18n.tr("settings.palette.clickToPick"); color: Config.textMuted; font.pixelSize: Config.fontSizeExtraSmall; font.family: Config.fontSans; elide: Text.ElideRight }
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
                  Text { anchors.centerIn: parent; text: Config.iconColorPicker + "  " + I18n.tr("settings.system.pickColor"); color: Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
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
              title: I18n.tr("settings.palette.palettePreset")
              subtitle: I18n.tr("settings.palette.extractMethod")
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
              title: I18n.tr("settings.palette.darkTheme")
              subtitle: Config.dynamicDark ? I18n.tr("settings.palette.darkFromWall") : I18n.tr("settings.palette.lightFromWall")
              onClicked: root.setBoolSetting("dynamicDark", !Config.dynamicDark)
              ToggleSwitch { z: 1; checked: Config.dynamicDark; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("dynamicDark", !Config.dynamicDark) }
            }

            Text { text: I18n.tr("settings.palette.presets"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
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
                  readonly property bool isActive: !!Config.activeTheme && Config.activeTheme.name === modelData.name
                  width: (presetsGrid.width - 20) / 3
                  height: Config.scaledSize(52)
                  radius: Config.cardRadius
                  color: presetMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg
                  border.color: isActive ? Config.themeAccent : Config.subtleBorder
                  border.width: isActive ? 2 : 1

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

                  MouseArea { id: presetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPreset(modelData.name, modelData) }
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
              title: I18n.tr("settings.wallpaper.settings")
              expanded: false
              SettingsRow {
                icon: Config.iconFolder
                title: I18n.tr("settings.wallpaper.folder")
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
                title: I18n.tr("settings.wallpaper.display")
                subtitle: I18n.tr("settings.wallpaper.scaling")
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
                title: I18n.tr("settings.wallpaper.effect")
                subtitle: I18n.tr("settings.wallpaper.transition")
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
                title: I18n.tr("settings.wallpaper.autoChange")
                subtitle: Config.wallpaperCyclingEnabled ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
                onClicked: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled)
                ToggleSwitch { z: 1; checked: Config.wallpaperCyclingEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("wallpaperCyclingEnabled", !Config.wallpaperCyclingEnabled) }
              }
              SettingsRow {
                visible: Config.wallpaperCyclingEnabled
                icon: Config.iconStopwatch
                title: I18n.tr("settings.wallpaper.interval")
                subtitle: I18n.tr("settings.wallpaper.intervalHint")
                NumberSlider { value: Config.wallpaperCyclingInterval; from: 30; to: 43200; defaultValue: 300; suffix: I18n.tr("settings.general.secSuffixShort"); onValueEdited: root.applyWallpaperCyclingInterval(value) }
              }
              SettingsRow {
                visible: CompositorService.backend === "niri"
                icon: Config.iconBlur
                title: I18n.tr("settings.wallpaper.blurOverview")
                subtitle: Config.blurWallpaperOnOverview ? I18n.tr("common.on") : I18n.tr("common.off")
                onClicked: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview)
                ToggleSwitch { z: 1; checked: Config.blurWallpaperOnOverview; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("blurWallpaperOnOverview", !Config.blurWallpaperOnOverview) }
              }
              Text { text: I18n.tr("settings.wallpaper.video"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
              SettingsRow {
                icon: Config.iconSpeaker
                title: I18n.tr("settings.wallpaper.videoSound")
                subtitle: Config.videoWallpaperAudio ? I18n.tr("common.on") : I18n.tr("common.off")
                onClicked: root.setBoolSetting("videoWallpaperAudio", !Config.videoWallpaperAudio)
                ToggleSwitch { z: 1; checked: Config.videoWallpaperAudio; anchors.verticalCenter: parent.verticalCenter; onToggled: { root.setBoolSetting("videoWallpaperAudio", !Config.videoWallpaperAudio); reapplyTimer.restart() } }
              }
              SettingsRow {
                visible: Config.videoWallpaperAudio
                icon: Config.iconSpeaker
                title: I18n.tr("settings.wallpaper.videoVolume")
                subtitle: I18n.tr("settings.wallpaper.playbackVolume")
                NumberSlider { value: Config.videoWallpaperVolume; from: 0; to: 100; defaultValue: 100; suffix: "%"; onValueEdited: root.applyVideoWallpaperVolume(value) }
              }
              SettingsRow {
                icon: Config.iconGpu
                title: I18n.tr("settings.wallpaper.hwDecode")
                subtitle: Config.videoWallpaperHwdec ? I18n.tr("common.on") : I18n.tr("common.off")
                onClicked: root.setBoolSetting("videoWallpaperHwdec", !Config.videoWallpaperHwdec)
                ToggleSwitch { z: 1; checked: Config.videoWallpaperHwdec; anchors.verticalCenter: parent.verticalCenter; onToggled: { root.setBoolSetting("videoWallpaperHwdec", !Config.videoWallpaperHwdec); reapplyTimer.restart() } }
              }
              SettingsRow {
                visible: CompositorService.backend === "niri"
                icon: Config.iconPause
                title: I18n.tr("settings.wallpaper.pauseOverview")
                subtitle: Config.videoWallpaperPauseOnOverview ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
                onClicked: root.setBoolSetting("videoWallpaperPauseOnOverview", !Config.videoWallpaperPauseOnOverview)
                ToggleSwitch { z: 1; checked: Config.videoWallpaperPauseOnOverview; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("videoWallpaperPauseOnOverview", !Config.videoWallpaperPauseOnOverview) }
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
                    text: I18n.tr("settings.wallpaper.search")
                    color: Config.textPlaceholder
                    font.pixelSize: Config.fontSizeSmall
                    font.family: Config.fontSans
                    visible: !wallpaperFilterInput.text && !wallpaperFilterInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
            }
            Text { width: parent.width; visible: wallpapersModel.count === 0; text: I18n.tr("wallpaper.folderEmpty"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap }
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
                required property int wallWidth
                required property int wallHeight
                required property bool isVideo
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
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.margins: Config.scaledSize(6)
                      height: Config.scaledSize(20)
                      width: dimsRow.width + Config.scaledSize(10)
                      radius: Config.scaledSize(10)
                      color: "#b0000000"
                      visible: wallWidth > 0 && wallHeight > 0
                      Row {
                        id: dimsRow
                        anchors.centerIn: parent
                        spacing: Config.scaledSize(3)
                        Text {
                          text: wallWidth + "×" + wallHeight
                          color: Config.textWhite
                          font.pixelSize: Config.fontSizeTiny
                          font.family: Config.fontSans
                        }
                      }
                    }

                    Rectangle {
                      anchors.right: parent.right
                      anchors.top: parent.top
                      anchors.margins: Config.scaledSize(6)
                      width: Config.scaledSize(20)
                      height: Config.scaledSize(20)
                      radius: Config.scaledSize(10)
                      color: "#b0000000"
                      visible: tile.isVideo
                      Text {
                        anchors.centerIn: parent
                        text: Config.iconVideo
                        color: Config.textWhite
                        font.pixelSize: Config.fontSizeTiny + 2
                        font.family: Config.fontIcon
                      }
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
            Text { text: I18n.tr("settings.pages.barPage"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconPanelPosition
              title: I18n.tr("settings.popups.positionOfPanel")
              subtitle: Config.barPosition === "bottom" ? I18n.tr("settings.popups.bottom") : (Config.barPosition === "left" ? I18n.tr("settings.popups.left") : (Config.barPosition === "right" ? I18n.tr("settings.popups.right") : I18n.tr("settings.popups.top")))
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "top", label: "settings.dropdown.tc" }, { key: "bottom", label: "settings.dropdown.bc" }, { key: "left", label: "settings.popups.left" }, { key: "right", label: "settings.popups.right" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 4
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.barPosition === modelData.key
                    color: active ? Config.selectedBg : (barSectionMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: barSectionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarPosition(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconTheme
              title: I18n.tr("settings.barPage.design")
              subtitle: Config.barStyle === "islands" ? I18n.tr("settings.barPage.islands") : I18n.tr("settings.barPage.solid")
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "solid", label: "settings.barPage.solid" }, { key: "islands", label: "settings.barPage.islands" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - 4) / 2
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.barStyle === modelData.key
                    color: active ? Config.selectedBg : (barStyleMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: barStyleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarStyle(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconRefreshAuto
              title: I18n.tr("settings.barPage.adaptive")
              subtitle: I18n.tr("settings.barPage.adaptiveHint")
              onClicked: root.setBoolSetting("barAdaptive", !Config.barAdaptive)
              ToggleSwitch {
                z: 1
                checked: Config.barAdaptive
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.setBoolSetting("barAdaptive", !Config.barAdaptive)
              }
            }
            SettingsRow {
              icon: Config.iconScale
              title: I18n.tr("settings.barPage.thickness")
              subtitle: I18n.tr("settings.popups.wh")
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
              title: I18n.tr("settings.barPage.autoHide")
              subtitle: Config.barAutoHide ? I18n.tr("settings.barPage.hidesAutomatically") : I18n.tr("settings.barPage.alwaysShown")
              onClicked: root.setBoolSetting("barAutoHide", !Config.barAutoHide)
              ToggleSwitch { z: 1; checked: Config.barAutoHide; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barAutoHide", !Config.barAutoHide) }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("settings.barPage.hideDelay")
              subtitle: I18n.tr("settings.barPage.hideDelayHint")
              NumberSlider {
                value: Config.barAutoHideDelay
                from: 0
                to: 60
                defaultValue: 3
                suffix: I18n.tr("settings.general.secSuffixShort")
                onValueEdited: root.applyBarAutoHideDelay(value)
              }
            }
            SettingsRow {
              icon: Config.iconArrowUp
              title: I18n.tr("settings.popups.topPadding")
              subtitle: I18n.tr("settings.popups.topDistance")
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
              title: I18n.tr("settings.popups.bottomPadding")
              subtitle: I18n.tr("settings.popups.bottomDistance")
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
              title: I18n.tr("settings.popups.sidePadding")
              subtitle: I18n.tr("settings.popups.sameSideGap")
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
              title: I18n.tr("settings.barPage.radius")
              subtitle: I18n.tr("settings.barPage.radiusCorner")
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
              icon: Config.iconRoundedCorner
              title: I18n.tr("settings.barPage.radiusMode")
              subtitle: Config.barRadiusMode === "separate" ? I18n.tr("settings.barPage.separate") : I18n.tr("settings.barPage.full")
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "linked", label: "settings.barPage.full" }, { key: "separate", label: "settings.barPage.separate" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - Config.scaledSize(4)) / 2
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.barRadiusMode === modelData.key
                    color: active ? Config.selectedBg : (barRadiusModeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: barRadiusModeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyBarRadiusMode(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              visible: Config.barRadiusMode === "separate"
              icon: Config.iconRoundedCorner
              title: I18n.tr("settings.barPage.widgetRadius")
              subtitle: I18n.tr("settings.barPage.widgetRadiusCorner")
              NumberSlider {
                value: Config.barWidgetRadius
                from: 0
                to: 100
                defaultValue: 35
                suffix: "%"
                onValueEdited: root.applyBarWidgetRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconBlur
              title: I18n.tr("settings.barPage.blur")
              subtitle: Config.barBlurEnabled ? I18n.tr("common.on") : I18n.tr("common.off")
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
              title: I18n.tr("settings.barPage.outline")
              subtitle: Config.barBordersEnabled ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
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
              title: I18n.tr("settings.barPage.shadow")
              subtitle: Config.barShadowsEnabled ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
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
              title: I18n.tr("settings.popups.backgroundOpacity")
              subtitle: I18n.tr("settings.barPage.opacity")
              NumberSlider {
                value: Config.barFrostOpacity
                from: 0
                to: 100
                defaultValue: 56
                suffix: "%"
                onValueEdited: root.applyBarFrostOpacity(value)
              }
            }
            Text { text: I18n.tr("settings.general.barWidgets"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWorkspace
              title: I18n.tr("bar.workspaces")
              subtitle: Config.barWorkspacesEnabled ? I18n.tr("common.shownInBarPlural") : I18n.tr("common.hiddenFromBarPlural")
              onClicked: root.setBoolSetting("barWorkspacesEnabled", !Config.barWorkspacesEnabled)
              ToggleSwitch { z: 1; checked: Config.barWorkspacesEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barWorkspacesEnabled", !Config.barWorkspacesEnabled) }
            }
            SettingsRow {
              icon: Config.iconLauncher
              title: I18n.tr("bar.appMenu")
              subtitle: Config.barLauncherEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarN")
              onClicked: root.setBoolSetting("barLauncherEnabled", !Config.barLauncherEnabled)
              ToggleSwitch { z: 1; checked: Config.barLauncherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barLauncherEnabled", !Config.barLauncherEnabled) }
            }
            SettingsRow {
              icon: Config.iconApplication
              title: I18n.tr("bar.activeApp")
              subtitle: Config.barActiveAppEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarN")
              onClicked: root.setBoolSetting("barActiveAppEnabled", !Config.barActiveAppEnabled)
              ToggleSwitch { z: 1; checked: Config.barActiveAppEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barActiveAppEnabled", !Config.barActiveAppEnabled) }
            }
            SettingsRow {
              icon: Config.iconMusic
              title: I18n.tr("bar.mediaPlayerHyphen")
              subtitle: Config.barMediaEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBar")
              onClicked: root.setBoolSetting("barMediaEnabled", !Config.barMediaEnabled)
              ToggleSwitch { z: 1; checked: Config.barMediaEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barMediaEnabled", !Config.barMediaEnabled) }
            }
            SettingsRow {
              icon: Config.iconTray
              title: I18n.tr("bar.tray")
              subtitle: Config.barTrayEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBar")
              onClicked: root.setBoolSetting("barTrayEnabled", !Config.barTrayEnabled)
              ToggleSwitch { z: 1; checked: Config.barTrayEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barTrayEnabled", !Config.barTrayEnabled) }
            }
            SettingsRow {
              icon: Config.iconKeyboard
              title: I18n.tr("bar.keyboardLayout")
              subtitle: Config.barKeyboardLayoutEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barKeyboardLayoutEnabled", !Config.barKeyboardLayoutEnabled)
              ToggleSwitch { z: 1; checked: Config.barKeyboardLayoutEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barKeyboardLayoutEnabled", !Config.barKeyboardLayoutEnabled) }
            }
            SettingsRow {
              icon: Config.iconCpu
              title: I18n.tr("bar.systemMonitor")
              subtitle: Config.barSystemEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBar")
              onClicked: root.setBoolSetting("barSystemEnabled", !Config.barSystemEnabled)
              ToggleSwitch { z: 1; checked: Config.barSystemEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSystemEnabled", !Config.barSystemEnabled) }
            }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("bar.notifications")
              subtitle: Config.barNotificationsEnabled ? I18n.tr("common.shownInBarPlural") : I18n.tr("common.hiddenFromBarPlural")
              onClicked: root.setBoolSetting("barNotificationsEnabled", !Config.barNotificationsEnabled)
              ToggleSwitch { z: 1; checked: Config.barNotificationsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barNotificationsEnabled", !Config.barNotificationsEnabled) }
            }
            SettingsRow {
              icon: Config.iconVolHigh
              title: I18n.tr("bar.volume")
              subtitle: Config.barVolumeEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barVolumeEnabled", !Config.barVolumeEnabled)
              ToggleSwitch { z: 1; checked: Config.barVolumeEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barVolumeEnabled", !Config.barVolumeEnabled) }
            }
            SettingsRow {
              icon: Config.iconBrightHigh
              title: I18n.tr("bar.brightness")
              subtitle: Config.barBrightnessEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barBrightnessEnabled", !Config.barBrightnessEnabled)
              ToggleSwitch { z: 1; checked: Config.barBrightnessEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBrightnessEnabled", !Config.barBrightnessEnabled) }
            }
            SettingsRow {
              icon: Config.iconBattery
              title: I18n.tr("bar.battery")
              subtitle: Config.barBatteryEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barBatteryEnabled", !Config.barBatteryEnabled)
              ToggleSwitch { z: 1; checked: Config.barBatteryEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBatteryEnabled", !Config.barBatteryEnabled) }
            }
            SettingsRow {
              icon: Config.iconBluetooth
              title: I18n.tr("bar.bluetooth")
              subtitle: Config.barBluetoothEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBar")
              onClicked: root.setBoolSetting("barBluetoothEnabled", !Config.barBluetoothEnabled)
              ToggleSwitch { z: 1; checked: Config.barBluetoothEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barBluetoothEnabled", !Config.barBluetoothEnabled) }
            }
            SettingsRow {
              icon: Config.iconEthernet
              title: I18n.tr("bar.network")
              subtitle: Config.barNetworkEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barNetworkEnabled", !Config.barNetworkEnabled)
              ToggleSwitch { z: 1; checked: Config.barNetworkEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barNetworkEnabled", !Config.barNetworkEnabled) }
            }
            SettingsRow {
              icon: Config.iconClock
              title: I18n.tr("bar.clock")
              subtitle: Config.barDateTimeEnabled ? I18n.tr("common.shownInBarPlural") : I18n.tr("common.hiddenFromBarPlural")
              onClicked: root.setBoolSetting("barDateTimeEnabled", !Config.barDateTimeEnabled)
              ToggleSwitch { z: 1; checked: Config.barDateTimeEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barDateTimeEnabled", !Config.barDateTimeEnabled) }
            }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("settings.location.weather")
              subtitle: Config.barWeatherEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barWeatherEnabled", !Config.barWeatherEnabled)
              ToggleSwitch { z: 1; checked: Config.barWeatherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barWeatherEnabled", !Config.barWeatherEnabled) }
            }
            SettingsRow {
              icon: Config.iconVpnShield
              title: I18n.tr("bar.vpn")
              subtitle: Config.barVpnEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBar")
              onClicked: root.setBoolSetting("barVpnEnabled", !Config.barVpnEnabled)
              ToggleSwitch { z: 1; checked: Config.barVpnEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barVpnEnabled", !Config.barVpnEnabled) }
            }
            SettingsRow {
              icon: Config.iconColorPicker
              title: I18n.tr("bar.colorPicker")
              subtitle: Config.barColorPickerEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barColorPickerEnabled", !Config.barColorPickerEnabled)
              ToggleSwitch { z: 1; checked: Config.barColorPickerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barColorPickerEnabled", !Config.barColorPickerEnabled) }
            }
            SettingsRow {
              icon: Config.iconPower
              title: I18n.tr("bar.power")
              subtitle: Config.barPowerEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarN")
              last: true
              onClicked: root.setBoolSetting("barPowerEnabled", !Config.barPowerEnabled)
              ToggleSwitch { z: 1; checked: Config.barPowerEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barPowerEnabled", !Config.barPowerEnabled) }
            }
            Text { text: I18n.tr("bar.workspaces"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconWorkspaceNumber
              title: I18n.tr("bar.workspaceNumbers")
              subtitle: Config.showWorkspaceNumbers ? I18n.tr("common.shownPlural") : I18n.tr("common.hiddenPlural")
              ToggleSwitch { checked: Config.showWorkspaceNumbers; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showWorkspaceNumbers", !Config.showWorkspaceNumbers) }
            }
            SettingsRow {
              icon: Config.iconWorkspace
              title: I18n.tr("bar.workspacesAllScreens")
              subtitle: Config.showWorkspacesOnAllMonitors ? I18n.tr("common.shownPlural") : I18n.tr("bar.ownScreens")
              last: true
              onClicked: root.setBoolSetting("showWorkspacesOnAllMonitors", !Config.showWorkspacesOnAllMonitors)
              ToggleSwitch { z: 1; checked: Config.showWorkspacesOnAllMonitors; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showWorkspacesOnAllMonitors", !Config.showWorkspacesOnAllMonitors) }
            }
            SettingsRow {
              icon: Config.iconControlCenter
              title: I18n.tr("bar.workspaceIndicator")
              subtitle: Config.workspaceIndicatorStyle === "dot" ? I18n.tr("settings.popups.dot") : (Config.workspaceIndicatorStyle === "border" ? I18n.tr("settings.popups.border") : I18n.tr("settings.popups.highlight"))
              last: true
              Row {
                width: Config.scaledSize(194)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "tint", label: "settings.dropdown.background" }, { key: "dot", label: "settings.popups.dot" }, { key: "border", label: "settings.popups.border" }]
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
            Text { text: I18n.tr("settings.popups.popupPanels"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconPopupPosition
              title: I18n.tr("settings.popups.position")
              subtitle: I18n.tr("settings.popups.edges")
              Row {
                width: Config.scaledSize(154)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(6)
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                  model: [{ key: "top", label: "settings.dropdown.tc" }, { key: "bottom", label: "settings.dropdown.bc" }]
                  Rectangle {
                    required property var modelData
                    width: Config.scaledSize(74)
                    height: Config.scaledSize(30)
                    radius: Config.cardRadius
                    readonly property bool active: Config.popupVerticalAlign === modelData.key
                    color: active ? Config.selectedBg : (popupSideMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
                    MouseArea { id: popupSideMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPopupVerticalAlign(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconBlur
              title: I18n.tr("settings.popups.blur")
              subtitle: Config.popupBlurEnabled ? I18n.tr("common.on") : I18n.tr("common.off")
              onClicked: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled)
              ToggleSwitch { z: 1; checked: Config.popupBlurEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupBlurEnabled", !Config.popupBlurEnabled) }
            }
            SettingsRow {
              icon: Config.iconBorder
              title: I18n.tr("settings.popups.outline")
              subtitle: Config.popupBordersEnabled ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
              onClicked: root.setBoolSetting("popupBordersEnabled", !Config.popupBordersEnabled)
              ToggleSwitch { z: 1; checked: Config.popupBordersEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupBordersEnabled", !Config.popupBordersEnabled) }
            }
            SettingsRow {
              icon: Config.iconShadow
              title: I18n.tr("settings.popups.shadow")
              subtitle: Config.popupShadowsEnabled ? I18n.tr("settings.general.femOn") : I18n.tr("settings.general.femOff")
              onClicked: root.setBoolSetting("popupShadowsEnabled", !Config.popupShadowsEnabled)
              ToggleSwitch { z: 1; checked: Config.popupShadowsEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("popupShadowsEnabled", !Config.popupShadowsEnabled) }
            }
            SettingsRow {
              icon: Config.iconRoundedCorner
              title: I18n.tr("settings.popups.radius")
              subtitle: I18n.tr("settings.popups.dropdownRadius")
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
              icon: Config.iconRoundedCorner
              title: I18n.tr("settings.barPage.radiusMode")
              subtitle: Config.popupRadiusMode === "separate" ? I18n.tr("settings.barPage.separate") : I18n.tr("settings.barPage.full")
              Row {
                width: Config.scaledSize(194)
                spacing: Config.scaledSize(4)
                Repeater {
                  model: [{ key: "linked", label: "settings.barPage.full" }, { key: "separate", label: "settings.barPage.separate" }]
                  Rectangle {
                    required property var modelData
                    width: (parent.width - Config.scaledSize(4)) / 2
                    height: Config.scaledSize(30)
                    radius: Config.popupRadiusPx(8)
                    readonly property bool active: Config.popupRadiusMode === modelData.key
                    color: active ? Config.selectedBg : (popupRadiusModeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeTiny; font.family: Config.fontSans }
                    MouseArea { id: popupRadiusModeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPopupRadiusMode(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              visible: Config.popupRadiusMode === "separate"
              icon: Config.iconRoundedCorner
              title: I18n.tr("settings.barPage.popupElementRadius")
              subtitle: I18n.tr("settings.barPage.cardButtonRadius")
              NumberSlider {
                value: Config.popupWidgetRadius
                from: 0
                to: 100
                defaultValue: 45
                suffix: "%"
                onValueEdited: root.applyPopupWidgetRadius(value)
              }
            }
            SettingsRow {
              icon: Config.iconOpacity
              title: I18n.tr("settings.popups.opacity")
              subtitle: I18n.tr("settings.popups.menuBg")
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
            Text { text: I18n.tr("bar.notifications"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("notifications.dnd")
              subtitle: Config.doNotDisturb ? I18n.tr("notifications.toastsOff") : I18n.tr("notifications.toastsOn")
              ToggleSwitch { checked: Config.doNotDisturb; anchors.verticalCenter: parent.verticalCenter; onToggled: NotificationService.setDoNotDisturb(!Config.doNotDisturb) }
            }
            SettingsRow {
              icon: Config.iconToastPosition
              title: I18n.tr("settings.popups.toastPosition")
              subtitle: I18n.tr("notifications.position")
              PositionPicker { settingKey: "notificationPosition"; currentValue: Config.notificationPosition }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("settings.general.showTime")
              subtitle: Math.round(Config.notificationTimeoutMs / 1000) + I18n.tr("settings.monitoring.secSuffix")
              NumberSlider { value: Config.notificationTimeoutMs / 1000; from: 1; to: 300; defaultValue: 15; suffix: I18n.tr("settings.general.secSuffixShort"); onValueEdited: root.applyNotificationTimeout(value * 1000) }
            }
            SettingsRow {
              icon: Config.iconNotifications
              title: I18n.tr("notifications.maxToasts")
              subtitle: I18n.tr("notifications.visibleAtOnce")
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
            Text { text: I18n.tr("settings.general.screenIndicators"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconOsd
              title: I18n.tr("settings.popups.osdPosition")
              subtitle: I18n.tr("settings.general.volumeBrightness")
              PositionPicker { settingKey: "osdPosition"; currentValue: Config.osdPosition }
            }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "location"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("settings.sections.time"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconClock
              title: I18n.tr("settings.location.timeFormat")
              subtitle: Config.timeFormat === "12" ? I18n.tr("settings.location.h12") : I18n.tr("settings.location.h24")
              Row {
                width: Config.scaledSize(154)
                height: Config.scaledSize(30)
                spacing: Config.scaledSize(6)
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                  model: [{ key: "24", label: "settings.dropdown.h24" }, { key: "12", label: "settings.dropdown.h12" }]
                  Rectangle {
                    required property var modelData
                    width: Config.scaledSize(74)
                    height: Config.scaledSize(30)
                    radius: Config.cardRadius
                    readonly property bool active: Config.timeFormat === modelData.key
                    color: active ? Config.selectedBg : (timeMouse.containsMouse ? Config.hoverBg : Config.controlIdleBg)
                    border.color: active ? Config.activeBorderColor : Config.borderColor
                    border.width: 1
                    Text { anchors.centerIn: parent; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans }
                    MouseArea { id: timeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyTimeFormat(parent.modelData.key) }
                  }
                }
              }
            }
            SettingsRow {
              icon: Config.iconStopwatch
              title: I18n.tr("settings.location.showSeconds")
              subtitle: Config.showSeconds ? I18n.tr("common.shownPlural") : I18n.tr("common.hiddenPlural")
              ToggleSwitch { checked: Config.showSeconds; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("showSeconds", !Config.showSeconds) }
            }
            SettingsRow {
              icon: Config.iconCalendar
              title: I18n.tr("bar.date")
              subtitle: Config.barDateEnabled ? I18n.tr("common.shownInBar") : I18n.tr("common.hiddenFromBarF")
              onClicked: root.setBoolSetting("barDateEnabled", !Config.barDateEnabled)
              ToggleSwitch { z: 1; checked: Config.barDateEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barDateEnabled", !Config.barDateEnabled) }
            }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("settings.location.weatherInBar")
              subtitle: Config.weatherEnabled ? I18n.tr("common.shown") : I18n.tr("common.hidden")
              ToggleSwitch { checked: Config.weatherEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("weatherEnabled", !Config.weatherEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("settings.palette.tenths")
              subtitle: Config.weatherTenths ? I18n.tr("settings.palette.withTenths") : I18n.tr("settings.palette.wholeDegrees")
              onClicked: root.setBoolSetting("weatherTenths", !Config.weatherTenths)
              ToggleSwitch { z: 1; checked: Config.weatherTenths; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("weatherTenths", !Config.weatherTenths) }
            }
            SettingsRow {
              icon: Config.iconWeather
              title: I18n.tr("settings.location.weatherCity")
              subtitle: Config.weatherLocation.length > 0 ? Config.weatherLocation : I18n.tr("settings.location.autoIp")
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
                  Text { text: I18n.tr("settings.location.autoIpShort"); color: Config.textPlaceholder; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; visible: !weatherLocationInput.text && !weatherLocationInput.activeFocus; anchors.verticalCenter: parent.verticalCenter }
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
            Text { text: I18n.tr("bar.systemMonitor"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
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
                Text { text: I18n.tr("settings.monitoring.sysMetrics"); color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Medium; font.family: Config.fontSans }
                Text { text: I18n.tr("settings.monitoring.sysMetricsHint"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
              }
            }

            Text { text: I18n.tr("settings.monitoring.metrics"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconCpu
              title: I18n.tr("settings.monitoring.cpuUsage")
              subtitle: I18n.tr("settings.monitoring.cpuPercent")
              onClicked: root.setBoolSetting("barSysCpuEnabled", !Config.barSysCpuEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysCpuEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysCpuEnabled", !Config.barSysCpuEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("settings.monitoring.cpuTemp")
              subtitle: I18n.tr("settings.monitoring.cpuTempLong")
              onClicked: root.setBoolSetting("barSysCpuTempEnabled", !Config.barSysCpuTempEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysCpuTempEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysCpuTempEnabled", !Config.barSysCpuTempEnabled) }
            }
            SettingsRow {
              icon: Config.iconGpu
              title: I18n.tr("settings.monitoring.gpuUsage")
              subtitle: I18n.tr("settings.monitoring.gpuPercent")
              onClicked: root.setBoolSetting("barSysGpuEnabled", !Config.barSysGpuEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysGpuEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysGpuEnabled", !Config.barSysGpuEnabled) }
            }
            SettingsRow {
              icon: Config.iconTemperature
              title: I18n.tr("settings.monitoring.gpuTemp")
              subtitle: I18n.tr("settings.monitoring.gpuTempLong")
              onClicked: root.setBoolSetting("barSysGpuTempEnabled", !Config.barSysGpuTempEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysGpuTempEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysGpuTempEnabled", !Config.barSysGpuTempEnabled) }
            }
            SettingsRow {
              icon: Config.iconRam
              title: I18n.tr("settings.monitoring.memory")
              subtitle: I18n.tr("settings.monitoring.ramUsage")
              onClicked: root.setBoolSetting("barSysRamEnabled", !Config.barSysRamEnabled)
              ToggleSwitch { z: 1; checked: Config.barSysRamEnabled; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setBoolSetting("barSysRamEnabled", !Config.barSysRamEnabled) }
            }
            SettingsRow {
              icon: Config.iconNet
              title: I18n.tr("bar.network")
              subtitle: I18n.tr("settings.monitoring.downloadSpeed")
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
            Text { text: I18n.tr("settings.sections.system"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconLanguage
              title: I18n.tr("settings.general.language")
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
            Text { text: I18n.tr("settings.system.keybinds"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconKeyboard
              title: I18n.tr("settings.system.closeSettings")
              subtitle: I18n.tr("settings.system.closeSettingsHint")
                KeybindRecorder { keybind: Config.settingsCloseKeybind; apply: value => { root.applyCloseKeybind(value); return true } }
            }
            Text { text: I18n.tr("settings.system.global"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            Repeater {
              model: [
                { icon: Config.iconLauncher, title: "keybind.drawer", configKey: "keybindDrawer" },
                { icon: Config.iconSettings, title: "keybind.settings", configKey: "keybindSettings" },
                { icon: Config.iconClipboard, title: "keybind.clipboard", configKey: "keybindClipboard" },
                { icon: Config.iconNotifications, title: "keybind.notifications", configKey: "keybindNotifications" },
                { icon: Config.iconPower, title: "keybind.power", configKey: "keybindPower" },
                { icon: Config.iconControlCenter, title: "keybind.controlCenter", configKey: "keybindControlCenter" },
                { icon: Config.iconClock, title: "keybind.calendar", configKey: "keybindCalendar" },
                { icon: Config.iconMusic, title: "keybind.media", configKey: "keybindMedia" },
                { icon: Config.iconWifiConnected, title: "keybind.wifi", configKey: "keybindWiFi" },
                { icon: Config.iconBluetooth, title: "keybind.bluetooth", configKey: "keybindBluetooth" },
                { icon: Config.iconBrightHigh, title: "keybind.brightness", configKey: "keybindBrightness" },
                { icon: Config.iconKeyboard, title: "keybind.keyboardLayout", configKey: "keybindKeyboard" },
                { icon: Config.iconCpu, title: "keybind.systemMonitor", configKey: "keybindSystem" }
              ]
              SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: I18n.tr(modelData.title)
                subtitle: Config[modelData.configKey]
                KeybindRecorder { keybind: Config[modelData.configKey]; apply: value => root.applyGlobalKeybind(modelData.configKey, value) }
              }
            }
            Text { text: I18n.tr("settings.system.nav"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow { icon: Config.iconKeyboard; title: I18n.tr("settings.system.nextSection"); subtitle: "Ctrl+Tab" }
            SettingsRow { icon: Config.iconKeyboard; title: I18n.tr("settings.system.prevSection"); subtitle: "Ctrl+Shift+Tab" }
            SettingsRow { icon: Config.iconChevronRight; title: I18n.tr("settings.system.nextTab"); subtitle: "Alt+Right" }
            SettingsRow { icon: Config.iconChevronLeft; title: I18n.tr("settings.system.prevTab"); subtitle: "Alt+Left" }
          }

          Column {
            width: parent.width
            spacing: Config.scaledSize(10)
            visible: root.activeSection === "advanced"
            height: visible ? implicitHeight : 0
            clip: true
            Text { text: I18n.tr("settings.sections.advanced"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
            SettingsRow {
              icon: Config.iconBrightHigh
              title: I18n.tr("settings.system.monitorBus")
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
              title: I18n.tr("settings.system.ddcDelay")
              subtitle: I18n.tr("settings.system.ddcMultiplier")
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
            Text { text: I18n.tr("settings.sections.about"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
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
                  Text { text: "Naton"; color: Config.textWhite; font.pixelSize: Config.fontSizeLarge; font.weight: Font.Medium; font.family: Config.fontSans }
                  Text { text: I18n.tr("settings.about.description"); color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans; wrapMode: Text.Wrap; width: parent.width }
                  Text { text: I18n.tr("settings.about.installed") + ": " + root.aboutVersion; color: Config.textSubtle; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; width: parent.width; elide: Text.ElideRight }
                  Text { text: I18n.tr("settings.about.latest") + ": " + root.aboutLatest; color: Config.textSubtle; font.pixelSize: Config.fontMonoSizeSmall; font.family: Config.fontMono; width: parent.width; elide: Text.ElideRight }
                }
              }
            }

            Column {
              width: parent.width
              spacing: Config.scaledSize(8)
              visible: root.aboutContributors.length > 0
              Text { text: I18n.tr("settings.about.contributors") + " (" + root.aboutContributors.length + ")"; color: Config.textMuted; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Medium; font.family: Config.fontSans; font.letterSpacing: 0.8 }
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
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
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
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
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
                Text { anchors.left: parent.left; anchors.leftMargin: Config.scaledSize(10); anchors.verticalCenter: parent.verticalCenter; text: I18n.tr(parent.modelData.label); color: parent.active ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.family: Config.fontSans }
                MouseArea { id: wallpaperPaletteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyWallpaperPaletteScheme(parent.modelData.key) }
              }
            }
          }
        }
      }
  }
}
