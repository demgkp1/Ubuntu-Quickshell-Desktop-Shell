import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    property var lock: null
    property var context: null
    property var snapshotProvider: null
    property var screen: null
    // Freeze the selection for this lock session.
    property string style: "default"

    Loader {
        anchors.fill: parent
        sourceComponent: root.style === "caelestia" ? caelestia : defaultStyle
    }

    Component {
        id: caelestia
        CaelestiaLock {
            lock: root.lock
            context: root.context
            snapshotProvider: root.snapshotProvider
            screen: root.screen
        }
    }

    Component {
        id: defaultStyle
        DefaultLock {
            snapshotProvider: root.snapshotProvider
            lock: root.lock
            context: root.context
            screen: root.screen
        }
    }
}
