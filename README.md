# Clavis Desktop Shell for Ubuntu

<p align="center">
  <img src="https://raw.githubusercontent.com/StatIndet/picture/main/clavis-shell/Screenshot%20from%202026-09-12%2015-32-08.png" alt="Clavis Desktop Shell Showcase" width="85%" style="border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.3);" />
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white&style=flat-square" alt="Ubuntu" /></a>
  <a href="#"><img src="https://img.shields.io/badge/GNOME-46%20Mutter-4a154b?logo=gnome&logoColor=white&style=flat-square" alt="GNOME" /></a>
  <a href="https://quickshell.org/"><img src="https://img.shields.io/badge/Engine-Quickshell%200.3.1-007acc?logo=qt&logoColor=white&style=flat-square" alt="Quickshell" /></a>
  <a href="https://m3.material.io/"><img src="https://img.shields.io/badge/Design-Material%203-4285F4?logo=google&logoColor=white&style=flat-square" alt="Material Design 3" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-success.svg?style=flat-square" alt="License" /></a>
  <a href="https://github.com/demgkp1/Ubuntu-Quickshell-Desktop-Shell/releases"><img src="https://img.shields.io/badge/Release-v1.0.0-blue.svg?style=flat-square" alt="Release" /></a>
</p>

---

## 🌟 项目简介 (Overview)

**Clavis Desktop Shell for Ubuntu** 是一款专为 **Ubuntu 24.04 LTS (GNOME 46 / Mutter)** 环境打造的现代化、高质感液态桌面 Shell。

