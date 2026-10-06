pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property int searchSerial: 0
    property bool visible: false

    function registerSearchAnchor(item) {}
    function unregisterSearchAnchor(item) {}
    function retrySearch() {}

    function open(pageId, preserveSearch) {
        console.log("ControlCenterService.open requested, page:", pageId);
        WidgetState.closeAllPopups();
        visible = true;
        return true;
    }

    function close() {
        visible = false;
        return true;
    }

    function toggle(pageId) {
        if (visible)
            return close();
        return open(pageId);
    }

    function openOrFocus() {
        return open();
    }
}
