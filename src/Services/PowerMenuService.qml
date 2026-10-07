pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property bool active: false
    property string targetScreenName: ""

    signal actionRequested(string action)

    function open(screen) {
        console.log("PowerMenuService.open requested:", screen);
        const resolved = screen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
        WidgetState.closeAllPopups();
        targetScreenName = (resolved && resolved.name) ? String(resolved.name) : "";
        active = true;
        return true;
    }

    function toggle() {
        return active ? close() : open();
    }

    function close() {
        if (!active)
            return false;
        active = false;
        return true;
    }

    function trigger(action) {
        if (!active)
            return false;
        active = false;
        actionRequested(String(action || ""));
        return true;
    }
}
