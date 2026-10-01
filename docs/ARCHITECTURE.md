# 架构设计规范 (ARCHITECTURE.md)

本项目旨在为 **Ubuntu 24.04 (GNOME + Wayland)** 环境量身定制一个现代、模块化、高可维护性的 **Quickshell Desktop Shell**。本项目吸收 `StatIndet/quickshell` (Clavis) 的优秀设计与组件经验，彻底重构其底层平台耦合，建立分层清晰、职责单一的现代桌面架构。

---

## 一、系统总体架构

```mermaid
graph TD
    subgraph SystemLayer [操作系统与底层驱动]
        Ubuntu[Ubuntu 24.04 LTS] --> Mutter[Mutter Compositor / GNOME Shell]
        Ubuntu --> SystemServices[PipeWire / NetworkManager / UPower / BlueZ]
        Ubuntu --> LinuxFS[/proc /sys sysfs Backlight]
    end

    subgraph WindowingLayer [窗口协议与通道]
        Mutter --> Wayland[Wayland Display: wayland-0]
        Mutter --> XWayland[XWayland Server: DISPLAY=:0 / EWMH]
        Mutter --> DBus[GNOME / FreeDesktop Session D-Bus]
    end

    subgraph QuickshellHost [Quickshell 引擎宿主]
        Wayland --> QS[Quickshell Runtime / QtQuick 6]
        XWayland --> QS
    end

    subgraph Architecture [Desktop Shell 架构分层]
        direction TB
        
        subgraph UILayer [UI 表现层 (QML Presentation)]
            TopBar[Top Bar 顶部状态胶囊栏]
            DynamicIsland[Dynamic Island / Keystone 灵动岛]
            Sidebar[Sidebar 侧边抽屉: Dashboard & QuickSettings]
            Popups[ControlCenter / PowerMenu / Launcher]
            Cards[Desktop Cards & Widgets]
        end

        subgraph ServiceLayer [应用服务层 (Application Services)]
            WS[WorkspaceService]
            WinS[WindowService]
            AudS[AudioService]
            MedS[MediaService]
            NetS[NetworkService]
            PowS[PowerService]
            NotS[NotificationService]
            SysS[SystemMonitorService]
            ThmS[ThemeService]
        end

        subgraph PlatformLayer [平台抽象与后端适配 (Platform Abstraction)]
            Platform[Platform.qml 门面调度]
            GnomeBackend[GnomeBackend: D-Bus & EWMH 适配]
            LinuxBackend[LinuxBackend: /proc & sysfs 原生驱动]
            GenericWayland[WaylandBackend: Layer-Shell / Screen 拓扑]
        end
    end

    QS --> UILayer
    UILayer --> ServiceLayer
    ServiceLayer --> PlatformLayer
    PlatformLayer --> DBus
    PlatformLayer --> XWayland
    PlatformLayer --> SystemServices
    PlatformLayer --> LinuxFS
```

---

## 二、三层解耦设计原则

为彻底避免将 UI 与具体合成器绑定，严格实施三层解耦：

### 1. UI 表现层 (UI Presentation Layer)
- **职责**：只负责视觉呈现、组件排版、手势与键鼠交互、动效过渡。
- **纪律**：
  - **禁止在 UI 控件中直接执行 shell 脚本或系统命令**。
  - **禁止在 UI 控件中直接判断特定窗口管理器名称 (如 `niri` 或 `gnome`)**。
  - 所有数据绑定统一指向 `Services.*` 单例属性。
  - 所有用户动作通过 `Services.*` 方法派发。

### 2. 业务服务层 (Application Services Layer)
- **职责**：维护全局业务状态机（如当前媒体播放进度、通知队列、折叠抽屉状态、系统性能指标等）。
- **特点**：提供跨平台通用的稳定接口定义，提供 QML 信号驱动状态变更。
- **示例接口**：
  ```qml
  // WorkspaceService
  readonly property var workspaces: []
  readonly property int currentWorkspaceIndex: 0
  function activateWorkspace(id)

  // WindowService
  readonly property var activeWindow: ({ title: "", appName: "", icon: "" })
  readonly property var windowList: []
  function closeWindow(id)
  ```

### 3. 平台抽象层 (Platform Abstraction Layer)
- **职责**：负责与底层系统 API 通信，屏蔽发行版和合成器差异。
- **实现模式**：
  - `Platform.qml` 自动检测当前运行环境（当前为 GNOME Wayland）。
  - 根据环境动态装配 `GnomeBackend`、`LinuxBackend` 或通用的 `WaylandBackend`。
  - 若某项特定能力当前环境不支持，提供优雅降级（Graceful Degradation），保证整个 Shell 依然稳定运行。

---

## 三、GNOME 特殊适配策略

Ubuntu 24.04 使用 GNOME Shell 46 + Mutter + Wayland。针对 GNOME 的特殊处理如下：

### 1. 窗口图层与面板 (PanelWindow / Layer-Shell)
- **背景**：Mutter 暂未原生合入 `zwlr_layer_shell_v1`。
- **策略**：
  - Quickshell 在 XWayland 激活环境下支持 X11 EWMH Dock (`_NET_WM_WINDOW_TYPE_DOCK` 与 `_NET_WM_STRUT_PARTIAL`)，可以完美在屏幕边缘保留专属空间而不被普通窗口遮挡。
  - 架构设计保持对未来 Wayland layer-shell 协议的透明兼容。

