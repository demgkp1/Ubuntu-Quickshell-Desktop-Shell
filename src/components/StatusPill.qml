import QtQuick
import "../common"
import "../services"

TopBarPill {
    id: root

    baseColor: ControlCenterService.isOpen ? Appearance.colors.colLayer1Active : Appearance.colors.colLayer0
    borderColor: ControlCenterService.isOpen ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

    onClicked: {
        ControlCenterService.toggle();
    }

    Row {
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        // 1. Notification icon
        MaterialSymbol {
            text: "notifications"
            iconSize: 16
            color: Appearance.colors.colOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        // 2. Bluetooth icon
        MaterialSymbol {
            text: "bluetooth"
            iconSize: 16
            color: Appearance.colors.colOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        // 3. Wi-Fi icon
        MaterialSymbol {
            text: NetworkService.isConnected ? "wifi" : "wifi_off"
            iconSize: 16
            color: NetworkService.isConnected ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Qt.rgba(1, 1, 1, 0.12)
            anchors.verticalCenter: parent.verticalCenter
        }

        // 4. Battery / Power Status
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            MaterialSymbol {
                text: PowerService.isCharging ? "battery_charging_full" : "battery_horiz_075"
                iconSize: 18
                color: PowerService.isCharging ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: (PowerService.hasBattery ? PowerService.percentInt : 100) + "%"
                color: Appearance.colors.colOnSurface
                font.family: Fonts.numeric
                font.pixelSize: 12
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Qt.rgba(1, 1, 1, 0.12)
            anchors.verticalCenter: parent.verticalCenter
        }

        // 5. Power Button
        MaterialSymbol {
            text: "power_settings_new"
            iconSize: 16
            fill: 1
            color: Appearance.colors.colError
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
