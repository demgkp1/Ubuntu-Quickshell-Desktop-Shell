pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Common

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

    property string passwordRequestSsid: ""
    property string passwordRequestDeviceName: ""
    property int _scanOwnerCount: 0

    function _resolveNativeNetwork(network) {
        if (!network)
            return null;
        if (network.nativeNetwork)
            return network.nativeNetwork;
        const ssid = String(network.ssid || network.name || "");
        for (let i = 0; i < root._nativeWifiDevices.length; i += 1) {
            const dev = root._nativeWifiDevices[i];
            const networks = dev && dev.networks ? dev.networks.values : [];
            for (let j = 0; j < networks.length; j += 1) {
                const n = networks[j];
                if (n && (n.name === ssid || n.ssid === ssid))
                    return n;
            }
        }
        return null;
    }

    function disconnectNetwork(target) {
        const nativeNetwork = root._resolveNativeNetwork(target || root.activeNetwork);
        if (nativeNetwork && typeof nativeNetwork.disconnect === "function") {
            nativeNetwork.disconnect();
        } else {
            const name = target ? String(target.ssid || target.name || target.deviceName || "") : "";
            if (name.length > 0)
                Quickshell.execDetached(["nmcli", "connection", "down", name]);
        }
    }

    function connectNetwork(target, credentials) {
        const nativeNetwork = root._resolveNativeNetwork(target);
        const password = typeof credentials === "string" ? credentials : (credentials && credentials.password ? String(credentials.password) : "");
        const ssid = target ? String(target.ssid || target.name || "") : "";
        if (nativeNetwork) {
            if (password.length > 0 && typeof nativeNetwork.connectWithPsk === "function") {
                nativeNetwork.connectWithPsk(password);
            } else if (typeof nativeNetwork.connect === "function") {
                nativeNetwork.connect();
            }
        } else if (ssid.length > 0) {
            root.connectTargetSsid = ssid;
            if (password.length > 0) {
                // Secure invocation via helper script; never expose plaintext password in argv (CWE-214)
                if (wifiConnectProc.running)
                    wifiConnectProc.running = false;
                root.wifiConnecting = true;
                root.busy = true;
                wifiConnectProc.pendingSecret = password;
                wifiConnectProc.command = ["python3", Paths.systemScriptsDir + "/wifi_helper.py", ssid];
                wifiConnectProc.running = true;
            } else {
                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
            }
        }
    }

    function disconnectWifiNetwork() {
        root.disconnectNetwork(root.activeWifi || root.activeNetwork);
    }

    function connectToWifiNetwork(target) {
        if (!target)
            return;
        if (target.active) {
            root.disconnectNetwork(target);
        } else {
            root.connectNetwork(target, null);
        }
    }

    function cancelPasswordRequest(target) {
        root.passwordRequestSsid = "";
        root.passwordRequestDeviceName = "";
        root.connectTargetSsid = "";
    }

    function forgetProfile(target) {
        if (target && target.nativeSettings && typeof target.nativeSettings.forget === "function") {
            target.nativeSettings.forget();
        } else {
            const id = target ? String(target.uuid || target.name || "") : "";
            if (id.length > 0)
                Quickshell.execDetached(["nmcli", "connection", "delete", id]);
        }
    }

    function forgetNetwork(target) {
        const nativeNetwork = root._resolveNativeNetwork(target);
        if (nativeNetwork && typeof nativeNetwork.forget === "function") {
            nativeNetwork.forget();
        } else {
            root.forgetProfile(target);
        }
    }

    function connectProfile(target) {
        if (target && target.nativeNetwork && target.nativeSettings && typeof target.nativeNetwork.connectWithSettings === "function") {
            target.nativeNetwork.connectWithSettings(target.nativeSettings);
        } else {
            const id = target ? String(target.uuid || target.name || "") : "";
            if (id.length > 0)
                Quickshell.execDetached(["nmcli", "connection", "up", id]);
        }
    }

    function changePassword(target, password) {
        if (!target)
            return;
        const secret = String(password || "");
        if (secret.length === 0) {
            root.passwordRequestSsid = String(target.ssid || target.name || "");
            root.passwordRequestDeviceName = String(target.deviceName || "");
            return;
        }
        root.connectNetwork(target, { "password": secret });
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    function acquireScan(owner) {
        root._scanOwnerCount = (root._scanOwnerCount || 0) + 1;
        for (let i = 0; i < root._nativeWifiDevices.length; i += 1) {
            const dev = root._nativeWifiDevices[i];
            if (dev && typeof dev.scannerEnabled === "boolean")
                dev.scannerEnabled = true;
        }
    }

    function releaseScan(owner) {
        root._scanOwnerCount = Math.max(0, (root._scanOwnerCount || 1) - 1);
        if (root._scanOwnerCount === 0) {
            for (let i = 0; i < root._nativeWifiDevices.length; i += 1) {
                const dev = root._nativeWifiDevices[i];
                if (dev && typeof dev.scannerEnabled === "boolean")
                    dev.scannerEnabled = false;
            }
        }
    }

    function requestScan() {
        for (let i = 0; i < root._nativeWifiDevices.length; i += 1) {
            const dev = root._nativeWifiDevices[i];
            if (dev && typeof dev.scannerEnabled === "boolean")
                dev.scannerEnabled = true;
        }
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
    }

    function addWifiNetwork(ssid, hidden, secure, secret, callback) {
        if (callback)
            callback(false, "Unsupported in headless");
    }

    function profileSnapshot(profile) {
        return Object.assign({}, profile || {});
    }

    function writeProfile(profile, changes) {
        if (!profile || !changes)
            return false;
        const id = String(profile.uuid || profile.name || "");
        if (id.length === 0)
            return false;
        const args = ["nmcli", "connection", "modify", id];
        let hasChanges = false;
        for (const k in changes) {
            args.push(k, String(changes[k]));
            hasChanges = true;
        }
        if (hasChanges) {
            Quickshell.execDetached(args);
            return true;
        }
        return false;
    }

    function requestRuntimeDetails(interfaceName, isWifi, callback) {
        const iface = String(interfaceName || (root.activeWiredDeviceName !== "Ethernet" ? root.activeWiredDeviceName : ""));
        root.runtimeDetails = {
            "interface": iface,
            "type": isWifi ? "wifi" : "wired",
            "connected": root.connected,
            "connectionName": root.activeConnection
        };
        if (typeof callback === "function")
            callback(true, root.runtimeDetails, "");
    }

    function releaseRuntimeDetails() {
        root.runtimeDetails = { "addresses": [], "gateway": "", "dns": [], "frequency": "" };
        root.runtimeDetailsError = "";
    }

    Process {
        id: wifiConnectProc
        stdinEnabled: true
        property string pendingSecret: ""

        onStarted: {
            if (pendingSecret.length > 0) {
                write(pendingSecret + "\n");
                pendingSecret = "";
            }
        }

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.wifiConnecting = false;
            root.busy = false;
            if (exitCode !== 0) {
                const err = stderr.text.trim() || qsTr("Failed to connect to Wi-Fi");
                root.lastError = err;
            } else {
                root.lastError = "";
            }
        }
    }
}
