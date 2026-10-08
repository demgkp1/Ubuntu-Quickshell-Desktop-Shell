import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services

PanelWindow {
    id: root

    required property var targetScreen

    readonly property bool isActive: RegionSelectionService.active

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    property int x: targetScreen && targetScreen.geometry ? targetScreen.geometry.x : 0
    property int y: targetScreen && targetScreen.geometry ? targetScreen.geometry.y : 0
    implicitWidth: targetScreen && targetScreen.geometry ? targetScreen.geometry.width : 1920
    implicitHeight: targetScreen && targetScreen.geometry ? targetScreen.geometry.height : 1080

    // Persistent mapping under Mutter X11 to avoid compositor recreate/unmap lag.
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
        item: root.isActive ? fullInteractionRegion : emptyMaskRegion
    }

    property real pointerX: width / 2
    property real pointerY: height / 2
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragCurrentX: 0
    property real dragCurrentY: 0
    property bool dragging: false

    readonly property real selectionX: Math.min(dragStartX, dragCurrentX)
    readonly property real selectionY: Math.min(dragStartY, dragCurrentY)
    readonly property real selectionWidth: Math.abs(dragCurrentX - dragStartX)
    readonly property real selectionHeight: Math.abs(dragCurrentY - dragStartY)
    readonly property bool hasSelection: selectionWidth > 0 && selectionHeight > 0
    readonly property color guideColor: Appearance.colors.colPrimary
    readonly property color guideMuted: Appearance.applyAlpha(guideColor, 0.48)
    readonly property color selectionFill: Appearance.applyAlpha(guideColor, 0.12)

    function resetSelection() {
        root.dragging = false;
        root.dragStartX = 0;
        root.dragStartY = 0;
        root.dragCurrentX = 0;
        root.dragCurrentY = 0;
    }

    function finishSelection() {
        if (!RegionSelectionService.accept(root.targetScreen, root.selectionX, root.selectionY,
                                           root.selectionWidth, root.selectionHeight)) {
            root.resetSelection();
        }
    }

    Connections {
        target: RegionSelectionService
        function onActiveChanged() {
            if (RegionSelectionService.active) {
                root.resetSelection();
                Qt.callLater(() => {
                    keyboardGateway.forceActiveFocus(Qt.OtherFocusReason);
                });
            } else {
                root.resetSelection();
            }
        }
    }

    Item {
        id: interactionHost
        anchors.fill: parent
        visible: root.isActive
        focus: root.isActive

        Item {
            id: keyboardGateway
            anchors.fill: parent
            focus: root.isActive

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    RegionSelectionService.cancel();
                }
            }
        }

        // Full scrim when no selection is active
        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim
            visible: !root.hasSelection
        }

        // Four-quadrant scrim cutout around the active selection
        Item {
            anchors.fill: parent
            visible: root.hasSelection

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: root.selectionY
                color: Appearance.colors.colScrim
            }

            Rectangle {
                x: 0
                y: root.selectionY + root.selectionHeight
                width: parent.width
                height: Math.max(0, parent.height - y)
                color: Appearance.colors.colScrim
            }

            Rectangle {
                x: 0
                y: root.selectionY
                width: root.selectionX
                height: root.selectionHeight
                color: Appearance.colors.colScrim
            }

            Rectangle {
                x: root.selectionX + root.selectionWidth
                y: root.selectionY
                width: Math.max(0, parent.width - x)
                height: root.selectionHeight
                color: Appearance.colors.colScrim
            }
        }

        // Vertical crosshair
        Rectangle {
            x: Math.round(root.pointerX)
            y: 0
            width: 1
            height: parent.height
            color: root.guideMuted
        }

        // Horizontal crosshair
        Rectangle {
            x: 0
            y: Math.round(root.pointerY)
            width: parent.width
            height: 1
            color: root.guideMuted
        }

        // Selection rectangle outline
        Rectangle {
            id: selectionFrame
            x: Math.round(root.selectionX)
            y: Math.round(root.selectionY)
            width: Math.round(root.selectionWidth)
            height: Math.round(root.selectionHeight)
            radius: Appearance.rounding.extraSmall
            visible: root.hasSelection
            color: root.selectionFill
            border.width: 2
            border.color: root.guideColor
        }

        // Floating dimension badge
        Rectangle {
            id: dimensionLabel
            readonly property real preferredX: root.selectionX + root.selectionWidth - width
            readonly property real preferredY: root.selectionY > height + 20 ? root.selectionY - height - 8 :
                                                                               root.selectionY
                                                                               + root.selectionHeight + 8

            x: Math.max(12, Math.min(preferredX, root.width - width - 12))
            y: Math.max(12, Math.min(preferredY, root.height - height - 12))
            width: dimensionRow.implicitWidth + 24
            height: 36
            radius: Appearance.rounding.full
            visible: root.hasSelection
            color: Appearance.colors.colSurfaceContainerHighest

            RowLayout {
                id: dimensionRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    text: "crop_free"
                    font.family: Fonts.materialSymbolsRounded
                    font.pixelSize: 17
                    color: Appearance.colors.colPrimary
                }

                Text {
                    text: Math.round(root.selectionWidth) + " × " + Math.round(root.selectionHeight)
                    font.family: Fonts.numeric
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSurface
                }
            }
        }

        // Top instruction pill
        Rectangle {
            id: instructionLabel
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 24
            }
            width: instructionRow.implicitWidth + 28
            height: 40
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimaryContainer

            RowLayout {
                id: instructionRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "drag_pan"
                    font.family: Fonts.materialSymbolsRounded
                    font.pixelSize: 18
                    color: Appearance.colors.colOnPrimaryContainer
                }

                Text {
                    text: qsTr("Drag to select a region  ·  Esc to cancel")
                    font.family: Fonts.ui
                    font.pixelSize: 13
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        MouseArea {
            id: interactionArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.CrossCursor

            onPositionChanged: mouse => {
                root.pointerX = mouse.x;
                root.pointerY = mouse.y;
                if (root.dragging) {
                    root.dragCurrentX = Math.max(0, Math.min(mouse.x, root.width));
                    root.dragCurrentY = Math.max(0, Math.min(mouse.y, root.height));
                }
            }

            onPressed: mouse => {
                keyboardGateway.forceActiveFocus();
                root.pointerX = mouse.x;
                root.pointerY = mouse.y;
                root.dragStartX = Math.max(0, Math.min(mouse.x, root.width));
                root.dragStartY = Math.max(0, Math.min(mouse.y, root.height));
                root.dragCurrentX = root.dragStartX;
                root.dragCurrentY = root.dragStartY;
                root.dragging = true;
            }

            onReleased: mouse => {
                if (!root.dragging)
                    return;

                root.dragCurrentX = Math.max(0, Math.min(mouse.x, root.width));
                root.dragCurrentY = Math.max(0, Math.min(mouse.y, root.height));
                root.dragging = false;
                root.finishSelection();
            }
        }
    }
}
