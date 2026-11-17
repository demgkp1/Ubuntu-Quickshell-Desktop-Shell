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
    readonly property bool hasMultipleOutputs: (Quickshell.screens && Quickshell.screens.length > 1)
                                             || CompositorBackend.outputs.length > 1
    readonly property var workspaces: {
        // Touch reactive backend properties so QML updates when workspaces or outputs change.
        const allWorkspaces = CompositorBackend.workspaces;
        const _outputs = CompositorBackend.outputs;
        const _windows = CompositorBackend.windows;
        const _gen = CompositorBackend.connectionGeneration;
        if (root.screenName !== "")
            return CompositorBackend.workspacesForOutput(root.screenName);
        return Array.isArray(allWorkspaces) ? allWorkspaces : [];
    }

    visible: root.workspaces.length > 0
    implicitHeight: !visible ? 0 : (vertical ? layout.implicitHeight + 2 * Sizes.barPillHorizontalPadding :
                               Sizes.barPillThickness)
    implicitWidth: !visible ? 0 : (vertical ? Sizes.barPillThickness : layout.implicitWidth + 2
                              * Sizes.barPillHorizontalPadding)

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

                property bool belongsToScreen: root.acceptsOutput(
                    modelData && modelData.output !== undefined ? modelData.output : root.screenName)
                property bool active: modelData ? !!(modelData.isActive || modelData.active) : false
                property bool hasWindows: modelData ? (Number(modelData.windowCount || 0) > 0) : false
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

                    color: delegateRoot.active || delegateRoot.isHovered ? BarColors.selected :
                                                                           delegateRoot.hasWindows
                                                                           ? BarColors.inactiveWorkspace :
                                                                             BarColors.emptyWorkspace

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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (delegateRoot.modelData && delegateRoot.modelData.id !== undefined
                                && delegateRoot.modelData.id !== null)
                            Niri.focusWorkspaceById(delegateRoot.modelData.id);
                    }
                }

                PopupToolTip {
                    extraVisibleCondition: mouseArea.containsMouse
                    text: qsTr("Workspace ") + (delegateRoot.modelData ? delegateRoot.modelData.id : "") + (delegateRoot.hasWindows ? qsTr("\nWindows: ")
                                                                                     + (delegateRoot.modelData ? delegateRoot.modelData.windowCount : 0) : "")
                }
            }
        }
    }
}
