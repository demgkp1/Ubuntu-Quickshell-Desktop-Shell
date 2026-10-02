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

        // TopBar Prototype Capsule Layout
        Row {
            id: barLayout
            spacing: Theme.sizes.spacingSm

            // 1. Brand / System Pill
            Pill {
                borderColor: Theme.colors.primary

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
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

            // 2. Real-time Clock Pill (Powered by TimeService)
            ClockPill {
                showDate: true
                showSeconds: false
            }

            // 3. Status Pill (Mock system-independent indicators)
            StatusPill {
                networkText: "Wi-Fi"
                volumePercent: 75
                batteryPercent: 88
            }
        }
    }
}
