import QtQuick
import "../common"

Item {
    id: root

    default property alias leading: leadingRow.data
    property alias center: centerSlot.data
    property alias trailing: trailingRow.data

    property int paddingHorizontal: 16
    property int topMargin: 4

    implicitHeight: 44

    // 1. Leading Section (Left Pinned)
    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: root.paddingHorizontal
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        spacing: 8
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
        spacing: 8
    }
}
