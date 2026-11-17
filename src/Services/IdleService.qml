pragma Singleton
import QtQuick
import Quickshell
import qs.Services
Singleton {
    id: root
    readonly property bool inhibited: !!GnomeSession.desktop.inhibited
    readonly property bool policyReady: !!GnomeSession.desktop.idleAvailable
    readonly property bool policyEnabled: policyReady && Number(GnomeSession.desktop.idleDelay) > 0
    property bool busy: false
    property int requestId: -1
    readonly property real dimFraction: 0
    property string lastError: ""
    readonly property var stages: []
    readonly property bool supportsCustomStages: false
    function toggleInhibited() { return setInhibited(!inhibited); }
    function setInhibited(value) {
        if (!policyReady || busy) return false;
        requestId = GnomeSession.request("inhibit", {value: !!value});
        busy = requestId > 0;
        return busy;
    }
    function unsupported() {
        lastError = qsTr("GNOME owns idle dimming, blanking and locking. Configure these in GNOME Settings → Power; Clavis custom idle stages are unavailable.");
        return supportsCustomStages;
    }
    function setPolicyEnabled(value) { return unsupported(); }
    function setDimFraction(value) { return unsupported(); }
    function configureStage(id, config) { return unsupported(); }
    Connections {
        target: GnomeSession
        function onOperationFinished(id, accepted, error) {
            if (id !== root.requestId) return;
            root.busy = false;
            root.lastError = accepted ? "" : error;
        }
        function onDesktopChanged() { if (!root.policyReady) root.busy = false; }
    }
}
