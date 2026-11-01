# Ubuntu Quickshell Desktop Shell 工程基调与核心开发军规 (V2.3 工业终极版)
*(Engineering Tenets & Architecture Ground Rules - Industrial Ultimate Edition V2.3)*

> **定位**：本项目后续所有功能补全、重构与维护工作的**最高技术宪章与执行准则**。  
> **制定背景**：彻底终结开发中“表面照搬 UI 代码，内在掏空成 Mock 假数据”、“遇到渲染问题一刀切降级 CPU 软件光栅”、“以静态文件与 grep 假断言欺骗测试流水线”、“利用 imports/ 伪造 Mock 树瞒天过海”的形式主义弊病。  
> **权威效力**：本宪章效力高于所有常规开发习惯。凡与本宪章冲突的代码提交，一票否决。

---

## 一、 核心痛点与历史教训总结 (Post-Mortem Insights)

在前期的复刻尝试中，之所以出现“代码看似搬了，但实际效果天差地别”的现象，根源在于以下三大致命偏差：

1. **“假复刻”陷阱（The Mocking Trap）**：
   - 为追求“纯 QML 零编译”的表象，将上游 13 个原生 C++ 核心插件及底层服务直接切除；
   - 服务层被替换成大量静态假对象（如写死广州 25℃ 天气、写死 4 个假工作区、写死静态桌面标题）以及空函数 `{}`（如应用扫描清空、网络连接无动作、蓝牙配对 no-op）；
   - **后果**：整个桌面 Shell 沦为一个好看的“塑料模型”，没有任何真实生产力。
2. **“粗暴降级”陷阱（The Brutal Fallback Trap）**：
   - 在 Mutter X11 环境下遇到 OpenGL/FBO 兼容黑边，直接全局指定 `QT_QUICK_BACKEND="software"`；
   - 为了迁就 CPU 软件渲染，进一步删改了 `TopBarPill` 的 `MultiEffect` 圆角抗锯齿遮罩，并将背景双重叠加；
   - **后果**：彻底摧毁了上游原版最引以为傲的液态通透毛玻璃、Shader 壁纸过渡和流体动效。
3. **“单机硬编码”陷阱（The Hardcoding Trap）**：
   - 在测试脚本中写死了开发者的特定屏幕名 `DP-1`、固定分辨率 `2048x1152` 与绝对像素坐标；
   - 在 QML 服务层中甚至出现了 `Quickshell.execDetached(["/home/dkp/projects/.../toggle_spotlight.sh"])` 这种直接硬编码个人主目录的调用；
   - **后果**：换一台电脑、换一个分辨率，或者一经打包安装，整个桌面立即故障崩溃。

---

## 二、 后续开发四大最高准则 (The Four Cardinal Tenets)

### 准则一：真实系统互联与三级服务架构原则 (Real System Integration & Tiered Architecture)

#### 1. 绝对禁令与概念清算
- **绝对禁令**：严禁在 `src/Services/` 生产目录中新建任何静态 Mock 数据源！严禁向暴露给 UI 的核心操作函数中编写空函数 `{}`！
- **概念厘清（假数据 vs 显式加载状态机）**：
  - **严禁“假数据（Mock Data）”**：严禁在数据未决时胡乱填充虚假的 100% 电量、广州 25℃ 天气、默认 4 个工作区等。
  - **必须采用“显式加载状态机（Explicit State Machine）”**：硬件或网络数据异步获取期间，必须使用具名状态枚举：`State: "loading" | "ready" | "empty" | "unavailable"`。UI 层据此渲染骨架屏（Skeleton）或占位占空，严禁首帧剧烈布局抖动（Layout Thrashing）。
  - **确定性退避与离线占位契约 (3000ms Offline Contract)**：
    面对断网或首次全新启动无本地缓存场景，异步数据请求超过 **3000ms** 未果时，状态机必须强制转入 `unavailable` 或 `offline` 终态；UI 控件必须保留**最小安全几何占位（Min Size Reservation）**，优雅呈现离线图标或平滑淡出，绝对禁止尺寸突变为 0 像素引发周围控件剧烈跳跃。
