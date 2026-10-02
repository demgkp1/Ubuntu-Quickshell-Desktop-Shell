import QtQuick
import QtQuick.Layouts
import Quickshell

import "../common"
import "../components"
import "../services"

PanelWindow {
    id: root

    property var targetScreen: null
    screen: targetScreen

    visible: ControlCenterService.isOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Local UI states
    property bool caffeineActive: false
    property bool micMuted: false

    // 1. Transparent Backdrop: Clicking outside closes Control Center
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: ControlCenterService.close()
    }

    // 2. Floating Quick Settings Card (Anchored top-right below top bar)
    Rectangle {
        id: card
        width: 380
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.right: parent.right
        anchors.rightMargin: 16
        height: contentCol.implicitHeight + 36
        radius: Appearance.rounding.extraLarge
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colLayer0Border
        border.width: 1
        clip: true

        // Soft ambient elevation shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: card.radius + 4
            color: Appearance.colors.colShadow
            z: -1
        }

        // Card Click Absorber: Prevents closing when clicking inside
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 16

            // --- Header Row ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: "settings"
                    iconSize: 22
                    color: Appearance.colors.colPrimary
                }

                Text {
                    text: "Quick Settings"
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                // Action Tools (Screenshot, Reload, Settings, Power)
                RowLayout {
                    spacing: 6

                    // Screenshot
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: actionShot.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "photo_camera"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer2
                        }

                        MouseArea {
                            id: actionShot
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: ControlCenterService.takeScreenshot()
                        }
                    }

                    // Reload Quickshell
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: actionReload.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "restart_alt"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer2
                        }

                        MouseArea {
                            id: actionReload
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: Quickshell.reload(true)
                        }
                    }

                    // System Settings
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: actionSettings.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "tune"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer2
                        }

                        MouseArea {
                            id: actionSettings
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: ControlCenterService.openSettings()
                        }
                    }

                    // Power
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: actionPower.containsMouse ? Appearance.colors.colError : Appearance.colors.colLayer2

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "power_settings_new"
                            iconSize: 18
                            color: actionPower.containsMouse ? Appearance.colors.colOnError : Appearance.colors.colError
                        }

                        MouseArea {
                            id: actionPower
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: ControlCenterService.poweroff()
                        }
                    }
                }
            }

            // --- Sliders Section ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: slidersCol.implicitHeight + 20
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: slidersCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // 1. Brightness
                    QuickMaterialSlider {
                        materialSymbol: "light_mode"
                        value: 0.85
                    }

                    // 2. Sound (PipeWire)
                    QuickMaterialSlider {
                        materialSymbol: AudioService.isMuted ? "volume_off" : "volume_up"
                        value: AudioService.volume
                        percentText: AudioService.isMuted ? "MUTED" : Math.round(AudioService.volume * 100) + "%"
                        onMoved: val => AudioService.setVolume(val)
                    }

                    // 3. Microphone
                    QuickMaterialSlider {
                        materialSymbol: root.micMuted ? "mic_off" : "mic"
                        value: root.micMuted ? 0 : 0.65
                        percentText: root.micMuted ? "MUTED" : "65%"
                    }
                }
            }

            // --- Toggles Section ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: togglesCol.implicitHeight + 16
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: togglesCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Row 1: Wi-Fi (2), Bluetooth (1), Caffeine (1)
                    QuickToggleGroup {
                        QuickToggleButton {
                            expanded: true
                            iconName: NetworkService.isConnected ? "wifi" : "wifi_off"
                            title: "Network"
                            subtitle: NetworkService.activeConnection || (NetworkService.isConnected ? "Connected" : "Off")
                            toggled: NetworkService.isConnected
                            onTriggered: NetworkService.toggleWifi()
                            onAltTriggered: ControlCenterService.openWifiSettings()
                        }

                        QuickToggleButton {
                            expanded: false
                            iconName: "bluetooth"
                            toggled: ControlCenterService.isBluetoothEnabled
                            onTriggered: ControlCenterService.toggleBluetooth()
                            onAltTriggered: ControlCenterService.openBluetoothSettings()
                        }

                        QuickToggleButton {
                            expanded: false
                            iconName: "coffee"
                            toggled: root.caffeineActive
                            onTriggered: root.caffeineActive = !root.caffeineActive
                        }
                    }

                    // Row 2: Mic (1), Sound (1), Appearance (2)
                    QuickToggleGroup {
                        QuickToggleButton {
                            expanded: false
                            iconName: root.micMuted ? "mic_off" : "mic"
                            toggled: !root.micMuted
                            onTriggered: root.micMuted = !root.micMuted
                        }

                        QuickToggleButton {
                            expanded: false
                            iconName: AudioService.isMuted ? "volume_off" : "volume_up"
                            toggled: !AudioService.isMuted
                            onTriggered: AudioService.toggleMute()
                        }

                        QuickToggleButton {
                            expanded: true
                            iconName: ControlCenterService.isDarkMode ? "dark_mode" : "light_mode"
                            title: "Appearance"
                            subtitle: ControlCenterService.isDarkMode ? "Dark" : "Light"
                            toggled: ControlCenterService.isDarkMode
                            onTriggered: ControlCenterService.toggleDarkMode()
                        }
                    }

                    // Row 3: DND (1), Night Mode (2)
                    QuickToggleGroup {
                        QuickToggleButton {
                            expanded: false
                            iconName: ControlCenterService.isDndEnabled ? "notifications_paused" : "notifications"
                            toggled: ControlCenterService.isDndEnabled
                            onTriggered: ControlCenterService.toggleDnd()
                        }

                        QuickToggleButton {
                            expanded: true
                            iconName: "nightlight"
                            title: "Night Mode"
                            subtitle: ControlCenterService.isNightLight ? "4000 K" : "Off"
                            toggled: ControlCenterService.isNightLight
                            onTriggered: ControlCenterService.toggleNightLight()
                        }
                    }
                }
            }
        }
    }
}
