import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../components"
import "../services"

PanelWindow {
    id: root

    property var targetScreen: null
    screen: targetScreen

    color: "transparent"
    visible: LauncherService.isOpen
    aboveWindows: true
    focusable: true
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: LauncherService.close()
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    // Fullscreen backdrop: clicking outside card dismisses launcher
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: LauncherService.close()
    }

    // Start Menu Card Container
    Item {
        id: cardRoot
        width: 380
        height: 520
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.left: parent.left
        anchors.leftMargin: 16

        // Prevent clicks inside card from bubbling to backdrop
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
        }

        // 1. Ambient Drop Shadow
        Rectangle {
            id: shadow
            anchors.fill: surface
            anchors.margins: -4
            radius: Appearance.rounding.extraLarge + 4
            color: Appearance.colors.colShadow
            opacity: 0.6
            z: -1
        }

        // 2. Frosted Surface
        Rectangle {
            id: surface
            anchors.fill: parent
            radius: Appearance.rounding.extraLarge
            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colLayer0Border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header: Title & Close Hint
                Item {
                    width: parent.width
                    height: 24

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        MaterialSymbol {
                            text: "grid_view"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "应用程序"
                            color: Appearance.colors.colOnSurface
                            font.family: Fonts.ui
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ESC 退出"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Fonts.ui
                        font.pixelSize: 11
                    }
                }

                // Search Bar Input
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 19
                    color: Appearance.colors.colLayer1
                    border.color: searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        MaterialSymbol {
                            text: "search"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 32
                            anchors.verticalCenter: parent.verticalCenter
                            color: Appearance.colors.colOnSurface
                            font.family: Fonts.ui
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                text: "搜索应用程序..."
                                color: Appearance.colors.colOnSurfaceVariant
                                font.family: Fonts.ui
                                font.pixelSize: 13
                                visible: !searchInput.text && !searchInput.inputMethodComposing
                            }

                            Keys.onEscapePressed: {
                                LauncherService.close();
                            }
                        }
                    }
                }

                // Quick Actions Strip
                Row {
                    width: parent.width
                    spacing: 8

                    // 1. GNOME Native Overview Trigger
                    Rectangle {
                        height: 28
                        width: overviewRow.implicitWidth + 20
                        radius: 14
                        color: overviewMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                        border.color: Appearance.colors.colLayer0Border
                        border.width: 1

                        Row {
                            id: overviewRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "dashboard"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "原生概览"
                                color: Appearance.colors.colPrimary
                                font.family: Fonts.ui
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: overviewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: {
                                LauncherService.close();
                                GnomeService.toggleOverview();
                            }
                        }
                    }

                    // 2. Settings
                    Rectangle {
                        height: 28
                        width: settRow.implicitWidth + 20
                        radius: 14
                        color: settMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer1
                        border.color: Appearance.colors.colLayer0Border
                        border.width: 1

                        Row {
                            id: settRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "tune"
                                iconSize: 14
                                color: Appearance.colors.colOnSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "系统设置"
                                color: Appearance.colors.colOnSurface
                                font.family: Fonts.ui
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: settMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: {
                                LauncherService.close();
                                ControlCenterService.openSettings();
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // Filtered Application List
                ListView {
                    id: appList
                    width: parent.width
                    height: 310
                    clip: true
                    spacing: 3

                    model: {
                        var all = DesktopEntries.applications ? DesktopEntries.applications.values : [];
                        var q = searchInput.text.trim().toLowerCase();
                        if (!q) return all;
                        return all.filter(function(app) {
                            var nameMatch = app.name && app.name.toLowerCase().indexOf(q) !== -1;
                            var idMatch = app.id && app.id.toLowerCase().indexOf(q) !== -1;
                            return nameMatch || idMatch;
                        });
                    }

                    delegate: Rectangle {
                        id: itemSurface
                        width: appList.width
                        height: 42
                        radius: 8
                        color: itemMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            IconImage {
                                width: 24
                                height: 24
                                source: Quickshell.iconPath(modelData.icon)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 38
                                spacing: 1

                                Text {
                                    text: modelData.name
                                    color: itemMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
                                    font.family: Fonts.ui
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.genericName || modelData.id
                                    color: Appearance.colors.colOnSurfaceVariant
                                    font.family: Fonts.ui
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                    visible: text.length > 0
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onClicked: {
                                modelData.execute();
                                LauncherService.close();
                            }
                        }
                    }
                }

                // Footer / Status
                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Ubuntu 24.04 LTS"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Fonts.ui
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: (DesktopEntries.applications ? DesktopEntries.applications.values.length : 0) + " 个应用"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: Fonts.ui
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
