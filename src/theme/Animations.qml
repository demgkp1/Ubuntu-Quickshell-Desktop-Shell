pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Durations (in milliseconds)
    readonly property int instant: 0
    readonly property int fast: 150
    readonly property int normal: 250
    readonly property int slow: 400

    // Easing curves
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutCubic
    readonly property int easeIn: Easing.InCubic
}
