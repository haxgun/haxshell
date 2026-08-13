// Config.qml - Shared shell appearance, behavior, and command configuration
pragma Singleton

import QtQuick
import Quickshell

QtObject {
  id: root

  readonly property string hushctl: Quickshell.shellDir + "/hushctl"

  // ==========================================
  // 🎨 SECTION 1: COLOR PALETTE & THEMING
  // ==========================================
  property string themeName: "dark"
  property string dynamicAccent: "#e2e8f0"
  property string manualAccent: "#e2e8f0"
  property bool manualDark: true
  property bool shellBlurEnabled: true
  property bool shellBordersEnabled: true
  property bool shellShadowsEnabled: true
  readonly property bool isDynamicTheme: themeName === "dynamic"
  readonly property bool isManualTheme: themeName === "manual"
  readonly property bool isLightTheme: themeName === "light" || (isManualTheme && !manualDark)
  readonly property color themeAccent: isManualTheme ? manualAccent : (isDynamicTheme ? dynamicAccent : (isLightTheme ? "#64748b" : "#e2e8f0"))

  readonly property color glassBg: shellBlurEnabled ? (isLightTheme ? "#b8f8fafc" : "#901A1A1A") : (isLightTheme ? "#f3f8fc" : "#1b1b1b")
  readonly property color glassHoverBg: shellBlurEnabled ? (isLightTheme ? "#d2f8fafc" : "#c01A1A1A") : (isLightTheme ? "#eef4fa" : "#242424")
  readonly property color searchBg: shellBlurEnabled ? (isLightTheme ? "#90e2e8f0" : "#251A1A1A") : (isLightTheme ? "#dde7f0" : "#2a2a2a")
  readonly property color borderColor: shellBordersEnabled ? (isLightTheme ? "#8094a3b8" : "#80464646") : "#00000000"
  readonly property color activeBorderColor: shellBordersEnabled ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.55) : "#00000000"
  readonly property color separatorColor: isLightTheme ? "#6094a3b8" : "#5064748b"
  readonly property color shellShadowColor: isLightTheme ? "#2864748b" : "#50000000"

  // Element State Colors
  readonly property color hoverBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.15 : 0.13)
  readonly property color activeHoverBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.22 : 0.27)
  readonly property color selectedBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.19 : 0.21)
  readonly property color pressedBg: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, isLightTheme ? 0.14 : 0.19)

  // Text & Content Palette
  readonly property color textPrimary: isLightTheme ? "#0f172a" : "#e2e8f0"
  readonly property color textMuted: isLightTheme ? "#475569" : "#94a3b8"
  readonly property color textPlaceholder: isLightTheme ? "#64748b" : "#64748b"
  readonly property color textSubtle: isLightTheme ? "#334155" : "#cbd5e1"
  readonly property color textDark: isLightTheme ? "#94a3b8" : "#475569"
  readonly property color textWhite: isLightTheme ? "#020617" : "#ffffff"

  // Accent & Status Colors
  readonly property color accentGreen: "#1db954"       // Spotify & Success green
  readonly property color accentBlue: isLightTheme ? "#2563eb" : "#60a5fa"
  readonly property color warningAmber: "#f59e0b"      // High usage / Connecting amber
  readonly property color dangerRed: "#f87171"         // Mute / Critical usage / Power red

  // ==========================================
  // 📐 SECTION 2: DIMENSIONS & GEOMETRY
  // ==========================================
  property real uiScale: 1.0
  property bool reduceMotion: false

  readonly property int barHeight: Math.round(40 * uiScale)
  readonly property int barMargin: Math.round(12 * uiScale)
  readonly property int barPadding: Math.round(16 * uiScale)

  readonly property int widgetRadius: Math.round(14 * uiScale)
  readonly property int overlayRadius: Math.round(18 * uiScale)
  readonly property int cardRadius: Math.round(10 * uiScale)
  readonly property int innerBorderRadius: Math.round(12 * uiScale)
  readonly property int innerBorderMargin: 2
  readonly property int popupTopGap: 2
  readonly property int dropdownTopGap: popupTopGap
  readonly property int shellShadowOffsetY: Math.round(3 * uiScale)
  property string barPosition: "top"
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property int barRotation: barPosition === "left" ? -90 : (barPosition === "right" ? 90 : 0)

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
  property var availableFonts: ["Geist Mono", "JetBrains Mono", "Inter", "Noto Sans", "Cantarell", "Sans Serif"]
  readonly property string fontSans: fontFamily
  readonly property string fontMono: fontFamily
  readonly property string fontIcon: "JetBrainsMono Nerd Font"

  readonly property int fontSizeSmall: Math.round(12 * uiScale)
  readonly property int fontSizeNormal: Math.round(13 * uiScale)
  readonly property int fontSizeMedium: Math.round(14 * uiScale)
  readonly property int fontSizeLarge: Math.round(15 * uiScale)
  readonly property int fontSizeTitle: Math.round(18 * uiScale)
  readonly property int fontSizeIconSmall: Math.round(14 * uiScale)
  readonly property int fontSizeIconMedium: Math.round(16 * uiScale)
  readonly property int fontSizeIconLarge: Math.round(22 * uiScale)

  // ==========================================
  // ⚙️ SECTION 4: COMPONENT CONFIGURATION
  // ==========================================

  // Workspace Switcher Options
  // Options: "tint" (Soft Translucent Tint), "dot" (Bottom Dot), "border" (Subtle Border Ring)
  property string workspaceIndicatorStyle: "tint"
  property bool showWorkspaceNumbers: true
  property int defaultMinWorkspaces: 5
  property string timeFormat: "24"
  property bool showSeconds: false
  property string language: "ru"

  // MPRIS Media Player Options
  // Options: "progress" (Linear Progress Bar) or "visualizer" (Animated Soundwave)
  property string mprisRightDisplayMode: "visualizer"
  property bool musicVisualizerEnabled: true
  property int mprisVisualizerBarCount: 8
  property int mprisTargetSideWidth: 190

  // Hardware & Hardware Monitoring Options
  property int sysCheckIntervalMs: 3000
  property int netCheckIntervalMs: 5000
  property bool weatherEnabled: true
  property string weatherLocation: ""
  property int weatherRefreshIntervalMs: 900000
  property string weatherText: "--"
  property string weatherDetails: ""
  property string brightnessMonitorBus: "auto"
  property string brightnessSleepMultiplier: ".2"
  property string wallpaperDir: "~/wallpapers/animated"

  // ==========================================
  // 🇷🇺 SECTION 5: RUSSIAN LOCALIZATION
  // ==========================================
  readonly property var weekdayShortNamesRu: ["вс", "пн", "вт", "ср", "чт", "пт", "сб"]
  readonly property var weekdayBarNamesRu: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
  readonly property var calendarWeekdayNamesRu: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
  readonly property var monthShortNamesRu: ["янв", "фев", "мар", "апр", "мая", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]
  readonly property var monthBarNamesRu: ["янв.", "февр.", "мар.", "апр.", "мая", "июн.", "июл.", "авг.", "сент.", "окт.", "нояб.", "дек."]
  readonly property var monthNamesRu: [
    "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
    "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
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
