pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool ready: true
    readonly property bool present: false
    readonly property bool onBattery: false
    readonly property real percentage: NaN
    readonly property int state: 0
    readonly property bool charging: false
    readonly property bool full: false
    readonly property bool discharging: false
    readonly property bool powerConnected: true
    readonly property real timeToEmpty: NaN
    readonly property real timeToFull: NaN
    readonly property real changeRate: NaN
    readonly property real healthPercentage: NaN
}
