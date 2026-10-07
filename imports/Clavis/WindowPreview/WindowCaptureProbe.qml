import QtQuick

QtObject {
    id: root

    property var windows: []
    property bool ready: false
    property bool supported: false
    property bool active: false
    property string error: ""
    property string identifier: ""
    property int frameCount: 0
    property real firstFrameMs: 0
    property int maximumDimension: 256
    property int frameInterval: 100
    property size sourceSize: Qt.size(0, 0)

    signal windowsChanged()
    signal changed()
    signal limitsChanged()

    function open(displayName) {}
    function start(identifier) {}
    function stop() {}
    function close() {}
}
