package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

var langs = []string{"ru", "en", "de", "ja", "zh"}

var entries = [][6]string{
	{"common.on", "Включено", "Enabled", "Aktiviert", "有効", "已启用"},
	{"common.off", "Выключено", "Disabled", "Deaktiviert", "無効", "已禁用"},
	{"common.shown", "Показывается", "Shown", "Angezeigt", "表示", "显示"},
	{"common.shownPlural", "Показываются", "Shown", "Angezeigt", "表示", "显示"},
	{"common.hidden", "Скрыта", "Hidden", "Ausgeblendet", "非表示", "隐藏"},
	{"common.hiddenPlural", "Скрыты", "Hidden", "Ausgeblendet", "非表示", "隐藏"},
	{"common.shownInBar", "Показывается в панели", "Shown in bar", "In der Leiste sichtbar", "バーに表示", "在面板中显示"},
	{"common.shownInBarPlural", "Показываются в панели", "Shown in bar", "In der Leiste sichtbar", "バーに表示", "在面板中显示"},
	{"common.hiddenFromBar", "Скрыт из панели", "Hidden from bar", "Aus der Leiste ausgeblendet", "バーから非表示", "从面板隐藏"},
	{"common.hiddenFromBarF", "Скрыта из панели", "Hidden from bar", "Aus der Leiste ausgeblendet", "バーから非表示", "从面板隐藏"},
	{"common.hiddenFromBarN", "Скрыто из панели", "Hidden from bar", "Aus der Leiste ausgeblendet", "バーから非表示", "从面板隐藏"},
	{"common.hiddenFromBarPlural", "Скрыты из панели", "Hidden from bar", "Aus der Leiste ausgeblendet", "バーから非表示", "从面板隐藏"},
	{"common.nothingFound", "Ничего не найдено", "Nothing found", "Nichts gefunden", "何も見つかりません", "未找到结果"},
	{"clipboard.title", "Буфер обмена", "Clipboard history", "Zwischenablageverlauf", "クリップボード履歴", "剪贴板历史"},
	{"clipboard.clear", "Очистить", "Clear", "Leeren", "消去", "清除"},
	{"appDrawer.searchPlaceholder", "Поиск приложений, окон, команд или выражений", "Search apps, windows, commands, or expressions", "Apps, Fenster, Befehle oder Ausdrücke suchen", "アプリ、ウィンドウ、コマンド、式を検索", "搜索应用、窗口、命令或表达式"},
	{"appDrawer.runCommand", "Выполнить команду", "Run command", "Befehl ausführen", "コマンドを実行", "运行命令"},
	{"bar.workspaces", "Рабочие столы", "Workspaces", "Arbeitsflächen", "ワークスペース", "工作区"},
	{"bar.activeApp", "Активное приложение", "Active app", "Aktive App", "アクティブなアプリ", "活动应用"},
	{"bar.mediaPlayerHyphen", "Медиа-плеер", "Media player", "Mediaplayer", "メディアプレーヤー", "媒体播放器"},
	{"bar.mediaPlayer", "Медиаплеер", "Media player", "Mediaplayer", "メディアプレーヤー", "媒体播放器"},
	{"bar.tray", "Системный трей", "System tray", "System-Tray", "システムトレイ", "系统托盘"},
	{"bar.keyboardLayout", "Раскладка клавиатуры", "Keyboard layout", "Tastaturlayout", "キーボードレイアウト", "键盘布局"},
	{"bar.systemMonitor", "Мониторинг системы", "System monitor", "Systemmonitor", "システムモニター", "系统监视器"},
	{"bar.appMenu", "Меню приложений", "App menu", "Anwendungsmenü", "アプリケーションメニュー", "应用菜单"},
	{"bar.desktop", "Рабочий стол", "Workspace", "Arbeitsbereich", "ワークスペース", "工作区"},
	{"bar.clock", "Дата и время", "Date & time", "Datum und Uhrzeit", "日付と時刻", "日期和时间"},
	{"bar.date", "Дата", "Date", "Datum", "日付", "日期"},
	{"bar.volume", "Громкость", "Volume", "Lautstärke", "音量", "音量"},
	{"bar.brightness", "Яркость", "Brightness", "Helligkeit", "明るさ", "亮度"},
	{"bar.battery", "Батарея", "Battery", "Akku", "バッテリー", "电池"},
	{"bar.controlCenter", "Центр управления", "Control center", "Kontrollzentrum", "コントロールセンター", "控制中心"},
	{"bar.colorPicker", "Пипетка цвета", "Color picker", "Farbpipette", "カラーピッカー", "取色器"},
	{"bar.power", "Питание", "Power", "Energie", "電源", "电源"},
	{"bar.network", "Сеть", "Network", "Netzwerk", "ネットワーク", "网络"},
	{"bar.bluetooth", "Bluetooth", "Bluetooth", "Bluetooth", "Bluetooth", "蓝牙"},
	{"bar.vpn", "VPN", "VPN", "VPN", "VPN", "VPN"},
	{"bar.notifications", "Уведомления", "Notifications", "Benachrichtigungen", "通知", "通知"},
	{"bar.workspacesAllScreens", "Рабочие столы на всех экранах", "Workspaces on all screens", "Arbeitsflächen auf allen Bildschirmen", "すべての画面のワークスペース", "所有屏幕上的工作区"},
	{"bar.ownScreens", "На своих экранах", "On their own screens", "Auf ihren eigenen Bildschirmen", "各画面に表示", "在各自屏幕上"},
	{"bar.workspaceNumbers", "Цифры рабочих столов", "Workspace numbers", "Arbeitsflächennummern", "ワークスペース番号", "工作区编号"},
	{"bar.workspaceIndicator", "Индикатор занятого стола", "Occupied workspace indicator", "Belegter Arbeitsflächenindikator", "使用中ワークスペースのインジケータ", "占用工作区指示器"},
	{"cc.airplane", "Авиарежим", "Airplane mode", "Flugmodus", "機内モード", "飞行模式"},
	{"cc.powerProfile", "Режим питания", "Power mode", "Energiemodus", "電源モード", "电源模式"},
	{"cc.dnd", "Не беспокоить", "Do Not Disturb", "Nicht stören", "おやすみモード", "勿扰模式"},
	{"cc.caffeine", "Не спать", "Stay awake", "Wach bleiben", "スリープしない", "保持唤醒"},
	{"cc.nightLight", "Ночной свет", "Night light", "Nachtlicht", "夜間モード", "夜间模式"},
	{"cc.screenshot", "Снимок области", "Region screenshot", "Bereichsaufnahme", "範囲のスクリーンショット", "区域截图"},
	{"cc.selectRegion", "Выбрать область", "Select region", "Bereich auswählen", "範囲を選択", "选择区域"},
	{"cc.music", "Музыка", "Music", "Musik", "音楽", "音乐"},
	{"cc.unknownArtist", "Неизвестный исполнитель", "Unknown artist", "Unbekannter Künstler", "不明なアーティスト", "未知艺术家"},
	{"cc.noPlayer", "Нет активного плеера", "No active player", "Kein aktiver Player", "アクティブなプレイヤーなし", "无活动播放器"},
	{"cc.on", "Включен", "On", "Ein", "オン", "开启"},
	{"cc.off", "Выключен", "Off", "Aus", "オフ", "关闭"},
	{"cc.notConnected", "Не подключено", "Not connected", "Nicht verbunden", "未接続", "未连接"},
	{"cc.charging", "Заряжается", "Charging", "Wird geladen", "充電中", "充电中"},
	{"cc.onAc", "От сети", "On AC", "Netzbetrieb", "電源接続", "交流电"},
	{"cc.battery", "Аккумулятор", "Battery", "Akku", "バッテリー", "电池"},
	{"cc.powerSaver", "Экономия", "Power saver", "Energiesparmodus", "省電力", "节能"},
	{"cc.performance", "Производительность", "Performance", "Leistungsmodus", "パフォーマンス", "性能"},
	{"cc.balanced", "Баланс", "Balanced", "Ausgeglichen", "バランス", "均衡"},
	{"cc.caffeineBlocked", "Сон и idle заблокированы", "Sleep and idle are blocked", "Ruhemodus und Leerlauf sind blockiert", "スリープとアイドルをブロック中", "睡眠和空闲已阻止"},
	{"cc.caffeineNormal", "Обычный режим сна", "Normal sleep mode", "Normaler Ruhemodus", "通常のスリープモード", "普通睡眠模式"},
	{"calendar.agenda", "Повестка", "Agenda", "Agenda", "予定", "日程"},
	{"calendar.weatherUnavailable", "Погода недоступна", "Weather unavailable", "Wetter nicht verfügbar", "天気情報なし", "天气不可用"},
	{"calendar.weather", "Погода", "Weather", "Wetter", "天気", "天气"},
	{"calendar.humidity", " · влажность ", " · humidity ", " · Luftfeuchtigkeit ", " · 湿度 ", " · 湿度 "},
	{"calendar.forecast", "Прогноз", "Forecast", "Vorhersage", "予報", "预报"},
	{"calendar.noData", "Нет данных", "No data", "Keine Daten", "データなし", "无数据"},
	{"calendar.today", "Сегодня", "Today", "Heute", "今日", "今天"},
	{"calendar.currentCity", "Текущий город", "Current city", "Aktuelle Stadt", "現在の都市", "当前城市"},
	{"notifications.title", "Уведомления", "Notifications", "Benachrichtigungen", "通知", "通知"},
	{"notifications.history", "История", "History", "Verlauf", "履歴", "历史"},
	{"notifications.dnd", "Не беспокоить", "Do Not Disturb", "Nicht stören", "おやすみモード", "勿扰模式"},
	{"notifications.empty", "Нет уведомлений", "No notifications", "Keine Benachrichtigungen", "通知はありません", "没有通知"},
	{"notifications.current", "Текущие", "Current", "Aktuell", "現在", "当前"},
	{"notifications.fallback", "Уведомление", "Notification", "Benachrichtigung", "通知", "通知"},
	{"notifications.maxToasts", "Максимум тостов", "Maximum toasts", "Maximale Toast-Anzahl", "トーストの最大数", "最大通知数"},
	{"notifications.visibleAtOnce", "Одновременно на экране", "Visible at once", "Gleichzeitig sichtbar", "画面に同時表示", "同时显示在屏幕上"},
	{"notifications.toastsOn", "Всплывающие тосты включены", "Popup toasts enabled", "Popup-Toasts aktiviert", "ポップアップトースト有効", "弹出通知已启用"},
	{"notifications.toastsOff", "Всплывающие тосты выключены", "Popup toasts disabled", "Popup-Toasts deaktiviert", "ポップアップトースト無効", "弹出通知已禁用"},
	{"notifications.position", "Место появления уведомлений", "Notification position", "Benachrichtigungsposition", "通知の表示位置", "通知位置"},
	{"system.cpu", "CPU", "CPU", "CPU", "CPU", "处理"},
	{"system.gpu", "GPU", "GPU", "GPU", "GPU", "显卡"},
	{"system.ram", "RAM", "RAM", "RAM", "メモリ", "内存"},
	{"system.up", "UP", "UP", "AKTIV", "稼働", "运行"},
	{"system.title", "СИСТЕМА", "SYSTEM", "SYSTEM", "システム", "系统"},
	{"system.net", "СЕТЬ · МБ/С", "NET · MB/S", "NETZ · MB/S", "ネット · MB/S", "网络 · MB/S"},
	{"system.disk", "ДИСК · %", "DISK · %", "DISK · %", "ディスク · %", "磁盘 · %"},
	{"system.swap", "SWAP · ГБ", "SWAP · GB", "SWAP · GB", "スワップ · GB", "交换 · GB"},
	{"system.vram", "VRAM · ГБ", "VRAM · GB", "VRAM · GB", "VRAM · GB", "显存 · GB"},
	{"system.ramSuffix", " ГБ", " GB", " GB", " GB", " GB"},
	{"system.uptimeFallback", "0м", "0m", "0m", "0分", "0分"},
	{"power.title", "Питание", "Power", "Energie", "電源", "电源"},
	{"power.lock", "Заблокировать", "Lock", "Sperren", "ロック", "锁定"},
	{"power.sleep", "Сон", "Suspend", "Ruhezustand", "サスペンド", "挂起"},
	{"power.logout", "Выйти", "Log out", "Abmelden", "ログアウト", "注销"},
	{"power.reboot", "Перезагрузка", "Reboot", "Neustart", "再起動", "重启"},
	{"power.shutdown", "Выключить", "Shut down", "Herunterfahren", "シャットダウン", "关机"},
	{"osd.volume", "Громкость", "Volume", "Lautstärke", "音量", "音量"},
	{"osd.muted", "Звук выключен", "Sound muted", "Stumm", "ミュート", "已静音"},
	{"osd.brightness", "Яркость", "Brightness", "Helligkeit", "明るさ", "亮度"},
	{"osd.off", "Выкл.", "Off", "Aus", "オフ", "关"},
	{"media.noTrack", "Нет трека", "No track", "Kein Titel", "トラックなし", "无曲目"},
	{"media.unknownArtist", "Неизвестный артист", "Unknown artist", "Unbekannter Künstler", "不明なアーティスト", "未知艺术家"},
	{"wallpaper.none", "Нет обоев", "No wallpapers", "Keine Hintergründe", "壁紙なし", "无壁纸"},
	{"wallpaper.next", "Следующие обои", "Next wallpapers", "Nächste Hintergründe", "次の壁紙", "下一张壁纸"},
	{"wallpaper.folderEmpty", "В папке нет поддерживаемых изображений или видео", "No supported images or videos in this folder", "Keine unterstützten Bilder oder Videos in diesem Ordner", "このフォルダに対応する画像または動画はありません", "此文件夹中没有支持的图片或视频"},
	{"wifi.connected", "Подключено", "Connected", "Verbunden", "接続済み", "已连接"},
	{"wifi.connecting", "Подключение...", "Connecting...", "Verbinde...", "接続中...", "连接中..."},
	{"wifi.saved", "Сохранено", "Saved", "Gespeichert", "保存済み", "已保存"},
	{"wifi.available", "Доступно", "Available", "Verfügbar", "利用可能", "可用"},
	{"wifi.notConnected", "Не подключено", "Not connected", "Nicht verbunden", "未接続", "未连接"},
	{"wifi.off", "Выключено", "Disabled", "Deaktiviert", "無効", "已禁用"},
	{"wifi.adapterNotFound", "Wi-Fi адаптер не найден", "Wi-Fi adapter not found", "Kein Wi-Fi-Adapter gefunden", "Wi-Fiアダプターが見つかりません", "未找到 Wi-Fi 适配器"},
	{"wifi.known", "Знакомые сети", "Known networks", "Bekannte Netzwerke", "既知のネットワーク", "已知网络"},
	{"wifi.other", "Другие сети", "Other networks", "Andere Netzwerke", "その他のネットワーク", "其他网络"},
	{"wifi.hidden", "Скрытая сеть", "Hidden network", "Verstecktes Netzwerk", "隠しネットワーク", "隐藏网络"},
	{"wifi.passwordFor", "Пароль для ", "Password for ", "Passwort für ", "のパスワード ", "密码 "},
	{"wifi.cancel", "Отмена", "Cancel", "Abbrechen", "キャンセル", "取消"},
	{"wifi.connect", "Подключить", "Connect", "Verbinden", "接続", "连接"},
	{"bt.device", "Bluetooth устройство", "Bluetooth device", "Bluetooth-Gerät", "Bluetoothデバイス", "蓝牙设备"},
	{"bt.connected", "Подключено", "Connected", "Verbunden", "接続済み", "已连接"},
	{"bt.connecting", "Подключение...", "Connecting...", "Verbinde...", "接続中...", "连接中..."},
	{"bt.pairing", "Сопряжение...", "Pairing...", "Koppeln...", "ペアリング中...", "配对中..."},
	{"bt.paired", "Сопряжено", "Paired", "Gekoppelt", "ペアリング済み", "已配对"},
	{"bt.available", "Доступно", "Available", "Verfügbar", "利用可能", "可用"},
	{"bt.notConnected", "Не подключено", "Not connected", "Nicht verbunden", "未接続", "未连接"},
	{"bt.off", "Выключено", "Disabled", "Deaktiviert", "無効", "已禁用"},
	{"bt.adapterNotFound", "Bluetooth адаптер не найден", "Bluetooth adapter not found", "Kein Bluetooth-Adapter gefunden", "Bluetoothアダプターが見つかりません", "未找到蓝牙适配器"},
	{"battery.fullChargedConnected", "Полностью заряжена, подключена", "Fully charged, connected", "Voll geladen, angeschlossen", "満充電、接続中", "已充满并连接"},
	{"battery.charging", "Заряжается", "Charging", "Wird geladen", "充電中", "充电中"},
	{"battery.discharging", "Разряжается", "Discharging", "Entlädt sich", "放電中", "放电中"},
	{"battery.full", "Полностью заряжена", "Fully charged", "Voll geladen", "満充電", "已充满"},
	{"battery.onAc", "Подключена к сети", "Connected to AC", "Netzbetrieb", "電源に接続", "已连接电源"},
	{"battery.unknown", "Неизвестно", "Unknown", "Unbekannt", "不明", "未知"},
	{"battery.hoursMinutes", "{h}ч {m}м", "{h}h {m}m", "{h}h {m}m", "{h}時間{m}分", "{h}小时{m}分"},
	{"battery.remaining", "Осталось", "Remaining", "Verbleibend", "残り", "剩余"},
	{"battery.voltage", "Напряжение", "Voltage", "Spannung", "電圧", "电压"},
	{"battery.temperature", "Температура", "Temperature", "Temperatur", "温度", "温度"},
	{"battery.cycles", "Циклы", "Cycles", "Zyklen", "サイクル", "循环次数"},
	{"battery.chargeLabel", "Заряд", "Charge", "Ladung", "充電", "充电"},
	{"battery.remainingLabel", "Остаток", "Remaining", "Verbleibend", "残り", "剩余"},
	{"battery.powerProfile", "Профиль питания", "Power profile", "Energieprofil", "電源プロファイル", "电源模式"},
	{"battery.title", "Батарея", "Battery", "Akku", "バッテリー", "电池"},
	{"battery.voltageUnit", " В", " V", " V", " V", " V"},
	{"brightness.title", "Яркость экрана", "Screen brightness", "Bildschirmhelligkeit", "画面の明るさ", "屏幕亮度"},
	{"brightness.presets", "Пресеты", "Presets", "Voreinstellungen", "プリセット", "预设"},
	{"audio.title", "Звук", "Sound", "Ton", "サウンド", "声音"},
	{"audio.speakers", "Динамики", "Speakers", "Lautsprecher", "スピーカー", "扬声器"},
	{"audio.mic", "Микрофон", "Microphone", "Mikrofon", "マイク", "麦克风"},
	{"audio.noOutputs", "Устройства вывода не найдены", "No output devices found", "Keine Ausgabegeräte gefunden", "出力デバイスが見つかりません", "未找到输出设备"},
	{"audio.noInputs", "Устройства ввода не найдены", "No input devices found", "Keine Eingabegeräte gefunden", "入力デバイスが見つかりません", "未找到输入设备"},
	{"keyboard.title", "Раскладка", "Layout", "Layout", "レイアウト", "布局"},
	{"settings.title", "Настройки", "Settings", "Einstellungen", "設定", "设置"},
	{"settings.searchPlaceholder", "Поиск настроек", "Search settings", "Einstellungen suchen", "設定を検索", "搜索设置"},
	{"settings.sections.appearance", "Оформление", "Appearance", "Darstellung", "外観", "外观"},
	{"settings.sections.appearanceDesc", "Тема, шрифты, язык и анимации.", "Theme, fonts, language and animations.", "Design, Schriftarten, Sprache und Animationen.", "テーマ、フォント、言語、アニメーション。", "主题、字体、语言和动画。"},
	{"settings.sections.bar", "Бар и попапы", "Bar & popups", "Leiste & Popups", "バーとポップアップ", "栏和弹出窗口"},
	{"settings.sections.barDesc", "Панель, попапы и метрики системы.", "Bar, popups and system metrics.", "Leiste, Popups und Systemwerte.", "バー、ポップアップ、システムメトリクス。", "栏、弹出窗口和系统指标。"},
	{"settings.sections.desktop", "Обои", "Wallpapers", "Hintergrund", "壁紙", "壁纸"},
	{"settings.sections.desktopDesc", "Обои и автозамена.", "Wallpapers and auto-cycling.", "Hintergründe und automatischer Wechsel.", "壁紙と自動切り替え。", "壁纸和自动更换。"},
	{"settings.sections.time", "Время и локация", "Time & location", "Zeit & Ort", "時刻と場所", "时间与位置"},
	{"settings.sections.timeDesc", "Формат времени и погода.", "Time format and weather location.", "Zeitformat und Wetterort.", "時間形式と天気の場所。", "时间格式和天气位置。"},
	{"settings.sections.notifications", "Уведомления", "Notifications", "Benachrichtigungen", "通知", "通知"},
	{"settings.sections.notificationsDesc", "Уведомления, DND и OSD.", "Toasts, DND and OSD.", "Benachrichtigungen, DND und OSD.", "通知、DND、OSD。", "通知、免打扰和 OSD。"},
	{"settings.sections.system", "Система", "System", "System", "システム", "系统"},
	{"settings.sections.systemDesc", "Язык, хоткеи и питание.", "Language, keybinds and power.", "Sprache, Kürzel und Energie.", "言語、キーバインド、電源。", "语言、按键和电源。"},
	{"settings.sections.advanced", "Дополнительно", "Advanced", "Erweitert", "詳細", "高级"},
	{"settings.sections.advancedDesc", "Питание и подсветка.", "Power and backlight options.", "Energie und Helligkeit.", "電源と輝度のオプション。", "电源和亮度选项。"},
	{"settings.sections.about", "О программе", "About", "Über", "このプログラムについて", "关于"},
	{"settings.sections.aboutDesc", "Версия и компоненты.", "Version and runtime info.", "Version und Laufzeit.", "バージョンと実行情報。", "版本和运行信息。"},
	{"settings.sections.battery", "Батарея", "Battery", "Akku", "バッテリー", "电池"},
	{"settings.sections.batteryDesc", "Заряд и профиль питания", "Charge and power profile", "Ladezustand und Energiesparmodus", "充電と電源プロファイル", "充电和电源计划"},
	{"settings.sections.brightness", "Яркость", "Brightness", "Helligkeit", "明るさ", "亮度"},
	{"settings.sections.brightnessDesc", "Подсветка экрана", "Screen backlight", "Bildschirm-Hintergrundbeleuchtung", "画面のバックライト", "屏幕背光"},
	{"settings.sections.audio", "Звук", "Sound", "Ton", "サウンド", "声音"},
	{"settings.sections.audioDesc", "Динамики и микрофон", "Speakers and microphone", "Lautsprecher und Mikrofon", "スピーカーとマイク", "扬声器和麦克风"},
	{"settings.sections.wifi", "Wi-Fi", "Wi-Fi", "WLAN", "Wi-Fi", "Wi-Fi"},
	{"settings.sections.wifiDesc", "Беспроводные сети", "Wireless networks", "Drahtlose Netzwerke", "ワイヤレスネットワーク", "无线网络"},
	{"settings.sections.bluetooth", "Bluetooth", "Bluetooth", "Bluetooth", "Bluetooth", "蓝牙"},
	{"settings.sections.bluetoothDesc", "Беспроводные устройства", "Wireless devices", "Drahtlose Geräte", "ワイヤレスデバイス", "无线设备"},
	{"settings.pages.general", "Интерфейс", "Interface", "Oberfläche", "インターフェース", "界面"},
	{"settings.pages.palette", "Цветовая палитра", "Color palette", "Farbpalette", "カラーパレット", "调色板"},
	{"settings.pages.barPage", "Панель", "Bar", "Leiste", "バー", "栏"},
	{"settings.pages.popups", "Попапы", "Popups", "Popups", "ポップアップ", "弹出面板"},
	{"settings.pages.monitoring", "Мониторинг", "Monitoring", "Überwachung", "モニタリング", "监控"},
	{"settings.pages.wallpaper", "Обои", "Wallpapers", "Hintergrund", "壁紙", "壁纸"},
	{"settings.pages.location", "Время и локация", "Time & location", "Zeit & Ort", "時刻と場所", "时间与位置"},
	{"settings.pages.osd", "OSD", "OSD", "OSD", "OSD", "OSD"},
	{"settings.pages.systemPage", "Сочетания клавиш", "Keybinds", "Tastenkombinationen", "キーバインド", "快捷键"},
	{"settings.pages.advancedPage", "Яркость", "Brightness", "Helligkeit", "明るさ", "亮度"},
	{"settings.pages.aboutPage", "О программе", "About", "Über", "このプログラムについて", "关于"},
	{"settings.pages.batteryPage", "Батарея", "Battery", "Akku", "バッテリー", "电池"},
	{"settings.pages.brightnessPage", "Яркость", "Brightness", "Helligkeit", "明るさ", "亮度"},
	{"settings.pages.audioPage", "Звук", "Sound", "Ton", "サウンド", "声音"},
	{"settings.pages.wifiPage", "Wi-Fi", "Wi-Fi", "WLAN", "Wi-Fi", "Wi-Fi"},
	{"settings.pages.bluetoothPage", "Bluetooth", "Bluetooth", "Bluetooth", "Bluetooth", "蓝牙"},
	{"settings.fontPreview", "19:37 пн, июл. 20  ·  Быстрая лиса 123", "19:37 Mon, Jul 20  ·  The quick fox 123", "19:37 Mo, 20. Jul  ·  Schneller Fuchs 123", "19:37 月, 7月20日  ·  素早い狐 123", "19:37 周一, 7月20日  ·  敏捷的狐狸 123"},
	{"settings.general.reduceMotion", "Меньше анимаций", "Reduce motion", "Weniger Animationen", "モーションを減らす", "减少动画"},
	{"settings.general.reduced", "Анимации сокращены", "Animations reduced", "Animationen reduziert", "アニメーションを削減", "动画已减少"},
	{"settings.general.normal", "Обычные анимации", "Normal animations", "Normale Animationen", "通常のアニメーション", "普通动画"},
	{"settings.general.tooltips", "Подсказки", "Tooltips", "Tooltips", "ツールチップ", "提示"},
	{"settings.general.sansFont", "Основной шрифт", "Main font", "Hauptschrift", "メインフォント", "主字体"},
	{"settings.general.monoFont", "Моноширинный шрифт", "Monospaced font", "Monospace-Schrift", "等幅フォント", "等宽字体"},
	{"settings.general.fontSearch", "Поиск шрифта", "Search font", "Schrift suchen", "フォント検索", "搜索字体"},
	{"settings.general.uiScale", "Размер текста", "Text size", "Textgröße", "テキストサイズ", "文字大小"},
	{"settings.general.notificationSound", "Звук уведомлений", "Notification sound", "Benachrichtigungston", "通知音", "通知声音"},
	{"settings.general.mutedApps", "Отключённые приложения", "Muted apps", "Stumme Apps", "ミュートしたアプリ", "静音应用"},
	{"settings.general.mutedAppsHint", "Имена приложений через запятую", "Comma-separated application names", "Kommagetrennte App-Namen", "カンマ区切りのアプリ名", "以逗号分隔的应用名称"},
	{"settings.general.tileOrder", "Порядок плиток центра управления", "Control center tile order", "Reihenfolge der Kontrollzentrum-Kacheln", "コントロールセンタータイルの順序", "控制中心磁贴顺序"},
	{"settings.general.tileOrderHint", "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight", "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight", "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight", "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight", "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight"},
	{"settings.general.idlePolicy", "Правило простоя", "Idle policy", "Leerlaufrichtlinie", "アイドルポリシー", "空闲策略"},
	{"settings.general.idleHint", "0 отключает; применяется после простоя", "0 disables; applies after the idle timeout", "0 deaktiviert; wird nach der Leerlaufzeit angewendet", "0 は無効。アイドル時間後に適用されます", "0 为禁用；空闲超时后应用"},
	{"settings.general.idleHint2", "0 отключает; доступно при источнике idle", "0 disables; requires an idle event source", "0 deaktiviert; benötigt eine Leerlaufereignisquelle", "0 は無効。アイドルイベントソースが必要", "0 为禁用；需要空闲事件源"},
	{"settings.general.barWidgets", "Виджеты панели", "Bar widgets", "Leisten-Widgets", "バーのウィジェット", "面板组件"},
	{"settings.general.language", "Язык", "Language", "Sprache", "言語", "语言"},
	{"settings.general.lock", "Блокировка", "Lock", "Sperren", "ロック", "锁定"},
	{"settings.general.femOn", "Включена", "Enabled", "Aktiviert", "有効", "已启用"},
	{"settings.general.femOff", "Выключена", "Disabled", "Deaktiviert", "無効", "已禁用"},
	{"settings.general.screenIndicators", "Экранные индикаторы", "Screen indicators", "Bildschirmanzeigen", "画面インジケータ", "屏幕指示器"},
	{"settings.general.showTime", "Время показа", "Show duration", "Anzeigedauer", "表示時間", "显示时长"},
	{"settings.general.volumeBrightness", "Громкость и яркость", "Volume and brightness", "Lautstärke und Helligkeit", "音量と明るさ", "音量和亮度"},
	{"settings.general.secSuffixShort", " с", " s", " s", " 秒", " 秒"},
	{"settings.popups.positionOfPanel", "Положение панели", "Panel position", "Leistenposition", "パネルの位置", "面板位置"},
	{"settings.popups.backgroundOpacity", "Непрозрачность фона", "Background opacity", "Hintergrunddeckkraft", "背景不透明度", "背景不透明度"},
	{"settings.popups.popups", "Попапы", "Popups", "Popups", "ポップアップ", "弹出面板"},
	{"settings.popups.popupPanels", "Всплывающие панели", "Popup panels", "Popup-Panels", "ポップアップパネル", "弹出面板"},
	{"settings.popups.position", "Положение всплывающих панелей", "Popup position", "Popup-Position", "ポップアップの位置", "弹出面板位置"},
	{"settings.popups.radius", "Закругление панелей", "Popup rounding", "Abrundung der Popups", "ポップアップの角丸", "弹出面板圆角"},
	{"settings.popups.outline", "Обводка всплывающих панелей", "Popup outline", "Popup-Umrandung", "ポップアップの輪郭", "弹出面板描边"},
	{"settings.popups.shadow", "Тень всплывающих панелей", "Popup shadow", "Popup-Schatten", "ポップアップの影", "弹出面板阴影"},
	{"settings.popups.opacity", "Непрозрачность панелей", "Popup opacity", "Popup-Deckkraft", "ポップアップの不透明度", "弹出面板不透明度"},
	{"settings.popups.blur", "Размытие всплывающих панелей", "Popup blur", "Popup-Unschärfe", "ポップアップのぼかし", "弹出面板模糊"},
	{"settings.popups.menuBg", "Фон выпадающих меню и уведомлений", "Background of dropdowns and notifications", "Hintergrund von Dropdowns und Benachrichtigungen", "ドロップダウンと通知の背景", "下拉菜单和通知的背景"},
	{"settings.popups.dropdownRadius", "Радиус углов выпадающих меню", "Corner radius of dropdowns", "Eckenradius der Dropdowns", "ドロップダウンの角丸半径", "下拉菜单角半径"},
	{"settings.popups.osdPosition", "Положение OSD", "OSD position", "OSD-Position", "OSDの位置", "OSD 位置"},
	{"settings.popups.toastPosition", "Положение тостов", "Toast position", "Toast-Position", "トーストの位置", "通知位置"},
	{"settings.popups.edges", "Выбор для левой и правой панели", "Choice for the left and right panel", "Auswahl für linke und rechte Leiste", "左右パネルの選択", "左右面板的选择"},
	{"settings.popups.wh", "Высота или ширина панели", "Panel height or width", "Leistenhöhe oder -breite", "パネルの高さまたは幅", "面板的高度或宽度"},
	{"settings.popups.sameSideGap", "Одинаковое расстояние от боковых краёв", "Same distance from the side edges", "Gleicher Abstand von den Seitenrändern", "側端からの距離を同じにする", "与侧边距离相同"},
	{"settings.popups.topPadding", "Отступ сверху", "Top padding", "Abstand oben", "上パディング", "顶部内边距"},
	{"settings.popups.topDistance", "Расстояние от верхнего края", "Distance from the top edge", "Abstand vom oberen Rand", "上端からの距離", "距顶部边缘的距离"},
	{"settings.popups.bottomPadding", "Отступ снизу", "Bottom padding", "Abstand unten", "下パディング", "底部内边距"},
	{"settings.popups.bottomDistance", "Расстояние от нижнего края", "Distance from the bottom edge", "Abstand vom unteren Rand", "下端からの距離", "距底部边缘的距离"},
	{"settings.popups.sidePadding", "Отступы слева и справа", "Left and right padding", "Abstand links und rechts", "左右のパディング", "左右内边距"},
	{"settings.popups.left", "Слева", "Left", "Links", "左", "左"},
	{"settings.popups.right", "Справа", "Right", "Rechts", "右", "右"},
	{"settings.popups.top", "Сверху", "Top", "Oben", "上", "上"},
	{"settings.popups.bottom", "Снизу", "Bottom", "Unten", "下", "下"},
	{"settings.popups.dot", "Точка", "Dot", "Punkt", "ドット", "点"},
	{"settings.popups.border", "Рамка", "Border", "Rahmen", "枠", "边框"},
	{"settings.popups.highlight", "Подсветка", "Highlight", "Hervorhebung", "ハイライト", "高亮"},
	{"settings.barPage.design", "Дизайн панели", "Bar design", "Leisten-Design", "バーのデザイン", "面板设计"},
	{"settings.barPage.islands", "Островки", "Islands", "Inseln", "アイランド", "岛屿"},
	{"settings.barPage.solid", "Сплошной", "Solid", "Durchgehend", "一体化", "连续"},
	{"settings.barPage.thickness", "Толщина панели", "Panel thickness", "Leistendicke", "バーの厚さ", "面板厚度"},
	{"settings.barPage.radius", "Закругление бара", "Bar rounding", "Abrundung der Leiste", "バーの角丸", "栏圆角"},
	{"settings.barPage.radiusCorner", "Радиус углов панели", "Corner radius of the bar", "Eckenradius der Leiste", "バーの角丸半径", "栏的角半径"},
	{"settings.barPage.radiusMode", "Режим закругления", "Corner mode", "Eckenmodus", "角丸モード", "圆角模式"},
	{"settings.barPage.full", "Полный", "Full", "Gemeinsam", "一体", "统一"},
	{"settings.barPage.separate", "Раздельный", "Separate", "Getrennt", "個別", "独立"},
	{"settings.barPage.widgetRadius", "Закругление виджетов бара", "Bar widget rounding", "Abrundung der Leisten-Widgets", "バーウィジェットの角丸", "栏小部件圆角"},
	{"settings.barPage.widgetRadiusCorner", "Радиус углов элементов панели", "Corner radius of panel elements", "Eckenradius der Leistenelemente", "パネル要素の角丸半径", "面板元素圆角半径"},
	{"settings.barPage.popupElementRadius", "Закругление элементов панелей", "Popup element rounding", "Abrundung der Popup-Elemente", "ポップアップ要素の角丸", "弹出面板元素圆角"},
	{"settings.barPage.cardButtonRadius", "Радиус углов карточек и кнопок", "Corner radius of cards and buttons", "Eckenradius von Karten und Schaltflächen", "カードとボタンの角丸半径", "卡片和按钮圆角半径"},
	{"settings.barPage.opacity", "Непрозрачность фона панели", "Panel background opacity", "Hintergrunddeckkraft der Leiste", "バーの背景不透明度", "面板背景不透明度"},
	{"settings.barPage.blur", "Размытие фона", "Background blur", "Hintergrundunschärfe", "背景ぼかし", "背景模糊"},
	{"settings.barPage.outline", "Обводка бара", "Bar outline", "Leistenumrandung", "バーの輪郭", "栏描边"},
	{"settings.barPage.shadow", "Тень бара", "Bar shadow", "Leistenschatten", "バーの影", "栏阴影"},
	{"settings.barPage.autoHide", "Автоскрытие", "Auto-hide", "Automatisch ausblenden", "自動非表示", "自动隐藏"},
	{"settings.barPage.hidesAutomatically", "Скрывается автоматически", "Hides automatically", "Wird automatisch ausgeblendet", "自動的に隠れる", "自动隐藏"},
	{"settings.barPage.alwaysShown", "Всегда отображается", "Always shown", "Immer sichtbar", "常に表示", "始终显示"},
	{"settings.barPage.hideDelay", "Задержка скрытия", "Hide delay", "Ausblendeverzögerung", "非表示までの時間", "隐藏延迟"},
	{"settings.barPage.hideDelayHint", "Через сколько секунд скрывать панель", "Seconds before the panel hides", "Sekunden bis zum Ausblenden", "非表示までの秒数", "面板隐藏前的秒数"},
	{"settings.barPage.adaptive", "Адаптивный бар", "Adaptive bar", "Adaptive Leiste", "アダプティブバー", "自适应栏"},
	{"settings.barPage.adaptiveHint", "Прозрачный без окна на весь экран", "Transparent without a fullscreen window", "Transparent ohne Vollbildfenster", "全画面ウィンドウがないときは透明", "无全屏窗口时透明"},
	{"settings.monitoring.metrics", "Метрики в панели", "Bar metrics", "Metriken in der Leiste", "バーのメトリクス", "面板指标"},
	{"settings.monitoring.cpuUsage", "Загрузка CPU", "CPU usage", "CPU-Auslastung", "CPU使用率", "CPU使用率"},
	{"settings.monitoring.cpuTemp", "Температура CPU", "CPU temperature", "CPU-Temperatur", "CPU温度", "CPU温度"},
	{"settings.monitoring.gpuUsage", "Загрузка GPU", "GPU usage", "GPU-Auslastung", "GPU使用率", "GPU使用率"},
	{"settings.monitoring.gpuTemp", "Температура GPU", "GPU temperature", "GPU-Temperatur", "GPU温度", "GPU温度"},
	{"settings.monitoring.memory", "Оперативная память", "Memory", "Arbeitsspeicher", "メモリ", "内存"},
	{"settings.monitoring.cpuPercent", "Процент использования процессора", "Processor usage percentage", "Prozessorauslastung in Prozent", "プロセッサ使用率", "处理器使用百分比"},
	{"settings.monitoring.cpuTempLong", "Температура процессора", "Processor temperature", "Prozessortemperatur", "プロセッサ温度", "处理器温度"},
	{"settings.monitoring.gpuPercent", "Процент использования видеокарты", "GPU usage percentage", "GPU-Auslastung in Prozent", "GPU使用率", "显卡使用百分比"},
	{"settings.monitoring.gpuTempLong", "Температура видеокарты", "GPU temperature", "GPU-Temperatur", "GPU温度", "显卡温度"},
	{"settings.monitoring.ramUsage", "Использование RAM", "RAM usage", "RAM-Nutzung", "RAM使用量", "RAM使用量"},
	{"settings.monitoring.downloadSpeed", "Скорость загрузки", "Download speed", "Download-Geschwindigkeit", "ダウンロード速度", "下载速度"},
	{"settings.monitoring.sysMetrics", "Системные метрики", "System metrics", "Systemmetriken", "システムメトリクス", "系统指标"},
	{"settings.monitoring.sysMetricsHint", "CPU, память, сеть и накопители отображаются на панели и в системном попапе.", "CPU, memory, network and storage are shown in the bar and system popup.", "CPU, Speicher, Netzwerk und Speicher werden in der Leiste und im System-Popup angezeigt.", "CPU、メモリ、ネットワーク、ストレージがバーとシステムポップアップに表示されます。", "CPU、内存、网络和存储会显示在面板和系统弹出窗口中。"},
	{"settings.monitoring.secSuffix", " сек.", " s", " s", " 秒", " 秒"},
	{"settings.palette.theme", "Тема", "Theme", "Theme", "テーマ", "主题"},
	{"settings.palette.manualAccent", "Ручной акцент", "Manual accent", "Manuelle Akzentfarbe", "手動アクセント", "手动强调色"},
	{"settings.palette.clickToPick", "Кликни по цвету, чтобы выбрать его", "Click a color to select it", "Klicke eine Farbe an, um sie zu wählen", "色をクリックして選択", "点击颜色进行选择"},
	{"settings.palette.wallpaperAccent", "Акцент из обоев", "Wallpaper accent", "Akzent aus Hintergrund", "壁紙のアクセント", "壁纸强调色"},
	{"settings.palette.lightPalette", "Светлая палитра", "Light palette", "Helle Palette", "ライトパレット", "浅色调色板"},
	{"settings.palette.darkPalette", "Тёмная палитра", "Dark palette", "Dunkle Palette", "ダークパレット", "深色调色板"},
	{"settings.palette.darkTheme", "Тёмная тема", "Dark theme", "Dunkles Thema", "ダークテーマ", "深色主题"},
	{"settings.palette.darkFromWall", "Тёмные цвета из обоев", "Dark colors from wallpaper", "Dunkle Farben aus dem Hintergrund", "壁紙からダークカラー", "从壁纸提取深色"},
	{"settings.palette.lightFromWall", "Светлые цвета из обоев", "Light colors from wallpaper", "Helle Farben aus dem Hintergrund", "壁紙からライトカラー", "从壁纸提取浅色"},
	{"settings.palette.light", "Свет", "Light", "Hell", "ライト", "浅色"},
	{"settings.palette.dark", "Тьма", "Dark", "Dunkel", "ダーク", "深色"},
	{"settings.palette.dynamic", "Дин.", "Dyn.", "Dyn.", "動的", "动态"},
	{"settings.palette.custom", "Своя", "Custom", "Eigen", "カスタム", "自定义"},
	{"settings.palette.accent", "Акцент", "Accent", "Akzent", "アクセント", "强调色"},
	{"settings.palette.accentDark", "тёмная", "dark", "dunkel", "ダーク", "深色"},
	{"settings.palette.accentLight", "светлая", "light", "hell", "ライト", "浅色"},
	{"settings.palette.presets", "Пресеты", "Presets", "Presets", "プリセット", "预设"},
	{"settings.palette.preset", "Пресет", "Preset", "Preset", "プリセット", "预设"},
	{"settings.palette.palettePreset", "Пресет палитры", "Palette preset", "Palettenvoreinstellung", "パレットプリセット", "调色板预设"},
	{"settings.palette.extractMethod", "Как извлекать цвета из обоев", "How to extract colors from wallpapers", "Wie Farben aus Hintergründen extrahiert werden", "壁紙から色を抽出する方法", "如何从壁纸提取颜色"},
	{"settings.palette.tenths", "Точность до десятых", "Precision to tenths", "Genauigkeit auf Zehntel", "小数点以下1桁の精度", "精确到十分之一"},
	{"settings.palette.withTenths", "С десятыми", "With tenths", "Mit Zehnteln", "小数点あり", "带小数"},
	{"settings.palette.wholeDegrees", "Целые градусы", "Whole degrees", "Ganze Grad", "整数度", "整数度"},
	{"settings.palette.current", "Текущий", "Current", "Aktuell", "現在", "当前"},
	{"settings.location.timeFormat", "Формат времени", "Time format", "Zeitformat", "時刻形式", "时间格式"},
	{"settings.location.h12", "12-часовой формат", "12-hour format", "12-Stunden-Format", "12時間形式", "12小时制"},
	{"settings.location.h24", "24-часовой формат", "24-hour format", "24-Stunden-Format", "24時間形式", "24小时制"},
	{"settings.location.showSeconds", "Секунды в часах", "Clock seconds", "Sekunden in der Uhr", "秒を表示", "显示秒数"},
	{"settings.location.weatherCity", "Город погоды", "Weather city", "Wetterstadt", "天気の都市", "天气城市"},
	{"settings.location.autoIp", "Автоматически по IP", "Automatic by IP", "Automatisch per IP", "IPで自動", "按 IP 自动"},
	{"settings.location.autoIpShort", "авто по IP", "auto by IP", "auto per IP", "IPで自動", "按 IP 自动"},
	{"settings.location.weather", "Погода", "Weather", "Wetter", "天気", "天气"},
	{"settings.location.weatherInBar", "Погода на панели", "Weather in bar", "Wetter in der Leiste", "バーの天気", "面板天气"},
	{"settings.system.keybinds", "Сочетания клавиш", "Keybinds", "Tastenkombinationen", "キーバインド", "快捷键"},
	{"settings.system.nav", "Навигация настроек", "Settings navigation", "Einstellungsnavigation", "設定のナビゲーション", "设置导航"},
	{"settings.system.nextSection", "Следующий раздел", "Next section", "Nächster Bereich", "次のセクション", "下一部分"},
	{"settings.system.prevSection", "Предыдущий раздел", "Previous section", "Vorheriger Bereich", "前のセクション", "上一部分"},
	{"settings.system.nextTab", "Следующая вкладка", "Next tab", "Nächster Reiter", "次のタブ", "下一个标签页"},
	{"settings.system.prevTab", "Предыдущая вкладка", "Previous tab", "Vorheriger Reiter", "前のタブ", "上一个标签页"},
	{"settings.system.closeSettings", "Закрыть настройки", "Close settings", "Einstellungen schließen", "設定を閉じる", "关闭设置"},
	{"settings.system.closeSettingsHint", "Сочетание клавиш для закрытия окна настроек", "Shortcut to close the settings window", "Tastenkombination zum Schließen der Einstellungen", "設定ウィンドウを閉じるショートカット", "关闭设置窗口的快捷键"},
	{"settings.system.monitorBus", "Шина монитора", "Monitor bus", "Monitorbus", "モニターバス", "显示器总线"},
	{"settings.system.ddcDelay", "Задержка DDC/CI", "DDC/CI delay", "DDC/CI-Verzögerung", "DDC/CI 遅延", "DDC/CI 延迟"},
	{"settings.system.ddcMultiplier", "Множитель паузы между командами", "Delay multiplier between commands", "Verzögerungsmultiplikator zwischen Befehlen", "コマンド間の遅延倍率", "命令间延迟倍数"},
	{"settings.system.pickColor", "Выбрать цвет с экрана", "Pick color from screen", "Farbe vom Bildschirm auswählen", "画面から色を選択", "从屏幕取色"},
	{"settings.about.installed", "Установленная версия", "Installed version", "Installierte Version", "インストール済みバージョン", "已安装版本"},
	{"settings.about.latest", "Последняя версия", "Latest version", "Neueste Version", "最新バージョン", "最新版本"},
	{"settings.about.contributors", "Контрибьюторы", "Contributors", "Mitwirkende", "コントリビューター", "贡献者"},
	{"settings.about.description", "Naton is a customizable Wayland desktop shell built with Quickshell, QML, and Go.", "Naton is a customizable Wayland desktop shell built with Quickshell, QML, and Go.", "Naton ist eine anpassbare Wayland-Desktop-Shell, entwickelt mit Quickshell, QML und Go.", "Naton は Quickshell、QML、Go で構築されたカスタマイズ可能な Wayland デスクトップシェルです。", "Naton 是一个使用 Quickshell、QML 和 Go 构建的可定制 Wayland 桌面外壳。"},
	{"settings.about.commitSuffix", "коммит", "commit", "Commit", "コミット", "提交"},
	{"settings.about.commitSuffixGen", "коммита", "commits", "Commits", "コミット", "提交"},
	{"settings.about.commitSuffixPlural", "коммитов", "commits", "Commits", "コミット", "提交"},
	{"settings.wallpaper.settings", "Настройки обоев", "Wallpaper settings", "Hintergrundeinstellungen", "壁紙の設定", "壁纸设置"},
	{"settings.wallpaper.folder", "Папка обоев", "Wallpaper folder", "Hintergrundordner", "壁紙フォルダ", "壁纸文件夹"},
	{"settings.wallpaper.search", "Поиск обоев", "Search wallpapers", "Hintergründe suchen", "壁紙を検索", "搜索壁纸"},
	{"settings.wallpaper.video", "Видеообои", "Video wallpapers", "Video-Hintergründe", "動画の壁紙", "视频壁纸"},
	{"settings.wallpaper.videoSound", "Звук видеообоев", "Video wallpaper sound", "Video-Hintergrund Ton", "動画の壁紙の音", "视频壁纸声音"},
	{"settings.wallpaper.videoVolume", "Громкость видеообоев", "Video wallpaper volume", "Video-Hintergrund Lautstärke", "動画の壁紙の音量", "视频壁纸音量"},
	{"settings.wallpaper.playbackVolume", "Громкость воспроизведения", "Playback volume", "Wiedergabelautstärke", "再生音量", "播放音量"},
	{"settings.wallpaper.hwDecode", "Аппаратное декодирование", "Hardware decoding", "Hardware-Dekodierung", "ハードウェアデコード", "硬件解码"},
	{"settings.wallpaper.pauseOverview", "Пауза видео в Overview", "Pause video in Overview", "Video in der Übersicht pausieren", "Overview で動画を一時停止", "在 Overview 中暂停视频"},
	{"settings.wallpaper.autoChange", "Автоматическая смена", "Automatic cycling", "Automatischer Wechsel", "自動変更", "自动更换"},
	{"settings.wallpaper.interval", "Интервал смены", "Cycle interval", "Wechselintervall", "切り替え間隔", "更换间隔"},
	{"settings.wallpaper.intervalHint", "Секунды между обоями из текущей папки", "Seconds between wallpapers from the current folder", "Sekunden zwischen Hintergründen aus dem aktuellen Ordner", "現在のフォルダの壁紙を切り替える秒数", "当前文件夹壁纸的更换秒数"},
	{"settings.wallpaper.transition", "Переход при смене обоев", "Wallpaper transition", "Hintergrundübergang", "壁紙の切り替え効果", "壁纸过渡"},
	{"settings.wallpaper.effect", "Эффект смены", "Transition effect", "Übergangseffekt", "切り替え効果", "过渡效果"},
	{"settings.wallpaper.scaling", "Масштабирование изображения", "Image scaling", "Bildskalierung", "画像のスケーリング", "图像缩放"},
	{"settings.wallpaper.display", "Отображение обоев", "Wallpaper display", "Hintergrundanzeige", "壁紙の表示", "壁纸显示"},
	{"settings.wallpaper.blurOverview", "Размывать обои в Overview", "Blur wallpapers in Overview", "Hintergründe in der Übersicht unscharf machen", "Overview で壁紙をぼかす", "在 Overview 中模糊壁纸"},
	{"settings.wallpaper.clockMedia", "Часы и медиа", "Clock and media", "Uhr und Medien", "時計とメディア", "时钟和媒体"},
	{"settings.dropdown.stretch", "Растянуть", "Stretch", "Strecken", "引き伸ばし", "拉伸"},
	{"settings.dropdown.fit", "Вместить", "Fit", "Einpassen", "収まる", "适应"},
	{"settings.dropdown.fill", "Заполнить", "Fill", "Füllen", "埋める", "填充"},
	{"settings.dropdown.tile", "Замостить", "Tile", "Kacheln", "タイル", "平铺"},
	{"settings.dropdown.tileV", "Замостить по вертикали", "Tile vertically", "Vertikal kacheln", "縦タイル", "垂直平铺"},
	{"settings.dropdown.tileH", "Замостить по горизонтали", "Tile horizontally", "Horizontal kacheln", "横タイル", "水平平铺"},
	{"settings.dropdown.pad", "С полями", "With padding", "Mit Rand", "余白あり", "带边距"},
	{"settings.dropdown.noEffect", "Без эффекта", "No effect", "Kein Effekt", "効果なし", "无效果"},
	{"settings.dropdown.simple", "Простой", "Simple", "Einfach", "シンプル", "简单"},
	{"settings.dropdown.fade", "Плавное появление", "Fade in", "Einblenden", "フェード", "淡入"},
	{"settings.dropdown.wipe", "Стирание", "Wipe", "Wischen", "ワイプ", "擦除"},
	{"settings.dropdown.wave", "Волна", "Wave", "Welle", "波", "波浪"},
	{"settings.dropdown.grow", "Раскрытие", "Grow", "Wachsen", "拡大", "展开"},
	{"settings.dropdown.center", "Круг из центра", "Circle from center", "Kreis von der Mitte", "中心から円", "从中心圆"},
	{"settings.dropdown.any", "Круг из случайной точки", "Circle from random point", "Kreis von zufälligem Punkt", "ランダムな点から円", "从随机点圆"},
	{"settings.dropdown.outer", "Круг к центру", "Circle to center", "Kreis zur Mitte", "中心へ円", "向中心圆"},
	{"settings.dropdown.random", "Случайный", "Random", "Zufällig", "ランダム", "随机"},
	{"settings.dropdown.vibrant", "Яркий", "Vibrant", "Lebendig", "鮮やか", "鲜艳"},
	{"settings.dropdown.faithful", "Точный", "Faithful", "Originalgetreu", "忠実", "精确"},
	{"settings.dropdown.dysfunctional", "Диссонансный", "Dysfunctional", "Dysfunktional", "不協和", "不协调"},
	{"settings.dropdown.muted", "Приглушённый", "Muted", "Gedämpft", "落ち着いた", "柔和"},
	{"settings.dropdown.soft", "Мягкий", "Soft", "Weich", "ソフト", "柔和"},
	{"settings.dropdown.material", "Material", "Material", "Material", "マテリアル", "Material"},
	{"settings.dropdown.monochrome", "Монохромный", "Monochrome", "Monochrom", "モノクロ", "单色"},
	{"settings.dropdown.tl", "ВЛ", "Top left", "Oben links", "左上", "左上"},
	{"settings.dropdown.tc", "Верх", "Top center", "Oben Mitte", "上中央", "顶部居中"},
	{"settings.dropdown.tr", "ВП", "Top right", "Oben rechts", "右上", "右上"},
	{"settings.dropdown.bl", "НЛ", "Bottom left", "Unten links", "左下", "左下"},
	{"settings.dropdown.bc", "Низ", "Bottom center", "Unten Mitte", "下中央", "底部居中"},
	{"settings.dropdown.br", "НП", "Bottom right", "Unten rechts", "右下", "右下"},
	{"settings.dropdown.h24", "24ч", "24h", "24 Std.", "24時間", "24小时"},
	{"settings.dropdown.h12", "12ч", "12h", "12 Std.", "12時間", "12小时"},
	{"settings.dropdown.background", "Фон", "Background", "Hintergrund", "背景", "背景"},
	{"settings.battery.showPercent", "Проценты заряда", "Show charge percent", "Ladezustand in Prozent", "充電率を表示", "显示电量百分比"},
}

