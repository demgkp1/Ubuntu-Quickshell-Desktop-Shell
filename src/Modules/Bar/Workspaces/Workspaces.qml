import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets.common

TopBarPill {
    id: root

    property string screenName: ""
    property bool vertical: false
    readonly property bool hasMultipleOutputs: Quickshell.screens && Quickshell.screens.length > 1
    property int currentWorkspaceId: 1
    readonly property var workspaces: [
        { id: 1, output: root.screenName, isActive: root.currentWorkspaceId === 1, windowCount: 1 },
        { id: 2, output: root.screenName, isActive: root.currentWorkspaceId === 2, windowCount: 0 },
        { id: 3, output: root.screenName, isActive: root.currentWorkspaceId === 3, windowCount: 0 },
        { id: 4, output: root.screenName, isActive: root.currentWorkspaceId === 4, windowCount: 0 }
    ]

    implicitHeight: vertical ? layout.implicitHeight + 2 * Sizes.barPillHorizontalPadding :
                               Sizes.barPillThickness
    implicitWidth: vertical ? Sizes.barPillThickness : layout.implicitWidth + 2
                              * Sizes.barPillHorizontalPadding

    animateResize: {
        for (let index = 0; index < workspaceRepeater.count; ++index) {
            const workspace = workspaceRepeater.itemAt(index);
            if (workspace && workspace.resizing)
                return false;
        }
        return true;
    }

    function acceptsOutput(outputName) {
        if (root.screenName === "")
            return true;
        if (!root.hasMultipleOutputs && outputName === "")
            return true;
        return outputName === root.screenName;
    }

    GridLayout {
        id: layout
        anchors.centerIn: parent
        rowSpacing: Sizes.barItemSpacing
        columnSpacing: Sizes.barItemSpacing
        columns: root.vertical ? 1 : Math.max(1, root.workspaces.length)

        Repeater {
            id: workspaceRepeater
            model: root.workspaces

            delegate: Item {
                id: delegateRoot

                readonly property bool resizing: widthAnimation.running || heightAnimation.running

                required property var modelData

                property bool belongsToScreen: root.acceptsOutput(modelData ? modelData.output : "")
                property bool active: modelData ? !!modelData.isActive : false
                property bool hasWindows: modelData ? (modelData.windowCount > 0) : false
                property bool isHovered: mouseArea.containsMouse

                visible: belongsToScreen
                implicitWidth: !belongsToScreen ? 0 : root.vertical ? 12 : ((active || isHovered) ? 32 : 12)
                implicitHeight: !belongsToScreen ? 0 : root.vertical ? ((active || isHovered) ? 32 : 12) : 12

                Behavior on implicitWidth {
                    NumberAnimation {
                        id: widthAnimation
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        id: heightAnimation
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: height / 2

                    color: delegateRoot.active ? Appearance.colors.colPrimary : delegateRoot.hasWindows
                                                 ? Appearance.colors.colOnSurface : delegateRoot.isHovered
                                                   ? Appearance.colors.colLayer2Hover :
                                                     Appearance.colors.colLayer4

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: root.currentWorkspaceId = model.id
                }

                PopupToolTip {
                    extraVisibleCondition: mouseArea.containsMouse
                    text: qsTr("Workspace ") + model.id + (delegateRoot.hasWindows ? qsTr("\nWindows: ")
                                                                                     + model.windowCount : "")
                }
            }
        }
    }
}