- **Mock 隔离原则**：本地离线开发或独立组件验证若需数据桩，必须且仅能保存在 `tests/mocks/` 下，严禁污染 `src/Services/` 生产代码树。

#### 2. 系统能力接入合规分级法 (Tiered Integration Model)
针对切除 C++ 插件后的纯 QML/JS 架构，所有底层服务接入必须严格对号入座，禁止在 UI 线程随意派生子进程：

- **Tier 1 (直连型标准服务 - Zero Overhead)**：
  - **适用范围**：Linux 标准 D-Bus 接口（NetworkManager、UPower、PipeWire、BlueZ、GNOME SettingsDaemon）。
  - **实现规范**：必须通过 QML 原生 D-Bus / Quickshell 封装库进行响应式属性绑定与异步方法调用，由事件循环驱动，零进程开销。
  - **宿主总线冲突抑制协议 (Coexistence Protocol)**：对于系统全局独占性 D-Bus 服务（如 `org.freedesktop.Notifications`），必须在启动与配置脚本中显式协调宿主环境参数（如 GNOME gsettings 静音原生通知横幅），避免多重弹窗与总线争抢死锁。
- **Tier 2 (长驻辅助守护服务 - Streamlined IPC)**：
  - **适用范围**：X11 复合窗口追踪、Ayatana 托盘拦截、硬件底层传感等 QML 无法原生胜任或操作耗时 > 5ms 的底层能力。
  - **实现规范**：必须且仅能交由 `src/scripts/<category>/` 下的单一长驻 Python/C 伴生守护进程处理。通过长连接 `stdout` 以 **JSON-Lines (NDJSON)** 协议向 QML 单向流式广播事件；QML 发起控制通过单向 `stdin` 命令写入。
- **Tier 3 (冷数据异步缓存服务 - Cache-First & Non-Blocking)**：
  - **适用范围**：全机应用扫描（`/usr/share/applications/*.desktop` 遍历）、网络天气抓取等耗时 I/O。
  - **实现规范**：必须在本地 `Paths.cacheHome` 维护一份轻量 JSON 缓存。启动时**首帧极速读取缓存渲染**，后台异步触发独立子进程静默刷新缓存，刷新完毕热更新 QML 属性，绝对严禁在 GUI 线程做同步大文件遍历与网络阻塞。
  - **动态缓存时效与变更感知 (Cache Invalidation)**：本地 JSON 缓存必须具备实时或按需重载机制。对于应用程序列表，后台或伴生进程应监听 XDG 标准应用目录的变更，或在 Spotlight/Launcher 激活唤起时进行非阻塞的目录 mtime 比对（Stat Check），发现变动立即触发静默重载，严禁运行期应用状态僵死。

---

### 准则二：纯粹 QML 响应式架构与伴生进程防御 (Reactive Architecture & Daemon Defense)

#### 1. 纯粹 QML 响应式闭环
- **绝对禁令**：严禁在 QML 内部通过 `execDetached` 启动外部 Shell 脚本来反向通过 IPC 修改自身状态！
- **必须执行**：
  - 内部组件通信（如 Launcher 唤起 Spotlight、设置项切换）：必须使用单例属性绑定（Property Binding）与信号槽（Signals/Slots）在内存中毫秒级闭环；
  - 外部脚本（`clavisctl`）：仅作为终端用户与快捷键守护进程的外部调度工具，严禁作为内部 UI 互动的“转接二道贩子”。

#### 2. 伴生守护进程韧性与僵尸防御 (Daemon Lifecycle & Anti-Zombie)
- **父子生死绑定与多级派生防孤儿 (PR_SET_PDEATHSIG & Hierarchical Propagation)**：
  所有部署在 `src/scripts/` 下的长驻伴生 Python 脚本，必须在入口导入 `ctypes` 并声明调用 Linux `prctl(PR_SET_PDEATHSIG, signal.SIGTERM)`。
  **内核清除防御**：凡是调用 `os.fork()` 派生子进程、或内部使用 `subprocess.Popen` 启动下级进程，必须在每一个子进程分支入口处重新调用 `prctl(PR_SET_PDEATHSIG, signal.SIGTERM)`（防御内核在 fork 后自动清除死亡信号），并为二级子进程（如 `busctl monitor`）挂载 atexit 清理钩子，杜绝二级孤儿泄漏。
