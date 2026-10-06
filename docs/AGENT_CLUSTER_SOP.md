# Master-Worker Agent 集群作业 SOP 规范
*(Standard Operating Procedure for Multi-Agent Porting Cluster)*

---

## 一、 集群架构与工作流概览

本项目采用 **主控 Agent (Master Controller) + 专业子 Agent (Subagent Workers)** 协同作业模式。

```mermaid
flowchart TD
    User["用户 (User)"] <--> Master["主控 Agent (Master Controller)"]
    
    subgraph Cluster [子 Agent 矩阵 (Subagent Matrix)]
        P1["AssetTokensPorter (基石资产)"]
        P2["ComponentPorter (基础控件)"]
        P3["ViewModulePorter (业务视图)"]
        P4["ServiceAdapter (系统适配)"]
    end
    
    Master -->|"1. 签发任务卡 (Task Card)"| Cluster
    Cluster -->|"2. 交付成果与 Diff 报告"| Master
    
    subgraph Verification [质量总门禁 (Quality Gate)]
        V1["Diff 分类审查 (Differential Justification)"]
        V2["非驻留冒烟测试 (smoke_test.sh)"]
    end
    
    Master --> Verification
    Verification -- "验收通过" --> GitCommit["打上原子里程碑 Commit"]
    Verification -- "违规发现" --> Rollback["git reset 回滚至上一个 Checkpoint"]
```

---

## 二、 主控 Agent (Master Controller) 操作准则

1. **唯一接口人准则**：
   - 主控 Agent 是项目中唯一直接与用户交互的 Agent。
   - 负责向用户解释技术选型、展示里程碑成果，并汇报每一个关键设计决策。

2. **形式化任务卡签发准则**：
   - 绝不随意向子 Agent 发送发散、模糊的自然语言。
   - 每次派出子 Agent 前，必须起草具备明确约束的标准《任务卡》。

3. **三重审查门禁 (Gatekeeper)**：
   - **审查项 1 (Diff 审查)**：比对子 Agent 代码与 `reference/`。核验是否存在未经授权的 padding、margin、radius、color 改动。
   - **审查项 2 (非驻留冒烟测试)**：运行 `scripts/smoke_test.sh`，确保 0 语法报错、0 僵尸进程、GNOME 原生顶栏正常保护。
   - **审查项 3 (屏幕物理可见性审查)**：运行 `./scripts/launch.sh`，**必须在屏幕上实际看到顶栏或抽屉 UI 正常渲染**。绝对禁止仅凭后台进程存活或静态日志 Loaded 就判定为完成！

---

## 三、 子 Agent (Subagent Workers) 矩阵分工

| 角色代码 | 角色名称 | 允许操作范围 | 职责与红线 |
| :--- | :--- | :--- | :--- |
| **`AssetTokensPorter`** | 基石资产移植专家 | `src/Common/`、`src/assets/` | 负责设计系统令牌（Appearance、Metrics、Typography）与字体 Shader 1:1 克隆。**红线：严禁篡改原版配色算法**。 |
| **`ComponentPorter`** | 基础矢量控件专家 | `src/Components/`、`src/Widgets/` | 负责基础矢量按键、双轨滑块、输入框的 1:1 克隆。**红线：强制检查并锁定 `ArrowCursor`，杜绝光标形变**。 |
| **`ViewModulePorter`** | 原装视图装配专家 | `src/Modules/*`、`src/shell.qml` | 负责顶栏、控制中心、抽屉的原生视图组装与宿主挂载。**红线：严禁自创手写私有窗口外壳，必须 1:1 复刻上游窗口声明**。 |
| **`ServiceAdapter`** | 纯系统通信适配专家 | `src/Services/*` | 负责打桩 Mock 数据与对接真实 GNOME DBus、PipeWire、NetworkManager。**红线：绝对不准触碰任何 UI 文件**。 |

---

## 四、 标准任务卡模板 (Task Card Template)

