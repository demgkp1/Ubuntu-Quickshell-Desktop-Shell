import QtQuick
import Quickshell
import Clavis.Runtime
import qs.Common
import qs.Services

PanelWindow {
    id: root

    required property var targetScreen
    required property string corner
    property string action: "disabled"
    property bool locked: false

    readonly property bool active: !locked && action !== "disabled" && action !== ""
    readonly property bool isTop: corner === "top-left" || corner === "top-right"
    readonly property bool isLeft: corner === "top-left" || corner === "bottom-left"
    readonly property int cornerSize: Metrics.hotCornerSize

    screen: targetScreen
    implicitWidth: cornerSize
    implicitHeight: cornerSize
    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    PanelReservation { target: root.contentItem; placement: root.corner }

    anchors {
        top: root.isTop
        bottom: !root.isTop
        left: root.isLeft
        right: !root.isLeft
    }

    Item {
        id: emptyMaskRegion
        width: 0
        height: 0
    }

    Item {
        id: fullInteractionRegion
        anchors.fill: parent
    }

    mask: Region {
        item: root.active ? fullInteractionRegion : emptyMaskRegion
    }

    signal triggered(string action, string screenName)

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: root.active
        acceptedButtons: Qt.NoButton

        onEntered: {
            if (root.active) {
                dwellTimer.restart();
            }
        }

        onExited: {
            dwellTimer.stop();
        }
    }

    Timer {
        id: dwellTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (root.active) {
                const screenName = root.targetScreen ? root.targetScreen.name : "";
                console.log("[HotCorners] Triggered:", root.corner, "->", root.action, "on", screenName);
                root.triggered(root.action, screenName);
            }
        }
    }
}
