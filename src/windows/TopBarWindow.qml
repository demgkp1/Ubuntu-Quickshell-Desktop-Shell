import QtQuick
import Quickshell
import "../theme"

/**
 * TopBarWindow - Window Host Adapter
 *
 * Current Strategy:
 * Uses Quickshell's FloatingWindow (xdg-shell) spanning the screen width
 * to provide a three-section edge-to-edge floating capsule bar on GNOME Mutter.
 *
 * Future Portability:
 * Decoupled from TopBarLayout. When migrating to layer-shell compositors,
 * this adapter can simply be replaced with PanelWindow.
 */
FloatingWindow {
    id: root

    title: "Ubuntu Desktop Shell - TopBar"
    visible: true
    color: "transparent"

    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    screen: targetScreen

    // Automatically spans the display width
    implicitWidth: targetScreen ? targetScreen.width : 1920
    implicitHeight: Theme.sizes.topBarHeight + Theme.sizes.spacingSm

    default property alias content: contentContainer.data

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
