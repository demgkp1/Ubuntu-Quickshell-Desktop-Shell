# 可移植性分析矩阵 (Portability Matrix)

> 基于对参考项目 `StatIndet/quickshell` (Clavis) 源码与 Ubuntu 24.04 + GNOME + Wayland 本机环境的深度技术分析。

---

## 一、移植状态定义

| 图标 | 状态 | 说明 |
|---|---|---|
| 🟢 | **直接复用 / 低改动** | 遵循标准 Linux/FreeDesktop 规范或使用 Quickshell 内置跨平台服务，无特定合成器绑定 |
| 🟡 | **小幅修改 / 适配** | 核心逻辑可用，但需剥离个别 Niri 调用或对接 GNOME 设置 (如 gsettings) |
| 🟠 | **需重新实现 (GNOME Backend)** | 原方案与 Niri IPC 强耦合，需在 GNOME 下通过 D-Bus、EWMH 或轻量拓展重新实现后端 |
| 🔴 | **Niri 专属 / 废弃** | 属于 Niri 特有合成器逻辑或私有 IPC 协议，本项目不移植 |

---

## 二、Core 原生模块移植分析

| 模块 / 文件 | 原项目实现方式 | 可移植性 | Ubuntu 24.04 + GNOME 替代方案 |
|---|---|---|---|
| `niri_ipc_client.*` | 连接 `NIRI_SOCKET` Unix 套接字流式解析 JSON | 🔴 | 废弃。由 `GnomeBackend` (D-Bus / EWMH) 替代 |
| `niri_workspace_model.*` | 解析 Niri Workspaces 动态增删与 focus 事件 | 🔴 | 废弃。由 `WorkspaceService` 抽象接口替代 |
| `niri_window_model.*` | 解析 Niri Window 树与聚焦窗口 | 🔴 | 废弃。由 `WindowService` 抽象接口替代 |
| `niri_output_model.*` | Niri 屏幕几何与缩放事件 | 🔴 | 废弃。使用 `Quickshell.screens` 原生屏幕模型 |
| `weather_backend.*` / `openmeteo_client.*` | Open-Meteo REST API 客户端与缓存 | 🟢 | 直接复用或 QML 纯逻辑实现（标准 HTTPS JSON） |
| `weather_map_provider.*` | 雷达图 / 气象图瓦片下载与渲染 | 🟢 | 直接复用（基于 Qt Network 与 QQuickImageProvider） |
| `audio_collector.*` / `audio_level_collector.*` | PipeWire 原生音频流能量监控 | 🟢 | 直接复用（依赖系统 `libpipewire-0.3`） |
| `media_palette_backend.*` | 从专辑封面图像提取 Material You 配色 | 🟢 | 直接复用（纯图像处理与算法库） |

---

## 三、Services 服务层移植分析

| 服务名称 | 原项目依赖 | 可移植性 | GNOME 适配策略 |
|---|---|---|---|
| **Audio (Volume.qml)** | `Quickshell.Services.Pipewire` | 🟢 | 直接复用。Ubuntu 24.04 默认运行 PipeWire + WirePlumber |
| **Media (MediaManager.qml)** | `Quickshell.Services.Mpris` | 🟢 | 直接复用。MPRIS 为标准 D-Bus 规范，支持 Chrome/Spotify/VLC 等 |
| **Power (PowerService.qml)** | `Quickshell.Services.UPower` | 🟢 | 直接复用。标准 FreeDesktop UPower D-Bus 服务 |
| **Network (NetworkService.qml)** | `Quickshell.Networking` (NetworkManager) | 🟢 | 直接复用。Ubuntu 24.04 默认使用 NetworkManager |
| **Bluetooth (BluetoothService.qml)** | `Quickshell.Bluetooth` (BlueZ) | 🟢 | 直接复用。标准 BlueZ D-Bus 栈 |
| **Time (Time.qml)** | Qt 原生时钟 | 🟢 | 直接复用 |
| **Appearance / Animations / Sizes** | Material 3 动效曲线、尺寸与设计令牌 | 🟢 | 直接复用作为统一视觉体系基础 |
| **Brightness (Brightness.qml)** | sysfs backlight + `Niri.currentOutput` | 🟡 | 剥离 Niri 输出关联，通过平台抽象获取当前活动屏幕或标准 sysfs 控制 |
| **ThemeService.qml** | Matugen + Niri 光标同步 | 🟡 | 保留 Matugen 调色算法；移除 Niri 光标同步，对接 GNOME gsettings (`org.gnome.desktop.interface`) |
| **IdleService.qml** | `niri msg action power-off-monitors` | 🟡 | 替换为 GNOME Mutter `org.gnome.Mutter.DisplayConfig` 或 `loginctl` 锁屏/休眠 |
| **NotificationManager.qml** | `Quickshell.Services.Notifications` | 🟡 | 兼容设计：若独立接管通知则启动 D-Bus 监听，若与 GNOME 共存则可作为历史聚合与状态显示 |
| **SystemMonitorService.qml** | 依赖外部 `key-cli` 命令行流 | 🟡 | 剥离私有 CLI 依赖；采用直接读取 Linux `/proc/stat`、`/proc/meminfo` 的轻量原生服务 |
| **WorkspaceService** (新增抽象) | 原直接绑定 `Clavis.Niri` | 🟠 | 重新实现。GNOME 下使用 XWayland EWMH (`_NET_CURRENT_DESKTOP`) 或 GNOME D-Bus 扩展 |
| **WindowService** (新增抽象) | 原直接绑定 `Niri.focusedWindow` | 🟠 | 重新实现。GNOME 下使用 EWMH (`_NET_ACTIVE_WINDOW`) 或 GNOME D-Bus 扩展 |
| **DisplayConfigService.qml** | 原绑定 `Niri.outputSnapshot` | 🟠 | 重新实现。对接 `Quickshell.screens` 或 `org.gnome.Mutter.DisplayConfig` |
| **NiriConfigService.qml** | Niri KDL 配置文件读写 | 🔴 | 废弃。由 Shell 本地 JSON / QSettings 配置替代 |

