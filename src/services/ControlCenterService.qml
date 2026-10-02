pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * ControlCenterService - Quick Settings & Session Controller
 *
 * Manages the state of the right-hand Control Center popup,
 * system theme preferences (dark mode, night light), and session commands.
 */
Singleton {
    id: root

    property bool isOpen: false
    property bool isDarkMode: true
    property bool isNightLight: false

    // Initialize states from GNOME settings
    Component.onCompleted: {
        readSettingsProc.running = true;
    }

    Process {
        id: readSettingsProc
        command: [
            "bash", "-c",
            "dm=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null); nl=$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null); echo \"$dm|$nl\""
        ]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length >= 2) {
                    root.isDarkMode = parts[0].indexOf("prefer-dark") !== -1;
                    root.isNightLight = parts[1].indexOf("true") !== -1;
                }
            }
        }
    }

    // Runner for arbitrary shell commands
    Process {
        id: cmdProc
        property var pendingCmd: []
        command: pendingCmd
    }

    function runCmd(args) {
        cmdProc.pendingCmd = args;
        cmdProc.running = true;
    }

    function toggle() {
        isOpen = !isOpen;
    }

    function open() {
        isOpen = true;
    }

    function close() {
        isOpen = false;
    }

    function toggleDarkMode() {
        isDarkMode = !isDarkMode;
        var scheme = isDarkMode ? "prefer-dark" : "prefer-light";
        runCmd(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme]);
    }

    function toggleNightLight() {
        isNightLight = !isNightLight;
        var val = isNightLight ? "true" : "false";
        runCmd(["gsettings", "set", "org.gnome.settings-daemon.plugins.color", "night-light-enabled", val]);
    }

    function openSettings() {
        close();
        runCmd(["gnome-control-center"]);
    }

    function openNetworkSettings() {
        close();
        runCmd(["gnome-control-center", "network"]);
    }

    function openSoundSettings() {
        close();
        runCmd(["gnome-control-center", "sound"]);
    }

    function lockSession() {
        close();
        runCmd(["loginctl", "lock-session"]);
    }

    function suspend() {
        close();
        runCmd(["systemctl", "suspend"]);
    }

    function reboot() {
        close();
        runCmd(["systemctl", "reboot"]);
    }

    function poweroff() {
        close();
        runCmd(["systemctl", "poweroff"]);
    }
}
