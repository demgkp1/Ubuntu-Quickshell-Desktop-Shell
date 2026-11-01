pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var _nativeAdapters: Bluetooth.adapters ? Bluetooth.adapters.values : []
    readonly property var _nativeDevices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool blocked: available && adapter.state === BluetoothAdapterState.Blocked
    readonly property bool discovering: _nativeAdapters.some(candidate => candidate && candidate.discovering)
    readonly property bool scanning: discovering
    readonly property bool discoverable: available && adapter.discoverable
    readonly property bool pairable: available && adapter.pairable
    readonly property bool connected: connectedDevices.length > 0
    readonly property string connectedName: connected ? (connectedDevices[0].name || "") : ""
    readonly property bool busy: _pendingOperation.length > 0

    readonly property var adapters: _nativeAdapters.map(candidate => root._describeAdapter(candidate))
    readonly property var devices: root._deduplicatedDeviceDescriptors()
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property var pairedDevices: devices.filter(device => !device.connected && (device.paired || device.bonded || device.trusted))
    readonly property var availableDevices: devices.filter(device => !device.connected && !device.paired && !device.bonded && !device.trusted)

    property string lastError: ""
    property string _pendingOperation: ""

    signal operationStarted(string operation)
    signal operationSucceeded(string operation)
    signal operationFailed(string operation, string message)

    function clearError() {
        root.lastError = "";
    }

    function _describeAdapter(candidate) {
        if (!candidate)
            return {};

        return {
            "id": String(candidate.adapterId || ""),
            "name": String(candidate.name || candidate.adapterId || ""),
            "dbusPath": String(candidate.dbusPath || ""),
            "available": true,
            "enabled": !!candidate.enabled,
            "state": BluetoothAdapterState.toString(candidate.state),
            "blocked": candidate.state === BluetoothAdapterState.Blocked,
            "discovering": !!candidate.discovering,
            "discoverable": !!candidate.discoverable,
            "discoverableTimeout": Number(candidate.discoverableTimeout || 0),
            "pairable": !!candidate.pairable,
            "pairableTimeout": Number(candidate.pairableTimeout || 0)
        };
    }

    function _describeDevice(device) {
        if (!device)
            return {};

        const deviceAdapter = device.adapter;
        return {
            "name": String(device.name || device.deviceName || device.address || qsTr("Unknown device")),
            "deviceName": String(device.deviceName || ""),
            "address": String(device.address || ""),
            "icon": String(device.icon || ""),
            "adapterId": deviceAdapter ? String(deviceAdapter.adapterId || "") : "",
            "state": BluetoothDeviceState.toString(device.state),
            "connected": !!device.connected,
            "paired": !!device.paired,
            "bonded": !!device.bonded,
            "pairing": !!device.pairing,
            "connecting": device.state === BluetoothDeviceState.Connecting,
            "disconnecting": device.state === BluetoothDeviceState.Disconnecting,
            "trusted": !!device.trusted,
            "blocked": !!device.blocked,
            "legacyPairing": !!device.legacyPairing,
            "rssi": Number(device.rssi || 0),
            "hasRssi": device.rssi !== null && device.rssi !== undefined,
            "batteryPercentage": device.batteryPercentage !== null && device.batteryPercentage !== undefined ? Number(device.batteryPercentage) : NaN,
            "hasBattery": device.batteryPercentage !== null && device.batteryPercentage !== undefined,
            "wakeAllowed": !!device.wakeAllowed
        };
    }

    function _deduplicatedDeviceDescriptors() {
        const result = [];
        const seenAddresses = {};

        for (let index = 0; index < root._nativeDevices.length; index += 1) {
            const raw = root._nativeDevices[index];
            if (!raw)
                continue;

            const address = String(raw.address || "");
            if (address.length > 0 && seenAddresses[address])
                continue;

            if (address.length > 0)
                seenAddresses[address] = true;

            result.push(root._describeDevice(raw));
        }

        return result;
    }

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function setBluetoothEnabled(v) {
        if (adapter)
            adapter.enabled = !!v;
    }

    function setAdapterEnabled(v) {
        if (adapter)
            adapter.enabled = !!v;
    }

    function setDiscoverable(v) {
        if (adapter)
            adapter.discoverable = !!v;
    }

    function setPairable(v) {
        if (adapter)
            adapter.pairable = !!v;
    }

    function acquireDiscovery(owner) {
        if (adapter)
            adapter.discovering = true;
    }

    function releaseDiscovery(owner) {
        if (adapter)
            adapter.discovering = false;
    }

    function _resolveDevice(deviceLike) {
        if (!deviceLike)
            return null;
        if (typeof deviceLike.connect === "function")
            return deviceLike;
        const address = typeof deviceLike === "string" ? deviceLike : String(deviceLike.address || "");
        if (address.length === 0)
            return null;
        return root._nativeDevices.find(dev => dev && dev.address === address) || null;
    }

    function _resolveAddress(deviceLike) {
        if (!deviceLike)
            return "";
        if (typeof deviceLike === "string")
            return deviceLike;
        return String(deviceLike.address || "");
    }

    function connectDevice(device) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("connect");

        let handled = false;
        if (nativeDev && typeof nativeDev.connect === "function") {
            try {
                nativeDev.connect();
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] native connect() exception, attempting bluetoothctl fallback:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", "connect", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("connect");
        } else {
            root.lastError = qsTr("Device address or adapter not available for connection");
            root.operationFailed("connect", root.lastError);
        }
    }

    function disconnectDevice(device) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("disconnect");

        let handled = false;
        if (nativeDev && typeof nativeDev.disconnect === "function") {
            try {
                nativeDev.disconnect();
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] native disconnect() exception, attempting bluetoothctl fallback:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", "disconnect", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("disconnect");
        } else {
            root.lastError = qsTr("Device address or adapter not available for disconnect");
            root.operationFailed("disconnect", root.lastError);
        }
    }

    function pairDevice(device) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("pair");

        let handled = false;
        if (nativeDev && typeof nativeDev.pair === "function") {
            try {
                nativeDev.pair();
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] native pair() exception, attempting bluetoothctl fallback:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", "pair", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("pair");
        } else {
            root.lastError = qsTr("Device address not available for pairing");
            root.operationFailed("pair", root.lastError);
        }
    }

    function forgetDevice(device) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("forget");

        let handled = false;
        if (nativeDev && typeof nativeDev.forget === "function") {
            try {
                nativeDev.forget();
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] native forget() exception, attempting bluetoothctl fallback:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", "remove", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("forget");
        } else {
            root.lastError = qsTr("Device address not available for removal");
            root.operationFailed("forget", root.lastError);
        }
    }

    function setDeviceTrusted(device, trusted) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("set-trusted");

        let handled = false;
        if (nativeDev && nativeDev.trusted !== undefined) {
            try {
                nativeDev.trusted = !!trusted;
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] setting nativeDev.trusted exception:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", trusted ? "trust" : "untrust", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("set-trusted");
        } else {
            root.lastError = qsTr("Device not found to update trust state");
            root.operationFailed("set-trusted", root.lastError);
        }
    }

    function setDeviceWakeAllowed(device, wake) {
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("set-wake-allowed");

        if (nativeDev && nativeDev.wakeAllowed !== undefined) {
            nativeDev.wakeAllowed = !!wake;
            root.operationSucceeded("set-wake-allowed");
        } else {
            root.lastError = qsTr("Device does not support wake configuration");
            root.operationFailed("set-wake-allowed", root.lastError);
        }
    }

    function setDeviceBlocked(device, blocked) {
        const address = root._resolveAddress(device);
        const nativeDev = root._resolveDevice(device);
        root.lastError = "";
        root.operationStarted("set-blocked");

        let handled = false;
        if (nativeDev && nativeDev.blocked !== undefined) {
            try {
                nativeDev.blocked = !!blocked;
                handled = true;
            } catch (e) {
                console.warn("[BluetoothService] setting nativeDev.blocked exception:", e);
            }
        }

        if (!handled && address.length > 0) {
            Quickshell.execDetached(["bluetoothctl", blocked ? "block" : "unblock", address]);
            handled = true;
        }

        if (handled) {
            root.operationSucceeded("set-blocked");
        } else {
            root.lastError = qsTr("Device not found to update block state");
            root.operationFailed("set-blocked", root.lastError);
        }
    }
}
