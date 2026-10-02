import QtQuick
import "../theme"

/**
 * TopBarLayout - 3-Section Split Layout (Leading / Center / Trailing)
 *
 * Implements standard desktop shell 3-section layout:
 * - Leading: Anchored to the left with safety margin
 * - Center: Floating at the absolute horizontal center
 * - Trailing: Anchored to the right with safety margin
 *
 * Top-aligned to ensure minimal vertical offset.
 */
Item {
    id: root

    default property alias leading: leadingRow.data
    property alias center: centerSlot.data
    property alias trailing: trailingRow.data

    property int paddingHorizontal: Theme.sizes.spacingLg
    property int topMargin: 3

    implicitHeight: Theme.sizes.topBarHeight

    // 1. Leading Section (Left Pinned)
    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: root.paddingHorizontal
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        spacing: Theme.sizes.spacingSm
    }

    // 2. Center Section (Screen Center)
    Item {
        id: centerSlot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    // 3. Trailing Section (Right Pinned)
    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.rightMargin: root.paddingHorizontal
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        spacing: Theme.sizes.spacingSm
    }
}
