import QtQuick
import Quickshell
import "../theme"

/**
 * TopBarWindow - Window Host Adapter
 *
 * Automatically binds to the assigned screen's geometry (width & height),
 * ensuring responsive adaptation on any computer / resolution (1080p, 2K, 4K, ultrawide).
 */
FloatingWindow {
    id: root

    title: "Ubuntu Desktop Shell - TopBar"
    visible: true
    color: "transparent"

    required property var targetScreen
    screen: targetScreen

    // Automatically spans 100% of this specific monitor's width
    implicitWidth: targetScreen ? targetScreen.width : 1920
    implicitHeight: Theme.sizes.topBarHeight

    default property alias content: contentContainer.data

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
