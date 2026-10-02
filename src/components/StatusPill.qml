import QtQuick
import "../theme"

/**
 * StatusPill - Mock System Status Indicator
 *
 * Built upon Pill.qml. Displays mock / system-independent system metrics
 * (Volume, Network, Battery) using Theme tokens, without touching DBus or PipeWire.
 */
Pill {
    id: root

    // Mock system state properties (system-independent)
    property string networkText: "Wi-Fi"
    property int volumePercent: 72
    property int batteryPercent: 90

    // Network mock indicator
    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: Theme.colors.success
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.networkText
            color: Theme.colors.textSecondary
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Divider
    Rectangle {
        width: 1
        height: 12
        color: Theme.colors.borderSubtle
        anchors.verticalCenter: parent.verticalCenter
    }

    // Volume mock indicator
    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "VOL " + root.volumePercent + "%"
            color: Theme.colors.textSecondary
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Divider
    Rectangle {
        width: 1
        height: 12
        color: Theme.colors.borderSubtle
        anchors.verticalCenter: parent.verticalCenter
    }

    // Battery mock indicator
    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 8
            height: 8
            radius: 2
            color: Theme.colors.success
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.batteryPercent + "%"
            color: Theme.colors.text
            font.family: Theme.typography.familySans
            font.pixelSize: Theme.typography.sizeBodySmall
            font.weight: Theme.typography.weightMedium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
