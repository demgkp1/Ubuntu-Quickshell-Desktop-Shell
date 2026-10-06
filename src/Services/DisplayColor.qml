pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool ready: true
    property bool available: true
    property real dimming: 1.0
    readonly property real dimmingLowerLimit: 0.2
    readonly property real gamma: 1.0
    readonly property real contrast: 1.0
    property string error: ""

    property var preferences: ({
        nightEnabled: false,
        dimming: 1.0,
        gamma: 1.0,
        contrast: 1.0
    })

    property var schedule: ({
        temperature: 4500,
        condition: "normal"
    })

    function setDimming(v) {
        dimming = Math.max(0, Math.min(1, v));
        const next = Object.assign({}, preferences, { dimming: dimming });
        preferences = next;
    }

    function setPreference(key, value) {
        if (key === "dimming") {
            setDimming(value);
            return;
        }
        const next = Object.assign({}, preferences, { [key]: value });
        preferences = next;
    }
}
