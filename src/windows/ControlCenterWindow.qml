import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../theme"
import "../services"

/**
 * ControlCenterWindow - macOS-Grade Frosted Glass Quick Settings Panel
 *
 * Fullscreen scrim modal with click-outside dismiss & global ESC shortcut.
 * Designed with Matugen Sage & Mint Frosted Glass aesthetic:
 * - Connectivity cards: Wi-Fi, Bluetooth, Do Not Disturb, Screenshot
 * - PipeWire interactive sound slider & mute toggle
 * - MPRIS Now Playing media playback controller
 * - System quick toggles: Dark Mode, Night Light, Settings, Screen Lock
 * - Power session actions: Suspend, Reboot, Power Off
 * - All cursors strictly adhere to native ArrowCursor
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
        bottom: true
        left: true
        right: true
    }

    // 1. Global ESC shortcut to dismiss
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ControlCenterService.close()
    }

    onVisibleChanged: {
        if (visible) {
            focusScope.forceActiveFocus();
        }
    }

    // 2. Fullscreen transparent backdrop scrim: click outside to dismiss
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: ControlCenterService.close()
    }

    // 3. Focus scope for keyboard events
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ControlCenterService.close()

        // 4. Control Center Floating Card (Positioned top-right)
        Item {
            id: cardRoot
            width: 380
            anchors.top: parent.top
            anchors.topMargin: Theme.sizes.topBarHeight + 6
            anchors.right: parent.right
            anchors.rightMargin: Theme.sizes.spacingLg
            height: cardLayout.implicitHeight + 28

            // Prevent clicks inside card from bubbling to backdrop scrim
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
            }

            // Ambient Drop Shadow
            Rectangle {
                id: shadow
                anchors.fill: surface
                anchors.margins: -4
                radius: Theme.sizes.radiusCard + 4
                color: Theme.colors.glassShadow
                opacity: 0.65
                z: -1
            }

            // Frosted Surface
            Rectangle {
                id: surface
                anchors.fill: parent
                radius: Theme.sizes.radiusCard
                color: Qt.rgba(0.06, 0.12, 0.13, 0.94) // Frosted deep forest slate
                border.color: Theme.colors.glassBorder
                border.width: 1

                Column {
                    id: cardLayout
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
                                text: "控制中心"
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

                    // ==========================================
                    // SECTION 1: Top Connectivity & Action Block (macOS 2x2 Grid)
                    // ==========================================
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8

                        // 1.1 Wi-Fi Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 64
                            radius: 12
                            color: wifiMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: ControlCenterService.isWifiEnabled ? Theme.colors.primary : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                // Wi-Fi Icon Badge
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: ControlCenterService.isWifiEnabled ? Theme.colors.primaryContainer : Theme.colors.surface2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "📶"
                                        font.pixelSize: 13
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 40
                                    spacing: 2

                                    Text {
                                        text: "Wi-Fi"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeBodySmall
                                        font.weight: Theme.typography.weightBold
                                    }

                                    Text {
                                        text: ControlCenterService.isWifiEnabled
                                            ? (ControlCenterService.wifiSsid ? ControlCenterService.wifiSsid : "已开启")
                                            : "已关闭"
                                        color: ControlCenterService.isWifiEnabled ? Theme.colors.textSecondary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeCaption
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            // Click card body to open Wi-Fi settings
                            MouseArea {
                                id: wifiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.openWifiSettings()
                            }

                            // Right toggle switch pill
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                width: 28
                                height: 16
                                radius: 8
                                color: ControlCenterService.isWifiEnabled ? Theme.colors.primary : Theme.colors.surface2

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: Theme.colors.textOnPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: ControlCenterService.isWifiEnabled ? undefined : parent.left
                                    anchors.right: ControlCenterService.isWifiEnabled ? parent.right : undefined
                                    anchors.margins: 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.ArrowCursor
                                    onClicked: ControlCenterService.toggleWifi()
                                }
                            }
                        }

                        // 1.2 Bluetooth Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 64
                            radius: 12
                            color: btMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primary : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                // Bluetooth Icon Badge
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primaryContainer : Theme.colors.surface2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ᛒ"
                                        color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 40
                                    spacing: 2

                                    Text {
                                        text: "蓝牙"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeBodySmall
                                        font.weight: Theme.typography.weightBold
                                    }

                                    Text {
                                        text: ControlCenterService.isBluetoothEnabled ? "已开启" : "已关闭"
                                        color: ControlCenterService.isBluetoothEnabled ? Theme.colors.textSecondary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeCaption
                                    }
                                }
                            }

                            // Click card body to open Bluetooth settings
                            MouseArea {
                                id: btMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.openBluetoothSettings()
                            }

                            // Right toggle switch pill
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                width: 28
                                height: 16
                                radius: 8
                                color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primary : Theme.colors.surface2

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: Theme.colors.textOnPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: ControlCenterService.isBluetoothEnabled ? undefined : parent.left
                                    anchors.right: ControlCenterService.isBluetoothEnabled ? parent.right : undefined
                                    anchors.margins: 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.ArrowCursor
                                    onClicked: ControlCenterService.toggleBluetooth()
                                }
                            }
                        }

                        // 1.3 Do Not Disturb (勿扰模式) Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 56
                            radius: 12
                            color: dndMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: ControlCenterService.isDndEnabled ? Theme.colors.warning : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: ControlCenterService.isDndEnabled ? Theme.colors.surface2 : Theme.colors.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🌙"
                                        font.pixelSize: 13
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "勿扰模式"
                                        color: ControlCenterService.isDndEnabled ? Theme.colors.warning : Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeBodySmall
                                        font.weight: Theme.typography.weightMedium
                                    }

                                    Text {
                                        text: ControlCenterService.isDndEnabled ? "通知弹窗已静音" : "允许通知弹窗"
                                        color: Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeCaption
                                    }
                                }
                            }

                            MouseArea {
                                id: dndMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.toggleDnd()
                            }
                        }

                        // 1.4 Native Screenshot (屏幕截图) Card
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 56
                            radius: 12
                            color: shotMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Theme.colors.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "📸"
                                        font.pixelSize: 13
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "屏幕截图"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeBodySmall
                                        font.weight: Theme.typography.weightMedium
                                    }

                                    Text {
                                        text: "原生选区截图"
                                        color: Theme.colors.textSecondary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeCaption
                                    }
                                }
                            }

                            MouseArea {
                                id: shotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.takeScreenshot()
                            }
                        }
                    }

                    // ==========================================
                    // SECTION 2: PipeWire Audio Volume (macOS Chunky Slider)
                    // ==========================================
                    Rectangle {
                        width: parent.width
                        height: 78
                        radius: 12
                        color: Theme.colors.surface0
                        border.color: Theme.colors.glassBorder
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Device name, percent and sound settings launcher
                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: sndRightRow.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: AudioService.sinkName
                                    color: Theme.colors.textSecondary
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: Theme.typography.sizeCaption
                                    elide: Text.ElideRight
                                }

                                Row {
                                    id: sndRightRow
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        text: AudioService.isMuted ? "静音" : (AudioService.volumePercent + "%")
                                        color: AudioService.isMuted ? Theme.colors.textTertiary : Theme.colors.primary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: Theme.typography.sizeBodySmall
                                        font.weight: Theme.typography.weightBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "⚙"
                                        color: sndSetMouse.containsMouse ? Theme.colors.primary : Theme.colors.textTertiary
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            id: sndSetMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.ArrowCursor
                                            onClicked: ControlCenterService.openSoundSettings()
                                        }
                                    }
                                }
                            }

                            // Interactive Slider Track
                            Row {
                                width: parent.width
                                spacing: 8
                                anchors.horizontalCenter: parent.horizontalCenter

                                // Mute toggle button
                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: AudioService.isMuted ? Theme.colors.surface2 : Theme.colors.surface1
                                    border.color: AudioService.isMuted ? Theme.colors.error : Theme.colors.glassBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: AudioService.isMuted ? "✕" : "♪"
                                        color: AudioService.isMuted ? Theme.colors.error : Theme.colors.primary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.ArrowCursor
                                        onClicked: AudioService.toggleMute()
                                    }
                                }

                                // macOS-style Chunky Track
                                Rectangle {
                                    id: sliderTrack
                                    width: parent.width - 38
                                    height: 14
                                    radius: 7
                                    color: Theme.colors.surface2
                                    anchors.verticalCenter: parent.verticalCenter

                                    // Active progress fill
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(8, Math.min(parent.width, parent.width * AudioService.volume))
                                        radius: 7
                                        color: AudioService.isMuted ? Theme.colors.textMuted : Theme.colors.primary

                                        Behavior on width {
                                            enabled: !sliderMouse.drag.active
                                            NumberAnimation { duration: Theme.animations.fast }
                                        }
                                    }

                                    MouseArea {
                                        id: sliderMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.ArrowCursor
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

                    // ==========================================
                    // SECTION 3: Now Playing / Media Player (MPRIS)
                    // ==========================================
                    Rectangle {
                        id: mediaCard
                        width: parent.width
                        height: 58
                        radius: 12
                        color: Theme.colors.surface0
                        border.color: Theme.colors.glassBorder
                        border.width: 1

                        readonly property var activePlayer: (Mpris.players && Mpris.players.values.length > 0)
                            ? Mpris.players.values[0]
                            : null

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Music Icon / Disc Badge
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: Theme.colors.surface1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "🎵"
                                    font.pixelSize: 14
                                }
                            }

                            // Track Title & Artist
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 140
                                spacing: 2

                                Text {
                                    text: (mediaCard.activePlayer && mediaCard.activePlayer.trackTitle)
                                        ? mediaCard.activePlayer.trackTitle
                                        : "未在播放媒体"
                                    color: Theme.colors.text
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: Theme.typography.sizeBodySmall
                                    font.weight: Theme.typography.weightMedium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: (mediaCard.activePlayer && mediaCard.activePlayer.trackArtist)
                                        ? mediaCard.activePlayer.trackArtist
                                        : "MPRIS 媒体控制"
                                    color: Theme.colors.textTertiary
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: Theme.typography.sizeCaption
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Player Controls (Prev, Play/Pause, Next)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Prev
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: prevMouse.containsMouse ? Theme.colors.surface2 : Theme.colors.surface1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⏮"
                                        font.pixelSize: 10
                                        color: Theme.colors.textSecondary
                                    }

                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            if (mediaCard.activePlayer && mediaCard.activePlayer.canGoPrevious) {
                                                mediaCard.activePlayer.previous();
                                            }
                                        }
                                    }
                                }

                                // Play / Pause
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: Theme.colors.primary

                                    Text {
                                        anchors.centerIn: parent
                                        text: (mediaCard.activePlayer && mediaCard.activePlayer.playbackState === MprisPlaybackState.Playing) ? "⏸" : "▶"
                                        font.pixelSize: 10
                                        color: Theme.colors.textOnPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            if (mediaCard.activePlayer) {
                                                mediaCard.activePlayer.togglePlaying();
                                            }
                                        }
                                    }
                                }

                                // Next
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: nextMouse.containsMouse ? Theme.colors.surface2 : Theme.colors.surface1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⏭"
                                        font.pixelSize: 10
                                        color: Theme.colors.textSecondary
                                    }

                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            if (mediaCard.activePlayer && mediaCard.activePlayer.canGoNext) {
                                                mediaCard.activePlayer.next();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // SECTION 4: System Quick Toggles Grid (2x2)
                    // ==========================================
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8

                        // Dark Mode Toggle
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 44
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
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.toggleDarkMode()
                            }
                        }

                        // Night Light Toggle
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 44
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
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.toggleNightLight()
                            }
                        }

                        // System Settings
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 44
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
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.openSettings()
                            }
                        }

                        // Lock Screen
                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: 44
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
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.lockSession()
                            }
                        }
                    }

                    // ==========================================
                    // SECTION 5: Session Power Actions (Bottom Bar)
                    // ==========================================
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
                                cursorShape: Qt.ArrowCursor
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
                                cursorShape: Qt.ArrowCursor
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
                                cursorShape: Qt.ArrowCursor
                                onClicked: ControlCenterService.poweroff()
                            }
                        }
                    }
                }
            }
        }
    }
}
