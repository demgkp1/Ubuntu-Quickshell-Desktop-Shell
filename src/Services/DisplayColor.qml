pragma Singleton

import QtQuick
import Quickshell
import qs.Services

Singleton {
    id: root

    readonly property bool ready: available
    readonly property bool available: CompositorBackend.connected && !!CompositorBackend.capabilities.gamma
    property real dimming: 1.0
    readonly property real dimmingLowerLimit: 0.2
    readonly property real gamma: 1.0
    readonly property real contrast: 1.0
    property string error: qsTr("GNOME owns night light. Custom gamma, contrast, dimming and Clavis location scheduling are unavailable.")
    property bool locating: false
    property string locationError: ""
    property string scheduleWarning: ""
    property var outputs: []

    property var preferences: ({
        nightEnabled: false,
        dimming: 1.0,
        gamma: 1.0,
        contrast: 1.0
    })

    property var schedule: ({
        temperature: 4500,
        condition: "normal",
        period: "day",
        transitioning: false,
        next: 0
    })

    function unsupported() {
        error = qsTr("Use GNOME Settings → Displays for native night light; Clavis gamma controls are unavailable on this backend.");
        return root.available;
    }
    function setDimming(value) { return unsupported(); }
    function setPreference(key, value) { return unsupported(); }
    function locate() { return unsupported(); }
    function useWeatherLocation() { return unsupported(); }
}
