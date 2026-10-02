import QtQuick
import "../theme"

/**
 * Pill - Atomic Capsule Surface Component
 *
 * Provides a standardized rounded capsule container with theme-driven
 * background colors, subtle borders, and smooth hover feedback.
 */
Rectangle {
    id: root

    // Theme bindings
    color: isHovered && hoverEnabled ? hoverColor : baseColor
    border.color: isHovered && hoverEnabled ? borderHoverColor : borderColor
    border.width: 1
    radius: Theme.sizes.radiusPill

    property color baseColor: Theme.colors.base
    property color hoverColor: Theme.colors.surface0
    property color borderColor: Theme.colors.borderSubtle
    property color borderHoverColor: Theme.colors.surface1

    property int paddingHorizontal: Theme.sizes.pillPaddingHorizontal
    property int paddingVertical: Theme.sizes.pillPaddingVertical

    property bool hoverEnabled: true
    readonly property bool isHovered: mouseArea.containsMouse

    signal clicked()

    implicitHeight: Theme.sizes.pillHeight
    implicitWidth: contentLayout.implicitWidth + (paddingHorizontal * 2)

    default property alias content: contentLayout.data

    Behavior on color {
        ColorAnimation {
            duration: Theme.animations.fast
            easing.type: Theme.animations.easeOut
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animations.fast
            easing.type: Theme.animations.easeOut
        }
    }

    Row {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Theme.sizes.spacingSm
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        cursorShape: root.hoverEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
