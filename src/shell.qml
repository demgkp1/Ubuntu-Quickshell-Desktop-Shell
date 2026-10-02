//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_BACKEND=software
//@ pragma Env QT_QPA_PLATFORM=xcb

import QtQuick
import Quickshell

import "theme"
import "windows"
import "components"
import "services"

ShellRoot {
    // Automatically creates an adapted TopBar instance for every connected monitor
    Variants {
        model: Quickshell.screens

        TopBarWindow {
            id: barWindow
            required property var modelData
            targetScreen: modelData

            TopBarLayout {
                anchors.fill: parent

                // 1. Leading Section (Pinned Left: Workspaces + Brand)
                leading: [
                    WorkspacePill {
                        id: workspacePill
                    },

                    Pill {
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: Theme.colors.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Ubuntu"
                            color: Theme.colors.text
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBody
                            font.weight: Theme.typography.weightDemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                ]

                // 2. Center Section (Floating Luminous Clock)
                center: ClockPill {
                    showDate: true
                    showSeconds: false
                }

                // 3. Trailing Section (Pinned Right: Hardware Status + Quick Power)
                trailing: [
                    StatusPill {
                        networkText: "Wi-Fi"
                        volumePercent: 75
                        batteryPercent: 88
                    },

                    Pill {
                        paddingHorizontal: 12

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Theme.colors.error
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                ]
            }
        }
    }
}
