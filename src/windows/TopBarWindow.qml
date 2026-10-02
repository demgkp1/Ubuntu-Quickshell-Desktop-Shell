import QtQuick
import Quickshell
import "../theme"

/**
 * TopBarWindow - Window Host Adapter
 *
 * Implements native desktop dock reservation (Exclusive Zone / Struts).
 * - Anchors to the top, left, and right edges of the display.
 * - Sets exclusiveZone to ensure other windows (maximized or tiled)
 *   stop cleanly beneath the TopBar and NEVER overlap it.
 */
PanelWindow {
    id: root

    color: "transparent"

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: Theme.sizes.topBarHeight + 4
    implicitHeight: Theme.sizes.topBarHeight + 4

    default property alias content: contentContainer.data

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
