pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string systemThemeName: "Yaru"
    property int revision: 0
    property string currentTheme: "Yaru"

    function setThemeName(name) {
        currentTheme = name;
        revision += 1;
    }
}
