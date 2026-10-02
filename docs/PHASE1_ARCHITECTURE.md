# Phase 1 架构设计规范与设计系统基石 (PHASE1_ARCHITECTURE.md)

## 一、概述与核心目标

在 Phase 0 验证了 Quickshell 运行时与 GNOME Wayland 环境连通性的基础上，Phase 1 的首要任务是**确立长期可扩展、高内聚低耦合的代码组织架构与设计系统规范**。

为避免传统桌面 Shell 项目常见的“UI、系统调用与特定合成器强绑定”的痛点，本项目在开发具体 TopBar UI 之前，先完成以下基石建设：
1. **模块化目录架构**：将工程严格解耦为 `windows/`、`components/`、`services/`、`theme/` 四大核心领域。
2. **GNOME Wayland 窗口适配策略**：确立以 `FloatingWindow` 为基础的窗口适配器模式，彻底屏蔽 Mutter 缺失 layer-shell 的影响，并保留未来无缝切换至 layer-shell 合成器的架构能力。
3. **Design Token (设计令牌) 系统**：建立由 `Theme` 门面统一调度的色彩、尺寸、排版和动效标准。
4. **验证最小骨架**：保证所有模块通过 `qmldir` 与单例机制无缝协作，杜绝硬编码样式。

---

## 二、项目目录结构与职责划分

```text
src/
├── shell.qml                 # 顶层入口 (ShellRoot 调度)
│
├── theme/                    # 【设计系统】全局设计令牌与视觉门面
│   ├── qmldir                # 单例声明
│   ├── Theme.qml             # 门面聚合单例 (Colors / Sizes / Typography / Animations)
│   ├── Colors.qml            # 语义化色彩体系 (Catppuccin + Ubuntu Warm Orange)
│   ├── Sizes.qml             # 4px 栅格、间距、圆角与窗口组件规格
│   ├── Typography.qml        # 字体家族、字阶与字重枚举
│   └── Animations.qml        # 动效时长常量与缓动贝塞尔曲线
│
├── windows/                  # 【窗口宿主】顶层窗口生命周期与协议适配
│   ├── qmldir
│   └── TopBarWindow.qml      # 顶部栏窗口宿主适配器 (封装 FloatingWindow)
│
├── components/               # 【组件库】原子/分子级可复用纯 UI 控件
│   ├── qmldir
│   └── Pill.qml              # 基础胶囊卡片容器 (自适应内容、交互悬停与主题边框)
│
└── services/                 # 【服务层】系统状态机、数据模型与单例提供者
    ├── qmldir
    └── TimeService.qml       # 全局精准时间与日期服务 (无重复轮询、按秒同步)
```

### 职责边界原则

| 目录 | 职责 | 严禁事项 |
| :--- | :--- | :--- |
| `theme/` | 定义全局视觉常量与计算函数 | 严禁包含具体 UI 控件或平台状态调用 |
| `windows/` | 管理窗口几何、透明度、CSD 行为与合成器协议适配 | 严禁堆砌复杂业务 UI（只作为容器 slot 承载 content） |
| `components/` | 负责纯粹的视觉渲染与交互反馈（通过属性入参，信号派发） | 严禁直接调用系统命令，严禁感知自身被何种窗口所承载 |
| `services/` | 管理全局状态机、定时器、D-Bus 通信、原生文件系统数据流 | 严禁包含任何 QML 视觉元素（如 Rectangle、Text） |

---

## 三、Ubuntu GNOME Wayland 环境下的窗口策略

### 1. 协议现状与核心约束
- **现状**：Ubuntu 24.04 默认使用 **GNOME 46 + Mutter (Wayland)**。Mutter 截至目前**并未合入** wlroots 的 `zwlr_layer_shell_v1` 协议。
- **约束**：Quickshell 的 `PanelWindow` 强依赖 layer-shell 协议，直接在 Mutter 下运行会导致 `WARN: Failed to initialize layershell integration` 错误，无法正常呈现或锚定。
- **验证**：Quickshell 的 `FloatingWindow` 基于 Wayland 标准 `xdg-shell` 协议（`xdg_toplevel`），在 Mutter 下完全原生支持并稳定渲染。

