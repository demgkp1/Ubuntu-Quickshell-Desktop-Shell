import QtQuick

QtObject {
    id: root

    property bool supported: false
    property int captureCount: 0

    signal statusChanged()
    signal capturesChanged()
    signal snapshotFinished(string identifier)

    function open(displayName) {}
    function close() {}
    function setWindows(live, minimized) {}
    function setTargets(consumer, identifiers) {}
    function release(consumer) {}
    function captureFor(identifier) { return null; }
    function frameFor(identifier) { return null; }
    function prefetch(identifier) {}
    function requestSnapshot(identifier) {}
}
