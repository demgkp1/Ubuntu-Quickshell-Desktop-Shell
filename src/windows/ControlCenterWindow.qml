import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../theme"
import "../services"

/**
 * ControlCenterWindow - Clavis-Shell Inspired Quick Settings Panel
 *
 * Designed directly after Clavis Shell's reference layout:
 * - Top header with settings, screenshot, restart, lock, and power icons
 * - Clavis-style split / segmented sliders for audio volume & night light
 * - 3-column pill toggles (Wi-Fi, Bluetooth, DND/Caffeine, Sound, Appearance, Night Mode)
 * - MPRIS Now Playing media playback controller
 * - Fullscreen scrim backdrop for outside-click dismissal
 * - 100% native cursor preservation (no cursorShape overrides)
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

    // Fullscreen transparent backdrop scrim: click outside to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: ControlCenterService.close()
    }

    // Control Center Floating Card (Positioned top-right under the status pill)
    Item {
        id: cardRoot
        width: 320
        anchors.top: parent.top
        anchors.topMargin: Theme.sizes.topBarHeight + 6
        anchors.right: parent.right
        anchors.rightMargin: Theme.sizes.spacingLg
        height: cardLayout.implicitHeight + 24

        // Prevent clicks inside card from bubbling to backdrop scrim
        MouseArea {
            anchors.fill: parent
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

        // Frosted Glass Surface
        Rectangle {
            id: surface
            anchors.fill: parent
            radius: Theme.sizes.radiusCard
            color: Qt.rgba(0.06, 0.13, 0.14, 0.94) // Clavis frosted dark teal slate
            border.color: Theme.colors.glassBorder
            border.width: 1

            Column {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // ==========================================
                // 1. TOP HEADER (Clavis Reference Style)
                // Left: Hex/Settings | Right: Screenshot, Restart, Lock, Power
                // ==========================================
                Item {
                    width: parent.width
                    height: 24

                    // Left Settings Icon
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: 12
                        color: setMouse.containsMouse ? Theme.colors.surface1 : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "⚙"
                            color: Theme.colors.primary
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: setMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: ControlCenterService.openSettings()
                        }
                    }

                    // Right Utility Actions Row
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        // 1. Screenshot
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: shotMouse.containsMouse ? Theme.colors.surface1 : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "📸"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: shotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ControlCenterService.takeScreenshot()
                            }
                        }

                        // 2. Restart
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: rebMouse.containsMouse ? Theme.colors.surface1 : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "🔄"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: rebMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ControlCenterService.reboot()
                            }
                        }

                        // 3. Lock Screen
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: lockMouse.containsMouse ? Theme.colors.surface1 : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "🔒"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: lockMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ControlCenterService.lockSession()
                            }
                        }

                        // 4. Power Off
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: pwrMouse.containsMouse ? Qt.rgba(1, 0.4, 0.4, 0.2) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "⏻"
                                color: Theme.colors.error
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: pwrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ControlCenterService.poweroff()
                            }
                        }
                    }
                }

                // ==========================================
                // 2. CLAVIS SEGMENTED SLIDERS
                // Split capsule: Solid fill container on left + track on right
                // ==========================================
                Column {
                    width: parent.width
                    spacing: 6

                    // 2.1 Sound Volume Slider
                    Rectangle {
                        id: volumeSliderContainer
                        width: parent.width
                        height: 28
                        radius: 8
                        color: Theme.colors.surface0
                        border.color: Theme.colors.glassBorder
                        border.width: 1
                        clip: true

                        // Active Left Fill Pill
                        Rectangle {
                            id: volFillPill
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(54, parent.width * AudioService.volume)
                            radius: 8
                            color: AudioService.isMuted ? Theme.colors.surface2 : Theme.colors.surface2

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: AudioService.isMuted ? "MUTED" : (AudioService.volumePercent + "%")
                                    color: AudioService.isMuted ? Theme.colors.error : Theme.colors.primary
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: AudioService.isMuted ? "✕" : "♪"
                                    color: AudioService.isMuted ? Theme.colors.error : Theme.colors.textSecondary
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Behavior on width {
                                enabled: !volScrubMouse.drag.active
                                NumberAnimation { duration: Theme.animations.fast }
                            }
                        }

                        // Right Icon
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🔊"
                            font.pixelSize: 10
                            opacity: 0.6
                        }

                        // Mouse scrub across entire slider
                        MouseArea {
                            id: volScrubMouse
                            anchors.fill: parent
                            preventStealing: true

                            function updateFromMouse(mouse) {
                                var ratio = Math.max(0.0, Math.min(1.0, mouse.x / volumeSliderContainer.width));
                                AudioService.setVolume(ratio);
                            }

                            onPressed: mouse => updateFromMouse(mouse)
                            onPositionChanged: mouse => {
                                if (pressed) updateFromMouse(mouse);
                            }
                        }
                    }

                    // 2.2 Night Light / Screen Tone Slider
                    Rectangle {
                        id: nlSliderContainer
                        width: parent.width
                        height: 28
                        radius: 8
                        color: Theme.colors.surface0
                        border.color: Theme.colors.glassBorder
                        border.width: 1
                        clip: true

                        // Left Fill Pill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: ControlCenterService.isNightLight ? parent.width * 0.75 : parent.width * 0.28
                            radius: 8
                            color: ControlCenterService.isNightLight ? Qt.rgba(0.96, 0.79, 0.48, 0.25) : Theme.colors.surface1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: ControlCenterService.isNightLight ? "夜光 75%" : "标准"
                                    color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.textSecondary
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "👁"
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Behavior on width {
                                NumberAnimation { duration: Theme.animations.normal }
                            }
                        }

                        // Right Icon
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🌙"
                            font.pixelSize: 10
                            opacity: 0.6
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: ControlCenterService.toggleNightLight()
                        }
                    }
                }

                // ==========================================
                // 3. CLAVIS QUICK TOGGLES (Capsule Pills)
                // ==========================================
                Column {
                    width: parent.width
                    spacing: 6

                    // Row 1: Wi-Fi Pill + Bluetooth Pill + Caffeine
                    Row {
                        width: parent.width
                        spacing: 6

                        // Wi-Fi Pill
                        Rectangle {
                            width: (parent.width - 44) / 2
                            height: 38
                            radius: 10
                            color: ControlCenterService.isWifiEnabled ? Theme.colors.surface2 : Theme.colors.surface0
                            border.color: ControlCenterService.isWifiEnabled ? Theme.colors.primary : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Mini Circle Icon
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: ControlCenterService.isWifiEnabled ? Theme.colors.primary : Theme.colors.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "📶"
                                        font.pixelSize: 10
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.parent.width - 38
                                    spacing: 1

                                    Text {
                                        text: "Network"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: ControlCenterService.isWifiEnabled
                                            ? (ControlCenterService.wifiSsid ? ControlCenterService.wifiSsid : "已开启")
                                            : "已关闭"
                                        color: ControlCenterService.isWifiEnabled ? Theme.colors.textSecondary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleWifi()
                            }
                        }

                        // Bluetooth Pill
                        Rectangle {
                            width: (parent.width - 44) / 2
                            height: 38
                            radius: 10
                            color: ControlCenterService.isBluetoothEnabled ? Theme.colors.surface2 : Theme.colors.surface0
                            border.color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primary : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Mini Circle Icon
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: ControlCenterService.isBluetoothEnabled ? Theme.colors.primary : Theme.colors.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ᛒ"
                                        color: ControlCenterService.isBluetoothEnabled ? Theme.colors.textOnPrimary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.parent.width - 38
                                    spacing: 1

                                    Text {
                                        text: "Bluetooth"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: ControlCenterService.isBluetoothEnabled ? "已开启" : "已关闭"
                                        color: ControlCenterService.isBluetoothEnabled ? Theme.colors.textSecondary : Theme.colors.textTertiary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleBluetooth()
                            }
                        }

                        // Caffeine / DND Coffee Cup
                        Rectangle {
                            width: 32
                            height: 38
                            radius: 10
                            color: ControlCenterService.isDndEnabled ? Theme.colors.surface2 : Theme.colors.surface0
                            border.color: ControlCenterService.isDndEnabled ? Theme.colors.warning : Theme.colors.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "☕"
                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleDnd()
                            }
                        }
                    }

                    // Row 2: Mic Mute + Sound Quick Pill + Appearance Pill
                    Row {
                        width: parent.width
                        spacing: 6

                        // Mic Mute Pill
                        Rectangle {
                            width: 32
                            height: 36
                            radius: 10
                            color: Theme.colors.surface0
                            border.color: Theme.colors.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🎙"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: AudioService.toggleMute()
                            }
                        }

                        // Sound Pill (Direct sound settings launcher)
                        Rectangle {
                            width: (parent.width - 44) / 2
                            height: 36
                            radius: 10
                            color: Theme.colors.surface0
                            border.color: Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text {
                                    text: "🔊"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1

                                    Text {
                                        text: "Sound"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: AudioService.isMuted ? "静音" : (AudioService.volumePercent + "%")
                                        color: Theme.colors.textSecondary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.openSoundSettings()
                            }
                        }

                        // Appearance / Dark Mode Pill
                        Rectangle {
                            width: (parent.width - 44) / 2
                            height: 36
                            radius: 10
                            color: ControlCenterService.isDarkMode ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: ControlCenterService.isDarkMode ? Theme.colors.primary : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text {
                                    text: ControlCenterService.isDarkMode ? "🌙" : "🔆"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1

                                    Text {
                                        text: "Appearance"
                                        color: Theme.colors.text
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: ControlCenterService.isDarkMode ? "Dark" : "Light"
                                        color: Theme.colors.textSecondary
                                        font.family: Theme.typography.familySans
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleDarkMode()
                            }
                        }
                    }

                    // Row 3: Bell (DND) + Night Mode Pill
                    Row {
                        width: parent.width
                        spacing: 6

                        // Bell Notification Toggle
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 10
                            color: ControlCenterService.isDndEnabled ? Theme.colors.surface2 : Theme.colors.surface0
                            border.color: ControlCenterService.isDndEnabled ? Theme.colors.warning : Theme.colors.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "🔔"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleDnd()
                            }
                        }

                        // Night Mode Pill
                        Rectangle {
                            width: parent.width - 38
                            height: 32
                            radius: 10
                            color: ControlCenterService.isNightLight ? Theme.colors.surface1 : Theme.colors.surface0
                            border.color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.glassBorder
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text {
                                    text: "🌙"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Night Mode"
                                    color: ControlCenterService.isNightLight ? Theme.colors.warning : Theme.colors.text
                                    font.family: Theme.typography.familySans
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: ControlCenterService.toggleNightLight()
                            }
                        }
                    }
                }

                // ==========================================
                // 4. MPRIS MEDIA CONTROLLER
                // ==========================================
                Rectangle {
                    id: mprisContainer
                    width: parent.width
                    height: 48
                    radius: 10
                    color: Theme.colors.surface0
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    readonly property var activePlayer: (Mpris.players && Mpris.players.values.length > 0)
                        ? Mpris.players.values[0]
                        : null

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // Music Disc Icon
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: Theme.colors.surface1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "🎵"
                                font.pixelSize: 11
                            }
                        }

                        // Title & Artist
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 110
                            spacing: 1

                            Text {
                                text: (mprisContainer.activePlayer && mprisContainer.activePlayer.trackTitle)
                                    ? mprisContainer.activePlayer.trackTitle
                                    : "未在播放媒体"
                                color: Theme.colors.text
                                font.family: Theme.typography.familySans
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: (mprisContainer.activePlayer && mprisContainer.activePlayer.trackArtist)
                                    ? mprisContainer.activePlayer.trackArtist
                                    : "MPRIS 媒体控制"
                                color: Theme.colors.textTertiary
                                font.family: Theme.typography.familySans
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Playback Controls
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            // Prev
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: Theme.colors.surface1

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏮"
                                    font.pixelSize: 8
                                    color: Theme.colors.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (mprisContainer.activePlayer && mprisContainer.activePlayer.canGoPrevious) {
                                            mprisContainer.activePlayer.previous();
                                        }
                                    }
                                }
                            }

                            // Play/Pause
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: Theme.colors.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: (mprisContainer.activePlayer && mprisContainer.activePlayer.playbackState === MprisPlaybackState.Playing) ? "⏸" : "▶"
                                    font.pixelSize: 9
                                    color: Theme.colors.textOnPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (mprisContainer.activePlayer) {
                                            mprisContainer.activePlayer.togglePlaying();
                                        }
                                    }
                                }
                            }

                            // Next
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: Theme.colors.surface1

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏭"
                                    font.pixelSize: 8
                                    color: Theme.colors.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (mprisContainer.activePlayer && mprisContainer.activePlayer.canGoNext) {
                                            mprisContainer.activePlayer.next();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
