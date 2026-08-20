<div align="center">

<p align="center">
    <img src="docs/logo.svg" alt="Naton logo" width="160">
</p>

`Naton` - настраиваемая Wayland-оболочка рабочего стола на Quickshell, QML и Go для Hyprland и Niri.

[English](README.md) · **Русский** · [中文](README.zh.md) · [Deutsch](README.de.md)

<a href="https://github.com/vercel/next.js"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/vercel/next.js/license.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/github/vercel/next.js/license.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://quickshell.org/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/Quickshell-QML.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/badge/Quickshell-QML.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://hypr.land/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/Hyprland-Wayland.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/badge/Hyprland-Wayland.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://github.com/YaLTeR/niri"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/Niri-Wayland.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/badge/Niri-Wayland.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://go.dev/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/Go-1.25+.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/badge/Go-1.25+.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>  
<a href="https://github.com/haxgun/naton"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/haxgun/naton/stars.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/github/haxgun/naton/stars.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://github.com/haxgun/naton/forks"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/haxgun/naton/forks.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/github/haxgun/naton/forks.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://github.com/haxgun/naton/issues"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/haxgun/naton/issues.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/github/haxgun/naton/issues.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>
<a href="https://github.com/haxgun/naton/commits"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/haxgun/naton/last-commit.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=dark"><img alt="badge" src="https://shieldcn.dev/github/haxgun/naton/last-commit.svg?variant=outline&amp;size=xs&amp;font=geist&amp;mode=light"></picture></a>


</div>

## Возможности

- Панель с размещением сверху, снизу, слева или справа и настраиваемыми отступами.
- Переключатель рабочих пространств, индикатор активного приложения, часы, погода, медиа, трей и системные виджеты на панели — каждый включается независимо.
- Всплывающие панели календаря, медиа, питания и настроек, привязанные к панели и следующие за её положением. Wi-Fi, Bluetooth, звук, батарея и яркость вынесены в отдельные разделы настроек.
- Компактный центр управления с pill-кнопками быстрых настроек (Wi-Fi, Bluetooth, «Не беспокоить», «Не спать»), кнопкой снимка экрана, слайдерами яркости и громкости, статистикой CPU/RAM/диска, профилями питания, темой и медиа с переключением треков.
- Раздельное управление громкостью динамиков и микрофона, выбор устройств PipeWire.
- Единый MPRIS-контроллер с обложкой, живым progress и метаданными в панели; медиа-панель с размытым фоном из обложки.
- Уведомления, всплывающие тосты и центр уведомлений с отключением приложений и опциональным звуком; список следует за положением панели (сверху вниз при панели сверху и снизу вверх при панели снизу).
- Лаунчер с поиском приложений, окон, shell-команд и вычислений; история буфера обмена, док/панель задач и agenda календаря из khal.
- Выбор обоев с извлечением palette и динамической темой, которая окрашивает поверхности оболочки по текущим обоям. Семь схем palette (`vibrant`, `faithful`, `dysfunctional`, `muted`, `soft`, `material`, `monochrome`) с плавными цветовыми переходами между обоями.
- Видеообои через `mpvpaper` со статичной подложкой первого кадра через `awww`, настройками звука, аппаратного декодирования, масштабирования и паузы в Overview у Niri.
- Постоянные настройки темы, панели, типографики (раздельные семейства sans и mono с независимым масштабом), уведомлений, OSD, поведения обоев и внешнего вида оболочки.
- Правило простоя: блокировка сеанса или сон после настраиваемого таймаута через `swayidle`.

## Структура

