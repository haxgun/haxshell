#!/usr/bin/env python3
"""
Migrate QML sources from I18n.tr("Russian") to I18n.tr("slug") and wrap
remaining hardcoded Cyrillic strings in I18n.tr().

Requires scripts/gen_i18n.py to have been run (reads i18n_reverse.json).
Idempotent: literals already converted to slugs are left untouched.
"""
import json
import os
import re
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REVERSE = os.path.join(BASE, "i18n_reverse.json")

reverse = json.load(open(REVERSE, encoding="utf-8"))


def resolve(literal, slug):
    """Pick a single slug for a literal, with a sanity check against the reverse map."""
    known = reverse.get(literal)
    if known and slug not in known:
        raise SystemExit(f"mismatch: {literal!r} -> {slug!r} not in reverse map {known}")
    return slug


# Per-file tr() literal -> slug map. Ambiguous literals get explicit resolution;
# unambiguous ones fall back to the single reverse-map entry.
TR_MAP = {
    "quickshell/Modules/Bar/StatusWidget.qml": {
        "Мониторинг системы": "bar.systemMonitor",
        "Уведомления": "bar.notifications",
        "Громкость": "bar.volume",
        "Яркость": "bar.brightness",
        "Батарея": "bar.battery",
        "Bluetooth": "bar.bluetooth",
        "Сеть": "bar.network",
        "Центр управления": "bar.controlCenter",
        "Дата и время": "bar.clock",
        "VPN": "bar.vpn",
        "Пипетка цвета": "bar.colorPicker",
        "Питание": "bar.power",
    },
    "quickshell/Modules/ControlCenter/ControlCenterPopup.qml": {
        "Авиарежим": "cc.airplane",
        "Не беспокоить": "cc.dnd",
        "Не спать": "cc.caffeine",
        "Режим питания": "cc.powerProfile",
        "Ночной свет": "cc.nightLight",
        "Снимок области": "cc.screenshot",
        "Выбрать область": "cc.selectRegion",
        "Включено": "cc.on",
        "Выключено": "common.off",
    },
    "quickshell/Modules/Calendar/CalendarPopup.qml": {
        "Повестка": "calendar.agenda",
    },
    "quickshell/Modules/Notifications/Center/NotificationCenterPopup.qml": {
        "Уведомления": "notifications.title",
        "Не беспокоить": "notifications.dnd",
        "Текущие": "notifications.current",
        "История": "notifications.history",
        "Нет уведомлений": "notifications.empty",
    },
    "quickshell/Modules/System/SystemPopup.qml": {
        "UP": "system.up",
        "CPU": "system.cpu",
        "GPU": "system.gpu",
        "RAM": "system.ram",
    },
    "quickshell/Modules/AppDrawer/AppDrawer.qml": {
        "Выполнить команду": "appDrawer.runCommand",
        "Поиск приложений, окон, команд или выражений": "appDrawer.searchPlaceholder",
    },
    "quickshell/Modules/Bar/WorkspaceWidget.qml": {
        "Меню приложений": "bar.appMenu",
        "Рабочий стол": "bar.desktop",
    },
    "quickshell/Modules/Bar/TrayWidget.qml": {
        "Системный трей": "bar.tray",
    },
    "quickshell/Modules/Bar/MediaWidget.qml": {
        "Медиаплеер": "bar.mediaPlayer",
    },
    "quickshell/Modules/ClipboardPopup.qml": {
        "Буфер обмена": "clipboard.title",
        "Очистить": "clipboard.clear",
    },
    "quickshell/Modules/Settings/SettingsPopup.qml": {
        # header / search
        "Настройки": "settings.title",
        "Поиск настроек": "settings.searchPlaceholder",
        "Ничего не найдено": "common.nothingFound",
        # general section headers
        "Оформление": "settings.sections.appearance",
        "Интерфейс": "settings.pages.general",
        "Цветовая палитра": "settings.pages.palette",
        "Панель": "settings.pages.barPage",
        "Попапы": "settings.pages.popups",
        "Мониторинг": "settings.pages.monitoring",
        "Обои": "settings.pages.wallpaper",
        "OSD": "settings.pages.osd",
        "Система": "settings.sections.system",
        "Дополнительно": "settings.sections.advanced",
        # section headers (Text lines, distinguished by being the header)
        "Время и локация": "settings.sections.time",
        "Сочетания клавиш": "settings.system.keybinds",
        "О программе": "settings.sections.about",
        # general
        "Меньше анимаций": "settings.general.reduceMotion",
        "Анимации сокращены": "settings.general.reduced",
        "Обычные анимации": "settings.general.normal",
        "Подсказки": "settings.general.tooltips",
        "Показываются": "common.shownPlural",
        "Скрыты": "common.hiddenPlural",
        "Основной шрифт": "settings.general.sansFont",
        "Моноширинный шрифт": "settings.general.monoFont",
        "Размер текста": "settings.general.uiScale",
        "Звук уведомлений": "settings.general.notificationSound",
        "Отключённые приложения": "settings.general.mutedApps",
        "Имена приложений через запятую": "settings.general.mutedAppsHint",
        "Порядок плиток центра управления": "settings.general.tileOrder",
        "Правило простоя": "settings.general.idlePolicy",
        "0 отключает; применяется после простоя": "settings.general.idleHint",
        # font picker
        "Текущий": "settings.palette.current",
        "Поиск шрифта": "settings.general.fontSearch",
        "19:37 пн, июл. 20 · Быстрая лиса 123": "settings.fontPreview",
        # palette
        "Тема": "settings.palette.theme",
        "Ручной акцент": "settings.palette.manualAccent",
        "Акцент из обоев": "settings.palette.wallpaperAccent",
        "Светлая палитра": "settings.palette.lightPalette",
        "Тёмная палитра": "settings.palette.darkPalette",
        "Кликни по цвету, чтобы выбрать его": "settings.palette.clickToPick",
        "Выбрать цвет с экрана": "settings.system.pickColor",
        "Пресет палитры": "settings.palette.palettePreset",
        "Как извлекать цвета из обоев": "settings.palette.extractMethod",
        "Тёмная тема": "settings.palette.darkTheme",
        "Тёмные цвета из обоев": "settings.palette.darkFromWall",
        "Светлые цвета из обоев": "settings.palette.lightFromWall",
        "Пресеты": "settings.palette.presets",
        # wallpaper
        "Настройки обоев": "settings.wallpaper.settings",
        "Папка обоев": "settings.wallpaper.folder",
        "Отображение обоев": "settings.wallpaper.display",
        "Масштабирование изображения": "settings.wallpaper.scaling",
        "Эффект смены": "settings.wallpaper.effect",
        "Переход при смене обоев": "settings.wallpaper.transition",
        "Автоматическая смена": "settings.wallpaper.autoChange",
        "Включена": "settings.general.femOn",
        "Выключена": "settings.general.femOff",
        "Интервал смены": "settings.wallpaper.interval",
        "Секунды между обоями из текущей папки": "settings.wallpaper.intervalHint",
        "Размывать обои в Overview": "settings.wallpaper.blurOverview",
        "Видеообои": "settings.wallpaper.video",
        "Звук видеообоев": "settings.wallpaper.videoSound",
        "Громкость видеообоев": "settings.wallpaper.videoVolume",
        "Громкость воспроизведения": "settings.wallpaper.playbackVolume",
        "Аппаратное декодирование": "settings.wallpaper.hwDecode",
        "Пауза видео в Overview": "settings.wallpaper.pauseOverview",
        "Поиск обоев": "settings.wallpaper.search",
        "В папке нет поддерживаемых изображений или видео": "wallpaper.folderEmpty",
        # bar page
        "Положение панели": "settings.popups.positionOfPanel",
        "Снизу": "settings.popups.bottom",
        "Слева": "settings.popups.left",
        "Справа": "settings.popups.right",
        "Сверху": "settings.popups.top",
        "Дизайн панели": "settings.barPage.design",
        "Островки": "settings.barPage.islands",
        "Сплошной": "settings.barPage.solid",
        "Адаптивный бар": "settings.barPage.adaptive",
        "Прозрачный без окна на весь экран": "settings.barPage.adaptiveHint",
        "Толщина панели": "settings.barPage.thickness",
        "Высота или ширина панели": "settings.popups.wh",
        "Автоскрытие": "settings.barPage.autoHide",
        "Скрывается автоматически": "settings.barPage.hidesAutomatically",
        "Всегда отображается": "settings.barPage.alwaysShown",
        "Задержка скрытия": "settings.barPage.hideDelay",
        "Через сколько секунд скрывать панель": "settings.barPage.hideDelayHint",
        "Отступ сверху": "settings.popups.topPadding",
        "Расстояние от верхнего края": "settings.popups.topDistance",
        "Отступ снизу": "settings.popups.bottomPadding",
        "Расстояние от нижнего края": "settings.popups.bottomDistance",
        "Отступы слева и справа": "settings.popups.sidePadding",
        "Одинаковое расстояние от боковых краёв": "settings.popups.sameSideGap",
        "Закругление бара": "settings.barPage.radius",
        "Радиус углов панели": "settings.barPage.radiusCorner",
        "Режим закругления": "settings.barPage.radiusMode",
        "Раздельный": "settings.barPage.separate",
        "Полный": "settings.barPage.full",
        "Закругление виджетов бара": "settings.barPage.widgetRadius",
        "Радиус углов элементов панели": "settings.barPage.widgetRadiusCorner",
        "Размытие фона": "settings.barPage.blur",
        "Обводка бара": "settings.barPage.outline",
        "Тень бара": "settings.barPage.shadow",
        "Непрозрачность фона": "settings.popups.backgroundOpacity",
        "Непрозрачность фона панели": "settings.barPage.opacity",
        # bar widgets
        "Виджеты панели": "settings.general.barWidgets",
        "Рабочие столы": "bar.workspaces",
        "Показываются в панели": "common.shownInBarPlural",
        "Скрыты из панели": "common.hiddenFromBarPlural",
        "Меню приложений": "bar.appMenu",
        "Показывается в панели": "common.shownInBar",
        "Скрыто из панели": "common.hiddenFromBarN",
        "Активное приложение": "bar.activeApp",
        "Медиа-плеер": "bar.mediaPlayerHyphen",
        "Скрыт из панели": "common.hiddenFromBar",
        "Системный трей": "bar.tray",
        "Раскладка клавиатуры": "bar.keyboardLayout",
        "Скрыта из панели": "common.hiddenFromBarF",
        "Мониторинг системы": "bar.systemMonitor",
        "Уведомления": "bar.notifications",
        "Громкость": "bar.volume",
        "Яркость": "bar.brightness",
        "Батарея": "bar.battery",
        "Bluetooth": "bar.bluetooth",
        "Сеть": "bar.network",
        "Дата и время": "bar.clock",
        "Погода": "settings.location.weather",
        "VPN": "bar.vpn",
        "Пипетка цвета": "bar.colorPicker",
        "Питание": "bar.power",
        "Цифры рабочих столов": "bar.workspaceNumbers",
        "Рабочие столы на всех экранах": "bar.workspacesAllScreens",
        "На своих экранах": "bar.ownScreens",
        "Индикатор занятого стола": "bar.workspaceIndicator",
        # popups section
        "Всплывающие панели": "settings.popups.popupPanels",
        "Положение всплывающих панелей": "settings.popups.position",
        "Выбор для левой и правой панели": "settings.popups.edges",
        "Размытие всплывающих панелей": "settings.popups.blur",
        "Обводка всплывающих панелей": "settings.popups.outline",
        "Тень всплывающих панелей": "settings.popups.shadow",
        "Закругление панелей": "settings.popups.radius",
        "Радиус углов выпадающих меню": "settings.popups.dropdownRadius",
        "Закругление элементов панелей": "settings.barPage.popupElementRadius",
        "Радиус углов карточек и кнопок": "settings.barPage.cardButtonRadius",
        "Непрозрачность панелей": "settings.popups.opacity",
        "Фон выпадающих меню и уведомлений": "settings.popups.menuBg",
        # notifications section
        "Не беспокоить": "notifications.dnd",
        "Всплывающие тосты выключены": "notifications.toastsOff",
        "Всплывающие тосты включены": "notifications.toastsOn",
        "Положение тостов": "settings.popups.toastPosition",
        "Место появления уведомлений": "notifications.position",
        "Время показа": "settings.general.showTime",
        '" сек."': "settings.monitoring.secSuffix",
        "Максимум тостов": "notifications.maxToasts",
        "Одновременно на экране": "notifications.visibleAtOnce",
        # osd/location
        "Экранные индикаторы": "settings.general.screenIndicators",
        "Положение OSD": "settings.popups.osdPosition",
        "Громкость и яркость": "settings.general.volumeBrightness",
        "Формат времени": "settings.location.timeFormat",
        "12-часовой формат": "settings.location.h12",
        "24-часовой формат": "settings.location.h24",
        "Секунды в часах": "settings.location.showSeconds",
        "Дата": "bar.date",
        "Погода на панели": "settings.location.weatherInBar",
        "Показывается": "common.shown",
        "Скрыта": "common.hidden",
        "Точность до десятых": "settings.palette.tenths",
        "С десятыми": "settings.palette.withTenths",
        "Целые градусы": "settings.palette.wholeDegrees",
        "Город погоды": "settings.location.weatherCity",
        "Автоматически по IP": "settings.location.autoIp",
        "авто по IP": "settings.location.autoIpShort",
        # monitoring
        "Системные метрики": "settings.monitoring.sysMetrics",
        "CPU, память, сеть и накопители отображаются на панели и в системном попапе.": "settings.monitoring.sysMetricsHint",
        "Метрики в панели": "settings.monitoring.metrics",
        "Загрузка CPU": "settings.monitoring.cpuUsage",
        "Процент использования процессора": "settings.monitoring.cpuPercent",
        "Температура CPU": "settings.monitoring.cpuTemp",
        "Температура процессора": "settings.monitoring.cpuTempLong",
        "Загрузка GPU": "settings.monitoring.gpuUsage",
        "Процент использования видеокарты": "settings.monitoring.gpuPercent",
        "Температура GPU": "settings.monitoring.gpuTemp",
        "Температура видеокарты": "settings.monitoring.gpuTempLong",
        "Оперативная память": "settings.monitoring.memory",
        "Использование RAM": "settings.monitoring.ramUsage",
        "Скорость загрузки": "settings.monitoring.downloadSpeed",
        # system section
        "Язык": "settings.general.language",
        "Закрыть настройки": "settings.system.closeSettings",
        "Сочетание клавиш для закрытия окна настроек": "settings.system.closeSettingsHint",
        "Глобальные сочетания": "settings.system.global",
        "Навигация настроек": "settings.system.nav",
        "Следующий раздел": "settings.system.nextSection",
        "Предыдущий раздел": "settings.system.prevSection",
        "Следующая вкладка": "settings.system.nextTab",
        "Предыдущая вкладка": "settings.system.prevTab",
        "Шина монитора": "settings.system.monitorBus",
        "Задержка DDC/CI": "settings.system.ddcDelay",
        "Множитель паузы между командами": "settings.system.ddcMultiplier",
        # general hint
        "wifi, bluetooth, airplane, dnd, caffeine, screenshot, power, nightlight": "settings.general.tileOrderHint",
        # about
        "Naton is a customizable Wayland desktop shell built with Quickshell, QML, and Go.": "settings.about.description",
        "Установленная версия": "settings.about.installed",
        "Последняя версия": "settings.about.latest",
        "Контрибьюторы": "settings.about.contributors",
        # option labels (dropdown rows)
        "Растянуть": "settings.dropdown.stretch",
        "Вместить": "settings.dropdown.fit",
        "Заполнить": "settings.dropdown.fill",
        "Замостить": "settings.dropdown.tile",
        "Замостить по вертикали": "settings.dropdown.tileV",
        "Замостить по горизонтали": "settings.dropdown.tileH",
        "С полями": "settings.dropdown.pad",
        "Без эффекта": "settings.dropdown.noEffect",
        "Простой": "settings.dropdown.simple",
        "Плавное появление": "settings.dropdown.fade",
        "Стирание": "settings.dropdown.wipe",
        "Волна": "settings.dropdown.wave",
        "Раскрытие": "settings.dropdown.grow",
        "Круг из центра": "settings.dropdown.center",
        "Круг из случайной точки": "settings.dropdown.any",
        "Круг к центру": "settings.dropdown.outer",
        "Случайный": "settings.dropdown.random",
        "Яркий": "settings.dropdown.vibrant",
        "Точный": "settings.dropdown.faithful",
        "Диссонансный": "settings.dropdown.dysfunctional",
        "Приглушённый": "settings.dropdown.muted",
        "Мягкий": "settings.dropdown.soft",
        "Material": "settings.dropdown.material",
        "Монохромный": "settings.dropdown.monochrome",
        "ВЛ": "settings.dropdown.tl",
        "Верх": "settings.dropdown.tc",
        "ВП": "settings.dropdown.tr",
        "НЛ": "settings.dropdown.bl",
        "Низ": "settings.dropdown.bc",
        "НП": "settings.dropdown.br",
        "24ч": "settings.dropdown.h24",
        "12ч": "settings.dropdown.h12",
        "Фон": "settings.dropdown.background",
        "Свет": "settings.palette.light",
        "Тьма": "settings.palette.dark",
        "Дин.": "settings.palette.dynamic",
        "Своя": "settings.palette.custom",
        # keybind model titles (rendered via I18n.tr(modelData.title))
        "Буфер обмена": "clipboard.title",
        "Центр управления": "bar.controlCenter",
        # common.on/off in SettingsPopup
        "Включено": "common.on",
        "Выключено": "common.off",
        "Показывается в панели": "common.shownInBar",
    },
}

