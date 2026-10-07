import QtQuick
import Quickshell

Variants {
    id: variants

    model: Quickshell.screens

    PowerMenuWindow {
        required property var modelData
        targetScreen: modelData
    }
}
