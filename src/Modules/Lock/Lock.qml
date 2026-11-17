import QtQuick
import Quickshell
import qs.Common
import qs.Services
Scope {
    id: root
    readonly property bool active: GnomeSession.desktop.locked === true
    readonly property bool secure: active && !!GnomeSession.desktop.lockAvailable
    property bool capturePending: false
    property int requestId: -1
    signal unlocked
    signal secured
    Binding { target: WindowPreviewService; property: "suspended"; value: root.active }
    Binding { target: WidgetState; property: "sessionLocked"; value: root.active }
    function open() {
        if (active) return "ALREADY_LOCKED";
        if (!GnomeSession.desktop.lockAvailable) return "UNAVAILABLE";
        requestId = GnomeSession.request("lock", {});
        capturePending = requestId > 0;
        deadline.restart();
        return capturePending ? "PENDING" : "UNAVAILABLE";
    }
    function isLocked() { return active; }
    onActiveChanged: {
        capturePending = false;
        deadline.stop();
        if (active) { WidgetState.closeAllPopups(); secured(); }
        else unlocked();
    }
    Timer { id: deadline; interval: 3000; onTriggered: root.capturePending = false }
    Connections {
        target: GnomeSession
        function onOperationFinished(id, accepted, error) {
            if (id === root.requestId && !accepted) root.capturePending = false;
        }
    }
    // No custom lock windows, PAM form, screenshot or unlock IPC on GNOME.
}