- **系统级 Python 依赖锁死 (GDBus Only)**：
  长驻伴生脚本中的 D-Bus 监听必须且仅能使用系统原生自带的 `gi.repository.Gio` (GDBus) 或 Nix 声明的受控库，严禁引入未受控的外部第三方包，严禁在生产或开发环境随意 `pip install`。
- **IPC 通道异常吸收**：
  QML 接收伴生进程的 stdout 流时，必须对每一行 JSON 解析包裹 `try ... catch` 防护；遇到畸变行记录告警日志并丢弃，严禁因单行坏数据引发 QML 引擎未捕获异常。
- **崩溃感知与指数退避重连**：
  伴生进程意外退出时，服务层必须执行指数退避重试（1s -> 2s -> 4s -> max 16s），严禁在毫秒级死循环拉起导致 CPU 100% 锁死。
- **伴生进程低能耗与禁止盲轮询 (Zero Active Polling)**：
  长驻伴生 Python 脚本严禁使用 `while True: sleep(...)` 盲读硬件 sysfs 节点或高频调用子进程。对于托盘与状态变更，必须且仅能采用 D-Bus 信号驱动（`StatusNotifierWatcher` 信号监听），实现空闲状态零主动唤醒（0 Wakeups/sec）。
- **动态 QML 对象生命周期契约 (GC & Ring-Buffer Contract)**：
  所有在 QML 内部通过 `Component.createObject()` 动态创建的堆对象（如通知条目），必须纳入定长环形队列（Ring Buffer，例如上限 50 条）。在对象超出容量阈值或被移除时，必须显式调用 `object.destroy()`，绝对禁止只在数组中过滤而放任 QML 引擎堆内存无限制增长。

---

### 准则三：环境与物理参数零硬编码原则 (Zero Machine Hardcoding)

#### 1. 绝对禁令
- 严禁在任何 QML 文件、Python 脚本或 Bash 脚本中写死任何单机物理参数（如特定屏幕名 `DP-1`、固定分辨率 `2048x1152`、绝对像素坐标、开发者个人主目录路径 `/home/...`）！

#### 2. 防御性动态绑定模式 (Defensive Dynamic Binding)
在 X11 / XWayland 环境中，Quickshell 初始化首帧时 `screen.geometry` 可能短暂为空或返回 `0x0`。为避免 QML 抛出 `TypeError: Cannot read property 'width' of null` 或除以零异常：
- **必须提供物理安全的兜底计算**：
  ```qml
  readonly property int safeScreenWidth: root.screen && root.screen.geometry && root.screen.geometry.width > 0 ? root.screen.geometry.width : 1920
  readonly property int safeScreenHeight: root.screen && root.screen.geometry && root.screen.geometry.height > 0 ? root.screen.geometry.height : 1080
  ```
- **多显示器自适应 —— 双轨制宿主模型 (Dual-Track Hosting Model)**：
  严禁对所有窗口“一刀切”滥用 `Variants`！窗口语义不同，承载模式必须严格分流：
  - **轨道 A（多屏物理派生 - Per-Screen Panels）**：`TopBar`（顶栏）、`Dock`（停靠栏）必须使用 `Variants { model: Quickshell.screens }` 为每个物理显示器派生独立实例，自适应多屏扩展；
  - **轨道 B（全局焦点跟随单例 - Focus-Follows Global Singleton）**：`Spotlight`（聚光灯搜索）、`PowerMenu`（电源会话）、`Keystone`（灵动岛弹窗）、`SidebarHostWindow`（全屏透明遮罩层）**必须保持全局唯一单例窗口**！严禁为每个屏幕派生多份模态副本（否则会引发双屏下弹出两个输入框与全屏 X11 事件捕获死锁）。在触发唤起时，毫秒级将自身 `screen` 属性重定向至当前鼠标所在屏幕（或 `Quickshell.focusedScreen`），以单例形态优雅跟随焦点。
