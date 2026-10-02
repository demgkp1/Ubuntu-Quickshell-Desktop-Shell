pragma Singleton
import QtQuick
import Quickshell

/**
 * LauncherService - State Manager for Desktop Application Launcher
 *
 * Controls the open/closed visibility state and search query filter
 * for the floating start menu / launcher popup.
 */
Singleton {
    id: root

    property bool isOpen: false
    property string searchQuery: ""

    function toggle() {
        isOpen = !isOpen;
        if (!isOpen) {
            searchQuery = "";
        }
    }

    function open() {
        isOpen = true;
    }

    function close() {
        isOpen = false;
        searchQuery = "";
    }
}
