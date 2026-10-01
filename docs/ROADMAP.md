# 阶段演进路线图 (ROADMAP.md)

本项目采取分阶段推进、严密验证的迭代开发模式。在每个阶段，必须确保后端服务、数据模型与前端 UI 的解耦与稳定性，严禁直接堆砌未经验证的复杂代码。

---

## 阶段演进总览

```mermaid
timeline
    title Quickshell Desktop Shell 开发路线图
    Phase 0 : 环境审查与基石搭建 : 依赖诊断与安装计划 : 架构与移植矩阵 : 最小 PoC 验证
    Phase 1 : 顶部栏基础 (TopBar) : 胶囊 Pill 体系 : 工作区与焦点窗口 : 基础状态栏
    Phase 2 : 侧边栏与快捷设置 (Sidebar) : 抽屉滑入滑出动效 : 音量/亮度/网络/蓝牙控制面板
    Phase 3 : 媒体控制中心 (Media) : MPRIS 播放器对接 : 专辑封面与进度控制 : 调色盘联动
    Phase 4 : 仪表盘与系统监控 (Dashboard) : 日历与多维天气卡片 : CPU/内存/网络实时曲线
    Phase 5 : 动态通知系统 (Notification) : 悬浮 Toast 弹窗 : 历史聚合列表 : 请勿打扰机制
    Phase 6 : 动态主题与壁纸 (Theme) : Material You 调色体系 : 深浅色无缝过渡 : 壁纸色彩提取
    Phase 7 : 高级动效与灵动岛 (Advanced UI) : Dynamic Island 胶囊展开 : 全局聚焦启动器 : 电源菜单
```

---

## 详细阶段计划

### Phase 0 — 环境审查、架构确立与最小 PoC (当前阶段)
- [x] Ubuntu 24.04 LTS (GNOME 46 + Wayland) 本机环境诊断与记录
- [x] Quickshell / Qt 6 依赖状态确认
- [x] 参考项目 `StatIndet/quickshell` 深度源码剖析
- [x] 输出 `docs/PORTABILITY_MATRIX.md` (可移植性矩阵)
- [x] 输出 `docs/ARCHITECTURE.md` (架构规范与分层设计)
- [x] 确立本项目目录规范与 Git 版本库初始化
- [ ] **实施验证**：安装 Quickshell 运行时环境
- [ ] **实施验证**：启动最小 PanelWindow Demo (在当前 GNOME 会话正常呈现时钟与基本卡片)

---

### Phase 1 — Shell 基础 (TopBar 核心系统)
**目标**：在屏幕顶部呈现出稳定、美观的 Material 3 风格胶囊状态栏。
- 基础视觉体系落地：`Appearance.qml`, `Sizes.qml`, `Animations.qml`, `Typography.qml`
- 基础组件封装：`TopBarPill.qml`, `IconLabel.qml`
- 顶层容器：`Bar.qml`, `HorizontalBarWindow.qml`
- 时钟胶囊：时间、日期与悬停日历提示
- 状态胶囊组：PipeWire 音量指示、网络连接状态、电池电量指示
- 平台后端初版：
  - `WorkspaceService`：GNOME 工作区切换与指示器
  - `WindowService`：活动窗口标题与应用图标呈现

---

### Phase 2 — 侧边栏与快捷设置 (Sidebar & QuickSettings)
**目标**：可平滑拉出的功能抽屉，提供完整的日常硬件与系统快捷配置。
- 抽屉容器与贝塞尔曲线平滑进出动效 (`SidebarHostWindow`)
- 快捷开关网格：Wi-Fi、蓝牙、勿扰模式、夜间模式
- 交互滑块：系统输出音量、麦克风输入音量、屏幕背光亮度
- 网络子面板：扫描并显示可用 Wi-Fi 列表与连接状态
- 蓝牙子面板：已配对设备与附近蓝牙设备发现

---

### Phase 3 — 媒体控制中心 (Media Player Integration)
**目标**：高保真媒体展示卡片，与音乐/视频播放器实时同步。
- `MediaService` 深度集成 `Quickshell.Services.Mpris`
- 播放控制：播放/暂停、上一曲、下一曲、拖拽进度条定位
- 元数据解析：曲名、艺术家、专辑名、高清封面异步载入
- 状态栏 Mini 媒体小胶囊与展开大卡片自适应切换

---

### Phase 4 — 仪表盘与天气 (Dashboard & System Monitor)
**目标**：信息丰富、排版克制的综合信息中枢。
- 日历与待办事项聚合卡片
- 天气服务 (`WeatherService`)：基于 Open-Meteo 实时气象数据，包含温度、风速、空气质量与多日预报趋势图
- 系统资源监控 (`SystemMonitorService`)：
  - 直接读取 Linux `/proc/stat` 与 `/proc/meminfo`
  - CPU 综合占用率与多核曲线
  - 物理内存与 Swap 使用占比
  - 实时网络上行与下行速率动态图表

---

### Phase 5 — 动态通知中心 (Notification Center)
**目标**：非侵入式、信息层级清晰的通知处理中心。
- 屏幕右上角平滑滑入的 Toast 临时弹窗，超时自动消失
- 侧边栏通知历史持久化记录与应用归类分组
- 操作按钮联动（如“回复”、“标记已读”）
- “请勿打扰”状态联动与通知静音逻辑

---

### Phase 6 — 动态主题与个性化 (Theme & Dynamic Color)
**目标**：基于 Material Design 3 的色彩衍生与统一视觉定制。
- 集成 Matugen 调色算法，根据壁纸主色提取全套语义化配色令牌
- 深色 (Dark) / 浅色 (Light) 模式一键平滑渐变切换
- 全局主色调 (Primary / Accent) 自定义调整
- 壁纸管理服务与背景层联动

---

### Phase 7 — 灵动交互与高级特质 (Advanced UI & Polish)
**目标**：打造充满生机与现代感的交互细节。
- **Dynamic Island (灵动岛)**：居中状态指示器，根据音量变化、媒体切歌、通知到来时动态舒展/收缩
- **Spotlight 聚焦启动器**：支持应用快速搜索启动、计算器小工具与文件快速索引
- **现代化 PowerMenu**：优雅的全屏虚化锁屏、注销、休眠、重启与关机确认界面
- 性能深度调优：GPU 离屏渲染优化、空闲时零 CPU 唤醒优化
