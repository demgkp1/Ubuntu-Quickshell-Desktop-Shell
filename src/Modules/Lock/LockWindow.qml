import QtQuick
import Quickshell
import qs.Common
import qs.Services

PanelWindow {
    id: root

    required property var targetScreen
    required property var lockContext
    required property var lockController
    required property var snapshotProvider
    required property string sessionStyle

    readonly property bool isLocked: lockController.locked

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    property int x: targetScreen && targetScreen.geometry ? targetScreen.geometry.x : 0
    property int y: targetScreen && targetScreen.geometry ? targetScreen.geometry.y : 0
    implicitWidth: targetScreen && targetScreen.geometry ? targetScreen.geometry.width : 1920
    implicitHeight: targetScreen && targetScreen.geometry ? targetScreen.geometry.height : 1080

    // Persistent mapping under Mutter X11 to avoid compositor recreate/unmap failures.
    visible: true
    color: "transparent"
    exclusiveZone: 0

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Item {
        id: emptyMaskRegion
        width: 0
        height: 0
    }

    Item {
        id: fullInteractionRegion
        anchors.fill: parent
    }

    mask: Region {
        item: root.isLocked ? fullInteractionRegion : emptyMaskRegion
    }

    Connections {
        target: root
        function onIsLockedChanged() {
            if (root.isLocked) {
                Qt.callLater(() => {
                    interactionHost.forceActiveFocus(Qt.OtherFocusReason);
                });
            }
        }
    }

    Item {
        id: interactionHost
        anchors.fill: parent
        visible: root.isLocked
        focus: root.isLocked

        LockSurface {
            id: surface
            anchors.fill: parent
            screen: root.screen
            lock: root.lockController
            context: root.lockContext
            snapshotProvider: root.snapshotProvider
            style: root.sessionStyle
        }
    }
}
