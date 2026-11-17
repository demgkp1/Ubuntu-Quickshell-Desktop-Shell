// Only used on the test's private Xvfb/Openbox display; never a user window.
import QtQuick
import QtQuick.Window
import Quickshell
import Clavis.Runtime

ShellRoot {
    Window {
        id: window
        title: "Clavis isolated maximized-window check"
        flags: Qt.Window | Qt.FramlessWindowHint
        width: 640
        height: 480
        visible: true
        visibility: Window.Maximized
        color: "#34506a"
        property bool settled: false
        function report() {
            const actual = observer.inspect();
            if (!settled || actual.state !== "Ready" || !actual.visible || visibility !== Window.Maximized) return;
            console.log("MAXIMIZED_WINDOW " + JSON.stringify(actual));
            Qt.quit();
        }
        PanelReservation {
            id: observer
            target: window.contentItem
            onObservedChanged: window.report()
        }
        Timer {
            interval: 800
            running: true
            onTriggered: { window.settled = true; window.report(); }
        }
        Timer {
            interval: 3500
            running: true
            onTriggered: {
                console.error("Native maximized-window readback deadline exceeded");
                Qt.exit(2);
            }
        }
    }
}