本项目以 [StatIndet/quickshell](https://github.com/StatIndet/quickshell) 为视觉基准与设计灵魂，针对 Ubuntu 系统的稳定服务架构进行了**全栈纯 QML / JS 无损重构**。它在不破坏 Ubuntu 系统底层稳定性的前提下，赋予整机桌面如水流般灵动的 **Google Material Design 3 (M3)** 交互体验、实时壁纸色彩浸润、macOS 质感 Dock 以及毫秒级响应的系统微件。

---

## 🎨 视觉画廊与功能全景 (Gallery)

<table>
  <tr>
    <td width="50%">
      <img src="https://raw.githubusercontent.com/StatIndet/picture/main/clavis-shell/Screenshot%20from%202026-09-12%2015-20-21.png" alt="顶栏与灵动岛" width="100%" />
      <p align="center"><b>顶栏与 Keystone 灵动岛媒体流转</b></p>
    </td>
    <td width="50%">
      <img src="https://raw.githubusercontent.com/StatIndet/picture/main/clavis-shell/Screenshot%20from%202026-09-12%2015-23-30.png" alt="Material 3 暖色自适应主题" width="100%" />
      <p align="center"><b>Matugen 全桌面壁纸动态自适应调色</b></p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="https://raw.githubusercontent.com/StatIndet/picture/main/clavis-shell/Screenshot%20from%202026-09-12%2015-33-40.png" alt="Fluid Dock 与应用启动" width="100%" />
      <p align="center"><b>macOS 质感 Fluid 液态浮动 Dock</b></p>
    </td>
    <td width="50%">
      <img src="https://raw.githubusercontent.com/StatIndet/picture/main/clavis-shell/Screenshot%20from%202026-09-12%2015-43-18.png" alt="原生控制中心" width="100%" />
      <p align="center"><b>72 模块原生控制中心与系统快捷卡片</b></p>
    </td>
  </tr>
</table>

---

## ✨ 核心特性亮点 (Features)

- 🎨 **Matugen M3 动态色彩闭环**：全桌面（顶栏、灵动岛、Dock、卡片、滑块）跟随当前壁纸自动毫秒级提取主色、色盘与对比度，实现视觉体验的极致沉浸。
- 🏝️ **Keystone 灵动岛 (Dynamic Island)**：位于顶栏中央的动态流体交互胶囊，自适应承载高保真时钟、MPRIS 媒体流转、音量反馈及硬件状态监控。
- 🌊 **Fluid 液态 Dock**：支持 32px ~ 80px 动态平滑无级缩放，配备运行状态指示器、弹性悬停微动效与轻量启动器。
- 🔍 **Spotlight 全能聚光灯搜索**：绑定通用全局快捷键 `Ctrl+Space` / `Alt+Space`，支持极速应用检索、历史剪贴板回溯与快捷系统指令。
- ⚙️ **原生控制中心 (Control Center)**：内置 72 个功能页与状态微件，无缝调度 Wi-Fi 网络、蓝牙设备、夜间模式、音量均衡与壁纸偏好。
- 🔒 **Mutter X11 液态毛玻璃锁屏**：基于 ffmpeg 96ms 极速无黑边全屏快照与 PAM 密码认证，登录后享受丝滑的模糊过渡与卡片交互。
- 📐 **120ms 防抖四角热角 (HotCorners)**：屏幕四物理角防误触算法，瞬时响应角部停留，无缝联动 GNOME Overview 与快捷设置。
- 🚀 **零 C++ 编译负担**：100% 采用纯 QML / JavaScript Shim 架构，摆脱复杂的本地 C++ 编译工具链，开箱即用，即拉即跑。

---

## 📦 快速安装与开始使用 (Quick Start)

### 选项 A：直接下载独立 Release 压缩包（推荐）

无需克隆庞大的 Git 开发历史，直接下载预构建装箱的便携发行包：

1. 前往 [Releases 发布页面](https://github.com/demgkp1/Ubuntu-Quickshell-Desktop-Shell/releases) 下载最新发行归档：
   ```bash
   # 以 v1.0.0 为例
   wget https://github.com/demgkp1/Ubuntu-Quickshell-Desktop-Shell/releases/download/v1.0.0/clavis-desktop-shell-v1.0.0-ubuntu24.04.tar.gz
   tar -xzf clavis-desktop-shell-v1.0.0-ubuntu24.04.tar.gz
   cd clavis-desktop-shell-v1.0.0-ubuntu24.04
   ```

2. 运行一键安装脚本（自动配置守护单元与自启动项）：
   ```bash
   ./scripts/install.sh --enable --start
   ```

---

### 选项 B：从源码仓库克隆与构建

```bash
# 1. 克隆代码仓库
git clone https://github.com/demgkp1/Ubuntu-Quickshell-Desktop-Shell.git
cd "Ubuntu-Quickshell-Desktop-Shell"

# 2. 前台试运行桌面 Shell（按 Ctrl+C 可随时安全退出）
./scripts/launch.sh

# 3. 安装为开机自启系统服务
./scripts/install.sh --enable --start
```

> **环境依赖**：系统需安装 [Nix 包管理器](https://nixos.org/download.html)（用于拉取 Quickshell 0.3.1 运行时）。若未安装，运行 `./scripts/install.sh` 时会自动提供清晰引导。

---

## 🛠️ 日常运维管理工具 (`clavisctl`)

系统安装后，将自动注册 `clavisctl` 统一运维 CLI 至您的终端环境（`~/.local/bin/clavisctl`）：

### 服务生命周期与健康诊断

```bash
# 查看桌面 Shell 全维健康体检报告（Systemd 状态、PID、X11 窗口几何尺寸树、IPC 响应）
clavisctl status

# 重启桌面 Shell 服务
clavisctl restart

# 停止桌面 Shell 并平滑恢复 GNOME 原生顶栏
clavisctl stop

# 启动桌面 Shell 服务
clavisctl start

# 查看实时服务运行日志
clavisctl logs -f
```

### 开机自启动灵活控制

```bash
# 查看当前开机自启配置状态
clavisctl autostart status

# 随时一键禁用开机自启（保留桌面 Shell 与所有 CLI 工具）
clavisctl autostart disable

# 一键恢复开机自启
clavisctl autostart enable
```

### 交互界面快捷切换

```bash
clavisctl toggle spotlight       # 呼出 / 收起 Spotlight 聚光灯搜索
clavisctl toggle controlcenter   # 呼出 / 收起控制中心设置窗口
clavisctl toggle powermenu       # 呼出 / 收起电源会话菜单
clavisctl toggle quicksettings   # 展开 / 收起右侧快捷设置侧栏
clavisctl toggle lock            # 立即触发液态毛玻璃锁屏
clavisctl toggle screenshot      # 启动全屏区域截图选择器
clavisctl toggle color           # 启动屏幕高精度拾色器
```

---

## 🎬 上游同款壁纸与 Shader 动效实机演示

想要亲自体验上游演示中的同款壁纸过渡特效？我们在项目中预置了上游官方 6 张原版高清壁纸与 7 种 GLSL 过渡 Shader：

```bash
# 运行实机交互演示工具
./scripts/demo_wallpaper_effects.sh
```

**演示窗口功能**：
- 🌟 **6 款上游官方原版演示同款壁纸**：包含上游招牌日落耳机少女（`wallhaven-1q21jw`）、复古迈尔斯蜘蛛侠、青蓝夜云风景、淡雅花卉少女、赛博都市夜景与头文字 D AE86；
- 🌊 **7 大 GLSL 过渡 Shader 自由切换**：圆盘扩散（`disc`）、光晕绽放（`iris bloom`）、传送门（`portal`）、像素马赛克（`pixelate`）、线性擦除（`wipe`）、百叶窗条纹（`stripes`）与平滑淡入（`fade`）；
- 🎨 **Matugen M3 动态提取看板**：实时查看壁纸对应的 Primary、Secondary、Surface 提取色值；
- 🖥️ **一键设为整机桌面**：点击界面中的“设为整机桌面”，可立即联动您电脑当前运行中的 Clavis 桌面 Shell 实时变色！

---

## 📚 技术文档与架构参考

- 📐 **[核心分层架构设计规范 (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)**：1:1 源码级镜像分层架构、Matugen 调色管道与 Mutter 适配规范。
- 🚀 **[系统部署与开机自启运维指南 (docs/DEPLOYMENT_AND_AUTOSTART.md)](docs/DEPLOYMENT_AND_AUTOSTART.md)**：Systemd 服务单元深度解析与多场景启动策略。
- 💻 **[动态硬件自适应矩阵 (docs/HARDWARE_ADAPTATION_MATRIX.md)](docs/HARDWARE_ADAPTATION_MATRIX.md)**：台式机/笔记本、单双屏、有线/无线及硬件背光适配说明。

---

## 🧹 彻底卸载与还原 (Uninstallation)

若希望从系统中完全移除 Clavis Desktop Shell，只需在项目根目录下执行：

```bash
./scripts/uninstall.sh
```

卸载脚本会自动停止服务、移除 Systemd 单元、删除自启动快捷项、清理 CLI 软链接并恢复 GNOME 原生顶栏，**整机环境 100% 干净还原**。

---

## 🤝 致谢与开源参考 (Acknowledgements)

Clavis Desktop Shell for Ubuntu 衷心感谢以下开源项目与社区的先驱工作：

- [StatIndet/quickshell](https://github.com/StatIndet/quickshell) — 卓越的桌面设计概念与视觉源泉 (Clavis)
- [Quickshell Project](https://quickshell.org/) — 极速响应的新一代 Wayland/X11 QML 桌面外壳框架
- [InioX/matugen](https://github.com/InioX/matugen) — 优雅高效的 Material You / M3 跨平台色彩提取工具
- [Google Material Design 3](https://m3.material.io/) — 现代化、包容性的设计规范系统

---

## 📄 开源许可证 (License)

本项目依据 [GNU General Public License v3.0 (GPL-3.0)](LICENSE) 许可协议开源发布。
