pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool available: true
    property bool wifiAvailable: true
    property bool wifiEnabled: true
    property bool connected: true
    property string activeConnection: "Wired Connection"
    property bool wiredConnected: true
    property bool wifiConnected: false
    property string activeConnectionType: wiredConnected ? "ETHERNET" : (wifiConnected ? "WIFI" : "")

    readonly property bool ethernetConnected: wiredConnected
    property string wifiSignalIcon: "wifi"
    property int signalStrength: 85
    property bool internetAvailable: true
    property bool captivePortal: false
    property bool limitedConnectivity: false
    property bool busy: false
    property bool wifiHardwareEnabled: true
    property string lastError: ""
    property string connectTargetUuid: ""
    property var wifiConnectTarget: null

    property var activeNetwork: ({
        name: root.activeConnection,
        type: root.wiredConnected ? "wired" : "wifi",
        connected: root.connected
    })
    property var activeWifi: null
    property var wiredDevices: [
        {
            name: "eth0",
            deviceName: "Ethernet",
            hasLink: root.wiredConnected,
            connected: root.wiredConnected
        }
    ]
    property var availableWifiNetworks: []
    property var savedWifiProfiles: []

    function toggleWifi() {
        wifiEnabled = !wifiEnabled;
    }

    function setWifiEnabled(v) {
        wifiEnabled = !!v;
    }

    function disconnectNetwork(target) {}
    function connectNetwork(target) {}
    function disconnectWifiNetwork() {}
    function connectToWifiNetwork(target) {}
    function cancelPasswordRequest(target) {}
    function forgetProfile(target) {}
    function forgetNetwork(target) {}
    function connectProfile(target) {}
    function changePassword(target, password) {}
    function openPublicWifiPortal() {}
    function acquireScan(owner) {}
    function releaseScan(owner) {}
    function requestScan() {}
}
