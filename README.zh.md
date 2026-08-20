<div align="center">

<p align="center">
    <img src="docs/logo.svg" alt="Naton logo" width="160">
</p>

`Naton` 是一个基于 Quickshell、QML 和 Go 构建的可定制 Wayland 桌面外壳，支持 Hyprland 与 Niri。

[English](README.md) · [Русский](README.ru.md) · **中文** · [Deutsch](README.de.md)

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

## 功能

- 面板可放置在上、下、左、右边缘，并支持可配置边距。
- 工作区切换器、聚焦应用指示器、时钟、天气、媒体、托盘和系统小部件，均可独立开关。
- 日历、媒体、电源和设置弹窗锚定到面板，随面板位置移动。Wi-Fi、蓝牙、音频、电池和亮度位于各自的设置分区中。
- 紧凑的控制中心：胶囊快捷操作（Wi-Fi、蓝牙、勿扰、保持亮屏）、截图按钮、亮度和音量滑块、CPU/RAM/磁盘统计、电源配置、主题和带切歌的媒体控制。
- 扬声器和麦克风音量分离控制，支持 PipeWire 设备选择。
- 统一的 MPRIS 控制器，带专辑封面、实时播放进度、面板元数据，以及带有模糊封面背景的媒体弹窗。
- 通知通知条和通知中心，支持按应用静音和可选声音；列表顺序跟随面板位置（面板在上时从上到下，在下时从下到上）。
- 可搜索的启动器（应用、窗口、shell 命令、计算器提供方）；剪贴板历史；停靠/任务栏；来自 khal 的日历日程。
- 壁纸选择器带提取的色彩调色板和动态主题，从当前壁纸为外壳表面着色。七种调色板方案（`vibrant`、`faithful`、`dysfunctional`、`muted`、`soft`、`material`、`monochrome`），壁纸切换间有平滑的颜色过渡动画。
- 通过 `mpvpaper` 支持视频壁纸，通过 `awww` 提供静态首帧回退，支持声音、硬件解码、缩放以及在 Niri 概览中暂停的设置。
- 主题、面板、字体（独立的 sans 和 mono 字体族，可独立缩放）、通知、OSD、壁纸行为和外壳外观的持久化设置。
- 空闲策略：通过 `swayidle` 在可配置超时后锁定会话或挂起。

## 结构

```text
.
├── quickshell/               # Quickshell 配置
│   ├── shell.qml             # Quickshell 入口点
│   ├── Common/               # 共享配置与单例服务
│   ├── Modules/              # 面板、弹窗和设置
│   ├── Widgets/              # 可复用 QML 组件
│   ├── Services/             # QML 服务
│   ├── keybinds/             # 各合成器的键绑定片段（安装到 naton 配置文件夹）
│   └── translations/         # UI 翻译
├── core/                     # natonctl 的 Go 模块
│   ├── cmd/natonctl/          # natonctl 命令入口点
│   ├── internal/natonctl/     # 外壳特定命令实现
│   ├── pkg/                  # 公共 Go 包
│   ├── go.mod
│   └── go.sum
└── install.sh                # Arch Linux 安装脚本
```

## 运行

在仓库根目录：

```bash
quickshell --path quickshell
```

要自动启动外壳，创建指向项目目录的符号链接：

```bash
ln -s "$(pwd)/quickshell" ~/.config/quickshell
```

## 安装

内置安装脚本针对 Arch Linux。它安装仓库和 AUR 依赖、构建 `natonctl`，并将本仓库链接到 `~/.config/quickshell`，不会替换现有配置。

```bash
./install.sh
```

对于 Niri，请安装事件驱动的 `qml-niri` 集成作为必需依赖：

```bash
./install.sh --compositor niri
```

当 Vicinae 或 `mpvpaper` 未安装时需要 `yay` 或 `paru`，因为它们从 AUR 安装。

## 依赖

### 运行时

