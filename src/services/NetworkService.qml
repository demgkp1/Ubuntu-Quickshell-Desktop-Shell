pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

/**
 * NetworkService - Network Connectivity Provider
 *
 * Automatically monitors Ethernet and Wi-Fi connections via
 * Quickshell's native NetworkManager DBus integration.
 * Detects connection state, SSID, wired/wireless type, and signal strength.
 */
Singleton {
    id: root

    // Reference to the primary active network device
    readonly property var activeDevice: {
        var devs = Networking.devices ? Networking.devices.values : [];
        // First look for connected wifi or wired device
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected && devs[i].type === DeviceType.Wifi) {
                return devs[i];
            }
        }
        for (var j = 0; j < devs.length; j++) {
            if (devs[j].connected && devs[j].type === DeviceType.Wired) {
                return devs[j];
            }
        }
        // Fallback to any connected device
        for (var k = 0; k < devs.length; k++) {
            if (devs[k].connected) return devs[k];
        }
        return null;
    }

    readonly property bool isConnected: activeDevice !== null
    readonly property bool isWifi: activeDevice ? activeDevice.type === DeviceType.Wifi : false
    readonly property bool isWired: activeDevice ? activeDevice.type === DeviceType.Wired : false
    readonly property string interfaceName: activeDevice ? activeDevice.name : ""

    // Wi-Fi network currently connected (if on wireless)
    readonly property var activeWifiNetwork: {
        if (!isWifi || !activeDevice || !activeDevice.networks) return null;
        var nets = activeDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    // Wireless signal strength (0.0 - 1.0)
    readonly property real signalStrength: {
        if (activeWifiNetwork && typeof activeWifiNetwork.signalStrength === "number") {
            return activeWifiNetwork.signalStrength;
        }
        return isConnected ? 1.0 : 0.0;
    }

    // Human-readable connection name
    readonly property string networkName: {
        if (!isConnected) return "Offline";
        if (isWifi) {
            return activeWifiNetwork ? activeWifiNetwork.name : "Wi-Fi";
        }
        if (isWired) {
            return "Ethernet";
        }
        return "Connected";
    }

    // Status text for pills
    readonly property string statusText: networkName
}
