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
    // 1. TopBar Window for each connected screen
    Variants {
        model: Quickshell.screens

        TopBarWindow {
            id: barWindow
            required property var modelData
            targetScreen: modelData

            TopBarLayout {
                anchors.fill: parent

                // Leading: Workspaces + Application Launcher Trigger
                leading: [
                    WorkspacePill {
                        id: workspacePill
                    },

                    LauncherPill {
                        id: launcherPill
                    }
                ]

                // Center: Floating Luminous Clock
                center: ClockPill {
                    showDate: true
                    showSeconds: false
                }

                // Trailing: Hardware Status + Power Quick Action
                trailing: [
                    StatusPill {},

                    Pill {
                        paddingHorizontal: 12

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Theme.colors.error
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onClicked: {
                            GnomeService.toggleOverview();
                        }
                    }
                ]
            }
        }
    }

    // 2. Floating Application Launcher / Start Menu Window
    Variants {
        model: Quickshell.screens

        LauncherWindow {
            required property var modelData
            targetScreen: modelData
        }
    }
}
