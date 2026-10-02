import QtQuick
import Quickshell
import "../theme"

/**
 * TopBarWindow - Window Host Adapter
 *
 * Current Strategy:
 * Uses Quickshell's FloatingWindow (xdg-shell) to ensure full compatibility
 * with Ubuntu 24.04 GNOME Mutter (which lacks zwlr_layer_shell_v1).
 *
 * Future Portability:
 * The UI content is completely decoupled from the window frame. When targeting
 * compositors that support layer-shell (e.g., Niri, Hyprland, Sway), this window
 * host can be transitioned to PanelWindow with anchors and exclusiveZone, with zero
 * modifications required to components or services.
 */
FloatingWindow {
    id: root

    title: "Ubuntu Desktop Shell - TopBar"
    visible: true
    color: "transparent"

    default property alias content: contentContainer.data

    implicitWidth: contentContainer.implicitWidth
    implicitHeight: contentContainer.implicitHeight

    Item {
        id: contentContainer
        anchors.fill: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
