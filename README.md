# Clavis-style shell on GNOME

本项目以 **GNOME/Mutter 为桌面和窗口管理基础**，移植 Clavis 的界面与原生组件。
不是 niri 登录会话，也不以嵌套 niri 预览替代 GNOME 适配。当前是持续开发中的移植，
**不宣称完全视觉等价或已通过生产验收**。

## 检测到的环境与工具链

2026-11-16 的实际只读检测：

| 层级 | 实际版本/状态 |
| --- | --- |
| 系统 | Ubuntu 26.04，GNOME Wayland 登录会话 |
| 桌面 | GNOME Shell / Mutter 50.1 |
| 图形设备 | AMD Navi 48，amdgpu 驱动；GNOME 进程使用系统 Mesa EGL |
| 系统 Qt | 6.10.2；不用于加载本项目的 Nix 原生插件 |
| 项目 Qt | flake.lock 固定的 Nix Qt 6.11.2 |
| Quickshell | flake.lock 固定的 0.3.1 |
| 本机显示 | DP-1，2560×1440，GNOME 缩放 125%；XWayland 原生 root 4096×2304，Qt 逻辑屏幕 2048×1152 / DPR 2 |
| 原生形状库 | 外部 soramanew/m3shapes，固定提交 `8a6fe8961749887d677700b6508e0c9249968b7e` 与源码哈希 |

不自动安装系统包、升级 Qt、启用扩展、改变 GNOME 设置或改动登录管理器。
原生模块从本项目 `native/` 构建；`reference/` 只读。
`clavis-native` / `clavis-native-trial` 既不是构建依赖，也不是运行依赖。
上游来源与本地原生改动记录在 `native/UPSTREAM.md`。

## 架构与真实能力

### GNOME 窗口与工作区

项目提供 GNOME 50 扩展源码：`gnome-extension/clavis-bridge@local/`。
扩展用 Shell/Meta 正常扩展 API 与会话 D-Bus 导出窗口、真实焦点、动态工作区、
逻辑输出几何和缩放。支持提交激活、最小化、恢复、关闭、切换工作区操作。
**扩展在当前桌面的实际启用与操作尚待用户确认后验证**，不能把语法检查或打包当作通过。

`GnomeSession` 的伴生进程以 NDJSON 接入 D-Bus。`CompositorBackend` 提供界面模型；
`Niri.qml` 仅保留上游消费者所需的兼容接口，不运行 niri。
扩展缺失/禁用/断线时清空模型，不用四个假工作区、第一项假焦点或 EWMH 子集填补。
重新出现时通过 bus-name watcher 获取快照。操作返回值区分“已提交”与快照中的实际结果。
GNOME 工作区是全局集合，不冒充 niri 的独立输出工作区；最小化动画归 Mutter 管理。

### 表面与视觉

GNOME Wayland 会话不等于 layer-shell 会话。本项目外部面板目前使用 **XWayland/xcb**
绘制，保留 Mutter 和 GNOME 的传统窗口操作；这不是切换 Xorg 登录。
原生 Wayland layer-shell、niri 专用背景效果与跨进程输入协议不能由同名属性冒充。
XWayland 面板的真实 GNOME 定位、保留区域和 125% 缩放仍需现场验证。

真实外部 M3Shapes 替代了本地圆角 Rectangle 仿制模块。插件及 QML import tree 由
CMake 正常生成，不手写原生 qmldir。设置中心的无边框只修改本进程拥有的 Qt Window flags，不遍历/剥除其他 Quickshell 或应用窗口的装饰。
Qt 图标主题使用上游原生 IconThemeController，只设置进程内 QIcon，不在启动时覆写 GNOME icon-theme。
字体来自固定 Nix 依赖和已有 Google Sans Flex，
fontconfig 只作用于本次进程。顶栏、两侧栏和设置中心保留移植界面的布局、层级与动画。
没有强制载入历史奶白主题；默认配置不等于作者的个人截图配置。

### 模糊、壁纸与颜色

- `BlurService` 当前报告 GNOME 模糊 **不可用**；透明只表示颜色 alpha。
  没有实时桌面模糊，也没有已验证的“仅壁纸模糊”；不循环截图制造毛玻璃。
- GNOME 拥有实际桌面和 overview 壁纸。本项目不创建覆盖普通窗口的 WallpaperBackground。
- 壁纸文件、活动浅/深主题 URI 和全局填充模式通过真实 GSettings 读取、观察与写入；
  文件验证失败不会修改桌面，写入后读回状态。选择填充模式作用于所有输出。
