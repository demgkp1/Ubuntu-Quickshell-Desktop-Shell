import QtQuick
import "../common"
import "../services"

TopBarPill {
    id: root

    property bool showDate: false
    property bool showSeconds: false

    Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            visible: root.showDate
            text: TimeService.formattedDate
            color: Appearance.colors.colOnSurfaceVariant
            font.family: Fonts.ui
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.showSeconds 
                  ? TimeService.formattedTime + ":" + TimeService.formattedSeconds 
                  : TimeService.formattedTime
            color: Appearance.colors.colPrimary
            font.family: Fonts.expressive
            font.pixelSize: 15
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
