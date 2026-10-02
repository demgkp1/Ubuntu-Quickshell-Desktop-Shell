import QtQuick
import "../theme"

/**
 * WorkspacePill - Mock / Independent Workspace Indicator
 *
 * Recreates the iconic 3-indicator workspace pill seen in Clavis:
 * Active workspace is an elongated mint capsule, while inactive workspaces
 * are subtle sage dots.
 */
Pill {
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
                color: isActive ? Theme.colors.primary : (root.isHovered ? Theme.colors.textSecondary : Theme.colors.textMuted)

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animations.normal
                        easing.type: Theme.animations.easeOut
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animations.fast
                        easing.type: Theme.animations.easeOut
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        root.activeWorkspaceIndex = index;
                    }
                }
            }
        }
    }
}
