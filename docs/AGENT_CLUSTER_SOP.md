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
| **`ViewModulePorter`** | 原装视图装配专家 | `src/Modules/*`、`src/shell.qml` | 负责顶栏、控制中心、抽屉的原生视图组装与宿主挂载。**红线：内部 UI 与视图布局必须 1:1 复刻；但在顶层 Window 宿主与输入掩码上，必须严格执行第五节 Mutter XCB 桥接规范（禁止机械复刻 Wayland 属性导致协议冲突与性能雪崩）**。 |
| **`ServiceAdapter`** | 纯系统通信适配专家 | `src/Services/*` | 负责打桩 Mock 数据与对接真实 GNOME DBus、PipeWire、NetworkManager。**红线：绝对不准触碰任何 UI 文件；必须具备系统命令缺失降级机制，同时严禁粗暴切断服务自愈重连**。 |

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

## 五、 Ubuntu GNOME Mutter 窗口宿主与平台胶水层桥接规范 (核心经验传承)

> [!CAUTION]
> **历史严重教训与“机械 1:1 陷阱”**：
> 前序 Agent 曾反复出现三类恶性问题：
> 1. “代码全部编译通过，但启动后屏幕上空无一物”（0x0 尺寸塌陷）；
> 2. “机械照抄上游 Layer Shell 独占区，导致灵动岛被 Mutter 强制下压悬空 52px”；
> 3. “机械照抄全屏透明窗口并在 X11 软渲染下动态 Map/Unmap，导致全屏事件拦截死锁、严重掉帧与内存雪崩”。
> 
> **最高原则：内部 UI 表现、动效参数、配色 Token 必须 100% 恪守 1:1 严禁篡改；但在顶层 Window 宿主与平台胶水层，必须严格遵循本节规范实施针对 Ubuntu X11 Mutter 的特异性适配！**

---

### 1. 协议根因与退化机理
- **上游环境机制**：上游 Clavis 基于支持 `wlr-layer-shell-unstable-v1` 的 Wayland 合成器（如 Niri/Hyprland）。窗口（PanelWindow）通过 `WlrLayershell.layer` 和 QML `anchors` 即可由合成器自动完成物理尺寸展开，并原生支持非矩形透明穿透；
- **目标环境实情**：Ubuntu 24.04 LTS 默认使用 **GNOME 46 (Mutter)**，Mutter **不支持** `wlr-layer-shell`。Quickshell 退化为在 XCB (X11) 模式下以 override-redirect 窗口运行，且渲染后端通常为 CPU 软渲染（`QT_QUICK_BACKEND="software"`）。

---

### 2. Mutter XCB 平台适配四大铁律

#### 铁律一：0x0 物理几何显式绑定 (Eliminate 0x0 Collapse)
- 在 XCB/XWayland 下，Mutter 对 override-redirect 窗口**绝不会自动响应纯 QML anchors 进行拉伸**；
- 必须显式将 `width`、`height`、`x`、`y` 绑定至 `screen.geometry` 物理参数，杜绝几何尺寸塌陷为 `0x0`。

#### 铁律二：EWMH Strut 避让与层叠并存机制 (Eliminate 52px Gap)
- **机理**：Quickshell 在 X11 下将 `exclusiveZone: 52` 转译为 `_NET_WM_STRUT_PARTIAL`，Mutter 会把桌面工作区（`_NET_WORKAREA`）全局下推 52px，导致后续创建的贴顶窗口（如 Keystone 灵动岛）被强行下压到 `y = 52` 产生悬空断层；
- **规范**：当顶部存在横向顶栏与中央灵动岛多层并存时，`HorizontalBarWindow.qml` 必须显式设定 `exclusiveZone: 0`（或浮动覆盖模式），确保灵动岛等浮层能够严丝合缝贴紧物理顶边 `y: 0`。

