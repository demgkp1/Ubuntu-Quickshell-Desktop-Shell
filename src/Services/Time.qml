pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property double now: Date.now()
    readonly property string day: {
        return Qt.formatDateTime(clock.date, "d");
    }
    readonly property string month: {
        return Qt.formatDateTime(clock.date, "MMM");
    }
    readonly property string hours: {
        return Qt.formatDateTime(clock.date, "hh");
    }
    readonly property string minutes: {
        return Qt.formatDateTime(clock.date, "mm");
    }

    function refreshNow() {
        root.now = Date.now();
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshNow()
    }
}
