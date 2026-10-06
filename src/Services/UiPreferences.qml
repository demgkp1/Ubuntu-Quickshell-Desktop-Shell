pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dndEnabled: false
    property bool darkMode: true
    property string language: "en_US"

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }

    function setDndEnabled(val) {
        dndEnabled = !!val;
    }

    function setDarkMode(val) {
        darkMode = !!val;
    }
}
