pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property var windows: []
    property var ayatanaItems: []
    property bool ready: false

    signal notificationReceived(var notif)

    readonly property string helperScript: Paths.scriptsDir + "/x11_desktop_helper.py"

    function searchWindows(query) {
        if (!query)
            return root.windows;
        const q = String(query).toLowerCase();
        return root.windows.filter(w => {
            return (w.title && w.title.toLowerCase().includes(q)) ||
                   (w.appId && w.appId.toLowerCase().includes(q));
        });
    }

    function windowById(id) {
        const numId = Number(id);
        return root.windows.find(w => Number(w.id) === numId) || null;
    }

    function activateWindow(id) {
        if (!id)
            return false;
        helperProc.write("activate " + String(id) + "\n");
        return true;
    }

    function minimizeWindow(id) {
        if (!id)
            return false;
        helperProc.write("minimize " + String(id) + "\n");
        return true;
    }

    function closeWindow(id) {
        if (!id)
            return false;
        helperProc.write("close " + String(id) + "\n");
        return true;
    }

    function stripDecorations(id) {
        if (!id)
            return false;
        helperProc.write("strip " + String(id) + "\n");
        return true;
    }

    function activateAyatana(bus, path) {
        if (!bus || !path)
            return false;
        helperProc.write("ayatana_activate " + String(bus) + " " + String(path) + "\n");
        return true;
    }

    function refresh() {
        helperProc.write("refresh\n");
    }

    Process {
        id: helperProc
        command: ["python3", root.helperScript, "daemon"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line)
                    return;
                try {
                    const msg = JSON.parse(line);
                    if (msg.event === "windows" && Array.isArray(msg.data)) {
                        root.windows = msg.data;
                        root.ready = true;
                    } else if (msg.event === "ayatana" && Array.isArray(msg.data)) {
                        root.ayatanaItems = msg.data;
                    } else if (msg.event === "notification" && msg.data) {
                        root.notificationReceived(msg.data);
                    }
                } catch (e) {
                    // Ignore non-json or partial lines
                }
            }
        }
    }
}
