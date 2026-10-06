pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool available: true
    property bool enabled: true
    property bool connected: false
    property string connectedName: ""

    property bool busy: false
    property bool discovering: false
    property bool scanning: false
    property bool discoverable: false
    property bool pairable: false
    property string lastError: ""

    property var adapters: []
    property var devices: []
    property var connectedDevices: []
    property var pairedDevices: []
    property var availableDevices: []

    signal operationStarted(string operation)
    signal operationSucceeded(string operation)
    signal operationFailed(string operation, string message)

    function toggle() {
        enabled = !enabled;
    }

    function setBluetoothEnabled(v) {
        enabled = !!v;
    }

    function setAdapterEnabled(v) {
        enabled = !!v;
    }

    function acquireDiscovery(owner) {}
    function releaseDiscovery(owner) {}
    function connectDevice(device) {}
    function disconnectDevice(device) {}
    function pairDevice(device) {}
    function forgetDevice(device) {}
    function setDeviceTrusted(device, trusted) {}
    function setDeviceWakeAllowed(device, wake) {}
    function setDiscoverable(v) { discoverable = !!v; }
    function setPairable(v) { pairable = !!v; }
}
