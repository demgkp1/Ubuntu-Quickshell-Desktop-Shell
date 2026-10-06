pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool inhibited: false
    property bool policyReady: true
    property bool policyEnabled: true
    property bool busy: false
    property real dimFraction: 0.3
    property string lastError: ""
    property var stages: []

    function toggleInhibited() {
        inhibited = !inhibited;
    }

    function setInhibited(v) {
        inhibited = !!v;
    }

    function setPolicyEnabled(v) {
        policyEnabled = !!v;
    }

    function setDimFraction(v) {
        dimFraction = Math.max(0, Math.min(1, v));
    }

    function configureStage(id, config) {}
}
