import QtQuick

QtObject {
    id: root

    property bool hasFrame: false
    property size sourceSize: Qt.size(0, 0)

    signal changed()
}
