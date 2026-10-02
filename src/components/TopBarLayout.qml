import QtQuick
import "../theme"

/**
 * TopBarLayout - 3-Section Split Layout (Leading / Center / Trailing)
 *
 * Implements standard desktop shell 3-section layout:
 * - Leading: Anchored to the left (Workspaces, active app)
 * - Center: Floating at the absolute horizontal center (Clock & date)
 * - Trailing: Anchored to the right (Status indicators, quick toggles, power)
 */
Item {
    id: root

    default property alias leading: leadingRow.data
    property alias center: centerSlot.data
    property alias trailing: trailingRow.data

    property int paddingHorizontal: Theme.sizes.spacingLg

    implicitHeight: Theme.sizes.topBarHeight

    // 1. Leading Section (Left Pinned)
    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: root.paddingHorizontal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.sizes.spacingSm
    }

    // 2. Center Section (Screen Center)
    Item {
        id: centerSlot
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    // 3. Trailing Section (Right Pinned)
    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.rightMargin: root.paddingHorizontal
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.sizes.spacingSm
    }
}
