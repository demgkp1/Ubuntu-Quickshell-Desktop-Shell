# 动态硬件与平台自适应规范矩阵
*(Dynamic Hardware & Platform Adaptation Matrix)*

> **版本**：1.0.0 (Canonical)  
> **核心原则**：**绝对零硬编码 (Zero Hardcoding)**。所有硬件差异由程序在运行时自适应动态侦测，一套代码同时兼容台式机与笔记本电脑。

---

## 一、 自适应矩阵总览 (Adaptation Matrix)

| 硬件子系统 | 侦测数据源 | 笔记本 / 移动工作站表现 | 台式机 / 独立显示器表现 | 回退与容错行为 (Fallback) |
| :--- | :--- | :--- | :--- | :--- |
| **电源与电池**<br>*(Power/Battery)* | `Quickshell.Services.UPower`<br>`UPower.displayDevice` | 渲染顶栏电池胶囊（电量百分比、充放电状态动画、剩余时间提示）。 | **彻底隐藏（0 像素占位）**。绝不显示虚假 100% 或电量问号。 | 若 UPower 服务未就绪，保持隐藏或显示静默，不引发 QML 异常。 |
| **网络连接**<br>*(Network)* | `NetworkManager` D-Bus<br>`NetworkService.qml` | Wi-Fi 开启时显示信号格数与 SSID；支持无线热点扫描与密码弹窗。 | 若检测到有线连接（`wiredConnected`），自动优先展示有线网卡图标（`settings_ethernet`），抑制 Wi-Fi 轮询。 | 双网卡同时在线时优先展示活跃链路；完全无网时显示网络离线断开图标。 |
| **屏幕背光**<br>*(Backlight)* | `/sys/class/backlight/*`<br>`Brightness.qml` | 存在物理背光节点时，双轨滑块直接平滑调节物理面板亮度。 | 外接 DP/HDMI 显示器（无物理背光节点）时，滑块自动无缝分流至 `DisplayColor` 软件遮罩调光（Software Dimmer）。 | 双轨滑块外观与质感 100% 保持一致，用户无需感知底层调光机制差异。 |
| **夜间护眼**<br>*(Night Light)* | GNOME Color D-Bus /<br>`DisplayColor.qml` | 支持随日落时间或手动色温（4500K）调节屏幕冷暖调。 | 同左，若合成器接口受限，平滑退化为软件滤镜。 | 接口不可用时标明 "Unavailable" 并置灰，不崩溃。 |
| **蓝牙与外设**<br>*(Bluetooth)* | `BlueZ` D-Bus<br>`BluetoothService.qml` | 具备蓝牙控制器时支持开关、配对列表展示与快捷连接。 | 无蓝牙芯片时快捷磁贴自动标明“Unavailable”并禁用展开。 | 热插拔蓝牙适配器时动态刷新状态。 |
| **音频输出与输入**<br>*(Audio/Mic)* | `PipeWire` D-Bus / Socket<br>`Volume.qml` | 实时跟踪默认 Sink（耳机/扬声器）与麦克风音量及静音状态。 | 同左，自动识别 HDMI 声卡、USB DAC 与独立声卡节点。 | 无麦克风输入节点时，麦克风滑块自动隐藏或置灰。 |

---

## 二、 核心自适应代码范式 (Code Implementation Paradigms)

### 1. 电池自适应：台式机 0 像素折叠范式
在 `Modules/Bar/QuickSettings/Battery.qml` 中：
```qml
// 严禁假死写死，动态侦测是否存在真实电池设备
readonly property bool hasPhysicalBattery: {
    return PowerService.present && !isNaN(PowerService.percentage);
}

// 台式机无电池时彻底折叠，尺寸归零
visible: hasPhysicalBattery
implicitWidth: visible ? (root.vertical ? Math.max(28, batteryContent.implicitWidth) : batteryContent.implicitWidth + 8) : 0
implicitHeight: visible ? (root.vertical ? Math.max(Sizes.barControlCircleSize, batteryContent.implicitHeight) : Sizes.barControlCircleSize) : 0
```

### 2. 网络自适应：双网动态平滑切换范式
在 `Modules/Bar/QuickSettings/Network.qml` 与 `QuickSettingsSurface.qml` 中：
```qml
// 动态判定当前激活网络介质
readonly property string networkIcon: {
    if (NetworkService.wiredConnected)
        return "settings_ethernet";
    if (NetworkService.wifiConnected)
        return NetworkService.wifiSignalIcon;
    if (NetworkService.wifiAvailable)
        return "wifi_off";
    return "signal_wifi_off";
}

readonly property string networkLabel: {
    if (NetworkService.wiredConnected)
        return qsTr("Ethernet");
    if (NetworkService.wifiConnected)
        return NetworkService.activeConnection;
    return qsTr("Disconnected");
}
```

### 3. 背光自适应：物理背光与软件遮罩平滑流转
在 `Modules/QuickSettings/QuickSliders.qml` 中：
```qml
onMoved: {
    if (Brightness.hasHardwareBacklight) {
        // 物理屏幕直接调节背光
        Brightness.setBrightnessForScreen(root.screen, value);
    } else {
        // 外接显示器自动分流至软件伽马/调光遮罩
        DisplayColor.setDimming(value);
    }
}
```

---

## 三、 审查门禁判定准则
后续所有参与移植的 Agent 必须严格自检：
1. **是否引入了任何针对特定机器路径（如硬编码某个网卡名称 `wlan0`、某个显示器名字 `eDP-1`、固定电池编号 `BAT0`）的逻辑？**
   - 若有，立即判定违规退回重做。
2. **是否在台式机环境下测试了电池隐藏效果？**
   - 台式机顶栏绝不可出现空白占位或残缺图标。
