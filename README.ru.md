# hush

<p align="center"><img src="logo.svg" alt="Логотип hush" width="160"></p>

[English](README.md) | [Русский](README.ru.md)

[![Лицензия: MIT](https://img.shields.io/badge/Лицензия-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Go](https://img.shields.io/badge/Go-1.24-00ADD8.svg)](https://go.dev/)

`hush` - оболочка рабочего стола Wayland на Quickshell и QML, рассчитанная на работу с Hyprland.

## Возможности

- Панель с размещением сверху, снизу, слева или справа.
- Переключатель рабочих пространств и индикатор активного приложения.
- Всплывающие панели Wi-Fi, Bluetooth, яркости, звука, батареи, календаря, медиа и питания.
- Центр управления с быстрыми настройками.
- Раздельное управление громкостью динамиков и микрофона, выбор устройств PipeWire.
- Единый MPRIS-контроллер для виджетов медиаплеера.
- Уведомления, всплывающие тосты и центр уведомлений.
- Выбор обоев с сеткой миниатюр.
- Постоянные настройки темы, панели, шрифтов и внешнего вида оболочки.

## Структура

```text
.
├── quickshell/               # Конфигурация Quickshell
│   ├── shell.qml             # Точка входа Quickshell
│   ├── Common/               # Общая конфигурация и singleton-сервисы
│   ├── Modules/              # Панель, всплывающие окна и настройки
│   ├── Widgets/              # Переиспользуемые QML-компоненты
│   ├── Services/             # QML-сервисы
│   └── translations/         # Переводы интерфейса
├── core/                     # Go-модуль hushctl
│   ├── cmd/hushctl/          # Точка входа команды hushctl
│   ├── internal/hushctl/     # Реализация команд для оболочки
│   ├── pkg/                  # Публичные Go-пакеты
│   ├── go.mod
│   └── go.sum
└── install.sh                # Установщик для Arch Linux
```

## Запуск

Из корня репозитория:

```bash
quickshell --path quickshell
```

Для автоматического запуска можно создать символьную ссылку на каталог проекта:

```bash
ln -s "$(pwd)/quickshell" ~/.config/quickshell
```

## Установка

Встроенный установщик предназначен для Arch Linux с Hyprland. Он ставит зависимости из репозиториев и AUR, собирает `hushctl` и создаёт символьную ссылку на этот репозиторий в `~/.config/quickshell`, не заменяя существующую конфигурацию.

```bash
./install.sh
```

Если Vicinae ещё не установлен, потребуется `yay` или `paru`: этот пакет устанавливается из AUR.

## Сборка `hushctl`

`hushctl` используется QML-компонентами для системных операций: управления яркостью, звуком, погодой, обоями и другими функциями.

```bash
go build -C core -o ../quickshell/hushctl ./cmd/hushctl
```

После изменения файлов в `core/` пересоберите утилиту и перезапустите Quickshell.

## Настройка

- Общая конфигурация находится в `quickshell/Common/Config.qml`.
- Пользовательские параметры сохраняются через `quickshell/Common/SettingsStore.qml` в `quickshell/settings.json`.
- Параметры внешнего вида: `shellBlurEnabled`, `shellBordersEnabled`, `shellShadowsEnabled`.

## Проверка

```bash
git diff --check
quickshell --path quickshell
```
