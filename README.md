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

## 核心设计文档

- 📐 [架构设计规范 (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)：三层解耦原则、GNOME 适配策略与目录规范。
- 🔍 [可移植性分析矩阵 (docs/PORTABILITY_MATRIX.md)](docs/PORTABILITY_MATRIX.md)：参考项目模块逐项移植评估与替代方案。
- 🗺️ [阶段演进路线图 (docs/ROADMAP.md)](docs/ROADMAP.md)：Phase 0 至 Phase 7 渐进式实施规划。

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