```text
.
├── quickshell/               # Конфигурация Quickshell
│   ├── shell.qml             # Точка входа Quickshell
│   ├── Common/               # Общая конфигурация и singleton-сервисы
│   ├── Modules/              # Панель, всплывающие окна и настройки
│   ├── Widgets/              # Переиспользуемые QML-компоненты
│   ├── Services/             # QML-сервисы
│   ├── keybinds/             # Сниппеты сочетаний по композитору (устанавливаются в папки конфигов naton)
│   └── translations/         # Переводы интерфейса
├── core/                     # Go-модуль natonctl
│   ├── cmd/natonctl/          # Точка входа команды natonctl
│   ├── internal/natonctl/     # Реализация команд для оболочки
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

Встроенный установщик предназначен для Arch Linux. Он ставит зависимости из репозиториев и AUR, собирает `natonctl` и создаёт символьную ссылку на этот репозиторий в `~/.config/quickshell`, не заменяя существующую конфигурацию.

```bash
./install.sh
```

Для Niri установите обязательную событийную интеграцию `qml-niri`:

```bash
./install.sh --compositor niri
```

Если Vicinae или `mpvpaper` ещё не установлены, потребуется `yay` или `paru`: эти пакеты устанавливаются из AUR.

## Зависимости

### Рантайм

| Пакет | Описание |
| --- | --- |
| `quickshell` | рантайм оболочки |
| `curl` | погода, праздники и раздел «О программе» |
| `awww` | демон обоев |
| `mpv` | воспроизведение видеообоев |
| `imagemagick` | извлечение палитры, миниатюры, тайлинг обоев |
| `ffmpeg` | миниатюры и первый кадр видеообоев |
| `brightnessctl` | управление яркостью |
| `power-profiles-daemon` | профили питания |
| `pipewire`, `pipewire-pulse`, `wireplumber` | звук |
| `networkmanager` | Wi-Fi и состояние сети |
| `bluez`, `bluez-utils`, `blueman` | Bluetooth |
| `qt6-declarative`, `qt6-svg`, `qt6-multimedia` | рантайм Qt |
| `ttf-jetbrains-mono-nerd` | глифы иконок |
| `fontconfig` | поиск выбранного шрифта для пипетки |
| `zenity` или `kdialog` | выбор папки |
| `pavucontrol` | графический интерфейс громкости |
| `wl-clipboard` | история буфера обмена |
| `slurp`, `grim` | снимки выделенной области |
| `wlsunset` | ночной свет |
| `khal` | agenda календаря |
| `swayidle` | настроенное правило блокировки или сна при простое |

### Сборка

- `go` 1.25+

### Композитор

Один из:

- **Hyprland** — `hyprland`, `hyprlock`, `xdg-desktop-portal-hyprland`
- **Niri** — `niri`, плюс `base-devel`, `cmake`, `git` для сборки модуля `qml-niri`

### Опционально

- `vicinae` (AUR) — опциональный внешний лаунчер приложений (оболочка содержит встроенный лаунчер)
- `mpvpaper` (AUR) — демон видеообоев
- `cava` — визуализатор музыки на панели

Quickshell сам обрабатывает уведомления — отключите любой другой демон уведомлений (например, Dunst), чтобы тосты не дублировались.

## Сборка `natonctl`

`natonctl` используется QML-компонентами для системных операций: управления яркостью, звуком, погодой, обоями и другими функциями.

```bash
go build -C core -o ../quickshell/natonctl ./cmd/natonctl
```

После изменения файлов в `core/` пересоберите утилиту и перезапустите Quickshell.

## Настройка

- Общая конфигурация находится в `quickshell/Common/Config.qml`.
- Пользовательские параметры сохраняются через `quickshell/Common/SettingsStore.qml` в `quickshell/settings.json`.
- В Settings доступны параметры blur, границ, теней, palette, типографики (семейство и масштаб sans/mono), геометрии и отступов панели, переключения отдельных виджетов панели, положения всплывающих панелей, уведомлений, OSD и смены обоев.
- Разделы настроек охватывают внешний вид, панель, рабочий стол (обои), время/местоположение, уведомления/OSD, систему, дополнительные параметры, батарею, звук, Wi-Fi, Bluetooth и «О программе». Управление Wi-Fi, Bluetooth, звуком, батареей и яркостью перенесено из отдельных всплывающих панелей в эти разделы; яркость остаётся на главной странице центра управления.
- Настройки видеообоев (звук, громкость, аппаратное декодирование и пауза в Overview у Niri) находятся в Settings → Обои.
- Снимки выделенной области используют `slurp` и `grim`; история буфера открывается через `qs ipc call clipboard toggle`.
- Глобальные сочетания клавиш редактируются в Settings → System → Keyboard shortcuts. Они сохраняются в `settings.json` и записываются в переопределения биндов композитора: дефолты устанавливаются из `quickshell/keybinds/` в `~/.config/niri/naton/keybinds.kdl` (Niri) или `~/.config/hypr/naton/keybinds.lua` (Hyprland), переопределения пользователя — в `~/.config/niri/naton/binds.kdl` (Niri) или `~/.config/hypr/naton/binds.lua` (Hyprland), и композитор перезагружает их автоматически.
- Динамическая тема сохраняет извлечённую palette обоев в `dynamicPalette` и применяет её к поверхностям оболочки, controls, границам, tracks и индикаторам рабочих столов.

## Проверка

```bash
git diff --check
quickshell --path quickshell
```

## Статистика

![Alt](https://repobeats.axiom.co/api/embed/3caf808ce8401c6c39d1913e45a21c801fd6263a.svg "Repobeats analytics image")

<div align="center">
    <a href="https://github.com/haxgun/naton/graphs/contributors" target="_blank">
      <table>
        <tr>
          <th colspan="2">
            <br><img src="https://contrib.rocks/image?repo=haxgun/naton" /><br><br>
          </th>
        </tr>
      </table>
    </a>
</div>
