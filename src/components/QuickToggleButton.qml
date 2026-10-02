import QtQuick
import QtQuick.Layouts
import "../common"

Rectangle {
    id: root

    readonly property bool materialQuickToggleButton: true
    property string iconName: "settings"
    property string title: ""
    property string subtitle: ""
    property bool toggled: false
    property bool expanded: false
    property bool available: true
    property real baseHeight: 56
    property real collapsedWidth: 56
    property real expandedWidth: 160

    signal triggered()
    signal altTriggered()

    implicitWidth: expanded ? expandedWidth : collapsedWidth
    implicitHeight: baseHeight
    radius: toggled ? Appearance.rounding.large : (baseHeight / 2)
    clip: true
    enabled: available
    opacity: available ? 1.0 : 0.45

    readonly property color activeBg: mouseArea.pressed 
        ? Appearance.colors.colPrimaryActive 
        : (mouseArea.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary)
    readonly property color inactiveBg: mouseArea.pressed 
        ? Appearance.colors.colLayer2Active 
        : (mouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

    color: toggled ? activeBg : inactiveBg

    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }

    Behavior on radius {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }
    scale: mouseArea.pressed ? 0.96 : 1.0

    // Content for Expanded Button (2-cell)
    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        visible: root.expanded

        // Left Icon Capsule
        Rectangle {
            Layout.preferredWidth: root.baseHeight - 12
            Layout.preferredHeight: root.baseHeight - 12
            radius: (root.baseHeight - 12) / 2
            color: root.toggled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.iconName
                iconSize: 22
                fill: root.toggled ? 1 : 0
                color: root.toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
            }
        }

        // Right Text Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                font.family: Fonts.ui
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.subtitle
                elide: Text.ElideRight
                color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                font.family: Fonts.ui
                font.pixelSize: 11
                opacity: 0.85
            }
        }
    }

    // Content for Collapsed Button (1-cell)
    Item {
        anchors.fill: parent
        visible: !root.expanded

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconName
            iconSize: 24
            fill: root.toggled ? 1 : 0
            color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        }
    }

    // Interaction Area: Native arrow cursor strictly enforced
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.altTriggered();
            } else {
                root.triggered();
            }
        }
    }
}
