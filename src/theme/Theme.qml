pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property Colors colors: Colors
    readonly property Sizes sizes: Sizes
    readonly property Typography typography: Typography
    readonly property Animations animations: Animations
}