| 包 | 说明 |
| --- | --- |
| `quickshell` | 外壳运行时 |
| `curl` | 天气、节假日和“关于”分区 |
| `awww` | 壁纸守护进程 |
| `mpv` | 视频壁纸播放 |
| `imagemagick` | 调色板提取、缩略图、壁纸平铺 |
| `ffmpeg` | 视频壁纸缩略图和首帧提取 |
| `brightnessctl` | 亮度控制 |
| `power-profiles-daemon` | 电源配置 |
| `pipewire`, `pipewire-pulse`, `wireplumber` | 音频 |
| `networkmanager` | Wi-Fi 和网络状态 |
| `bluez`, `bluez-utils`, `blueman` | 蓝牙 |
| `qt6-declarative`, `qt6-svg`, `qt6-multimedia` | Qt 运行时 |
| `ttf-jetbrains-mono-nerd` | 图标字形 |
| `fontconfig` | 颜色选择器的所选字体查找 |
| `zenity` 或 `kdialog` | 文件夹选择器 |
| `pavucontrol` | 音量控制 GUI |
| `wl-clipboard` | 剪贴板历史 |
| `slurp`, `grim` | 区域截图 |
| `wlsunset` | 夜间模式 |
| `khal` | 日历日程 |
| `swayidle` | 配置的空闲锁定或挂起策略 |

### 构建

- `go` 1.25+

### 合成器

以下之一：

- **Hyprland** — `hyprland`, `hyprlock`, `xdg-desktop-portal-hyprland`
- **Niri** — `niri`, 外加 `base-devel`, `cmake`, `git` 用于构建 `qml-niri` 模块

### 可选

- `vicinae`（AUR）— 可选的外部应用启动器（外壳内置启动器）
- `mpvpaper`（AUR）— 视频壁纸守护进程
- `cava` — 面板音乐可视化器

Quickshell 自行处理通知 — 请禁用任何其他通知守护进程（如 Dunst），以免通知条重复。

## 构建 `natonctl`

QML 组件使用 `natonctl` 进行系统操作，包括亮度、音频、天气和壁纸控制。

```bash
go build -C core -o ../quickshell/natonctl ./cmd/natonctl
```

修改 `core/` 下的文件后，重新构建该工具并重启 Quickshell。

## 配置

- 共享配置位于 `quickshell/Common/Config.qml`。
- 用户设置由 `quickshell/Common/SettingsStore.qml` 持久化到 `quickshell/settings.json`。
- 外观设置：模糊、边框、阴影、调色板、字体（sans/mono 字体族和缩放）、面板几何和边距、按部件开关的面板项、弹窗定位、通知、OSD 和壁纸轮换，均可在 Settings 弹窗中设置。
- 设置弹窗分区涵盖外观、面板、桌面（壁纸）、时间/位置、通知/OSD、系统、高级、电池、音频、Wi-Fi、蓝牙和“关于”。Wi-Fi、蓝牙、音频、电池和亮度控制已从独立的弹出式浮窗移入这些设置分区；亮度保留在控制中心主页面上。
- 视频壁纸设置（音频、音量、硬件解码和 Niri 概览中的暂停）位于 Settings → 壁纸。
- 区域截图使用 `slurp` 和 `grim`；剪贴板历史可通过 `qs ipc call clipboard toggle` 打开。
- 全局键盘快捷键在 Settings → System → 键盘快捷键中编辑。它们持久化到 `settings.json`，并写入各合成器的键绑定覆盖：默认值从 `quickshell/keybinds/` 安装到 `~/.config/niri/naton/keybinds.kdl`（Niri）或 `~/.config/hypr/naton/keybinds.lua`（Hyprland），用户覆盖位于 `~/.config/niri/naton/binds.kdl`（Niri）或 `~/.config/hypr/naton/binds.lua`（Hyprland），合成器会自动重新加载它们。
- 动态主题将提取的壁纸调色板存储在 `dynamicPalette` 中，并将其应用于外壳表面、控件、边框、轨道和工作区指示器。

## 验证

```bash
git diff --check
quickshell --path quickshell
```

## 统计

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
