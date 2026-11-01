pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal brightnessChanged()

    property real hardwareBrightnessValue: 0.75
    property bool hasHardwareBacklight: false
    readonly property real brightnessValue: hasHardwareBacklight ? hardwareBrightnessValue : (DisplayColor.dimming !== undefined ? DisplayColor.dimming : 1.0)
    readonly property var activeScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property var monitors: []
    property var ddcMonitors: []

    Component.onCompleted: {
        root.detectHardwareBacklight();
    }

    function detectHardwareBacklight() {
        backlightDetectProcess.running = true;
    }

    Process {
        id: backlightDetectProcess
        command: ["sh", "-c", "test -d /sys/class/backlight && [ -n \"$(ls -A /sys/class/backlight 2>/dev/null)\" ]"]
        onExited: exitCode => {
            root.hasHardwareBacklight = (exitCode === 0);
            root.brightnessChanged();
        }
    }

    Process {
        id: hardwareSetProc
    }

    Connections {
        target: DisplayColor
        function onDimmingChanged() {
            if (!root.hasHardwareBacklight)
                root.brightnessChanged();
        }
    }

    function getMonitorForScreen(s) {
        return {
            brightness: root.brightnessValue,
            screen: s || root.activeScreen,
            hasHardwareBacklight: root.hasHardwareBacklight,
            isSoftwareDimmer: !root.hasHardwareBacklight,
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

    function setBrightnessForScreen(s, v, allowZero) {
        const targetValue = Math.max(allowZero ? 0 : 0.05, Math.min(1.0, v));
        if (root.hasHardwareBacklight) {
            hardwareBrightnessValue = targetValue;
            hardwareSetProc.command = ["brightnessctl", "s", Math.round(targetValue * 100) + "%", "--quiet"];
            hardwareSetProc.running = true;
        } else {
            DisplayColor.setDimming(targetValue);
        }
        root.brightnessChanged();
    }

    function clampBrightness(val, allowZero) {
        return Math.max(allowZero ? 0 : 0.05, Math.min(1, val));
    }
}