### 2. 工作区与窗口管理 (Workspaces & Active Window)
- **获取当前活动窗口与工作区**：
  - 首选方案：通过 XWayland 根窗口暴露的 EWMH 属性（`_NET_CURRENT_DESKTOP`、`_NET_NUMBER_OF_DESKTOPS`、`_NET_ACTIVE_WINDOW`）实时读取，低延迟且无需额外依赖。
  - 扩展方案：提供选配的超轻量 GNOME Shell Extension，通过 D-Bus 广播高精度 Wayland 原生窗口焦点事件。

### 3. 系统级控制与快捷操作
- **GNOME Overview 触发**：通过 GNOME D-Bus 接口 (`org.gnome.Shell.ShowApplications` 或快捷键绑定) 联动。
- **锁屏 / 登出 / 关机**：
  - 锁屏：调用 `loginctl lock-session`
  - 登出：调用 `gnome-session-quit --logout --no-prompt`
  - 关机/重启：调用 `systemctl poweroff` / `systemctl reboot`

### 4. 系统指标监控 (CPU/内存/网络/磁盘)
- **原项目缺陷**：依赖外部非标准的 `key-cli` 工具解析。
- **本项目重构**：直接由 `LinuxBackend` 读取 Linux 原生虚拟文件系统：
  - CPU 使用率：`/proc/stat`
  - 内存使用率：`/proc/meminfo`
  - 网络流量：`/proc/net/dev`
  - 采用定时器合理采样（默认 1000ms），绝不允许毫秒级密集轮询，保证极低 CPU 占用。

---

## 四、本项目推荐目录结构

```text
/home/dkp/projects/Ubuntu Quickshell Desktop Shell/
├── docs/                      # 架构、兼容性矩阵与开发指南
│   ├── ARCHITECTURE.md
│   ├── PORTABILITY_MATRIX.md
│   ├── ROADMAP.md
│   └── GNOME_BACKEND.md
├── src/
│   ├── shell.qml              # Quickshell 顶层入口
│   ├── AppShell.qml           # 顶层组件装配
│   │
│   ├── common/                # 设计体系与全局令牌
│   │   ├── Appearance.qml     # 调色盘与 Material 3 颜色计算
│   │   ├── Animations.qml     # 贝塞尔曲线与时间度量
│   │   ├── Sizes.qml          # 尺寸、圆角、间距度量
│   │   ├── Typography.qml     # 字体字阶系统
│   │   └── Paths.qml          # 路径与资源查找
│   │
│   ├── components/            # 跨业务可复用基础 UI 组件
│   │   ├── TopBarPill.qml     # 状态栏胶囊卡片容器
│   │   ├── MaterialSlider.qml # M3 风格滑块
│   │   ├── MaterialSwitch.qml # M3 开关控件
│   │   ├── SurfaceCard.qml    # 带模糊与圆角的卡片基类
│   │   └── IconLabel.qml      # 图标文本自适应组合
│   │
│   ├── widgets/               # 展示型小组件
│   │   ├── ClockWidget.qml    # 时钟小部件
│   │   ├── BatteryWidget.qml  # 电池指示小部件
│   │   ├── VolumeWidget.qml   # 音量指示小部件
│   │   ├── NetworkWidget.qml  # 网络状态小部件
│   │   └── SysInfoWidget.qml  # 性能指示小部件
│   │
│   ├── modules/               # 独立业务模块
│   │   ├── Bar/               # 顶部主状态栏
│   │   ├── Sidebars/          # 侧边栏 (Dashboard & QuickSettings)
│   │   ├── Keystone/          # 灵动岛 (Dynamic Island)
│   │   ├── Launcher/          # 应用启动器 / 聚焦搜索
│   │   ├── PowerMenu/         # 电源菜单
│   │   └── Notifications/     # 通知呈现与弹窗
│   │
│   ├── services/              # 业务服务单例
│   │   ├── AudioService.qml
│   │   ├── MediaService.qml
│   │   ├── NetworkService.qml
│   │   ├── PowerService.qml
│   │   ├── WorkspaceService.qml
│   │   ├── WindowService.qml
│   │   ├── BrightnessService.qml
│   │   ├── SystemMonitorService.qml
│   │   ├── ThemeService.qml
│   │   └── NotificationService.qml
│   │
│   ├── platform/              # 平台与合成器后端抽象
│   │   ├── Platform.qml       # 后端调度门面
│   │   ├── GnomeBackend.qml   # GNOME / Mutter / D-Bus 适配
│   │   ├── LinuxBackend.qml   # Linux 标准 /proc /sys 驱动
│   │   └── WaylandBackend.qml # Wayland 原生协议接口
│   │
│   └── utils/                 # 工具函数
│       ├── StringUtils.js
│       └── ColorUtils.js
│
├── assets/                    # 图标、着色器与字体资源
│   ├── icons/
│   ├── shaders/
│   └── fonts/
│
└── tests/                     # 验证与测试用例
```
