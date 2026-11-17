pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root
    readonly property string forcedBackend: String(Quickshell.env("CLAVIS_SESSION_BACKEND") || "").trim().toLowerCase()
    readonly property string desktopEnv: String(Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    readonly property string sessionEnv: String(Quickshell.env("DESKTOP_SESSION") || "").toLowerCase()
    readonly property string niriSocketEnv: String(Quickshell.env("NIRI_SOCKET") || "").trim()
    readonly property bool isNiriSession: forcedBackend === "niri"
        || (forcedBackend !== "gnome" && forcedBackend !== "disabled"
            && (niriSocketEnv !== "" || desktopEnv.includes("niri") || sessionEnv.includes("niri")))
    readonly property bool bridgeEnabled: forcedBackend !== "disabled" && !isNiriSession

    property string state: bridgeEnabled ? "pending" : "unavailable"
    property string lastError: ""
    property var snapshot: ({})
    property var desktop: ({})
    property string helperError: ""
    property int generation: 0
    property int nextRequest: 0
    signal operationFinished(request: int, accepted: bool, error: string)
    readonly property bool connected: state === "ready"
    readonly property bool helperRunning: helper.running

    function request(action, arguments) {
        if (!helper.running) {
            root.lastError = qsTr("GNOME session bridge is not running");
            return -1;
        }
        const id = ++root.nextRequest;
        helper.write(JSON.stringify(Object.assign({}, arguments || {}, {action: action, id: id})) + "\n");
        return id;
    }

    Process {
        id: helper
        // Ubuntu Gio is isolated from the Nix Qt ABI and GIO modules.
        command: ["/usr/bin/env", "-u", "GI_TYPELIB_PATH", "-u", "LD_LIBRARY_PATH", "-u", "GIO_EXTRA_MODULES",
                  "-u", "PYTHONPATH", "-u", "PYTHONHOME",
                  "GSETTINGS_SCHEMA_DIR=/usr/share/glib-2.0/schemas",
                  "/usr/bin/python3", Paths.systemScriptsDir + "/gnome_bridge.py"]
        running: root.bridgeEnabled
        stdinEnabled: true
        onStarted: root.helperError = ""
        stderr: SplitParser { onRead: line => root.helperError = String(line) }
        stdout: SplitParser {
            onRead: line => {
                try {
                    const message = JSON.parse(line);
                    if (message.event === "compositor") {
                        root.state = message.state;
                        root.lastError = message.error || "";
                        root.snapshot = message.state === "ready" ? message.data : ({});
                        root.generation++;
                    } else if (message.event === "desktop") {
                        root.desktop = message;
                    } else if (message.event === "result") {
                        if (!message.accepted) root.lastError = message.error || qsTr("Operation failed");
                        root.operationFinished(message.id || 0, !!message.accepted, message.error || "");
                    }
                } catch (error) {
                    root.state = "unavailable";
                    root.snapshot = ({});
                    root.lastError = String(error);
                }
            }
        }
        onExited: (code, status) => {
            root.state = "unavailable";
            root.snapshot = ({});
            root.desktop = ({});
            root.lastError = root.helperError || qsTr("GNOME session helper exited (%1)").arg(code);
            if (root.bridgeEnabled)
                retry.restart();
        }
    }
    Timer {
        id: retry
        interval: 3000
        onTriggered: {
            if (root.bridgeEnabled) helper.running = true;
        }
    }
}