# Hardcoded Cyrillic strings -> (file, old, new) replacements.
HARDCODED_MAP = {
    "quickshell/Modules/Wallpapers/WallpaperPopup.qml": [
        ('property string wallName: "Нет обоев"', 'property string wallName: I18n.tr("wallpaper.none")'),
        ('root.wallName = res.name || "Нет обоев"', 'root.wallName = res.name || I18n.tr("wallpaper.none")'),
        ('text: "Следующие обои"', 'text: I18n.tr("wallpaper.next")'),
    ],
    "quickshell/Modules/Notifications/Popup/NotificationToast.qml": [
        ('toastData.summary || "Уведомление"', 'toastData.summary || I18n.tr("notifications.fallback")'),
    ],
    "quickshell/Modules/Notifications/Center/NotificationCard.qml": [
        ('modelData.summary || modelData.appName || "Уведомление"', 'modelData.summary || modelData.appName || I18n.tr("notifications.fallback")'),
    ],
    "quickshell/Modules/Notifications/Popup/NotificationPopupManager.qml": [
        ('notification.summary || notification.appName || "Уведомление"', 'notification.summary || notification.appName || I18n.tr("notifications.fallback")'),
    ],
    "quickshell/Services/NotificationService.qml": [
        ('notification.summary || notification.appName || "Уведомление"', 'notification.summary || notification.appName || I18n.tr("notifications.fallback")'),
    ],
    "quickshell/Modules/System/SystemPopup.qml": [
        ('property string uptime: "0м"', 'property string uptime: I18n.tr("system.uptimeFallback")'),
        ('root.uptime = res.uptime || "0м"', 'root.uptime = res.uptime || I18n.tr("system.uptimeFallback")'),
        ('if (key === "net") return "СЕТЬ · МБ/С"', 'if (key === "net") return I18n.tr("system.net")'),
        ('if (key === "disk") return "ДИСК · %"', 'if (key === "disk") return I18n.tr("system.disk")'),
        ('if (key === "swap") return "SWAP · ГБ"', 'if (key === "swap") return I18n.tr("system.swap")'),
        ('return "VRAM · ГБ"', 'return I18n.tr("system.vram")'),
        ('text: "СИСТЕМА"', 'text: I18n.tr("system.title")'),
        ('"/ " + root.ramTotal.toFixed(0) + " ГБ"', '"/ " + root.ramTotal.toFixed(0) + I18n.tr("system.ramSuffix")'),
    ],
    "quickshell/Modules/Calendar/CalendarPopup.qml": [
        ('property string weatherCondition: "Погода недоступна"', 'property string weatherCondition: I18n.tr("calendar.weatherUnavailable")'),
        ('property string weatherDetails: "Погода недоступна"', 'property string weatherDetails: I18n.tr("calendar.weatherUnavailable")'),
        ('root.weatherCondition = res.condition || "Погода"', 'root.weatherCondition = res.condition || I18n.tr("calendar.weather")'),
        ('(res.name || Config.weatherLocation || "Текущий город") + " · влажность " + root.weatherHumidity',
         '(res.name || Config.weatherLocation || I18n.tr("calendar.currentCity")) + I18n.tr("calendar.humidity") + root.weatherHumidity'),
        ('desc: day.condition || "Прогноз"', 'desc: day.condition || I18n.tr("calendar.forecast")'),
        ('desc: "Нет данных"', 'desc: I18n.tr("calendar.noData")'),
        ('if (index === 0) return "Сегодня"', 'if (index === 0) return I18n.tr("calendar.today")'),
        ('text: Config.weatherLocation || "Погода"', 'text: Config.weatherLocation || I18n.tr("calendar.weather")'),
    ],
    "quickshell/Modules/Power/PowerPopup.qml": [
        ('text: "Питание"', 'text: I18n.tr("power.title")'),
        ('{ label: "Заблокировать", icon: Config.iconLock, command: "loginctl lock-session" }', '{ label: I18n.tr("power.lock"), icon: Config.iconLock, command: "loginctl lock-session" }'),
        ('{ label: "Сон", icon: Config.iconSuspend, command: "systemctl suspend" }', '{ label: I18n.tr("power.sleep"), icon: Config.iconSuspend, command: "systemctl suspend" }'),
        ('{ label: "Выйти", icon: Config.iconLogout, command: "loginctl terminate-user $USER" }', '{ label: I18n.tr("power.logout"), icon: Config.iconLogout, command: "loginctl terminate-user $USER" }'),
        ('{ label: "Перезагрузка", icon: Config.iconRestart, command: "systemctl reboot" }', '{ label: I18n.tr("power.reboot"), icon: Config.iconRestart, command: "systemctl reboot" }'),
        ('{ label: "Выключить", icon: Config.iconPower, command: "systemctl poweroff", danger: true }', '{ label: I18n.tr("power.shutdown"), icon: Config.iconPower, command: "systemctl poweroff", danger: true }'),
    ],
    "quickshell/Modules/OSD/Osd.qml": [
        ('property string label: "Громкость"', 'property string label: I18n.tr("osd.volume")'),
        ('label = muted ? "Звук выключен" : "Громкость"', 'label = muted ? I18n.tr("osd.muted") : I18n.tr("osd.volume")'),
        ('label = "Яркость"', 'label = I18n.tr("osd.brightness")'),
        ('text: root.muted ? "Выкл." : root.value + "%"', 'text: root.muted ? I18n.tr("osd.off") : root.value + "%"'),
    ],
    "quickshell/Modules/ControlCenter/KeyboardLayoutPopup.qml": [
        ('text: "Раскладка"', 'text: I18n.tr("keyboard.title")'),
    ],
    "quickshell/Modules/Media/MediaPopup.qml": [
        ('text: root.title || "Нет трека"', 'text: root.title || I18n.tr("media.noTrack")'),
        ('text: root.artist || "Неизвестный артист"', 'text: root.artist || I18n.tr("media.unknownArtist")'),
    ],
    "quickshell/Modules/Bar/StatusWidget.qml": [
        ('property string sysUptime: "0м"', 'property string sysUptime: I18n.tr("system.uptimeFallback")'),
    ],
    "quickshell/Modules/ControlCenter/ControlCenterPopup.qml": [
        ('return !Networking.wifiEnabled ? "Выключен" : (connectedNetworkName || "Не подключено")',
         'return !Networking.wifiEnabled ? I18n.tr("cc.off") : (connectedNetworkName || I18n.tr("cc.notConnected"))'),
        ('return !adapter || !adapter.enabled ? "Выключен" : (connectedDeviceName || "Включен")',
         'return !adapter || !adapter.enabled ? I18n.tr("cc.off") : (connectedDeviceName || I18n.tr("cc.on"))'),
        ('return (batteryCharging ? "Заряжается" : (acOnline ? "От сети" : "Аккумулятор")) + " · " + profileName(powerProfile)',
         'return (batteryCharging ? I18n.tr("cc.charging") : (acOnline ? I18n.tr("cc.onAc") : I18n.tr("cc.battery"))) + " · " + profileName(powerProfile)'),
        ('return profile === "power-saver" ? "Экономия" : (profile === "performance" ? "Производительность" : "Баланс")',
         'return profile === "power-saver" ? I18n.tr("cc.powerSaver") : (profile === "performance" ? I18n.tr("cc.performance") : I18n.tr("cc.balanced"))'),
        ('text: root.hasMedia ? (root.mediaTitle || "Музыка") : "Музыка"',
         'text: root.hasMedia ? (root.mediaTitle || I18n.tr("cc.music")) : I18n.tr("cc.music")'),
        ('text: root.hasMedia ? (root.mediaArtist || "Неизвестный исполнитель") : "Нет активного плеера"',
         'text: root.hasMedia ? (root.mediaArtist || I18n.tr("cc.unknownArtist")) : I18n.tr("cc.noPlayer")'),
    ],
    "quickshell/Modules/Bar/ActiveAppWidget.qml": [
        ('if (!value) return "Рабочий стол"', 'if (!value) return I18n.tr("bar.desktop")'),
    ],
    "quickshell/Modules/ControlCenter/WiFiPopup.qml": [
        ('if (network.connected) return "Подключено"', 'if (network.connected) return I18n.tr("wifi.connected")'),
        ('if (network.state === ConnectionState.Connecting || network.stateChanging) return "Подключение..."', 'if (network.state === ConnectionState.Connecting || network.stateChanging) return I18n.tr("wifi.connecting")'),
        ('return network.known ? "Сохранено" : "Доступно"', 'return network.known ? I18n.tr("wifi.saved") : I18n.tr("wifi.available")'),
        ('text: root.connectedNetworkName || (Networking.wifiEnabled ? "Не подключено" : "Выключено")',
         'text: root.connectedNetworkName || (Networking.wifiEnabled ? I18n.tr("wifi.notConnected") : I18n.tr("wifi.off"))'),
        ('text: "Wi-Fi адаптер не найден"', 'text: I18n.tr("wifi.adapterNotFound")'),
        ('text: section === "true" ? "Знакомые сети" : "Другие сети"', 'text: section === "true" ? I18n.tr("wifi.known") : I18n.tr("wifi.other")'),
        ('text: modelData.name || "Скрытая сеть"', 'text: modelData.name || I18n.tr("wifi.hidden")'),
        ('text: "Пароль для " + (modelData.name || "сети")', 'text: I18n.tr("wifi.passwordFor") + (modelData.name || "сети")'),
        ('text: "Отмена"', 'text: I18n.tr("wifi.cancel")'),
        ('text: "Подключить"', 'text: I18n.tr("wifi.connect")'),
    ],
    "quickshell/Modules/ControlCenter/BluetoothPopup.qml": [
        ('return device.name || device.deviceName || device.address || "Bluetooth устройство"', 'return device.name || device.deviceName || device.address || I18n.tr("bt.device")'),
        ('if (device.connected) return "Подключено"', 'if (device.connected) return I18n.tr("bt.connected")'),
        ('if (device.state === BluetoothDeviceState.Connecting) return "Подключение..."', 'if (device.state === BluetoothDeviceState.Connecting) return I18n.tr("bt.connecting")'),
        ('if (device.pairing) return "Сопряжение..."', 'if (device.pairing) return I18n.tr("bt.pairing")'),
        ('if (device.paired || device.bonded) return "Сопряжено"', 'if (device.paired || device.bonded) return I18n.tr("bt.paired")'),
        ('return "Доступно"', 'return I18n.tr("bt.available")'),
        ('text: root.connectedDeviceName || (root.adapter && root.adapter.enabled ? "Не подключено" : "Выключено")',
         'text: root.connectedDeviceName || (root.adapter && root.adapter.enabled ? I18n.tr("bt.notConnected") : I18n.tr("bt.off"))'),
        ('text: "Bluetooth адаптер не найден"', 'text: I18n.tr("bt.adapterNotFound")'),
    ],
    "quickshell/Modules/ControlCenter/BatteryPopup.qml": [
        ('if (root.batteryCharging && root.batteryStatus === "Full") return "Полностью заряжена, подключена"', 'if (root.batteryCharging && root.batteryStatus === "Full") return I18n.tr("battery.fullChargedConnected")'),
        ('if (root.batteryStatus === "Charging") return "Заряжается"', 'if (root.batteryStatus === "Charging") return I18n.tr("battery.charging")'),
        ('if (root.batteryStatus === "Discharging") return "Разряжается"', 'if (root.batteryStatus === "Discharging") return I18n.tr("battery.discharging")'),
        ('if (root.batteryStatus === "Full") return "Полностью заряжена"', 'if (root.batteryStatus === "Full") return I18n.tr("battery.full")'),
        ('if (root.acOnline) return "Подключена к сети"', 'if (root.acOnline) return I18n.tr("battery.onAc")'),
        ('return "Неизвестно"', 'return I18n.tr("battery.unknown")'),
        ('return hours + "ч " + minutes + "м"', 'return I18n.tr("battery.hoursMinutes").replace("{h}", hours).replace("{m}", minutes)'),
        ('if (profile === "power-saver") return "Экономия"', 'if (profile === "power-saver") return I18n.tr("cc.powerSaver")'),
        ('if (profile === "performance") return "Производительность"', 'if (profile === "performance") return I18n.tr("cc.performance")'),
        ('return "Баланс"', 'return I18n.tr("cc.balanced")'),
        ('text: "Батарея"', 'text: I18n.tr("battery.title")'),
        ('text: root.batteryCharging ? "Заряд" : "Остаток"', 'text: root.batteryCharging ? I18n.tr("battery.chargeLabel") : I18n.tr("battery.remainingLabel")'),
        ('BatteryInfoRow { label: "Осталось"; value: root.timeText();', 'BatteryInfoRow { label: I18n.tr("battery.remaining"); value: root.timeText();'),
        ('BatteryInfoRow { label: "Напряжение"; value: root.batteryVoltage > 0 ? root.batteryVoltage.toFixed(2) + " В" : "--";', 'BatteryInfoRow { label: I18n.tr("battery.voltage"); value: root.batteryVoltage > 0 ? root.batteryVoltage.toFixed(2) + I18n.tr("battery.voltageUnit") : "--";'),
        ('BatteryInfoRow { label: "Температура"; value:', 'BatteryInfoRow { label: I18n.tr("battery.temperature"); value:'),
        ('BatteryInfoRow { label: "Циклы"; value:', 'BatteryInfoRow { label: I18n.tr("battery.cycles"); value:'),
        ('text: "Профиль питания"', 'text: I18n.tr("battery.powerProfile")'),
    ],
    "quickshell/Modules/ControlCenter/BrightnessPopup.qml": [
        ('text: "Яркость экрана"', 'text: I18n.tr("brightness.title")'),
    ],
    "quickshell/Modules/ControlCenter/AudioPopup.qml": [
        ('text: "Звук"', 'text: I18n.tr("audio.title")'),
        ('title: "Динамики"', 'title: I18n.tr("audio.speakers")'),
        ('emptyText: "Устройства вывода не найдены"', 'emptyText: I18n.tr("audio.noOutputs")'),
        ('title: "Микрофон"', 'title: I18n.tr("audio.mic")'),
        ('emptyText: "Устройства ввода не найдены"', 'emptyText: I18n.tr("audio.noInputs")'),
    ],
}


