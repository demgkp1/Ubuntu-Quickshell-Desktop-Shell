import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

/**
 * ControlCenterWindow - Frosted Glass System Quick Settings & Control Center
 *
 * Floating popup window anchored below the trailing status pill.
 * Features:
 * - Interactive PipeWire audio volume slider and mute toggle
 * - Network state monitor and settings launcher
 * - Dark mode & night light system toggles
 * - Session actions (Lock, Suspend, Reboot, Power Off)
 * - GNOME native panel fallback
 */
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    color: "transparent"
    visible: ControlCenterService.isOpen
    aboveWindows: true
    focusable: true
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.sizes.topBarHeight + 6
        right: Theme.sizes.spacingLg
    }

    implicitWidth: 340
    implicitHeight: 460

    // ESC key closes control center
    Item {
        focus: root.visible
        Keys.onEscapePressed: {
            ControlCenterService.close();
        }
    }

    // 1. Ambient Drop Shadow
    Rectangle {
        id: shadow
        anchors.fill: surface
        anchors.margins: -4
        radius: Theme.sizes.radiusCard + 4
        color: Theme.colors.glassShadow
        opacity: 0.6
        z: -1
    }

    // 2. Frosted Surface
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.sizes.radiusCard
        color: Qt.rgba(0.06, 0.12, 0.13, 0.94) // Frosted deep forest slate
        border.color: Theme.colors.glassBorder
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header: Title & Close Hint
            Item {
                width: parent.width
                height: 22

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "快捷控制中心"
                        color: Theme.colors.text
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeBodyLarge
                        font.weight: Theme.typography.weightBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ESC 退出"
                    color: Theme.colors.textTertiary
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeCaption
                }
            }

            // 1. Audio Volume Card
            Rectangle {
                width: parent.width
                height: 76
                radius: 12
                color: Theme.colors.surface0
                border.color: Theme.colors.glassBorder
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Device name and percentage
                    Item {
                        width: parent.width
                        height: 16

                        Text {
                            anchors.left: parent.left
                            anchors.right: volPctText.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: AudioService.sinkName
                            color: Theme.colors.textSecondary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeCaption
                            elide: Text.ElideRight
                        }

                        Text {
                            id: volPctText
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: AudioService.isMuted ? "静音" : (AudioService.volumePercent + "%")
                            color: AudioService.isMuted ? Theme.colors.textTertiary : Theme.colors.primary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBodySmall
                            font.weight: Theme.typography.weightBold
                        }
                    }

                    // Interactive Slider Row
                    Row {
                        width: parent.width
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Mute button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: AudioService.isMuted ? Theme.colors.surface2 : Theme.colors.surface1
                            border.color: AudioService.isMuted ? Theme.colors.error : Theme.colors.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: AudioService.isMuted ? "✕" : "♪"
                                color: AudioService.isMuted ? Theme.colors.error : Theme.colors.primary
                                font.family: Theme.typography.familySans
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleMute()
                            }
                        }

                        // Slider Track
                        Rectangle {
                            id: sliderTrack
                            width: parent.width - 36
                            height: 10
                            radius: 5
                            color: Theme.colors.surface2
                            anchors.verticalCenter: parent.verticalCenter

                            // Active progress fill
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(8, Math.min(parent.width, parent.width * AudioService.volume))
                                radius: 5
                                color: AudioService.isMuted ? Theme.colors.textMuted : Theme.colors.primary

                                Behavior on width {
                                    enabled: !sliderMouse.drag.active
                                    NumberAnimation { duration: Theme.animations.fast }
                                }
                            }

                            MouseArea {
                                id: sliderMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function updateFromMouse(mouse) {
                                    var ratio = Math.max(0.0, Math.min(1.0, mouse.x / sliderTrack.width));
                                    AudioService.setVolume(ratio);
                                }

                                onPressed: mouse => updateFromMouse(mouse)
                                onPositionChanged: mouse => {
                                    if (pressed) updateFromMouse(mouse);
                                }
                            }
                        }
                    }
                }
            }

            // 2. Network Card
            Rectangle {
                width: parent.width
                height: 52
                radius: 12
                color: Theme.colors.surface0
                border.color: Theme.colors.glassBorder
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: NetworkService.isConnected ? Theme.colors.primary : Theme.colors.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80
                        spacing: 2

                        Text {
                            text: NetworkService.networkName
                            color: Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBody
                            font.weight: Theme.typography.weightMedium
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: NetworkService.isWifi ? "无线网络连接" : (NetworkService.isWired ? "以太网有线连接" : "已断开连接")
                            color: Theme.colors.textTertiary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeCaption
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 52
                        height: 24
                        radius: 12
                        color: netMouse.containsMouse ? Theme.colors.surface2 : Theme.colors.surface1
                        border.color: Theme.colors.glassBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "配置"
                            color: Theme.colors.textSecondary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeCaption
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.openNetworkSettings()
                        }
                    }
                }
            }

            // 3. Quick Toggles Grid (2x2)
            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                // Dark Mode Toggle
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 48
                    radius: 10
                    color: ControlCenterService.isDarkMode ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: ControlCenterService.isDarkMode ? Theme.colors.primary : Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: ControlCenterService.isDarkMode ? Theme.colors.primary : Theme.colors.textTertiary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "深色模式"
                            color: ControlCenterService.isDarkMode ? Theme.colors.primary : Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBodySmall
                            font.weight: Theme.typography.weightMedium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.toggleDarkMode()
                    }
                }

                // Night Light Toggle
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 48
                    radius: 10
                    color: ControlCenterService.isNightLight ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.textTertiary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "夜光模式"
                            color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBodySmall
                            font.weight: Theme.typography.weightMedium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.toggleNightLight()
                    }
                }

                // System Settings
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 48
                    radius: 10
                    color: setMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "⚙ 系统设置"
                            color: Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBodySmall
                        }
                    }

                    MouseArea {
                        id: setMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.openSettings()
                    }
                }

                // Lock Screen
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 48
                    radius: 10
                    color: lockMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "🔒 锁定屏幕"
                            color: Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBodySmall
                        }
                    }

                    MouseArea {
                        id: lockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.lockSession()
                    }
                }
            }

            // 4. Session Action Buttons (Bottom Bar)
            Row {
                width: parent.width
                spacing: 8

                // Suspend
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: 32
                    radius: 8
                    color: suspMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "待机"
                        color: Theme.colors.textSecondary
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeCaption
                    }

                    MouseArea {
                        id: suspMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.suspend()
                    }
                }

                // Reboot
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: 32
                    radius: 8
                    color: rebMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "重启"
                        color: Theme.colors.warning
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeCaption
                    }

                    MouseArea {
                        id: rebMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.reboot()
                    }
                }

                // Power Off
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: 32
                    radius: 8
                    color: pwrMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                    border.color: Theme.colors.error
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "关机"
                        color: Theme.colors.error
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeCaption
                        font.weight: Theme.typography.weightBold
                    }

                    MouseArea {
                        id: pwrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.poweroff()
                    }
                }
            }
        }
    }
}