- **多显示器动态热插拔销毁防御 (Hotplug Teardown Guard)**：
  单例模态窗口（Spotlight/PowerMenu/SidebarHost）必须安全处理 `Quickshell.screensChanged` 事件。当所绑定的显示器被物理拔出或合盖断开时，必须在下一帧渲染前将自身 `screen` 安全回退至当前有效主屏（`Quickshell.screens[0]`）或 `null`，严禁访问已析构的 QScreen 野指针。

---

### 准则四：统一脚本收敛与单向依赖原则 (Unified Scripting & Clean Paths)

#### 1. 目录收敛与路径安全
- 所有供桌面 Shell 运行时调用的内部后台守护、扫描与解析工具，必须统一部署在 `src/scripts/<category>/` 下；
- 根目录的 `scripts/` 仅保留对外运维与部署脚本（`clavisctl`, `install.sh`, `uninstall.sh`, `package_release.sh`, `smoke_test.sh`）；
- 严禁使用任何 `Paths.shellDir + "/../scripts/..."` 这种穿透打包根目录的危险相对路径！所有内部脚本调用必须且仅能通过 `Paths.qml` 提供的标准化 XDG 路径令牌解析（如 `Paths.systemScriptsDir + "/..."`）。

#### 2. 严格的单向依赖流
```
UI Views (Modules/)
   │ (仅声明式绑定属性 / 触发方法)
   ▼
Services Layer (src/Services/)
   │ (D-Bus / stdout JSON 流式通信)
   ▼
Helper Daemons (src/scripts/<category>/)
   │ (Linux 系统原生调用)
   ▼
Linux OS Kernel / EWMH / Mutter / D-Bus
```
严禁底层脚本反向探测或操作 UI，保持核心系统单向解耦。

---

### 准则五：图形渲染管线与视觉保真红线 (Graphics Pipeline & Visual Integrity)

#### 1. 彻底终结软渲染粗暴降级
- **GPU 加速基准**：本项目确立以 **GPU 硬件加速（OpenGL / EGL / Vulkan）** 为唯一生产基准管线。禁止通过全局环境变量滥用 `QT_QUICK_BACKEND="software"`；
- **Mutter XWayland 桥接与 32-bit ARGB TrueColor Visual 规范**：
  在 Ubuntu 24.04 GNOME 46 Mutter 环境下，无论底层会话是 Wayland 还是 X11，默认统一通过 **XWayland 桥接（`QT_QPA_PLATFORM=xcb`）** 启动。必须确保透明顶层窗口申请到 32 位带有 Alpha 通道的 Visual，宿主窗口显式设定 `color: "transparent"`，严禁为了规避合成器黑色背景而反向将代码降级为 CPU 软件光栅。
- **排他工作区完整性契约 (Strut Reservation Contract)**：
  严禁为了规避居中定位 bug 将顶栏或 Dock 的排他厚度粗暴置零（如 `exclusiveZone: 0`）。在 X11 下必须显式声明 `exclusiveZone: exclusiveThickness` 并向 Mutter 导出 `_NET_WM_STRUT_PARTIAL`，确保任何应用最大化时正确定位在顶栏下方，坚决杜绝窗口标题栏与标签页被遮挡吞噬。
- **核心 Shader 与遮罩完整性**：
  - 严禁注释或删除 `TopBarPill` 中的 `MultiEffect` 抗锯齿圆角遮罩；
  - 严禁破坏 `TopBarPillBackground` 的透明度图层；
  - 必须保持壁纸过渡 Shader (`wp_*.frag.qsb`) 与毛玻璃特效的 GPU 原生执行能力。

---

### 准则六：测试真实度与反欺骗红线 (Ground Truth Testing & Anti-Fraud)

