pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    signal brightnessChanged()

    property real brightnessValue: 0.75
    property bool hasHardwareBacklight: false
    readonly property var activeScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property var monitors: []
    property var ddcMonitors: []

    function getMonitorForScreen(s) {
        return {
            brightness: root.brightnessValue,
            screen: s || root.activeScreen,
            setBrightness: function(val, allowZero) {
                root.setBrightnessForScreen(s, val, allowZero);
            }
        };
    }

    function getScreenByName(name) {
        if (!name || name.length === 0)
            return null;
        if (Quickshell.screens) {
            for (let i = 0; i < Quickshell.screens.length; i += 1) {
                if (Quickshell.screens[i].name === name)
                    return Quickshell.screens[i];
            }
        }
        return activeScreen;
    }

    function getMonitorByName(name) {
        return getMonitorForScreen(getScreenByName(name));
    }

    function setBrightness(v, allowZero) {
        setBrightnessForScreen(null, v, allowZero);
    }

    function setBrightnessForScreen(s, v, flag) {
        brightnessValue = Math.max(0, Math.min(1, v));
        root.brightnessChanged();
    }

    function clampBrightness(val, allowZero) {
        return Math.max(allowZero ? 0 : 0.05, Math.min(1, val));
    }
}
