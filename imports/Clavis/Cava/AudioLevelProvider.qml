import QtQuick

Item {
    id: root

    property bool active: false
    property string sourceNodeName: ""
    property bool captureSink: false
    property string errorString: ""
    property real level: 0.0
    property var values: []
    property bool available: true
    property real visualAmplitude: 0.0
    property double visualTimestampMs: 0
}
