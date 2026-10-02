import QtQuick
import "../theme"
import "../services"

/**
 * LauncherPill - Desktop Brand & Application Launcher Trigger
 *
 * Displays glowing mint accent and OS brand title.
 * - Left click: Toggles the Quickshell frosted glass Start Menu
 * - Right click: Directly toggles GNOME native Activities Overview
 */
Pill {
    id: root

    signal launcherRequested()

    onClicked: {
        launcherRequested();
        LauncherService.toggle();
    }

    onRightClicked: {
        GnomeService.toggleOverview();
    }

    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: LauncherService.isOpen ? Theme.colors.accent : Theme.colors.primary
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animations.fast }
            }

            Behavior on scale {
                NumberAnimation { duration: Theme.animations.fast }
            }
            scale: root.isHovered || LauncherService.isOpen ? 1.25 : 1.0
        }

        Text {
            text: "Ubuntu"
            color: LauncherService.isOpen ? Theme.colors.primary : Theme.colors.text
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBody
            font.weight: Theme.typography.weightDemiBold
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animations.fast }
            }
        }
    }
}