type ordered struct {
	keys []string
	m    map[string]any
}

func newOrdered() *ordered {
	return &ordered{m: make(map[string]any)}
}

func (o *ordered) insert(parts []string, value string) {
	if len(parts) == 1 {
		k := parts[0]
		if _, ok := o.m[k]; !ok {
			o.keys = append(o.keys, k)
		}
		o.m[k] = value
		return
	}
	k := parts[0]
	child, ok := o.m[k]
	var node *ordered
	if !ok {
		node = newOrdered()
		o.m[k] = node
		o.keys = append(o.keys, k)
	} else {
		node = child.(*ordered)
	}
	node.insert(parts[1:], value)
}

func marshalString(s string) []byte {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(s)
	b := buf.Bytes()
	// Encode adds trailing newline; trim it
	if len(b) > 0 && b[len(b)-1] == '\n' {
		b = b[:len(b)-1]
	}
	return b
}

func writeOrdered(buf *bytes.Buffer, o *ordered, depth int, indent string) {
	buf.WriteString("{\n")
	for i, k := range o.keys {
		for j := 0; j < depth+1; j++ {
			buf.WriteString(indent)
		}
		buf.Write(marshalString(k))
		buf.WriteString(": ")
		v := o.m[k]
		switch vv := v.(type) {
		case string:
			buf.Write(marshalString(vv))
		case *ordered:
			writeOrdered(buf, vv, depth+1, indent)
		}
		if i < len(o.keys)-1 {
			buf.WriteString(",")
		}
		buf.WriteString("\n")
	}
	for j := 0; j < depth; j++ {
		buf.WriteString(indent)
	}
	buf.WriteString("}")
}

func findRepoRoot() string {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatalf("getwd: %v", err)
	}
	// Walk up from wd looking for quickshell/translations
	cur := wd
	for {
		if _, err := os.Stat(filepath.Join(cur, "quickshell", "translations")); err == nil {
			return cur
		}
		parent := filepath.Dir(cur)
		if parent == cur {
			break
		}
		cur = parent
	}
	// Fallback: relative to executable / source file location
	// Try current wd as repo root
	return wd
}

func main() {
	repo := findRepoRoot()
	trDir := filepath.Join(repo, "quickshell", "translations")

	for idx, lang := range langs {
		_ = idx
		o := newOrdered()
		for _, e := range entries {
			slug := e[0]
			val := e[1+idx]
			parts := strings.Split(slug, ".")
			o.insert(parts, val)
		}
		var buf bytes.Buffer
		writeOrdered(&buf, o, 0, "  ")
		buf.WriteString("\n")
		outPath := filepath.Join(trDir, lang+".json")
		if err := os.WriteFile(outPath, buf.Bytes(), 0644); err != nil {
			log.Fatalf("write %s: %v", outPath, err)
		}
		fmt.Printf("%s.json: %d keys written\n", lang, len(entries))
	}
}
