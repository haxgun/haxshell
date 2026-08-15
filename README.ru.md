<div align="center">

<p align="center">
    <img src="docs/logo.svg" alt="vey logo" width="160">
</p>

`vey` - настраиваемая Wayland-оболочка рабочего стола на Quickshell, QML и Go для Hyprland и Niri.

[English](README.md) · **Русский**

[![License: MIT](https://img.shields.io/badge/License-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Niri](https://img.shields.io/badge/Niri-Wayland-7c4dff.svg)](https://github.com/YaLTeR/niri)
[![Go](https://img.shields.io/badge/Go-1.25-00ADD8.svg)](https://go.dev/)
[![Stars](https://img.shields.io/github/stars/ValoryLabs/Valory?style=flat&color=green)](https://github.com/ValoryLabs/Valory/stargazers)
[![Forks](https://img.shields.io/github/forks/ValoryLabs/Valory?style=flat&color=green)](https://github.com/ValoryLabs/Valory/forks)
[![Issues](https://img.shields.io/github/issues/ValoryLabs/Valory?style=flat)](https://github.com/ValoryLabs/Valory/issues)
![GitHub last commit](https://img.shields.io/github/last-commit/haxgun/vey)

</div>

## Возможности

- Панель с размещением сверху, снизу, слева или справа и настраиваемыми отступами.
- Переключатель рабочих пространств, индикатор активного приложения, часы, погода, медиа, трей и системные виджеты на панели — каждый включается независимо.
- Всплывающие панели Wi-Fi, Bluetooth, яркости, звука, батареи, календаря, медиа, питания и настроек, привязанные к панели и следующие за её положением.
- Компактный центр управления с pill-кнопками быстрых настроек (Wi-Fi, Bluetooth, «Не беспокоить», «Не спать»), кнопкой снимка экрана, слайдерами яркости и громкости, статистикой CPU/RAM/диска, профилями питания, темой и медиа с переключением треков.
- Раздельное управление громкостью динамиков и микрофона, выбор устройств PipeWire.
- Единый MPRIS-контроллер с обложкой, живым progress и метаданными в панели; медиа-панель с размытым фоном из обложки.
- Уведомления, всплывающие тосты и центр уведомлений.
- Выбор обоев с извлечением palette и динамической темой, которая окрашивает поверхности оболочки по текущим обоям. Семь схем palette (`vibrant`, `faithful`, `dysfunctional`, `muted`, `soft`, `material`, `monochrome`) с плавными цветовыми переходами между обоями.
- Постоянные настройки темы, панели, типографики (раздельные семейства sans и mono с независимым масштабом), уведомлений, OSD, поведения обоев и внешнего вида оболочки.

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
├── core/                     # Go-модуль veyctl
│   ├── cmd/veyctl/          # Точка входа команды veyctl
│   ├── internal/veyctl/     # Реализация команд для оболочки
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

Встроенный установщик предназначен для Arch Linux. Он ставит зависимости из репозиториев и AUR, собирает `veyctl` и создаёт символьную ссылку на этот репозиторий в `~/.config/quickshell`, не заменяя существующую конфигурацию.

```bash
./install.sh
```

Для Niri установите обязательную событийную интеграцию `qml-niri`:

```bash
./install.sh --compositor niri
```

Если Vicinae ещё не установлен, потребуется `yay` или `paru`: этот пакет устанавливается из AUR.

## Зависимости

### Рантайм

- `quickshell` — рантайм оболочки
- `curl` — погода, праздники и раздел «О программе»
- `awww` — демон обоев
- `imagemagick` — извлечение палитры, миниатюры, тайлинг обоев
- `ffmpeg` — миниатюры видеообоев
- `brightnessctl` — управление яркостью
- `power-profiles-daemon` — профили питания
- `pipewire`, `pipewire-pulse`, `wireplumber` — звук
- `networkmanager` — Wi-Fi и состояние сети
- `bluez`, `bluez-utils`, `blueman` — Bluetooth
- `qt6-declarative`, `qt6-svg`, `qt6-multimedia` — рантайм Qt
- `ttf-jetbrains-mono-nerd` — глифы иконок
- `zenity` или `kdialog` — выбор папки
- `pavucontrol` — графический интерфейс громкости

### Сборка

- `go` 1.25+

### Композитор

Один из:

- **Hyprland** — `hyprland`, `hyprlock`, `hyprpicker`, `xdg-desktop-portal-hyprland`, `grim`
- **Niri** — `niri`, плюс `base-devel`, `cmake`, `git` для сборки модуля `qml-niri`

### Опционально

- `vicinae` (AUR) — лаунчер приложений
- `cava` — визуализатор музыки на панели

Quickshell сам обрабатывает уведомления — отключите любой другой демон уведомлений (например, Dunst), чтобы тосты не дублировались.

## Сборка `veyctl`

`veyctl` используется QML-компонентами для системных операций: управления яркостью, звуком, погодой, обоями и другими функциями.

```bash
go build -C core -o ../quickshell/veyctl ./cmd/veyctl
```

После изменения файлов в `core/` пересоберите утилиту и перезапустите Quickshell.

## Настройка

- Общая конфигурация находится в `quickshell/Common/Config.qml`.
- Пользовательские параметры сохраняются через `quickshell/Common/SettingsStore.qml` в `quickshell/settings.json`.
- В Settings доступны параметры blur, границ, теней, palette, типографики (семейство и масштаб sans/mono), геометрии и отступов панели, переключения отдельных виджетов панели, положения всплывающих панелей, уведомлений, OSD и смены обоев.
- Снимки экрана делаются инструментами композитора (`niri msg action screenshot` на Niri, `grim` на Hyprland).
- Динамическая тема сохраняет извлечённую palette обоев в `dynamicPalette` и применяет её к поверхностям оболочки, controls, границам, tracks и индикаторам рабочих столов.

## Проверка

```bash
git diff --check
quickshell --path quickshell
```

## Статистика

![Alt](https://repobeats.axiom.co/api/embed/3caf808ce8401c6c39d1913e45a21c801fd6263a.svg "Repobeats analytics image")

<div align="center">
    <a href="https://github.com/haxgun/vey/graphs/contributors" target="_blank">
      <table>
        <tr>
          <th colspan="2">
            <br><img src="https://contrib.rocks/image?repo=haxgun/vey" /><br><br>
          </th>
        </tr>
      </table>
    </a>
</div>
