pragma Singleton
import QtQuick
import Quickshell
import qs.Services

Singleton {
    id: root

    // niri's ext identifier is its decimal IPC window ID. Do not infer this
    // relationship for other compositors or match windows by title/app-id.
    readonly property bool supported: Niri.connected && backend.supported
    readonly property bool connected: Niri.connected && !suspended
    readonly property int captureCount: backend.captureCount
    property bool suspended: false
    property int revision: 0
    property int nextConsumer: 0
    property bool initialized: false
    property var _snapshots: ({})
    property string _lastFocusedId: ""

    function createConsumer() {
        return "dock-preview-" + (++nextConsumer);
    }
    function setTargets(consumer, ids) {
        backend.setTargets(consumer, connected ? ids : []);
    }
    function release(consumer) {
        backend.release(consumer);
    }
    function captureFor(id) {
        return backend.captureFor(String(id));
    }
    function frameFor(id) {
        return connected ? backend.frameFor(String(id)) : null;
    }
    function snapshot(id, callback) {
        if (!connected)
            return false;
        const key = String(id);
        if (_snapshots[key])
            return true;
        _snapshots[key] = {
            generation: Niri.connectionGeneration,
            callback: callback
        };
        backend.requestSnapshot(key);
        return true;
    }
    function syncWindows() {
        if (!initialized || !connected)
            return;
        const windows = Niri.searchWindows("");
        backend.setWindows(windows.map(window => String(window.id)), windows.filter(window
                                                                                    => window.isMinimized).map(
                               window => String(window.id)));
        const focused = windows.find(window => window.isFocused);
        const id = focused ? String(focused.id) : "";
        if (id && id !== _lastFocusedId)
            backend.prefetch(id);
        _lastFocusedId = id;
    }
    function connectBackend() {
        if (!initialized)
            return;
        _snapshots = ({});
        _lastFocusedId = "";
        if (connected) {
            backend.open(Quickshell.env("WAYLAND_DISPLAY"));
            syncWindows();
        } else
            backend.close();
    }
    onConnectedChanged: connectBackend()
    Component.onCompleted: {
        initialized = true;
        connectBackend();
    }
    Component.onDestruction: backend.close()

    QtObject {
        id: backend
        readonly property bool supported: false
        readonly property bool ready: false
        readonly property string error: ""
        readonly property int captureCount: 0
        function setTargets(consumer, ids) {
            return false;
        }
        function release(consumer) {
            return false;
        }
        function captureFor(id) {
            return null;
        }
        function frameFor(id) {
            return null;
        }
        function requestSnapshot(key) {
            return false;
        }
        function setWindows(w, m) {
            return false;
        }
        function prefetch(id) {
            return false;
        }
        function open(display) {
            return false;
        }
        function close() {
            return false;
        }
    }

    Connections {
        target: Niri
        function onWindowsChanged() {
            root.syncWindows();
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.connected && !backend.ready && backend.error !== ""
        onTriggered: root.connectBackend()
    }
}