#### 1. 绝对禁令
- **严禁“假测试（Fraudulent Testing）”**：严禁使用纯 `grep` 匹配源码文本充当逻辑或视觉对齐测试！严禁仅用 `[ -f ]` 判断图片存在充当视觉基准比对！
- **严禁“吞噬错误（Swallowing Failures）”**：冒烟测试严禁仅仅依赖 `timeout 3s` 退出码 `124` 判为通过！凡是标准错误输出（stderr）中出现未捕获的图形后端崩溃、GLX 致命错误（`FATAL:`）或协议异常，即便未触发主动退出，亦直接判定测试失败！
- **严禁建立伪造模块树**：严禁在 `imports/` 目录下建立伪造的本地空桩库（如 `imports/Clavis/`）欺骗编译。全仓 `import Clavis.*` 必须真正归零！

#### 2. 真值比对规范 (Ground Truth Protocol)
- 视觉真值对比必须在无头虚拟帧缓冲（Xvfb）中真实渲染 QML 场景，捕获实际帧缓冲图像后，通过图像感知哈希或像素绝对误差（ImageMagick `compare -metric AE`）与黄金基准图比对；
- 状态机与组件测试必须在真实无头 QPA 实例中挂载运行并断言其属性值。

---

## 三、 性能与资源消耗红线 (SLOs & Budgets)

所有代码合并前，必须在标准配置环境（4 核 CPU / 集成或独立显卡）通过以下硬性量化指标测试：

| 指标维度 | 严格合格线 (SLO Target) | 测量方式 |
| :--- | :--- | :--- |
| **冷启动时延 (Cold Start)** | **≤ 800 ms** (首帧完成顶栏与 Dock 渲染) | `time ./scripts/launch.sh` 测量首帧就绪时间戳 |
| **空闲常驻内存 (Idle RSS)** | **Quickshell ≤ 120 MB**, **伴生守护 ≤ 35 MB** | 稳定运行 5 分钟后 `ps aux | grep ...` 检查 RSS |
| **空闲 CPU 占用率 (Idle CPU)** | **≤ 0.5%** (常驻静止状态下) | `pidstat 1 30` 采样 30 秒平均 CPU 利用率 |
| **动画交互流畅度 (Frame Rate)** | 60Hz 屏幕稳定 **≥ 57 FPS**；144Hz 稳定 **≥ 135 FPS** | QML Profiler 捕获 TopBar/Dock 悬停与展开动效 |
| **伴生进程响应延迟** | **≤ 16 ms** (1 帧以内响应窗口焦点切换) | `x11_desktop_helper.py` 事件广播至 QML 接收耗时 |

---

## 四、 自动化门禁检验机制 (Automated Gatekeeper)

在本地提交或 CI 验证阶段，运行 `scripts/verify_tenets.sh` 自动执行以下一票否决级校验：

1. **静态语法与代码审查 (Static AST Gate)**：
   - 检索源码中是否存在写死的绝对路径（`/home/`、`/tmp/` 等，包含 `tests/` 目录）；
   - 使用多行 AST 解析器检测全仓（含 `src/` 与 `imports/`）所有真实空函数与常量占位桩，严格执行 48 处基线单向递减律；
   - 检索是否存在未封装的 `console.log` 脏日志；
   - 无白名单检索全仓是否存在废弃 C++ 模块导入（`import Clavis.*` 必须为 0 处）；
   - 检查是否存在伪造 Mock 模块目录（如 `imports/Clavis`，必须不存在）。
2. **伴生进程安全审计 (Daemon Security Gate)**：
   - 检查 `src/scripts/` 下的所有 Python 伴生进程及其 `os.fork()` 子分支是否正确调用了 `PR_SET_PDEATHSIG`；
   - 检查测试退出后系统是否存在残留孤儿进程。
3. **渲染模式与无头冒烟审计 (Rendering & Smoke Gate)**：
   - 检查构建配置与启动脚本中是否存在硬编码强制 `QT_QUICK_BACKEND="software"`；
   - 运行无头合成器冒烟测试，捕获 stderr，确保零致命图形错误。