```yaml
TaskCard:
  Card_ID: "TC-[Milestone]-[ModuleName]"
  Target_Role: "AssetTokensPorter | ComponentPorter | ViewModulePorter | ServiceAdapter"
  
  Scope_Whitelist:
    - "目标操作文件路径 (相对 src/)"
  
  Ground_Truth_Ref:
    - "对应 upstream 参考源路径 (相对 reference/StatIndet-quickshell/)"
  
  Allowed_Adaptations:
    - "硬件与平台动态自适应描述 (如 hasBattery 动态隐藏、外接屏软件背光)"
    - "Mutter XCB 几何显式绑定 (显式指定 width/height 消除 0x0 塌陷)"
  
  Forbidden_Actions:
    - "严禁修改任何排版、圆角、内边距、外边距、颜色参数"
    - "严禁新建未经批准的封装类或外部守护脚本"
  
  Verification_Steps:
    - "diff -u reference/... src/..."
    - "scripts/smoke_test.sh"
    - "屏幕真实物理可见性确认"
```

---

## 五、 Ubuntu GNOME Mutter 窗口宿主与几何桥接规范 (核心经验传承)

> [!CAUTION]
> **历史严重教训**：前序 Agent 曾出现“代码全部加载通过，但用户运行 `./scripts/launch.sh` 屏幕上完全没有显示任何 UI”的严重问题。后续所有 Agent 必须铭记本规范，严防该问题重蹈覆辙！

### 1. 协议根因与退化机制
- **上游环境假设**：上游 Clavis 基于支持 `wlr-layer-shell-unstable-v1` 的 Wayland 合成器（如 Niri/Hyprland），窗口（PanelWindow）通过 `WlrLayershell.layer` 和 QML `anchors` 即可由合成器自动完成物理尺寸展开；
- **目标环境实情**：Ubuntu 24.04 LTS 默认使用 **GNOME 46 (Mutter)**，Mutter **不支持** `wlr-layer-shell`。因此 Quickshell 必须在 XCB (XWayland) 模式下以无边框、置顶的 X11 窗口运行；
- **0x0 尺寸塌陷陷阱**：在 XCB/XWayland 下，Mutter 对 override-redirect 窗口**绝不会自动响应纯 QML anchors 进行拉伸**。若窗口未显式绑定物理尺寸，其实际 X11 窗口几何尺寸为 `0x0`，导致视觉上空无一物！

### 2. 双窗口宿主几何绑定铁律
在挂载顶层窗口时，必须在保留上游内部所有控件 1:1 的前提下，为顶层宿主补充显式几何桥接：

#### (1) 顶栏宿主 (`HorizontalBarWindow.qml`)
- **角色定位**：常驻桌面顶部的视觉中枢，也是触发快捷设置与侧边栏的交互入口；
- **几何桥接规则**：
  ```qml
  // 必须显式绑定目标屏幕的物理几何尺寸
  screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  x: root.screen ? root.screen.geometry.x : 0
  y: root.screen ? root.screen.geometry.y : 0
  width: root.screen ? root.screen.geometry.width : 1920
  height: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin
  ```
- **可见性保证**：启动后必须立即可见，为用户提供桌面基准锚点。

#### (2) 侧栏宿主 (`SidebarHostWindow.qml`)
- **角色定位**：覆盖整个屏幕的透明捕获层，承载右侧滑出的 `QuickSettingsSidebar` 与左侧的 `DashboardSidebar`；
- **几何桥接规则**：
  ```qml
  // 必须显式铺满整个屏幕，使内部 EdgeRevealSurface 具备正确的基准宽度，且 MouseArea 能全屏捕获空白点击
  x: root.screen ? root.screen.geometry.x : 0
  y: root.screen ? root.screen.geometry.y : 0
  width: root.screen ? root.screen.geometry.width : 1920
  height: root.screen ? root.screen.geometry.height : 1080
  ```
- **边缘抽屉联动**：
  - 默认情况下抽屉收起（`open: false`），抽屉处于屏幕外（偏移 `width`）；
  - 点击顶栏上的快捷设置按钮时，触发 `WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen`，抽屉向内平滑滑出；
  - 点击空白区域或按 ESC 触发收起，抽屉向外平滑滑出。

### 3. Agent 验收红线
所有参与视图移植的 Agent（特别是 `ViewModulePorter`）：
- **绝对不准仅以终端输出 `Configuration Loaded` 作为交付依据**；
- 每次交付前，必须核查顶层窗口的 `width` 与 `height` 是否在运行时大于 0；
- 必须确保用户执行 `./scripts/launch.sh` 后，能够直接在屏幕上看到顶栏和抽屉动画。