---

## 四、UI 与组件层移植分析

| UI 模块 | 原模块位置 | 可移植性 | 移植工作与改动点 |
|---|---|---|---|
| **TopBar (Bar)** | `Modules/Bar/` | 🟡 | 复用布局、Capsule 视觉和交互结构；Workspaces & ActiveWindow 改接抽象服务 |
| **Workspaces Pill** | `Modules/Bar/Workspaces/` | 🟠 | UI 胶囊动画与点击切换复用；数据源改接 `WorkspaceService` |
| **ActiveWindow Pill** | `Modules/Bar/ActiveWindow/` | 🟠 | UI 图标与标题渐变复用；数据源改接 `WindowService` |
| **Media Player Card** | `Modules/Bar/Media/` | 🟢 | 完美复用，基于 MPRIS |
| **QuickSettings Bar/Popup** | `Modules/Bar/QuickSettings/` | 🟢 | 完美复用，基于 Audio/Network/Bluetooth/Power 服务 |
| **SysMonitor Widget** | `Modules/Bar/SysMonitor/` | 🟢 | 视觉复用，改接系统指标服务 |
| **Tray Pill** | `Modules/Bar/Tray/` | 🟢 | 基于 SNI / StatusNotifierItem，标准 D-Bus 托盘 |
| **Sidebar (Dashboard)** | `Modules/Sidebars/Dashboard/` | 🟢 | 日历、天气、系统监控、通知中心卡片结构完整复用 |
| **Sidebar (QuickSettings)** | `Modules/Sidebars/QuickSettings/` | 🟢 | 音频滑块、网络列表、蓝牙设备面板完整复用 |
| **Dynamic Island (Keystone)** | `Modules/Keystone/` | 🟡 | 视觉与展开动效复用；移除 Niri overview 绑定，改接全局通用触发器 |
| **Launcher / Spotlight** | `Modules/Launcher/` | 🟡 | 桌面入口（.desktop 搜索）复用；移除 Niri 窗口切换，改用标准 app 启动 |
| **PowerMenu** | `Modules/PowerMenu/` | 🟢 | 锁屏/注销/重启/关机；注销改为 `gnome-session-quit`，关机走 `systemctl` |
| **Lock Screen** | `Modules/Lock/` | 🟡 | 可选使用 Quickshell 锁屏或委托给 GNOME 锁屏 (`loginctl lock-session`) |
| **HotCorners** | `Modules/HotCorners/` | 🟡 | GNOME 自身已有热角机制；若在 Quickshell 中实现，改调 GNOME Overview |

---

## 五、外部工具依赖分析与替代

| 依赖项 | 原用途 | GNOME 环境状态 | 替代 / 集成方案 |
|---|---|---|---|
| `quickshell` | QML 运行环境与窗口管理 | 需安装 | 通过 PPA `avengemedia/danklinux` 或源码编译安装 |
| `qt6-base` / `declarative` | QML/Qt 核心运行时 | 系统已安装 6.4.2 | 基础库就绪，若编译原生插件安装 `-dev` 包即可 |
| `niri` | 平铺 Wayland 合成器 | 不安装 (GNOME) | 平台抽象层隔离，全面使用 GNOME/Mutter 对应接口 |
| `pipewire` / `wireplumber` | 音频引擎 | 系统已运行 (Active) | 直接通过 `Quickshell.Services.Pipewire` 对接 |
| `matugen` | Material You 调色 CLI | 可选工具 | 可独立安装二进制作为壁纸主题自动提取器 |
| `key-cli` | 原项目配套 CLI (监控/录音) | 不依赖 | 采用标准 Linux `/proc` 文件接口，避免私有工具依赖 |
| `awww` | Wayland 动态壁纸守护进程 | 不强制 | 可使用 Quickshell 自身壁纸窗口，或使用 GNOME 背景设置 |
| `wlogout` | 登出管理器 | 不需要 | 使用本项目内置 Material 3 风格 PowerMenu |
