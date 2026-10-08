# Ubuntu Quickshell Desktop Shell

以 [StatIndet/quickshell](https://github.com/StatIndet/quickshell) 为视觉与工程参考，面向 **Ubuntu 24.04 + GNOME + Wayland** 环境，基于 **Quickshell / QML / Qt 6** 重新设计并构建的现代化 Linux Desktop Shell。

---

## 项目愿景与设计理念

本项目致力于在保留 Ubuntu 24.04 及 GNOME 稳定系统服务的前提下，以 Quickshell 作为顶层用户交互与桌面体验呈现层。

核心原则：
- **不替换底层发行版**：完全基于 Ubuntu 24.04 LTS (Noble Numbat) 与 GNOME 46。
- **解耦平台绑定**：剥离原项目与 niri 合成器的强耦合，构建高内聚、低耦合的通用平台抽象层。
- **分层清晰**：严格遵循 `UI 表现层 -> 业务服务层 -> 平台抽象层`，UI 控件不直接调用系统命令或底层专属 IPC。
- **现代克制的视觉**：基于 Material Design 3 规范与设计令牌，追求层级清晰、质感优雅的桌面体验。

---

## 系统分层架构

```text
                    Ubuntu 24.04
                          │
                       Wayland
                          │
                     GNOME/Mutter
                          │
                    ┌─────▼─────┐
                    │ Quickshell│
                    └─────┬─────┘
                          │
             ┌────────────┼────────────┐
             │            │            │
          UI Layer    Service Layer  Platform Layer
             │            │            │
        ┌────┴────┐   ┌───┴────┐   ┌───┴────┐
        │ TopBar  │   │ Media  │   │ GNOME  │
        │ Sidebar │   │ Audio  │   │ Linux  │
        │ Panel   │   │ Network│   │ Wayland│
        │ Widget  │   │ Power  │   │ D-Bus  │
        └─────────┘   └────────┘   └────────┘
```

---

## 核心设计与交接文档

- 📖 **[Agent 权威交接文档与全周期踩坑复盘手册 (docs/AGENT_HANDOVER_AND_POSTMORTEM.md)](docs/AGENT_HANDOVER_AND_POSTMORTEM.md)**：包含 M1~M15 全量交付矩阵、7 大深水区踩坑复盘、5 大预防铁律及交付子系统技术详解。
- 📐 [架构设计规范 (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)：1:1 源码级镜像分层架构、Matugen 调色管道与 Mutter 适配规范。
- 📋 [Master-Worker Agent 集群作业 SOP (docs/AGENT_CLUSTER_SOP.md)](docs/AGENT_CLUSTER_SOP.md)：子 Agent 任务卡签发标准与多宿主窗口验收硬门禁。
- 🚀 [部署与开机自启运维指南 (docs/DEPLOYMENT_AND_AUTOSTART.md)](docs/DEPLOYMENT_AND_AUTOSTART.md)：Systemd 用户服务配置、`clavisctl` CLI 工具与开机自启运维。
- 💻 [动态硬件自适应矩阵 (docs/HARDWARE_ADAPTATION_MATRIX.md)](docs/HARDWARE_ADAPTATION_MATRIX.md)：台式机/笔记本、有线/无线、硬件/软件背光自适应矩阵。

---

## 快速安装与运维管理 (`clavisctl`)

在具备 Nix 环境的 Ubuntu 24.04 系统中，执行一键部署：

```bash
# 一键安装服务、开机自启桌面条目与命令行工具
./scripts/install.sh --enable --start

# 日常运维与健康检查
clavisctl status     # 查看服务状态、PID、X11 窗口几何树与 IPC 响应
clavisctl restart    # 重启桌面 Shell
clavisctl stop       # 停止 Shell 并自动恢复 GNOME 原生顶栏
clavisctl logs -f    # 跟踪实时日志

# 交互切换指令
clavisctl toggle spotlight       # 呼出/收起聚光灯搜索
clavisctl toggle controlcenter   # 呼出/收起控制中心设置
clavisctl toggle powermenu       # 呼出/收起电源菜单
clavisctl toggle quicksettings   # 展开/收起右侧快捷设置
clavisctl toggle lock            # 锁屏
clavisctl toggle screenshot      # 呼出区域截图选区
clavisctl toggle color           # 呼出屏幕拾色器
```

---

## 目录结构规划

```text
.
├── docs/                      # 核心架构与兼容性技术文档
├── src/
│   ├── shell.qml              # Quickshell 运行入口
│   ├── AppShell.qml           # 顶层组件装配
│   ├── common/                # Material 3 设计系统、色彩与动效令牌
│   ├── components/            # 胶囊栏、滑块等基础可复用 UI 控件
│   ├── widgets/               # 时钟、电池、音量等展示小部件
│   ├── modules/               # TopBar、Sidebars、Launcher 等业务模块
│   ├── services/              # 媒体、音频、网络、工作区等状态单例
│   ├── platform/              # GNOME、Linux、Wayland 平台抽象后端
│   └── utils/                 # 工具函数库
└── assets/                    # 图标、着色器与字体
```

---

## License

GPL-3.0 License.
