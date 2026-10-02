pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * ControlCenterService - macOS-Grade Quick Settings & Session Controller
 *
 * Manages states and actions for:
 * - Wi-Fi (Radio state, SSID, NetworkManager settings)
 * - Bluetooth (rfkill / BlueZ state, settings)
 * - Do Not Disturb / Focus mode (GNOME notification banners)
 * - Native Interactive Screenshot (Portal Screenshot API)
 * - Dark mode & Night light (GNOME themes & color daemon)
 * - System Session & Power commands (Settings, Lock, Suspend, Reboot, Poweroff)
 */
Singleton {
    id: root

    property bool isOpen: false

    // Quick Settings states
    property bool isDarkMode: true
    property bool isNightLight: false
    property bool isDndEnabled: false
    property bool isWifiEnabled: true
    property string wifiSsid: ""
    property bool isBluetoothEnabled: true

    onIsOpenChanged: {
        if (isOpen) {
            refresh();
        }
    }

    Component.onCompleted: {
        refresh();
    }

    // Comprehensive query of system states in a single subshell
    Process {
        id: readSettingsProc
        command: [
            "bash", "-c",
            "dm=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null); " +
            "nl=$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null); " +
            "dnd=$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null); " +
            "wf=$(nmcli -t -f WIFI g 2>/dev/null); " +
            "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 | head -n 1); " +
            "bt=$(rfkill list bluetooth 2>/dev/null | grep -i 'soft blocked:' | head -n 1 | awk '{print $3}'); " +
            "echo \"$dm|$nl|$dnd|$wf|$ssid|$bt\""
        ]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (!line) return;
                var parts = line.split("|");
                if (parts.length >= 6) {
                    root.isDarkMode = parts[0].indexOf("prefer-dark") !== -1;
                    root.isNightLight = parts[1].indexOf("true") !== -1;
                    // In GNOME, show-banners: false means Do Not Disturb is ON
                    root.isDndEnabled = parts[2].indexOf("false") !== -1;
                    root.isWifiEnabled = parts[3].indexOf("enabled") !== -1;
                    root.wifiSsid = parts[4] || "";
                    root.isBluetoothEnabled = parts[5].indexOf("no") !== -1;
                }
            }
        }
    }

    function refresh() {
        if (!readSettingsProc.running) {
            readSettingsProc.running = true;
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

    // 1. Wi-Fi Toggle & Settings
    function toggleWifi() {
        isWifiEnabled = !isWifiEnabled;
        var action = isWifiEnabled ? "on" : "off";
        runCmd(["nmcli", "radio", "wifi", action]);
    }

    function openWifiSettings() {
        close();
        runCmd(["gnome-control-center", "wifi"]);
    }

    // 2. Bluetooth Toggle & Settings
    function toggleBluetooth() {
        isBluetoothEnabled = !isBluetoothEnabled;
        var script = isBluetoothEnabled
            ? "rfkill unblock bluetooth"
            : "rfkill block bluetooth";
        runCmd(["bash", "-c", script]);
    }

    function openBluetoothSettings() {
        close();
        runCmd(["gnome-control-center", "bluetooth"]);
    }

    // 3. Do Not Disturb (DND)
    function toggleDnd() {
        isDndEnabled = !isDndEnabled;
        // show-banners is inverted from DND
        var banners = isDndEnabled ? "false" : "true";
        runCmd(["gsettings", "set", "org.gnome.desktop.notifications", "show-banners", banners]);
    }

    // 4. Native Interactive Screenshot (Portal API)
    function takeScreenshot() {
        close();
        runCmd([
            "gdbus", "call", "--session",
            "--dest", "org.freedesktop.portal.Desktop",
            "--object-path", "/org/freedesktop/portal/desktop",
            "--method", "org.freedesktop.portal.Screenshot.Screenshot",
            "", "{'interactive': <true>}"
        ]);
    }

    // 5. Theme Toggles
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

    // 6. Navigation & Session Actions
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
