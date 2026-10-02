pragma Singleton
import QtQuick
import Quickshell

/**
 * TimeService - Centralized Time & Date Provider
 *
 * Provides synchronized time updates across all topbar pills and widgets
 * without redundant polling timers.
 */
Singleton {
    id: root

    property var currentTime: new Date()

    readonly property string formattedTime: {
        var h = String(currentTime.getHours()).padStart(2, '0');
        var m = String(currentTime.getMinutes()).padStart(2, '0');
        return h + ":" + m;
    }

    readonly property string formattedSeconds: {
        return String(currentTime.getSeconds()).padStart(2, '0');
    }

    readonly property string formattedDate: {
        return currentTime.toLocaleDateString(Qt.locale(), "ddd, MMM d");
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }
}
