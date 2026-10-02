import QtQuick
import "../common"
import "../services"

TopBarPill {
    id: root

    baseColor: LauncherService.isOpen ? Appearance.colors.colLayer1Active : Appearance.colors.colLayer0
    borderColor: LauncherService.isOpen ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

    onClicked: {
        LauncherService.toggle();
    }

    onRightClicked: {
        GnomeService.toggleOverview();
    }

    Row {
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        MaterialSymbol {
            text: "grid_view"
            iconSize: 16
            color: LauncherService.isOpen ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "Ubuntu"
            color: LauncherService.isOpen ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
            font.family: Fonts.ui
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
