pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal brightnessChanged()

    property real hardwareBrightnessValue: 0
    property bool hardwareReadReady: false
    readonly property bool available: hasHardwareBacklight && hardwareReadReady
    property string lastError: ""
    property bool hasHardwareBacklight: false
    readonly property real brightnessValue: hasHardwareBacklight ? hardwareBrightnessValue : 0
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
            if (root.hasHardwareBacklight) hardwareReadProc.running = true;
            root.brightnessChanged();
        }
    }

    Process {
        id: hardwareSetProc
        onExited: code => {
            root.lastError = code === 0 ? "" : qsTr("Hardware brightness update failed");
            hardwareReadProc.running = true;
        }
    }
    Process {
        id: hardwareReadProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                const percent = fields.length > 3 ? Number(fields[3].replace("%", "")) : NaN;
                if (isFinite(percent)) {
                    root.hardwareBrightnessValue = Math.max(0, Math.min(1, percent / 100));
                    root.hardwareReadReady = true;
                }
                else { root.hardwareReadReady = false; root.lastError = qsTr("Hardware brightness readback unavailable"); }
            }
        }
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
            isSoftwareDimmer: false,
            available: root.available,
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
            hardwareSetProc.command = ["brightnessctl", "s", Math.round(targetValue * 100) + "%", "--quiet"];
            hardwareSetProc.running = true;
        } else {
            root.lastError = qsTr("No hardware backlight. GNOME software dimming and DDC are not implemented by this service.");
        }
        root.brightnessChanged();
    }

    function clampBrightness(val, allowZero) {
        return Math.max(allowZero ? 0 : 0.05, Math.min(1, val));
    }
}
