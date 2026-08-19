<div align="center">

<p align="center">
    <img src="docs/logo.svg" alt="Naton logo" width="160">
</p>

`Naton` ist eine anpassbare Wayland-Desktop-Shell auf Basis von Quickshell, QML und Go für Hyprland und Niri.

[English](README.md) · [Русский](README.ru.md) · [中文](README.zh.md) · **Deutsch**

[![License: MIT](https://img.shields.io/badge/License-MIT-6b8e23.svg)](LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-5c7cfa.svg)](https://quickshell.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff.svg)](https://hyprland.org/)
[![Niri](https://img.shields.io/badge/Niri-Wayland-7c4dff.svg)](https://github.com/YaLTeR/niri)
[![Go](https://img.shields.io/badge/Go-1.25-00ADD8.svg)](https://go.dev/)
[![Stars](https://img.shields.io/github/stars/haxgun/naton?style=flat&color=green)](https://github.com/ValoryLabs/Valory/stargazers)
[![Forks](https://img.shields.io/github/forks/haxgun/naton?style=flat&color=green)](https://github.com/ValoryLabs/Valory/forks)
[![Issues](https://img.shields.io/github/issues/haxgun/naton?style=flat)](https://github.com/ValoryLabs/Valory/issues)
![GitHub last commit](https://img.shields.io/github/last-commit/haxgun/naton)

</div>

## Funktionen

- Leiste an der oberen, unteren, linken oder rechten Kante mit konfigurierbaren Rändern.
- Workspace-Umschalter, Anzeige für die fokussierte Anwendung, Uhr, Wetter, Medien, Tray und System-Widgets in der Leiste, jeweils einzeln ein-/ausschaltbar.
- Popups für Kalender, Medien, Strom und Einstellungen, an der Leiste verankert und ihrer Position folgend. Wi-Fi, Bluetooth, Audio, Akku und Helligkeit befinden sich in eigenen Einstellungsabschnitten.
- Kompaktes Control Center mit Pill-Schnellaktionen (Wi-Fi, Bluetooth, Nicht stören, Bildschirm an), Screenshot-Schaltfläche, Helligkeits- und Lautstärkereglern, CPU/RAM/Disk-Statistiken, Energiesparprofilen, Thema und Mediensteuerung mit Titelsprung.
- Getrennte Lautstärkeregelung für Lautsprecher und Mikrofon, mit PipeWire-Geräteauswahl.
- Gemeinsamer MPRIS-Controller mit Albumcover, Live-Wiedergabefortschritt, Leisten-Metadaten und einem Medien-Popup mit verschwommenem Cover-Hintergrund.
- Benachrichtigungs-Toasts und ein Benachrichtigungscenter mit Stummschaltung pro App und optionalem Ton; die Liste folgt der Leistenposition (von oben nach unten bei Leiste oben, von unten nach oben bei Leiste unten).
- Suchbarer Launcher mit Anwendungs-, Fenster-, Shell-Befehl- und Taschenrechner-Anbietern; Zwischenablageverlauf; Dock/Taskleiste; Kalenderagenda aus khal.
- Wallpaper-Auswahl mit extrahierten Farbpaletten und einem dynamischen Thema, das die Shell-Oberflächen aus dem aktuellen Wallpaper färbt. Sieben Paletten-Schemata (`vibrant`, `faithful`, `dysfunctional`, `muted`, `soft`, `material`, `monochrome`) mit animierten Farbübergängen zwischen Wallpapers.
- Video-Wallpapers über `mpvpaper`, mit statischem Erste-Frame-Fallback über `awww` und Einstellungen für Audio, Hardware-Dekodierung, Skalierung und Pausieren in Niris Overview.
- Persistente Einstellungen für Thema, Leiste, Typografie (getrennte Sans- und Mono-Schriftfamilien mit unabhängiger Skalierung), Benachrichtigungen, OSD, Wallpaper-Verhalten und Shell-Optik.
- Leerlauf-Policy, die die Sitzung nach einem konfigurierbaren Timeout über `swayidle` sperrt oder in den Ruhezustand versetzt.

## Struktur

```text
.
├── quickshell/               # Quickshell-Konfiguration
│   ├── shell.qml             # Quickshell-Einstiegspunkt
│   ├── Common/               # Gemeinsame Konfiguration und Singleton-Dienste
│   ├── Modules/              # Leiste, Popups und Einstellungen
│   ├── Widgets/              # Wiederverwendbare QML-Komponenten
│   ├── Services/             # QML-Dienste
│   ├── keybinds/             # Keybind-Ausschnitte je Compositor (in naton-Konfigordner installiert)
│   └── translations/         # UI-Übersetzungen
├── core/                     # Go-Modul für natonctl
│   ├── cmd/natonctl/          # natonctl-Befehlseinstiegspunkt
│   ├── internal/natonctl/     # Shell-spezifische Befehlsimplementierung
│   ├── pkg/                  # Öffentliche Go-Pakete
│   ├── go.mod
│   └── go.sum
└── install.sh                # Arch-Linux-Installationsprogramm
```

## Ausführen

Aus dem Repository-Root:

```bash
quickshell --path quickshell
```

Um die Shell automatisch zu starten, erstelle einen symbolischen Link auf das Projektverzeichnis:

```bash
ln -s "$(pwd)/quickshell" ~/.config/quickshell
```

## Installation

Das enthaltene Installationsprogramm zielt auf Arch Linux. Es installiert Repository- und AUR-Abhängigkeiten, baut `natonctl` und verlinkt dieses Repository auf `~/.config/quickshell`, ohne eine bestehende Konfiguration zu ersetzen.

```bash
./install.sh
```

Für Niri installiere die ereignisgesteuerte `qml-niri`-Integration als Pflichtabhängigkeit:

```bash
./install.sh --compositor niri
```

`yay` oder `paru` wird benötigt, wenn Vicinae oder `mpvpaper` nicht installiert sind, da sie aus dem AUR installiert werden.

## Abhängigkeiten

### Laufzeit

| Paket | Beschreibung |
| --- | --- |
| `quickshell` | die Shell-Laufzeit |
| `curl` | Wetter, Feiertage und der Abschnitt „Über“ |
| `awww` | Wallpaper-Daemon |
| `mpv` | Video-Wallpaper-Wiedergabe |
| `imagemagick` | Palettenextraktion, Thumbnails, Wallpaper-Tiling |
| `ffmpeg` | Video-Wallpaper-Thumbnails und Erste-Frame-Extraktion |
| `brightnessctl` | Helligkeitssteuerung |
| `power-profiles-daemon` | Energiesparprofile |
| `pipewire`, `pipewire-pulse`, `wireplumber` | Audio |
| `networkmanager` | Wi-Fi- und Netzwerkstatus |
| `bluez`, `bluez-utils`, `blueman` | Bluetooth |
| `qt6-declarative`, `qt6-svg`, `qt6-multimedia` | Qt-Laufzeit |
| `ttf-jetbrains-mono-nerd` | Symbolglyphen |
| `fontconfig` | Schriftsuche für den Farbwähler |
| `zenity` oder `kdialog` | Ordnerauswahl |
| `pavucontrol` | GUI zur Lautstärkeregelung |
| `wl-clipboard` | Zwischenablageverlauf |
| `slurp`, `grim` | Regions-Screenshots |
| `wlsunset` | Nachtlicht |
| `khal` | Kalenderagenda |
| `swayidle` | konfigurierte Leerlauf-Sperre oder Ruhezustand |

### Build

- `go` 1.25+

### Compositor

Einer von:

- **Hyprland** — `hyprland`, `hyprlock`, `xdg-desktop-portal-hyprland`
- **Niri** — `niri`, plus `base-devel`, `cmake`, `git` zum Bauen des `qml-niri`-Moduls

### Optional

- `vicinae` (AUR) — optionaler externer App-Launcher (die Shell enthält einen eingebauten Launcher)
- `mpvpaper` (AUR) — Video-Wallpaper-Daemon
- `cava` — Musikvisualisierer für die Leiste

Quickshell übernimmt Benachrichtigungen selbst — deaktiviere andere Benachrichtigungs-Daemons (z. B. Dunst), damit Toasts nicht dupliziert werden.

## `natonctl` bauen

`natonctl` wird von QML-Komponenten für Systemoperationen verwendet, darunter Helligkeit, Audio, Wetter und Wallpaper-Steuerung.

```bash
go build -C core -o ../quickshell/natonctl ./cmd/natonctl
```

Baue das Werkzeug neu und starte Quickshell neu, nachdem du Dateien unter `core/` geändert hast.

## Konfiguration

- Die gemeinsame Konfiguration liegt in `quickshell/Common/Config.qml`.
- Benutzereinstellungen werden von `quickshell/Common/SettingsStore.qml` in `quickshell/settings.json` gespeichert.
- Erscheinungsbild: Blur, Rahmen, Schatten, Palette, Typografie (Sans-/Mono-Schriftfamilie und Skalierung), Leisten-Geometrie und Ränder, Widget-Schalter pro Leisten-Element, Popup-Positionierung, Benachrichtigungen, OSD und Wallpaper-Rotation sind im Settings-Popup verfügbar.
- Die Einstellungsabschnitte umfassen Erscheinungsbild, Leiste, Desktop (Wallpaper), Zeit/Ort, Benachrichtigungen/OSD, System, Erweitert, Akku, Audio, Wi-Fi, Bluetooth und „Über“. Wi-Fi-, Bluetooth-, Audio-, Akku- und Helligkeitssteuerung wurden aus separaten Flyouts in diese Einstellungsabschnitte verlagert; die Helligkeit bleibt auf der Hauptseite des Control Centers.
- Video-Wallpaper-Einstellungen (Audio, Lautstärke, Hardware-Dekodierung und Pause in Niris Overview) liegen unter Einstellungen → Wallpaper.
- Regions-Screenshots nutzen `slurp` und `grim`; der Zwischenablageverlauf ist über `qs ipc call clipboard toggle` verfügbar.
- Globale Tastenkürzel werden unter Einstellungen → System → Tastenkürzel bearbeitet. Sie werden in `settings.json` gespeichert und in kompositorspezifische Bind-Overrides geschrieben: Standardwerte werden aus `quickshell/keybinds/` nach `~/.config/niri/naton/keybinds.kdl` (Niri) bzw. `~/.config/hypr/naton/keybinds.lua` (Hyprland) installiert, benutzerdefinierte Overrides unter `~/.config/niri/naton/binds.kdl` (Niri) bzw. `~/.config/hypr/naton/binds.lua` (Hyprland); der Compositor lädt sie automatisch neu.
- Das dynamische Thema speichert die extrahierte Wallpaper-Palette in `dynamicPalette` und wendet sie auf Shell-Oberflächen, Steuerelemente, Rahmen, Tracks und Workspace-Indikatoren an.

## Verifikation

```bash
git diff --check
quickshell --path quickshell
```

## Statistiken

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