- Clavis 自定义桌面过渡、时长、Bezier、视差、独立 overview 和逐输出壁纸不受此后端支持，
  相应控件禁用并说明。壁纸颜色特效不可用时提示，不只保存一个无效果的属性。
- 封面配色由原生模块异步解码真实本地或 HTTP(S) 图片；下载限时 3 秒、限 8 MiB，
  过期结果丢弃。读取失败保留主题回退并暴露错误，而非宣称成功取色。

### 安全与系统所有权

- **锁屏：GNOME 原生锁屏**。只调用 `org.gnome.ScreenSaver.Lock`，没有自制 PAM 窗口或 unlock IPC。
  `GetActive` 只反映 screensaver；实际锁定状态来自 GNOME 发布的 logind `LockedHint`。
  未知状态不宣称 secure。测试不自动锁屏。
- **Idle：GNOME 原策略**。Keep awake 用 SessionManager 的真实 inhibit cookie；
  连接退出释放抑制。自定义 dim/lock/DPMS 阶段禁用，去 GNOME Settings → Power 设置。
- **夜灯/色彩：GNOME 所有**。原假 gamma/dimming 状态不再宣称有效；页面指向 GNOME Displays。
  硬件背光只在检测并读回成功后可用；桌面显示器的 DDC 控制尚未实现，不用软件 dimming 冒充。
- **音频：PipeWire/libcava 原生采样**，无计时器随机波形。未激活或没有新 PCM 数据时频谱不可用。
  音量控制保留原有真实 PipeWire 路径；后端失效时不再把固定 35% 等回退值当作可操作设备。
- **网络/蓝牙：保留既有 Quickshell 原生后端和 Wi-Fi stdin 凭据路径**。
  移除网络固定在线、假以太网设备和假信号强度；仍有未完成的配置操作，不能据此宣称全部网络功能可用。
- **通知/托盘/全局快捷键：GNOME 默认所有**。默认不创建第二个通知服务或 SNI watcher；
  Clavis 本地通知历史不等于 GNOME 的系统通知历史。Qt 局部快捷键不冒充 GNOME 全局快捷键。
  实验性的 `CLAVIS_OWN_NOTIFICATIONS=1` / `CLAVIS_OWN_TRAY=1` 只供显式选择所有权时使用，
  不会自动关闭 GNOME 所有者，不应在普通 GNOME 会话中随意启用。

## 构建与启动

需已有 Nix 与图形会话。构建会下载固定依赖到 Nix store，并写项目 `build/`；不改系统桌面。

```bash
cd "/home/dkp/projects/Ubuntu Quickshell Desktop Shell"
./scripts/build.sh
```

Qt ABI 变化时必须重建。构建脚本处理项目路径空格造成的 Nix 输出链接参数问题。
所有本地模块及外部 M3Shapes 使用同一 Nix Qt；不混入 `/usr/lib` 的 Ubuntu Qt 插件。

从 GNOME 会话内的终端启动：

```bash
./scripts/launch.sh
```

必须继承真实 `DISPLAY` 和会话环境；不猜测 `:0`，也不启动 niri。
GNOME Wayland 下有意使用 **XWayland + xcb/EGL**，不是切换到 Xorg；
Quickshell 关于 `WAYLAND_DISPLAY` 与 `xcb` 的通用警告不能通过直接改为 `wayland` 来处理。
启动器只给本实例配置固定 Nix Mesa/libglvnd 的库、DRI 与 EGL vendor 路径，
不向 `/usr/lib` 拼接 Ubuntu Qt 插件，也不强制软件渲染。
扩展未启用时仍可查看外壳，但窗口/工作区功能明确降级。
GNOME 原生顶栏、Dock、通知不会被脚本隐藏或关闭，因此可能有重复视觉区域；
是否接管这些区域需要单独确认，不能当作已完成替换。

无可见窗口的真实图形预检（也会在普通启动前执行）：

```bash
./scripts/launch.sh --check-graphics
```

它在当前显示上创建上下文、绘制 2×2 离屏 FBO 并读回像素，输出 Qt、实际 renderer 和屏幕信息；
失败/超时直接返回非零并停止启动，而不是以进程仍存活当作成功。
如需对照 GLX 路径，可单次使用 `CLAVIS_XCB_GL_INTEGRATION=xcb_glx ./scripts/launch.sh --check-graphics`；
默认仍为已验证的 EGL，不修改登录环境。