### 2. 当前阶段方案：窗口适配器模式 (Window Adapter Pattern)
1. **使用 `FloatingWindow` 作为当前宿主**：
   - 在 [`src/windows/TopBarWindow.qml`](file:///home/dkp/projects/Ubuntu%20Quickshell%20Desktop%20Shell/src/windows/TopBarWindow.qml) 中，将 `FloatingWindow` 封装为窗口适配器。
   - 通过 `@pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1` 禁用客户端窗口阴影与标题栏装饰。
   - 窗口底色设为透明，视觉边界完全交由内部 UI 胶囊容器定义。
2. **内容插槽解耦**：
   - 窗口通过 `default property alias content: contentContainer.data` 对外暴露插槽。
   - 所有顶栏卡片、胶囊均作为子项放入该插槽中，使得 UI 逻辑与外层窗口彻底解耦。

### 3. 未来平滑迁移路线 (Migration Path)
当运行环境切换至支持 layer-shell 的合成器（例如后续选配 Niri、Hyprland、Sway，或 GNOME Mutter 未来支持 layer-shell）时：
- **UI 与服务 0 成本复用**：`components/`、`services/`、`theme/` 中的所有代码无需更改任何一行。
- **仅需替换适配器**：将 `TopBarWindow.qml` 内部的 `FloatingWindow` 替换为 `PanelWindow`，并声明：
  ```qml
  PanelWindow {
      anchors {
          top: true
          left: true
          right: true
      }
      exclusiveZone: Theme.sizes.topBarHeight
  }
  ```

---

## 四、Theme / Design Token 系统设计

### 1. 调色板 (`Colors.qml`)
采用现代化暗色桌面美学，融合 **Catppuccin Mocha** 深色系与 **Ubuntu Warm Orange** 品牌特征色：

| 语义分类 | 令牌名称 | 默认色值 | 设计用途 |
| :--- | :--- | :--- | :--- |
| **底色 (Base)** | `crust` | `#11111B` | 最底层背板 |
| | `mantle` | `#181825` | 窗口宿主与大面板背景 |
| | `base` | `#1E1E2E` | 胶囊与卡片标准背景底色 |
| **表面 (Surfaces)** | `surface0` | `#313244` | 卡片悬停/次级胶囊填充 |
| | `surface1` | `#45475A` | 激活/按下状态填充 |
| | `surface2` | `#585B70` | 高亮表面 |
| **边界 (Borders)** | `borderSubtle` | `#22FFFFFF` | 胶囊默认细微半透明边缘 |
| | `border` | `#313244` | 标准实色边框 |
| | `borderHighlight` | `#A6E3A1` | 成功/对齐高亮边缘 |
| **文本 (Typography)** | `text` | `#CDD6F4` | 主文本（高对比白微蓝） |
| | `textSecondary` | `#BAC2DE` | 次级信息、时间与副标题 |
| | `textMuted` | `#6C7086` | 提示性、禁用文字 |
| **强调与状态** | `primary` | `#E95420` | **Ubuntu 标志性暖橙色** |
| | `primaryHover` | `#FF6E38` | 主题色悬停反馈 |
| | `success` | `#A6E3A1` | 成功/在线指示点 |
| | `warning` | `#F9E2AF` | 警告/低电量提示 |
| | `error` | `#F38BA8` | 错误/断网指示 |
| | `info` | `#89B4FA` | 信息通知颜色 |

同时提供 `alpha(color, opacity)` 辅助函数，确保玻璃拟态和动态透明度渲染的色彩正确性。

### 2. 空间与尺寸度量 (`Sizes.qml`)
遵循 4px 基础网格系统：
- **网格基数**：`gridUnit = 4`
- **间距梯度**：
  - `spacingXxs: 2`、`spacingXs: 4`、`spacingSm: 8`、`spacingMd: 12`、`spacingLg: 16`、`spacingXl: 24`
- **圆角规范**：
  - `radiusXs: 4`、`radiusSm: 8`、`radiusMd: 12`、`radiusLg: 16`、`radiusPill: 9999`（完整胶囊圆角）
- **顶部栏组件度量**：
  - 顶部栏标准高度：`topBarHeight = 44px`
  - 胶囊标准高度：`pillHeight = 32px`
  - 胶囊水平内边距：`pillPaddingHorizontal = 12px`
  - 胶囊垂直内边距：`pillPaddingVertical = 6px`
  - 胶囊间距：`pillSpacing = 8px`
  - 图标规格：小号 `14px`、中号 `16px`、大号 `20px`

### 3. 排版体系 (`Typography.qml`)
- **字体家族**：
  - `familySans`: `"Ubuntu, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"`
  - `familyMono`: `"Ubuntu Mono, 'JetBrains Mono', 'Fira Code', monospace"`
- **字重枚举**：
  - `weightLight`: 300
  - `weightNormal`: 400
  - `weightMedium`: 500
  - `weightDemiBold`: 600
  - `weightBold`: 700
- **字号阶梯**：
  - `sizeCaption = 11px`（状态小标签）
  - `sizeBodySmall = 12px`（次要文字）
  - `sizeBody = 13px`（胶囊文本与主标签）
  - `sizeBodyLarge = 14px`（突出标题）
  - `sizeTitleSmall = 16px`、`sizeTitle = 18px`、`sizeDisplay = 24px`（时钟与卡片大标题）

### 4. 动效规范 (`Animations.qml`)
- **时长分类**：
  - `instant = 0ms`：无过渡
  - `fast = 150ms`：微交互（如胶囊悬停、边框变色）
  - `normal = 250ms`：尺寸展开、胶囊滑动
  - `slow = 400ms`：弹窗、抽屉进出动效
- **缓动曲线**：
  - `easeOut = Easing.OutCubic`（进入与交互动效）
  - `easeInOut = Easing.InOutCubic`（状态流转）
  - `easeIn = Easing.InCubic`（退出动效）

---

## 五、架构验证总结

在 [`src/shell.qml`](file:///home/dkp/projects/Ubuntu%20Quickshell%20Desktop%20Shell/src/shell.qml) 中，已成功串联验证：
1. `TopBarWindow` 成功作为窗口适配器启动。
2. `Pill` 组件成功渲染，具备流畅的悬停动画和主题边框。
3. `Theme` 令牌系统无缝生效。
4. `TimeService` 服务每秒驱动时钟胶囊更新。
5. 整个 QML 体系在 Nix 环境下 0 报错，已为 Phase 1 真正的 TopBar 核心功能开发奠定了最坚实的基础。
