// Config.qml - Shared shell appearance, behavior, and command configuration
pragma Singleton

import QtQuick
import Quickshell

QtObject {
  id: root

  readonly property string veyctl: Quickshell.shellDir + "/veyctl"

  // ==========================================
  // 🎨 SECTION 1: COLOR PALETTE & THEMING
  // ==========================================
  property string themeName: "dark"
  property string dynamicAccent: "#e2e8f0"
  property var dynamicPalette: ["#e2e8f0", "#334155", "#64748b", "#94a3b8"]
  property string manualAccent: "#e2e8f0"
  property bool manualDark: true

  // Animated color state. These mirror the palette-derived colors and are the
  // single source of truth for rendering; applyDynamicPalette writes to them and
  // the Behavior below smoothly interpolates between the old and new palette.
  property color animatedAccent: "#e2e8f0"
  property color animatedSurface: "#334155"
  property color animatedLayer: "#64748b"
  property color animatedHighlight: "#94a3b8"

  Behavior on animatedAccent { ColorAnimation { duration: Config.reduceMotion ? 0 : 400; easing.type: Easing.InOutQuad } }
  Behavior on animatedSurface { ColorAnimation { duration: Config.reduceMotion ? 0 : 400; easing.type: Easing.InOutQuad } }
  Behavior on animatedLayer { ColorAnimation { duration: Config.reduceMotion ? 0 : 400; easing.type: Easing.InOutQuad } }
  Behavior on animatedHighlight { ColorAnimation { duration: Config.reduceMotion ? 0 : 400; easing.type: Easing.InOutQuad } }
  property bool shellBlurEnabled: true
  property bool barBlurEnabled: true
  property bool popupBlurEnabled: true
  property bool shellBordersEnabled: true
  property bool barBordersEnabled: true
  property bool popupBordersEnabled: true
  property bool shellShadowsEnabled: true
  property bool barShadowsEnabled: true
  property bool popupShadowsEnabled: true
  property bool doNotDisturb: false
  property string notificationPosition: "top-right"
  property int notificationTimeoutMs: 15000
  property string osdPosition: "bottom-center"
  readonly property bool isDynamicTheme: themeName === "dynamic"
  readonly property bool isManualTheme: themeName === "manual"
  readonly property color dynamicSurface: animatedSurface
  readonly property color dynamicLayer: animatedLayer
  readonly property color dynamicHighlight: animatedHighlight
  readonly property bool dynamicIsLight: colorLuminance(dynamicSurface) > 0.52
  readonly property bool isLightTheme: themeName === "light" || (isManualTheme && !manualDark) || (isDynamicTheme && dynamicIsLight)
  readonly property color themeAccent: isManualTheme ? manualAccent : (isDynamicTheme ? animatedAccent : (isLightTheme ? "#64748b" : "#e2e8f0"))

  readonly property color glassBg: isDynamicTheme ? Qt.rgba(dynamicSurface.r, dynamicSurface.g, dynamicSurface.b, popupBlurEnabled ? 0.78 : 1) : (popupBlurEnabled ? (isLightTheme ? "#b8f8fafc" : "#901A1A1A") : (isLightTheme ? "#f3f8fc" : "#1b1b1b"))
  readonly property color glassHoverBg: isDynamicTheme ? Qt.rgba(dynamicLayer.r, dynamicLayer.g, dynamicLayer.b, popupBlurEnabled ? 0.86 : 1) : (popupBlurEnabled ? (isLightTheme ? "#d2f8fafc" : "#c01A1A1A") : (isLightTheme ? "#eef4fa" : "#242424"))
  readonly property color searchBg: isDynamicTheme ? Qt.rgba(dynamicLayer.r, dynamicLayer.g, dynamicLayer.b, popupBlurEnabled ? 0.62 : 1) : (popupBlurEnabled ? (isLightTheme ? "#90e2e8f0" : "#251A1A1A") : (isLightTheme ? "#dde7f0" : "#2a2a2a"))
  readonly property color surfaceBorderColor: isDynamicTheme ? Qt.rgba(dynamicHighlight.r, dynamicHighlight.g, dynamicHighlight.b, 0.58) : (isLightTheme ? "#8094a3b8" : "#80464646")
  readonly property color borderColor: shellBordersEnabled ? surfaceBorderColor : "#00000000"
  readonly property color barBorderColor: barBordersEnabled ? surfaceBorderColor : "#00000000"
  readonly property color popupBorderColor: popupBordersEnabled ? surfaceBorderColor : "#00000000"
  readonly property color activeBorderColor: shellBordersEnabled ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.7) : "#00000000"
  readonly property color separatorColor: isDynamicTheme ? Qt.rgba(dynamicHighlight.r, dynamicHighlight.g, dynamicHighlight.b, 0.5) : (isLightTheme ? "#6094a3b8" : "#5064748b")
  readonly property color controlIdleBg: isDynamicTheme ? Qt.rgba(dynamicLayer.r, dynamicLayer.g, dynamicLayer.b, 0.42) : "#151A1A1A"
  readonly property color subtleBorder: isDynamicTheme ? Qt.rgba(dynamicHighlight.r, dynamicHighlight.g, dynamicHighlight.b, 0.48) : "#30464646"
  readonly property color meterTrack: isDynamicTheme ? Qt.rgba(dynamicHighlight.r, dynamicHighlight.g, dynamicHighlight.b, 0.35) : "#35464646"
  readonly property color workspaceOccupiedBg: isDynamicTheme ? Qt.rgba(dynamicLayer.r, dynamicLayer.g, dynamicLayer.b, 0.42) : "#18e2e8f0"
  readonly property color workspaceOccupiedBorder: isDynamicTheme ? Qt.rgba(dynamicHighlight.r, dynamicHighlight.g, dynamicHighlight.b, 0.62) : "#50e2e8f0"
  readonly property color shellShadowColor: isLightTheme ? "#2864748b" : "#50000000"
  readonly property color popupInputBg: Qt.rgba(searchBg.r, searchBg.g, searchBg.b, searchBg.a * popupBackgroundOpacity / 100)

  // Element State Colors
  readonly property color hoverBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.15 : 0.13)
  readonly property color activeHoverBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.22 : 0.27)
  readonly property color selectedBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.19 : 0.21)
  readonly property color pressedBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.14 : 0.19)

  // Text & Content Palette
  readonly property color textPrimary: isDynamicTheme ? dynamicOnSurface : (isLightTheme ? "#0f172a" : "#e2e8f0")
  readonly property color textMuted: isDynamicTheme ? Qt.rgba(dynamicOnSurface.r, dynamicOnSurface.g, dynamicOnSurface.b, 0.68) : (isLightTheme ? "#475569" : "#94a3b8")
  readonly property color textPlaceholder: isDynamicTheme ? Qt.rgba(dynamicOnSurface.r, dynamicOnSurface.g, dynamicOnSurface.b, 0.45) : "#64748b"
  readonly property color textSubtle: isDynamicTheme ? Qt.rgba(dynamicOnSurface.r, dynamicOnSurface.g, dynamicOnSurface.b, 0.82) : (isLightTheme ? "#334155" : "#cbd5e1")
  readonly property color textDark: isDynamicTheme ? Qt.rgba(dynamicOnSurface.r, dynamicOnSurface.g, dynamicOnSurface.b, 0.5) : (isLightTheme ? "#94a3b8" : "#475569")
  readonly property color textWhite: isDynamicTheme ? dynamicOnSurface : (isLightTheme ? "#020617" : "#ffffff")

  // Icon color used by bar widgets: pure white in dark themes so every glyph
  // reads uniformly, near-black in light themes.
  readonly property color iconColor: isDynamicTheme ? dynamicOnSurface : (isLightTheme ? "#0f172a" : "#ffffff")

  // Accent & Status Colors
  readonly property color accentGreen: "#1db954"       // Spotify & Success green
  readonly property color accentBlue: isLightTheme ? "#2563eb" : "#60a5fa"
  readonly property color warningAmber: "#f59e0b"      // High usage / Connecting amber
  readonly property color dangerRed: "#f87171"         // Mute / Critical usage / Power red

  readonly property color dynamicOnSurface: dynamicIsLight ? "#101418" : "#ffffff"

  function colorLuminance(color) {
    return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
  }

  function paletteColor(index, fallback) {
    let value = dynamicPalette && dynamicPalette.length > index ? dynamicPalette[index] : fallback
    return /^#[0-9A-Fa-f]{6}$/.test(value) ? value : fallback
  }

  function applyDynamicPalette(colors) {
    let next = []
    for (let i = 0; i < colors.length; i++) {
      let color = colors[i]
      if (/^#[0-9A-Fa-f]{6}$/.test(color) && next.indexOf(color) < 0) next.push(color)
    }
    if (next.length === 0) return
    dynamicPalette = next
    dynamicAccent = next[0]
    animatedAccent = next[0]
    animatedSurface = paletteColor(1, dynamicAccent)
    animatedLayer = paletteColor(2, dynamicAccent)
    animatedHighlight = paletteColor(3, dynamicAccent)
  }

  // ==========================================
  // 📐 SECTION 2: DIMENSIONS & GEOMETRY
  // ==========================================
  property real uiScale: 1.0
  property bool reduceMotion: false

  property int barThickness: 40
  property int barTopMargin: 6
  property int barBottomMargin: 6
  property int barHorizontalMargin: 12
  property int barRadius: 14
  property int barFrostOpacity: 56
  property int popupRadius: 18
  property int popupBackgroundOpacity: 56
  readonly property int barHeight: Math.round(barThickness * uiScale)
  readonly property int scaledBarTopMargin: Math.round(barTopMargin * uiScale)
  readonly property int scaledBarBottomMargin: Math.round(barBottomMargin * uiScale)
  readonly property int barMargin: Math.round(barHorizontalMargin * uiScale)
  readonly property int scaledBarRadius: Math.round(barRadius * uiScale)
  readonly property color barBackgroundBg: Qt.rgba(glassBg.r, glassBg.g, glassBg.b, barFrostOpacity / 100)
  readonly property color popupGlassBg: Qt.rgba(glassBg.r, glassBg.g, glassBg.b, popupBackgroundOpacity / 100)
  readonly property int barPadding: Math.round(16 * uiScale)

  readonly property int widgetRadius: Math.round(14 * uiScale)
  readonly property int overlayRadius: Math.round(popupRadius * uiScale)
  readonly property int cardRadius: Math.round(10 * uiScale)
  readonly property int innerBorderRadius: Math.round(12 * uiScale)
  readonly property int innerBorderMargin: 2
  readonly property int popupGap: 2
  readonly property int shellShadowOffsetY: Math.round(3 * uiScale)
  property string barPosition: "top"
  property string popupVerticalAlign: "top"
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property int barRotation: barPosition === "left" ? -90 : (barPosition === "right" ? 90 : 0)
  readonly property bool popupsAtBottom: barPosition === "bottom" || (isBarVertical && popupVerticalAlign === "bottom")
  readonly property bool popupsAtLeft: barPosition === "left"
  readonly property bool popupsAtRight: barPosition === "right"

  readonly property int buttonHeight: Math.round(28 * uiScale)
  readonly property int buttonWidth: Math.round(28 * uiScale)
  readonly property int buttonRadius: Math.round(8 * uiScale)

  // Overlay Container Dimensions
  readonly property int appDrawerWidth: Math.round(360 * uiScale)
  readonly property int appDrawerHeight: Math.round(520 * uiScale)
  readonly property int calendarWidth: Math.round(500 * uiScale)
  readonly property int brightnessWidth: Math.round(270 * uiScale)
  readonly property int notificationsWidth: Math.round(360 * uiScale)

  // ==========================================
  // 🔤 SECTION 3: TYPOGRAPHY SYSTEM
  // ==========================================
  property string fontFamily: "Geist Mono"
  property string fontMonoFamily: "Geist Mono"
  property real fontScale: 1.0
  property real fontMonoScale: 1.0
  property var availableFonts: ["Geist Mono", "JetBrains Mono", "Inter", "Noto Sans", "Cantarell", "Sans Serif"]
  readonly property string fontSans: fontFamily
  readonly property string fontMono: fontMonoFamily
  readonly property string fontIcon: "JetBrainsMono Nerd Font"

  readonly property int fontSizeSmall: Math.round(12 * uiScale * fontScale)
  readonly property int fontSizeNormal: Math.round(13 * uiScale * fontScale)
  readonly property int fontSizeMedium: Math.round(14 * uiScale * fontScale)
  readonly property int fontSizeLarge: Math.round(15 * uiScale * fontScale)
  readonly property int fontSizeTitle: Math.round(18 * uiScale * fontScale)
  readonly property int fontSizeIconSmall: Math.round(14 * uiScale)
  readonly property int fontSizeIconMedium: Math.round(16 * uiScale)
  readonly property int fontSizeIconLarge: Math.round(22 * uiScale)

  readonly property int fontMonoSizeSmall: Math.round(12 * uiScale * fontMonoScale)
  readonly property int fontMonoSizeNormal: Math.round(13 * uiScale * fontMonoScale)
  readonly property int fontMonoSizeMedium: Math.round(14 * uiScale * fontMonoScale)
  readonly property int fontMonoSizeLarge: Math.round(15 * uiScale * fontMonoScale)
  readonly property int fontMonoSizeTitle: Math.round(18 * uiScale * fontMonoScale)

  // ==========================================
  // ⚙️ SECTION 4: COMPONENT CONFIGURATION
  // ==========================================

  // Workspace Switcher Options
  // Options: "tint" (Soft Translucent Tint), "dot" (Bottom Dot), "border" (Subtle Border Ring)
  property string workspaceIndicatorStyle: "tint"
  property bool showWorkspaceNumbers: true
  property bool showWorkspacesOnAllMonitors: false
  property int defaultMinWorkspaces: 5
  property string timeFormat: "24"
  property bool showSeconds: false
  property string language: "ru"

  // MPRIS Media Player Options
  // Options: "progress" (Linear Progress Bar) or "visualizer" (Animated Soundwave)
  property string mprisRightDisplayMode: "visualizer"
  property int mprisVisualizerBarCount: 8
  property int mprisTargetSideWidth: 190

  // Hardware & Hardware Monitoring Options
  property int sysCheckIntervalMs: 3000
  property int netCheckIntervalMs: 5000
  property bool weatherEnabled: true
  property bool barDateTimeEnabled: true
  property bool barWeatherEnabled: true
  property bool barColorPickerEnabled: true
  property bool barWorkspacesEnabled: true
  property bool barLauncherEnabled: true
  property bool barActiveAppEnabled: true
  property bool barMediaEnabled: true
  property bool barTrayEnabled: true
  property bool barKeyboardLayoutEnabled: true
  property bool barSystemEnabled: true
  property bool barNotificationsEnabled: true
  property bool barVolumeEnabled: true
  property bool barBrightnessEnabled: true
  property bool barBatteryEnabled: true
  property bool barBluetoothEnabled: true
  property bool barNetworkEnabled: true
  property bool barControlCenterEnabled: true
  property bool barVpnEnabled: true
  property bool barPowerEnabled: true
  property string weatherLocation: ""
  property int weatherRefreshIntervalMs: 900000
  property string weatherText: "--"
  property string weatherDetails: ""
  property string brightnessMonitorBus: "auto"
  property string brightnessSleepMultiplier: ".2"
  property string wallpaperDir: "~/wallpapers/animated"
  property string wallpaperFillMode: "fill"
  property string wallpaperTransition: "fade"
  property string wallpaperPaletteScheme: "vibrant"
  property bool wallpaperCyclingEnabled: false
  property int wallpaperCyclingInterval: 300
  property bool blurWallpaperOnOverview: false

  // ==========================================
  // 🇷🇺 SECTION 5: RUSSIAN LOCALIZATION
  // ==========================================
  readonly property var weekdayShortNamesRu: ["вс", "пн", "вт", "ср", "чт", "пт", "сб"]
  readonly property var weekdayBarNamesRu: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
  readonly property var weekdayFullNamesRu: ["Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"]
  readonly property var calendarWeekdayNamesRu: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
  readonly property var monthShortNamesRu: ["янв", "фев", "мар", "апр", "мая", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]
  readonly property var monthBarNamesRu: ["янв.", "февр.", "мар.", "апр.", "мая", "июн.", "июл.", "авг.", "сент.", "окт.", "нояб.", "дек."]
  readonly property var monthNamesRu: [
    "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
    "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
  ]
  readonly property var monthGenitiveNamesRu: [
    "января", "февраля", "марта", "апреля", "мая", "июня",
    "июля", "августа", "сентября", "октября", "ноября", "декабря"
  ]

  function formatShortDateRu(date) {
    return weekdayShortNamesRu[date.getDay()] + ", " + date.getDate() + " " + monthShortNamesRu[date.getMonth()]
  }

  function formatTime24(date) {
    return Qt.formatDateTime(date, "HH:mm")
  }

  function formatBarTime(date) {
    let format = timeFormat === "12" ? (showSeconds ? "h:mm:ss AP" : "h:mm AP") : (showSeconds ? "HH:mm:ss" : "HH:mm")
    return Qt.formatDateTime(date, format)
  }

  function formatBarDateTimeRu(date) {
    return weekdayBarNamesRu[date.getDay()] + ", " + date.getDate() + " " + monthBarNamesRu[date.getMonth()] + " " + formatBarTime(date)
  }

  function formatLongDate(date) {
    if (language === "ru") {
      return weekdayFullNamesRu[date.getDay()] + ", " + date.getDate() + " " + monthGenitiveNamesRu[date.getMonth()]
    }
    return Qt.formatDateTime(date, "dddd, MMMM d")
  }

  // ==========================================
  // 󰀻 SECTION 6: NERD FONT GLYPH ICONS
  // ==========================================
  readonly property string iconLauncher: "󰀻"
  readonly property string iconWorkspace: "󰍹"
  readonly property string iconSearch: "󰍉"
  readonly property string iconPlay: "󰐊"
  readonly property string iconPause: "󰏤"
  readonly property string iconPrevTrack: "󰒮"
  readonly property string iconNextTrack: "󰒭"
  readonly property string iconCpu: "󰍛"
  readonly property string iconRam: "󰘚"
  readonly property string iconNet: "󰛳"
  readonly property string iconDisk: "󰋊"
  readonly property string iconWeather: "󰖕"
  readonly property string iconTemperature: "󰔏"
  readonly property string iconHumidity: "󰖎"
  readonly property string iconBluetooth: "󰂯"
  readonly property string iconHeadphones: "󰋋"
  readonly property string iconSpeaker: "󰔃"
  readonly property string iconEthernet: "󰈀"
  readonly property string iconWifiConnected: "󰤨"
  readonly property string iconWifiConnecting: "󱍸"
  readonly property string iconWifiDisconnected: "󰤭"
  readonly property string iconWifiSignalLow: "󰤟"
  readonly property string iconWifiSignalMid: "󰤢"
  readonly property string iconWifiSignalHigh: "󰤥"
  readonly property string iconPower: "󰐥"
  readonly property string iconChevronLeft: "󰅁"
  readonly property string iconChevronRight: "󰅂"
  readonly property string iconRefresh: "󰑓"
  readonly property string iconMic: "󰍬"
  readonly property string iconKeyboard: "󰌌"
  readonly property string iconWallpaper: "󰸉"
  readonly property string iconBattery: "󰁹"
  readonly property string iconBatteryCharging: "󰚥"
  readonly property string iconPowerSaver: "󰌪"
  readonly property string iconBalanced: "󰗑"
  readonly property string iconPerformance: "󰓅"
  readonly property string iconNotifications: "󰂚"
  readonly property string iconNotificationsActive: "󰂞"
  readonly property string iconTrash: "󰆴"
  readonly property string iconSettings: "󰒓"
  readonly property string iconInfo: "󰋽"
  readonly property string iconControlCenter: "󰕮"
  readonly property string iconAirplane: "󰀝"
  readonly property string iconMoon: "󰖔"
  readonly property string iconSun: "󰖙"
  readonly property string iconTheme: "󰔎"
  readonly property string iconVpnShield: "󰒃"
  readonly property string iconColorPicker: "󰈋"
  readonly property string iconCoffee: "󰅶"
  readonly property string iconFolder: "󰉋"
  readonly property string iconLock: "󰌾"
  readonly property string iconUnlock: "󰌿"
  readonly property string iconLogout: "󰗽"
  readonly property string iconSuspend: "󰤄"
  readonly property string iconRestart: "󰜉"
  readonly property string iconClock: "󰥔"
  readonly property string iconStopwatch: "󰔟"
  readonly property string iconMusic: "󰝚"
  readonly property string iconMotion: "󰿎"
  readonly property string iconFont: "󰛖"
  readonly property string iconScale: "󰗍"
  readonly property string iconPalette: "󰏘"
  readonly property string iconLanguage: "󰗊"

  // Volume Icons
  readonly property string iconVolHigh: "󰕾"
  readonly property string iconVolMedium: "󰖀"
  readonly property string iconVolLow: "󰕿"
  readonly property string iconVolMuted: "󰝟"

  // Brightness Icons
  readonly property string iconBrightHigh: "󰃠"
  readonly property string iconBrightMedium: "󰃟"
  readonly property string iconBrightLow: "󰃞"
  readonly property string iconBrightOff: "󰃝"

  // ==========================================
  // 🚀 SECTION 7: APPLICATION COMMANDS
  // ==========================================
  readonly property string cmdVolumeControl: "pavucontrol"
  readonly property string cmdBluetoothControl: "blueman-manager"
  readonly property string cmdNetworkControl: "nm-connection-editor"
  readonly property string cmdLauncher: "vicinae toggle"
  readonly property string cmdPowerMenu: "quickshell ipc call power toggle"
}