#### 铁律三：全屏宿主常驻映射与 XShape 物理裁剪法则 (Anti-Freeze & Anti-Leak)
- **机理**：
  1. 在 X11 软渲染下，全屏透明宿主窗口**严禁动态切换 `visible`（动态 Map/Unmap）**！动态映射会导致 XServer 重新分配 2048x1100 显存/内存 Backing Store，并迫使 `CompositorBlurRegion` 同步执行全屏抓图（`XGetImage`），引发瞬间数秒的致命卡死并拖垮系统其他进程；
  2. 在 X11 下，`mask: Region` 若被传入 `null`，XShape 会失效并默认捕获全屏事件，造成全屏事件死锁。
- **规范**：
  - 侧栏全屏宿主窗口必须保持常驻映射（`visible: true` 保证生命周期稳定）；
  - 收起不可见时，必须向 `mask: Region` 提供显式的 `0x0` 空白 Item（如 `emptyMaskRegion`），利用 XShape 物理“挖空”事件接收区，既实现零开销事件穿透，又消除重映射的性能雪崩。

#### 铁律四：守护进程缺失防御与崩溃自愈韧性法则 (Daemon Resilience)
- **机理**：上游 QML 强依赖专属 CLI 二进制（如 `key`）。在缺失该命令的宿主环境下，进程启动即失败并触发重试定时器，引发无限重试风暴锁死 QML 事件队列；但若粗暴以 `exitCode !== 0` 中断重连，会彻底破坏正常运行时崩溃后的自愈重连。
- **规范**：
  - 拦截退出码必须精准判定启动失败：`if (exitCode < 0 || exitCode === 127 || exitCode === 255)`；
  - 仅在明确命令不存在或无法执行时停止重试，严禁破坏正常的崩溃恢复循环。

---

### 3. 多宿主窗口显式桥接规范

#### (1) 顶栏宿主 (`HorizontalBarWindow.qml`)
```qml
screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
x: root.screen && root.screen.geometry ? root.screen.geometry.x : 0
y: root.screen && root.screen.geometry ? root.screen.geometry.y : 0
width: root.screen && root.screen.geometry ? root.screen.geometry.width : 1920
height: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin
exclusiveZone: 0 // 消除 EWMH Strut 对灵动岛的 52px 挤压
```

#### (2) 侧栏全屏宿主 (`SidebarHostWindow.qml`)
```qml
screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
x: root.screen && root.screen.geometry ? root.screen.geometry.x : 0
y: root.screen && root.screen.geometry ? root.screen.geometry.y : 0
width: root.screen && root.screen.geometry ? root.screen.geometry.width : 1920
height: root.screen && root.screen.geometry ? root.screen.geometry.height : 1080
visible: retainedScreen !== null || fallbackScreen !== null // 保持常驻映射，杜绝动态 Map 性能雪崩

Item {
    id: emptyMaskRegion
    width: 0
    height: 0
}

mask: Region {
    // 激活时捕获全屏点击用以关闭，收起时精准收缩为 0x0 物理穿透
    item: root.anySidebarOpen ? interactionRegion : emptyMaskRegion
}
```

#### (3) 灵动岛宿主 (`KeystoneSurface.qml`)
```qml
screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
property int x: screen && screen.geometry ? screen.geometry.x : 0
property int y: screen && screen.geometry ? screen.geometry.y : 0 // 物理精确锁定顶边 y: 0
```

---

### 4. Agent 验收硬指标 (Gatekeeper)
所有参与视图移植的 Agent：
1. **禁止静态臆测**：绝对不准仅以终端输出 `Configuration Loaded` 作为交付依据；
2. **几何与坐标核验**：启动后必须使用 `xwininfo -root -tree` 验证所有顶层窗口 `width > 0`、`height > 0` 且坐标无漂移；
3. **真机交互验证**：必须亲眼验证用户运行 `./scripts/launch.sh` 后：
   - 顶栏与灵动岛无缝贴合物理顶边（0 像素缝隙）；
   - 呼出与收起控制中心顺滑无卡顿，桌面其他应用点击正常不受阻；
   - 进程列表中无 `key` 等死循环子进程。

