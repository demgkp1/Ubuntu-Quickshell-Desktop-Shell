import QtQuick
import "../theme"

/**
 * StatusPill - Frosted System Status Indicator
 *
 * Built upon the frosted glass Pill. Displays system indicators
 * in soft sage and vibrant mint accents.
 */
Pill {
    id: root

    property string networkText: "Wi-Fi"
    property int volumePercent: 72
    property int batteryPercent: 90

    // 1. Network indicator
    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: Theme.colors.primary
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
        color: Theme.colors.glassBorder
        anchors.verticalCenter: parent.verticalCenter
    }

    // 2. Volume indicator
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
        color: Theme.colors.glassBorder
        anchors.verticalCenter: parent.verticalCenter
    }

    // 3. Battery capsule indicator
    Row {
        spacing: Theme.sizes.spacingXs
        anchors.verticalCenter: parent.verticalCenter

        // Mini battery icon
        Rectangle {
            width: 18
            height: 10
            radius: 3
            color: "transparent"
            border.color: Theme.colors.primary
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            // Fill level
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1.5
                width: Math.max(2, (parent.width - 3) * (root.batteryPercent / 100))
                radius: 1.5
                color: Theme.colors.primary
            }
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