def migrate_file(relpath, tr_map, hardcoded):
    path = os.path.join(BASE, relpath)
    src = open(path, encoding="utf-8").read()
    original = src

    # Replace hardcoded strings first (they may contain tr()-like patterns).
    for old, new in hardcoded:
        if old not in src:
            continue
        src = src.replace(old, new)

    # Replace tr("Russian") -> tr("slug").
    # Build reverse lookup: unambiguous literal -> single slug; ambiguous handled by tr_map.
    CYRILLIC = re.compile(r"[А-Яа-яЁё]")

    def tr_repl(match):
        lit = match.group(1)
        if lit in tr_map:
            return f'I18n.tr("{tr_map[lit]}")'
        # Skip already-converted slug keys (dotted, non-Cyrillic) and native strings.
        if not CYRILLIC.search(lit):
            return match.group(0)
        known = reverse.get(lit, [])
        if len(known) == 1:
            return f'I18n.tr("{known[0]}")'
        raise SystemExit(f"{relpath}: no slug for ambiguous literal {lit!r} (map: {known})")

    src = re.sub(r'I18n\.tr\("([^"]+)"\)', tr_repl, src)

    if src != original:
        open(path, "w", encoding="utf-8").write(src)
        return True
    return False


def main():
    changed = []
    all_files = set(TR_MAP) | set(HARDCODED_MAP)
    for relpath in sorted(all_files):
        tr_map = TR_MAP.get(relpath, {})
        hard = HARDCODED_MAP.get(relpath, [])
        if migrate_file(relpath, tr_map, hard):
            changed.append(relpath)
    print("migrated:", len(changed))
    for c in changed:
        print("  ", c)


if __name__ == "__main__":
    main()
