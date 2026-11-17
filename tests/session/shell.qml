import QtQuick
import Quickshell
import qs.Services
ShellRoot {
    property bool complete: false
    readonly property string backendState: CompositorBackend.state
    readonly property bool lockInterfaceAvailable: !!GnomeSession.desktop.lockAvailable
    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (lockInterfaceAvailable && backendState !== "pending") {
                console.log("GNOME_QML_STATE " + JSON.stringify({state: backendState,
                    connected: CompositorBackend.connected, windows: CompositorBackend.windows.length,
                    workspaces: CompositorBackend.workspaces.length,
                    locked: GnomeSession.desktop.locked,
                    wallpaper: GnomeSession.desktop.wallpaper}));
                Qt.quit();
            }
        }
    }
    Timer { interval: 3000; running: true; onTriggered: { console.error("Read-only GNOME QML deadline exceeded: " + JSON.stringify({state: CompositorBackend.state, error: GnomeSession.lastError, running: GnomeSession.helperRunning, desktop: GnomeSession.desktop})); Qt.quit(); } }
}
