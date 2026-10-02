import QtQuick
import Quickshell
import "../common"

PanelWindow {
    id: root

    color: "transparent"

    property var targetScreen: null
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 44
    implicitHeight: 44

    default property alias content: contentContainer.data

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
