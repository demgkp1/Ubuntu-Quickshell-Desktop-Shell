pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var _nativeDevices: Networking.devices ? Networking.devices.values : []
    readonly property var _nativeWifiDevices: _nativeDevices.filter(device => device && device.type === DeviceType.Wifi)
    readonly property var _nativeWiredDevices: _nativeDevices.filter(device => device && device.type === DeviceType.Wired)
    readonly property bool hasNativeDevices: _nativeDevices.length > 0

    property bool fallbackWiredConnected: true
    property bool fallbackWifiConnected: false
    property bool fallbackConnected: true
    property bool fallbackWifiEnabled: true

    readonly property bool available: Networking.backend === NetworkBackendType.NetworkManager || true
    readonly property bool wifiAvailable: hasNativeDevices ? _nativeWifiDevices.length > 0 : true
    readonly property bool wifiEnabled: hasNativeDevices ? Networking.wifiEnabled : fallbackWifiEnabled
    readonly property bool wifiHardwareEnabled: hasNativeDevices ? Networking.wifiHardwareEnabled : true
    readonly property bool wiredConnected: hasNativeDevices ? _nativeWiredDevices.some(device => device && device.connected) : fallbackWiredConnected
    readonly property bool wifiConnected: hasNativeDevices ? _nativeWifiDevices.some(device => device && device.connected) : fallbackWifiConnected
    readonly property bool connected: hasNativeDevices ? _nativeDevices.some(device => device && device.connected) : fallbackConnected

    readonly property string activeWiredDeviceName: {
        for (let i = 0; i < _nativeWiredDevices.length; i += 1) {
            if (_nativeWiredDevices[i] && _nativeWiredDevices[i].connected)
                return _nativeWiredDevices[i].name || "Ethernet";
        }
        return "Ethernet";
    }

    readonly property string activeWifiSsid: {
        for (let i = 0; i < _nativeWifiDevices.length; i += 1) {
            const dev = _nativeWifiDevices[i];
            if (dev && dev.connected && dev.activeNetwork)
                return dev.activeNetwork.name || "Wi-Fi";
        }
        return "Wi-Fi";
    }

    property string activeConnection: wiredConnected ? (hasNativeDevices ? activeWiredDeviceName : "Wired Connection") :
                                      wifiConnected ? (hasNativeDevices ? activeWifiSsid : "Wi-Fi") :
                                      connected ? qsTr("Connected") : qsTr("Disconnected")
    property string activeConnectionType: wiredConnected ? "ETHERNET" : (wifiConnected ? "WIFI" : (connected ? "OTHER" : ""))

    readonly property bool ethernetConnected: wiredConnected
    property string wifiSignalIcon: "wifi"
    property int signalStrength: 85
    readonly property bool internetAvailable: hasNativeDevices ? (Networking.connectivity === NetworkConnectivity.Full) : true
    readonly property bool captivePortal: hasNativeDevices ? (Networking.connectivity === NetworkConnectivity.Portal) : false
    readonly property bool limitedConnectivity: hasNativeDevices ? (Networking.connectivity === NetworkConnectivity.Limited) : false
    property bool busy: false
    property string lastError: ""
    property string connectTargetUuid: ""
    property var wifiConnectTarget: null

    property var activeNetwork: ({
        name: root.activeConnection,
        type: root.wiredConnected ? "wired" : "wifi",
        connected: root.connected
    })
    property var activeWifi: null
    property var wiredDevices: hasNativeDevices ? _nativeWiredDevices : [
        {
            name: "eth0",
            deviceName: "Ethernet",
            hasLink: root.wiredConnected,
            connected: root.wiredConnected
        }
    ]
    property var availableWifiNetworks: []
    property var savedWifiProfiles: []
    property var wiredProfiles: []
    readonly property var allWifiNetworks: availableWifiNetworks
    readonly property var nearbyWifiNetworks: availableWifiNetworks
    property var runtimeDetails: ({ addresses: [], gateway: "", dns: [], frequency: "" })
    property string runtimeDetailsError: ""
    property bool wifiConnecting: false
    property string connectTargetSsid: ""

    function toggleWifi() {
        if (hasNativeDevices)
            Networking.wifiEnabled = !Networking.wifiEnabled;
        else
            fallbackWifiEnabled = !fallbackWifiEnabled;
    }

    function setWifiEnabled(v) {
        if (hasNativeDevices)
            Networking.wifiEnabled = !!v;
        else
            fallbackWifiEnabled = !!v;
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
    function addWifiNetwork(ssid, hidden, secure, secret, callback) { if (callback) callback(false, "Unsupported in headless"); }
    function profileSnapshot(profile) { return Object.assign({}, profile || {}); }
    function writeProfile(profile, changes) { return true; }
    function requestRuntimeDetails(interfaceName, isWifi, callback) {}
    function releaseRuntimeDetails() {}
}
