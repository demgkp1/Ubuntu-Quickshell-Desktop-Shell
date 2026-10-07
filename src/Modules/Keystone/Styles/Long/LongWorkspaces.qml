pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets.common

Item {
    id: root

    required property var screen
    property bool vertical: false
    property int currentWorkspaceId: 1
    readonly property var workspaces: [
        { id: 1, index: 1, name: "1", isActive: root.currentWorkspaceId === 1, is_active: root.currentWorkspaceId === 1, output: root.screen ? root.screen.name : "" },
        { id: 2, index: 2, name: "2", isActive: root.currentWorkspaceId === 2, is_active: root.currentWorkspaceId === 2, output: root.screen ? root.screen.name : "" },
        { id: 3, index: 3, name: "3", isActive: root.currentWorkspaceId === 3, is_active: root.currentWorkspaceId === 3, output: root.screen ? root.screen.name : "" },
        { id: 4, index: 4, name: "4", isActive: root.currentWorkspaceId === 4, is_active: root.currentWorkspaceId === 4, output: root.screen ? root.screen.name : "" }
    ]

    implicitWidth: vertical ? 32 : workspaceRow.implicitWidth
    implicitHeight: vertical ? workspaceColumn.implicitHeight : 32

    Flow {
        id: workspaceRow
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: root.vertical ? null : root.workspaces
            delegate: WorkspaceNumber {}
        }
    }

    Column {
        id: workspaceColumn
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: root.vertical ? root.workspaces : null
            delegate: WorkspaceNumber {}
        }
    }

    component WorkspaceNumber: Item {
        id: workspace
        required property var model
        readonly property bool belongsToScreen: !root.screen || model.output === root.screen.name || model.output === ""
        visible: belongsToScreen
        width: visible ? 28 : 0
        height: visible ? 32 : 0
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Workspace %1").arg(model.name || model.index)
        Accessible.onPressAction: root.currentWorkspaceId = model.id

        Text {
            anchors.centerIn: parent
            text: workspace.model.index
            color: workspace.model.isActive || pointer.containsMouse ? Appearance.colors.colPrimary :
                                                                       Appearance.colors.colOnSurfaceVariant
            font.family: Fonts.numeric
            font.pixelSize: 13
            font.weight: workspace.model.isActive ? Font.Bold : Font.Normal
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onClicked: root.currentWorkspaceId = workspace.model.id
        }

        PopupToolTip {
            extraVisibleCondition: pointer.containsMouse
            text: qsTr("Workspace %1").arg(workspace.model.name || workspace.model.index)
            textFormat: Text.PlainText
        }
    }
}
