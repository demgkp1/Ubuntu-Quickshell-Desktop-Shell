import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../common"

Slider {
    id: root

    property color highlightColor: Appearance.colors.colPrimary
    property color trackColor: Appearance.colors.colLayer2
    property color handleColor: Appearance.colors.colPrimary
    property real trackHeight: 36
    property real trackRadius: 18
    property real handleWidth: pressed ? 4 : 4
    property real handleHeight: trackHeight + 4
    property real handleGap: 4

    readonly property real effectiveDraggingWidth: width - leftPadding - rightPadding

    from: 0
    to: 1
    implicitHeight: Math.max(trackHeight, handleHeight)
    implicitWidth: 200
    hoverEnabled: true
    leftPadding: 2
    rightPadding: 2
    Layout.fillWidth: true

    Behavior on value {
        SmoothedAnimation {
            velocity: 850
        }
    }

    // Preserve native arrow cursor: NEVER morph to hand cursor!
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onPressed: mouse => mouse.accepted = false
    }

    background: Item {
        id: background
        anchors.verticalCenter: parent.verticalCenter
        width: root.width
        height: root.trackHeight

        readonly property real splitX: root.leftPadding + root.visualPosition * root.effectiveDraggingWidth

        // Active / Left Portion
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, background.splitX - root.handleGap / 2)
            color: root.highlightColor
            topLeftRadius: root.trackRadius
            bottomLeftRadius: root.trackRadius
            topRightRadius: 4
            bottomRightRadius: 4
        }

        // Inactive / Right Portion
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Math.min(parent.width, background.splitX + root.handleGap / 2)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: root.trackColor
            topRightRadius: root.trackRadius
            bottomRightRadius: root.trackRadius
            topLeftRadius: 4
            bottomLeftRadius: 4
        }
    }

    handle: Rectangle {
        id: handle
        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        x: root.leftPadding + root.visualPosition * root.effectiveDraggingWidth - root.handleWidth / 2
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: root.handleColor
        opacity: root.pressed ? 1.0 : 0.85
    }
}
