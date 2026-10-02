import QtQuick
import "../common"

TopBarPill {
    id: root

    property int activeWorkspaceIndex: 0
    property int workspaceCount: 3

    Row {
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.workspaceCount

            delegate: Rectangle {
                id: indicator
                required property int index
                readonly property bool isActive: index === root.activeWorkspaceIndex

                width: isActive ? 22 : 6
                height: 6
                radius: 3
                color: isActive ? Appearance.colors.colPrimary : (root.isHovered ? Appearance.colors.colOnSurfaceVariant : Appearance.colors.colOutlineVariant)

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.ArrowCursor
                    onClicked: root.activeWorkspaceIndex = index
                }
            }
        }
    }
}