2026-11-16 图形启动现场定位：Ubuntu **26.04.1 LTS / GNOME 50.1 / Wayland** 上，
旧环境缺失 GLX vendor 查找路径，`libGLX_mesa.so.0` 的 `openat` 均返回 `ENOENT`，
导致 `Could not initialize GLX`。同一会话补全路径后，EGL 与 GLX 都实际读回
`[64,128,191,255]`，renderer 为 **AMD Radeon RX 9070 GRE / radeonsi / Mesa 26.2.3**。
这是图形驱动加载修复，不代表 GNOME 50 的全部协议、分数缩放或多屏布局已验收。

`Ctrl+C` 退出本次实例，或停止已由用户安装的 `clavis-desktop-shell.service`。
启动器不执行 `killall`，不更改 GNOME GSettings，因此无需覆盖用户设置来“恢复桌面”。
服务模板用 `KillMode=control-group`，仅回收本服务的进程。原生进程由专属 supervisor 管理，
桥接进程绑定父进程死亡信号；不会杀其他 Quickshell/niri 实例。
supervisor 明确设置上游支持的 `QS_DISABLE_CRASH_HANDLER=1`，禁用脱离本实例的崩溃 GUI/自动重启；
保留致命 stderr 与内核原生 coredump（依系统配置），signal 退出转换为 `128+signal` 非零状态。
字体临时配置直到实际子进程退出后才删除，不再被残留崩溃报告窗口引用。

### 屏幕定位与工作区保留

GNOME 的 125% 显示缩放不等于 Qt/XWayland 的 DPR；本机读回的 Qt DPR 是 2。
Qt 内部布局使用逻辑像素，`_NET_WM_STRUT[_PARTIAL]` 则必须使用 X11 root 原生像素。
`Clavis.Runtime.PanelReservation` 只接受本进程 QQuickItem，查询真实 RandR 输出边界，
按所属窗口 DPR 写入本窗口的 EWMH 保留区，不乘错多屏原点，也不修改其他应用的窗口属性。
只在窗口/屏幕/属性变化时协调；没有全局轮询或按进程名移动窗口。
原生读回由独立只读 XCB 连接在工作线程执行，回复等待共享 3 秒期限；
UI 的 Pending 状态也在 3 秒后降级，不会同步等待 X server 或在查询卡住时不断创建工作线程。
窗口/屏幕更换后丢弃旧查询。

- 顶栏和 Dock 保留静止视觉厚度；阴影、动画画布不占用工作区。
- Keystone、侧栏、桌面卡片、Launcher 等画布使用物理屏幕边缘，而非再次偏移到顶栏保留区下方。
  同一边缘的顶栏与静止 Keystone 保留区由 WM 取最大值，不叠加成两行。
- Quickshell 0.3.1 在改变 X11 exclusionMode 后不总是重算自身几何；
  适配器用真实 QScreen 维护显式选择的本进程全屏画布/热角，不靠无效的自定义 `property x/y`。
- 顶栏 top/bottom 与 left/right 使用对应的水平/垂直窗口；不能把左侧顶栏当作水平窗居中。
- 无真实背光时，硬件探测的失败信号不会在启动时把中央时钟替换成假的 0% 亮度 OSD。

`diagnostics snapshot` IPC 的 `panels` 包含实际 native 窗口、输出/根窗口边界、DPR、
视觉矩形和从 X server 异步读回的 strut，可用于定位，不用硬编码坐标冒充状态。
`state` 区分 Pending/Ready/Unavailable，`readbackAt` 标记最近一次实际读回的时间；
查询尚未完成时不会把推算的坐标或刚写入的 strut 冒充读回结果。
仅查询真实会话、不显示窗口的检测器是 `build/bin/clavis-placement-probe`
（需在固定 Nix/graphics-env 环境运行）；检查前后系统工作区已确认不变。

本轮定位验证在私有 Xvfb/Openbox/picom 上分别使用 Qt DPR 1、1.25、2，
检查实际窗口原生坐标、独立 `xprop` 属性读回，并让专属测试 Qt 窗口真正请求最大化；
按实际 `_NET_FRAME_EXTENTS` 验证包含 WM 装饰的完整窗口与工作区一致，而不假定无边框提示被接受。
还检查启动器 SIGKILL 后专属子进程退出，私有 WM 工作区恢复为完整 root，未残留保留区。
DPR 2 时顶栏保留由错误的 52 修正为 104，Dock 由 78 修正为 156 个 X11 原生像素；
中央/侧栏画布从 y=104 修正为 y=0。截图和日志在 `build/placement-validation/`。
这不是用户真实 GNOME 上的可见面板/最大化验收；真实桌面上的多输出、热插拔和混合缩放仍待验证。
用户手动隐藏的 GNOME 顶栏/Dock 不会被启动器修改或恢复，桥接扩展也没有为此自动安装/启用。

