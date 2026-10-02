//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell

import "theme"
import "windows"
import "components"
import "services"

ShellRoot {
    TopBarWindow {
        id: barWindow

        // TopBar Floating Capsule Row
        Row {
            id: barLayout
            spacing: Theme.sizes.spacingSm

            // 1. Workspaces Pill (Clavis style 3-indicator switcher)
            WorkspacePill {
                id: workspacePill
            }

            // 2. Brand / System Pill (Frosted Mint Glass)
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

            // 3. Central Luminous Clock Pill (Powered by TimeService)
            ClockPill {
                showDate: true
                showSeconds: false
            }

            // 4. Hardware Status Pill (Wi-Fi, Vol, Battery visual fill)
            StatusPill {
                networkText: "Wi-Fi"
                volumePercent: 75
                batteryPercent: 88
            }

            // 5. Quick Power Pill (Coral red accent from screenshot)
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
        }
    }
}
