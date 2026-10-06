pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool active: false
    property bool presentationActive: false
    property bool frozen: false
    property string phase: "idle"

    function requestCancel() {
        active = false;
    }
}
