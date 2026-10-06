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

3. **双重审查门禁 (Gatekeeper)**：
   - **审查项 1 (Diff 审查)**：比对子 Agent 代码与 `reference/`。核验是否存在未经授权的 padding、margin、radius、color 改动。
   - **审查项 2 (冒烟测试)**：运行 `scripts/smoke_test.sh`，确保 0 语法报错、0 僵尸进程、GNOME 原生顶栏正常保护。

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
  
  Forbidden_Actions:
    - "严禁修改任何排版、圆角、内边距、外边距、颜色参数"
    - "严禁新建未经批准的封装类或外部守护脚本"
  
  Verification_Steps:
    - "diff -u reference/... src/..."
    - "scripts/smoke_test.sh"
```
