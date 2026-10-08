import QtQuick
import Quickshell

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        RegionSelectionWindow {
            required property var modelData
            targetScreen: modelData
        }
    }
}
