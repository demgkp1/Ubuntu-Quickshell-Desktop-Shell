import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Wallpaper

ShellRoot {
    id: root

    readonly property string demoDir: Quickshell.shellDir
    readonly property string wallpapersDir: demoDir + "/wallpapers"

    property var wallpapers: [
        {
            name: "Sunset Headphones Girl (日落耳机少女)",
            tag: "上游官方 README 招牌演示同款",
            desc: "温暖日落与耳机少女，提取温润奶油米粉 M3 色系",
            file: "wallhaven-1q21jw.jpg",
            primaryColor: "#E27B66",
            surfaceColor: "#2A1815",
            containerColor: "#4B2822"
        },
        {
            name: "Spider-Man Marvel (复古插画蜘蛛侠)",
            tag: "上游官方基准 target_spider_cream",
            desc: "复古漫画风格迈尔斯·莫拉莱斯，米白暖调主题",
            file: "【哲风壁纸】插画-漫威-漫威宇宙.png",
            primaryColor: "#C96D56",
            surfaceColor: "#201A19",
            containerColor: "#392B28"
        },
        {
            name: "Night Clouds Landscape (青蓝夜云风景)",
            tag: "上游官方基准 target_teal_theme",
            desc: "深邃青蓝夜空与云彩风景，Clavis 招牌冷翠青色主题",
            file: "【哲风壁纸】云彩-夜晚-夜景.png",
            primaryColor: "#4EA8A6",
            surfaceColor: "#101E1E",
            containerColor: "#1B3333"
        },
        {
            name: "Flower Girl (淡雅花卉少女)",
            tag: "上游官方演示截图 1 & 4 同款",
            desc: "柔和漫射光线与花卉少女，明亮浅色高对比度色系",
            file: "wallhaven-d8demg.png",
            primaryColor: "#B58A63",
            surfaceColor: "#241F1A",
            containerColor: "#3E332A"
        },
        {
            name: "Cyberpunk City (冷调都市夜景)",
            tag: "上游官方演示截图 5 同款",
            desc: "流光溢彩的赛博都市，冷色调蓝紫荧光色系",
            file: "wallhaven-vp299m.jpg",
            primaryColor: "#7A8BE2",
            surfaceColor: "#161828",
            containerColor: "#242845"
        },
        {
            name: "Initial D AE86 (头文字D 秋名山)",
            tag: "上游选图器第 1 张卡片同款",
            desc: "秋名山传奇赛车 8K 超清壁纸，极简工业风深灰冷调",
            file: "ae86.png",
            primaryColor: "#A6AAB2",
            surfaceColor: "#181A1C",
            containerColor: "#282C30"
        }
    ]

    property var shaders: [
        { id: "fade", label: "Fade (平滑淡入)", icon: "✨" },
        { id: "wipe", label: "Wipe (线性擦除)", icon: "🌊" },
        { id: "disc", label: "Disc (圆盘扩散)", icon: "⭕" },
        { id: "stripes", label: "Stripes (百叶条纹)", icon: "🦓" },
        { id: "iris bloom", label: "Iris Bloom (光晕绽放)", icon: "🌸" },
        { id: "pixelate", label: "Pixelate (像素马赛克)", icon: "🔲" },
        { id: "portal", label: "Portal (传送门)", icon: "🌀" },
        { id: "random", label: "Random (随机切换)", icon: "🎲" }
    ]

    property int currentWallpaperIndex: 0
    property string selectedShader: "iris bloom"
    property bool autoTour: false
    property string statusMessage: "就绪：点击下方卡片或着色器体验过渡动效"

    readonly property var currentWp: wallpapers[currentWallpaperIndex]
    readonly property string currentWpPath: wallpapersDir + "/" + currentWp.file

    function selectWallpaper(index, immediate) {
        if (index < 0) index = wallpapers.length - 1;
        if (index >= wallpapers.length) index = 0;
        currentWallpaperIndex = index;

        let shaderToUse = selectedShader;
        if (shaderToUse === "random") {
            const list = ["fade", "wipe", "disc", "stripes", "iris bloom", "pixelate", "portal"];
            shaderToUse = list[Math.floor(Math.random() * list.length)];
        }
        transitionSurface.transitionType = shaderToUse;
        transitionSurface.requestWallpaper(currentWpPath, immediate);
        root.statusMessage = "正在渲染 [" + shaderToUse + "] 过渡至: " + currentWp.name;
    }

    function applyToDesktop() {
        setDesktopProcess.command = [
            "gsettings", "set", "org.gnome.desktop.background", "picture-uri", "file://" + currentWpPath
        ];
        setDesktopDarkProcess.command = [
            "gsettings", "set", "org.gnome.desktop.background", "picture-uri-dark", "file://" + currentWpPath
        ];
        setDesktopProcess.running = true;
        setDesktopDarkProcess.running = true;
        root.statusMessage = "✓ 已设为整机桌面！正在联动当前运行中的 Clavis 桌面 Shell 实时变色...";
    }

    Process {
        id: setDesktopProcess
    }

    Process {
        id: setDesktopDarkProcess
    }

    Timer {
        id: tourTimer
        interval: 3800
        running: root.autoTour
        repeat: true
        onTriggered: {
            root.selectWallpaper(root.currentWallpaperIndex + 1, false);
        }
    }

    FloatingWindow {
        id: window
        title: "Clavis Desktop Shell — 上游同款壁纸与 Shader 动效实机演示"
        implicitWidth: 1120
        implicitHeight: 700
        color: "transparent"
        visible: true

        Rectangle {
            id: mainCard
            anchors.fill: parent
            radius: 16
            clip: true
            color: "#16171a"
            border.width: 1
            border.color: "#30ffffff"

            // 1. Wallpaper Transition Surface (Canvas)
            WallpaperTransitionSurface {
                id: transitionSurface
                anchors.fill: parent
                sourcePath: root.currentWpPath
                transitionType: "iris bloom"
                transitionDurationMs: 900
            }

            // Subtle vignette shadow around edges
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: "#25ffffff"
                radius: 16
            }

            // 2. Top Header Bar Overlay
            Rectangle {
                id: topBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                height: 48
                radius: 24
                color: "#c015181e"
                border.width: 1
                border.color: "#30ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "🎨 Clavis 官方同款壁纸与 GLSL Shader 动效演示"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }

                    Rectangle {
                        height: 22
                        width: 1
                        color: "#40ffffff"
                    }

                    Text {
                        text: "当前 Shader: " + transitionSurface.transitionType
                        font.pixelSize: 12
                        color: "#a0ffffff"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.statusMessage
                        font.pixelSize: 12
                        color: "#80d0ff"
                        elide: Text.ElideRight
                        Layout.maximumWidth: 380
                    }

                    // Exit button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: closeMouse.containsMouse ? "#40ffffff" : "#20ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.quit()
                        }
                    }
                }
            }

            // 3. Bottom Control Deck (Glass M3 Control Panel)
            Rectangle {
                id: bottomDeck
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                height: 250
                radius: 16
                color: "#d814161c"
                border.width: 1
                border.color: "#28ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Row 1: Shader Selection Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "过渡 Shader:"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#d0ffffff"
                            Layout.rightMargin: 4
                        }

                        Repeater {
                            model: root.shaders

                            Rectangle {
                                id: shaderPill
                                height: 30
                                width: pillText.implicitWidth + 20
                                radius: 15
                                color: root.selectedShader === modelData.id ? "#386a9f" : (pillMouse.containsMouse ? "#30ffffff" : "#18ffffff")
                                border.width: 1
                                border.color: root.selectedShader === modelData.id ? "#70a5ff" : "#20ffffff"

                                Text {
                                    id: pillText
                                    anchors.centerIn: parent
                                    text: modelData.icon + " " + modelData.label
                                    font.pixelSize: 11
                                    font.bold: root.selectedShader === modelData.id
                                    color: root.selectedShader === modelData.id ? "#ffffff" : "#c0ffffff"
                                }

                                MouseArea {
                                    id: pillMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedShader = modelData.id;
                                        root.selectWallpaper(root.currentWallpaperIndex, false);
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Row 2: Upstream Showcase Wallpapers Carousel
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Repeater {
                            model: root.wallpapers

                            Rectangle {
                                id: wpCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                clip: true
                                color: "#20222a"
                                border.width: root.currentWallpaperIndex === index ? 2 : 1
                                border.color: root.currentWallpaperIndex === index ? "#6ea8fe" : (cardMouse.containsMouse ? "#50ffffff" : "#25ffffff")

                                Image {
                                    anchors.fill: parent
                                    source: root.wallpapersDir + "/" + modelData.file
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: root.currentWallpaperIndex === index ? 1.0 : (cardMouse.containsMouse ? 0.85 : 0.6)
                                }

                                // Gradient shade at bottom for text
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 38
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: "#e0000000" }
                                    }
                                }

                                Text {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectWallpaper(index, false);
                                    }
                                }
                            }
                        }
                    }

                    // Row 3: Action Toolbar & Live Matugen M3 Palette Swatches
                    RowLayout {
                        Layout.fillWidth: true
                        height: 36
                        spacing: 10

                        // Prev / Next Buttons
                        Rectangle {
                            height: 30
                            width: 80
                            radius: 15
                            color: prevMouse.containsMouse ? "#30ffffff" : "#1cffffff"
                            border.width: 1
                            border.color: "#30ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: "◀ 上一张"
                                font.pixelSize: 11
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectWallpaper(root.currentWallpaperIndex - 1, false)
                            }
                        }

                        Rectangle {
                            height: 30
                            width: 80
                            radius: 15
                            color: nextMouse.containsMouse ? "#30ffffff" : "#1cffffff"
                            border.width: 1
                            border.color: "#30ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: "下一张 ▶"
                                font.pixelSize: 11
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectWallpaper(root.currentWallpaperIndex + 1, false)
                            }
                        }

                        // Auto-Tour Toggle Button
                        Rectangle {
                            height: 30
                            width: 110
                            radius: 15
                            color: root.autoTour ? "#2a683a" : (tourMouse.containsMouse ? "#30ffffff" : "#1cffffff")
                            border.width: 1
                            border.color: root.autoTour ? "#60d380" : "#30ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: root.autoTour ? "⏱️ 轮播中 (开启)" : "⏱️ 自动轮播"
                                font.pixelSize: 11
                                font.bold: root.autoTour
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: tourMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.autoTour = !root.autoTour;
                                    root.statusMessage = root.autoTour ? "自动巡回轮播已启动 (每 3.8 秒切换)" : "自动巡回轮播已暂停";
                                }
                            }
                        }

                        Rectangle {
                            height: 20
                            width: 1
                            color: "#30ffffff"
                        }

                        // Live Matugen Palette Chips
                        Text {
                            text: "M3 色盘提取:"
                            font.pixelSize: 11
                            color: "#a0ffffff"
                        }

                        Row {
                            spacing: 6

                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: root.currentWp.primaryColor
                                border.width: 1; border.color: "#ffffff"
                                ToolTip.visible: chip1Mouse.containsMouse
                                ToolTip.text: "Primary: " + root.currentWp.primaryColor
                                MouseArea { id: chip1Mouse; anchors.fill: parent; hoverEnabled: true }
                            }

                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: root.currentWp.containerColor
                                border.width: 1; border.color: "#80ffffff"
                                ToolTip.visible: chip2Mouse.containsMouse
                                ToolTip.text: "Container: " + root.currentWp.containerColor
                                MouseArea { id: chip2Mouse; anchors.fill: parent; hoverEnabled: true }
                            }

                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: root.currentWp.surfaceColor
                                border.width: 1; border.color: "#80ffffff"
                                ToolTip.visible: chip3Mouse.containsMouse
                                ToolTip.text: "Surface: " + root.currentWp.surfaceColor
                                MouseArea { id: chip3Mouse; anchors.fill: parent; hoverEnabled: true }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Apply to Desktop Button
                        Rectangle {
                            height: 30
                            width: 190
                            radius: 15
                            color: applyMouse.containsMouse ? "#2f7250" : "#24583d"
                            border.width: 1
                            border.color: "#5cd68f"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "🖥️ 设为整机桌面 (联动变色)"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                id: applyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyToDesktop()
                            }
                        }
                    }
                }
            }
        }
    }
}
