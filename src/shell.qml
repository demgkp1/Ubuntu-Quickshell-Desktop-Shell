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

        // Minimal prototype container - strictly follows non-complex UI constraint
        Row {
            spacing: Theme.sizes.spacingSm

            // Brand / Status Indicator Pill
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
                    text: "Ubuntu Shell"
                    color: Theme.colors.text
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeBody
                    font.weight: Theme.typography.weightDemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Synchronized Time Pill
            Pill {
                Text {
                    text: TimeService.formattedTime
                    color: Theme.colors.textSecondary
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeBody
                    font.weight: Theme.typography.weightNormal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