### 可选 GNOME 扩展（需用户确认影响）

打包不安装、不启用：

```bash
./scripts/gnome-extension.sh pack
```

用户确认后自行执行：

```bash
./scripts/gnome-extension.sh install
./scripts/gnome-extension.sh enable
```

扩展允许同一用户会话中的本地客户端访问窗口信息并提交窗口操作。
它不隐藏 GNOME 顶栏、不替换通知/锁屏、不切换桌面、不安装特权规则。
首次安装的扩展有时只能在下一次由用户自行选择的登录后被 Shell 发现；
安装失败或不可发现时不得自动注销/重启 Shell。

回退桥接：

```bash
./scripts/gnome-extension.sh disable
```

禁用后外壳清空窗口模型。删除本项目不会删除既有 niri 集成；扩展文件也不由默认卸载脚本强删。
源码改动可用 `git diff` 审查；本轮未自动提交。

## 验证范围（不能互相替代）

| 检查 | 能说明什么 | 不能说明什么 |
| --- | --- | --- |
| CMake / Ninja | 同一 Qt ABI 的三个原生模块成功构建 | GNOME 的实际视觉与系统操作 |
| `scripts/launch.sh --check-graphics` | 当前真实 GNOME XWayland 上的硬件上下文与 FBO 像素读回；本机 EGL、GLX 均验证 | 可见面板摆放、动画、全量 GNOME 功能 |
| `tests/test_run_instance.py`（在同一图形/Nix 环境） | 无可见窗口的真实 Quickshell IPC 就绪后，针对该 PID 注入 SIGABRT；检查 exit 134、字体清理、无脱离实例的 reporter | 用户桌面上的完整外壳视觉；不操作用户窗口 |
| `scripts/native-check.sh` | 加载源树实际使用的 native URI；真实形状像素不同；两张解码封面产生不同配色；未激活音频不可用 | 用户音频链路、真实 GNOME 模糊 |
| `nix develop --command ./tests/session-check.sh` | 无可见窗口，仅把真实 GNOME 状态传到 QML；后端缺失时空模型；可用 `CLAVIS_TEST_QPA_PLATFORM=xcb` 检查真实 XWayland/EGL（默认 offscreen） | 扩展窗口操作、桌面视觉 |
| `/usr/bin/python3 tests/test_gnome_bridge.py -v` | 只读 GNOME 壁纸/screensaver 状态、无效操作拒绝、SIGKILL 后 500ms 内伴生退出 | 真正锁屏、休眠、断网、扩展窗口操作 |
| `scripts/smoke_test.sh` | 私有 D-Bus + Xvfb + Openbox/picom：打开顶栏、两侧栏、设置中心及受影响设置页；实际帧非空、侧栏像素变化、正常退出和启动器 SIGKILL 后无伴生残留检查 | GNOME Wayland、原生 niri 对照、多屏/分数缩放、硬件加速真实性 |
| 定位 DPR 矩阵（`tests/gnome-render.sh`） | Qt DPR 1/1.25/2 的实际 native 几何、strut 独立读回、测试窗口最大化避让；真实 GNOME 的隐藏窗口 RandR 只读查询 | 真实 GNOME 可见面板与用户窗口操作、多输出混合缩放 |
| 既有 debt/质量门禁 | 局部约束与未增债检查；原 C++ 禁令改为真实原生运行验证 | 零技术债、完整功能、安全与视觉验收 |

截图产生在 `build/gnome-validation/`，压缩后每张不超过 200,000 字节，查看每次最多两张。
原生形状测试输出在 `build/native-validation/`。Xvfb 图片不是用户实际 GNOME 桌面截图。
日志保留，正常的资源缺失等 advisory warning 不称“零警告”。

尚待明确授权的现场验收：启用桥接后观察全部 Wayland/XWayland 窗口、切换工作区、
最小化/恢复、125% 缩放和多屏；确认视觉区域所有权后统一壁纸/主题/字体作完整对照；
锁屏/idle 抑制、网络认证、蓝牙配对、真实音频等动作分别确认影响后测试。
