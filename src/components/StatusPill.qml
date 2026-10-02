import QtQuick
import "../theme"
import "../services"

/**
 * StatusPill - Frosted System Status Indicator
 *
 * Connected directly to real Linux system services:
 * - NetworkService (Ethernet / Wi-Fi via NetworkManager)
 * - AudioService (Volume / Mute via PipeWire)
 * - PowerService (Battery / AC mains via UPower)
 *
 * Left click toggles the ControlCenterWindow quick settings.
 * Wheel scroll on volume adjusts volume.
 */
Pill {
    id: root

    baseColor: ControlCenterService.isOpen ? Theme.colors.glassBackgroundActive : Theme.colors.glassBackground
    borderColor: ControlCenterService.isOpen ? Theme.colors.primary : Theme.colors.glassBorder

    onClicked: {
        ControlCenterService.toggle();
    }

    // 1. Network indicator
    Row {
        id: networkRow
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: NetworkService.isConnected ? Theme.colors.primary : Theme.colors.textTertiary
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animations.fast }
            }
        }

        Text {
            text: NetworkService.statusText
            color: NetworkService.isConnected ? Theme.colors.textSecondary : Theme.colors.textTertiary
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Divider: Network -> Volume
    Rectangle {
        width: 1
        height: 12
        color: Theme.colors.glassBorder
        anchors.verticalCenter: parent.verticalCenter
    }

    // 2. Volume indicator
    Item {
        id: volumeContainer
        implicitWidth: volumeText.implicitWidth
        implicitHeight: volumeText.implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: volumeText
            anchors.centerIn: parent
            text: AudioService.isMuted
                ? "MUTED"
                : ("VOL " + AudioService.volumePercent + "%")
            color: AudioService.isMuted
                ? Theme.colors.textTertiary
                : Theme.colors.textSecondary
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            font.weight: AudioService.isMuted ? Theme.typography.weightNormal : Theme.typography.weightMedium
        }

        // Wheel handler for adjusting volume with mouse scroll
        WheelHandler {
            target: volumeContainer
            onWheel: event => {
                if (event.angleDelta.y > 0) {
                    AudioService.stepVolume(0.05);
                } else if (event.angleDelta.y < 0) {
                    AudioService.stepVolume(-0.05);
                }
            }
        }

        // Click on volume text directly toggles mute
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: AudioService.toggleMute()
        }
    }

    // Divider: Volume -> Battery (only shown if battery exists)
    Rectangle {
        id: batteryDivider
        visible: PowerService.hasBattery
        width: visible ? 1 : 0
        height: 12
        color: Theme.colors.glassBorder
        anchors.verticalCenter: parent.verticalCenter
    }

    // 3. Battery capsule indicator (only shown if battery exists)
    Row {
        id: batteryRow
        visible: PowerService.hasBattery
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        // Mini battery icon
        Rectangle {
            width: 18
            height: 10
            radius: 3
            color: "transparent"
            border.color: PowerService.isCharging ? Theme.colors.accent : Theme.colors.primary
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            // Fill level
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1.5
                width: Math.max(2, (parent.width - 3) * (PowerService.percentage / 100))
                radius: 1.5
                color: PowerService.isCharging ? Theme.colors.accent : Theme.colors.primary

                Behavior on width {
                    NumberAnimation { duration: Theme.animations.normal }
                }
            }
        }

        Text {
            text: PowerService.percentInt + "%"
            color: Theme.colors.text
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            font.weight: Theme.typography.weightMedium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
