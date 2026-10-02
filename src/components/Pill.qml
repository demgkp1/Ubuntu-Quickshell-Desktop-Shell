import QtQuick
import "../theme"

/**
 * Pill - Frosted Glass Capsule Component
 *
 * Implements a modern frosted glass aesthetic with translucent backing,
 * a delicate mint glass rim, soft ambient elevation shadow, and smooth
 * hover illumination.
 */
Item {
    id: root

    property color baseColor: Theme.colors.glassBackground
    property color hoverColor: Theme.colors.glassBackgroundHover
    property color borderColor: Theme.colors.glassBorder
    property color borderHoverColor: Theme.colors.glassBorderHover

    property int paddingHorizontal: Theme.sizes.pillPaddingHorizontal
    property int paddingVertical: Theme.sizes.pillPaddingVertical
    property int radius: Theme.sizes.radiusPill

    property bool hoverEnabled: true
    readonly property bool isHovered: mouseArea.containsMouse

    signal clicked()
    signal rightClicked()

    implicitHeight: Theme.sizes.pillHeight
    implicitWidth: contentLayout.implicitWidth + (paddingHorizontal * 2)

    default property alias content: contentLayout.data

    // 1. Ambient Drop Shadow (elevation layer)
    Rectangle {
        id: shadowLayer
        anchors.fill: surface
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: root.radius
        color: Theme.colors.glassShadow
        opacity: root.isHovered ? 0.6 : 0.4
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animations.fast
                easing.type: Theme.animations.easeOut
            }
        }
    }

    // 2. Frosted Glass Surface
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.isHovered && root.hoverEnabled ? root.hoverColor : root.baseColor
        border.color: root.isHovered && root.hoverEnabled ? root.borderHoverColor : root.borderColor
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.animations.fast
                easing.type: Theme.animations.easeOut
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animations.fast
            }
        }
    }

    // 3. Mouse Interaction Area (Pill background hover & click)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else {
                root.clicked();
            }
        }
    }

    // 4. Inner Content Container (Rendered on top of background mouseArea)
    Row {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Theme.sizes.spacingSm
    }
}
