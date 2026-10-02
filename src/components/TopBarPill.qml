import QtQuick
import "../common"

Item {
    id: root

    property color baseColor: Appearance.colors.colLayer0
    property color hoverColor: Appearance.colors.colLayer1Hover
    property color borderColor: Appearance.colors.colLayer0Border
    property color borderHoverColor: Appearance.colors.colPrimary

    property int paddingHorizontal: 14
    property int paddingVertical: 6
    property real pillHeight: 34
    property real radius: pillHeight / 2

    property bool hoverEnabled: true
    readonly property bool isHovered: mouseArea.containsMouse

    signal clicked()
    signal rightClicked()

    implicitHeight: pillHeight
    implicitWidth: contentLayout.implicitWidth + (paddingHorizontal * 2)

    default property alias content: contentLayout.data

    // 1. Ambient Elevation Shadow
    Rectangle {
        id: shadowLayer
        anchors.fill: surface
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: root.radius
        color: Appearance.colors.colShadow
        opacity: root.isHovered ? 0.7 : 0.45
        z: -1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    // 2. Frosted Capsule Surface
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.isHovered && root.hoverEnabled ? root.hoverColor : root.baseColor
        border.color: root.isHovered && root.hoverEnabled ? root.borderHoverColor : root.borderColor
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 180 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 180 }
        }
    }

    // 3. Mouse Area - Native cursor strictly enforced
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.ArrowCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else {
                root.clicked();
            }
        }
    }

    // 4. Content Container
    Row {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 8
    }
}
