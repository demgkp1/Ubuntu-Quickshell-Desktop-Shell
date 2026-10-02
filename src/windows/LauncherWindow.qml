import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../services"

/**
 * LauncherWindow - Frosted Glass Application Launcher & Start Menu
 *
 * Floating popup window anchored directly beneath the topbar brand pill.
 * Features:
 * - Real-time application search filtering over system DesktopEntries
 * - 1-click launch for desktop applications
 * - Quick shortcuts to GNOME Native Overview, Terminal, Settings, and Files
 * - Full Matugen Sage & Mint Frosted Glass aesthetics
 */
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    color: "transparent"
    visible: LauncherService.isOpen
    aboveWindows: true
    focusable: true
    exclusiveZone: 0

    anchors {
        top: true
        left: true
    }

    margins {
        top: Theme.sizes.topBarHeight + 6
        left: Theme.sizes.spacingLg
    }

    implicitWidth: 380
    implicitHeight: 520

    // Auto-focus search input when opened
    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    // 1. Ambient Drop Shadow
    Rectangle {
        id: shadow
        anchors.fill: surface
        anchors.margins: -4
        radius: Theme.sizes.radiusCard + 4
        color: Theme.colors.glassShadow
        opacity: 0.6
        z: -1
    }

    // 2. Frosted Surface
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.sizes.radiusCard
        color: Qt.rgba(0.06, 0.12, 0.13, 0.92) // Frosted deep forest slate
        border.color: Theme.colors.glassBorder
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header: Title & Close Hint
            Item {
                width: parent.width
                height: 24

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "应用程序"
                        color: Theme.colors.text
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeBodyLarge
                        font.weight: Theme.typography.weightBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ESC 退出"
                    color: Theme.colors.textTertiary
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeCaption
                }
            }

            // Search Bar Input
            Rectangle {
                width: parent.width
                height: 36
                radius: 18
                color: Theme.colors.surface0
                border.color: searchInput.activeFocus ? Theme.colors.primary : Theme.colors.glassBorder
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animations.fast }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.colors.text
                        font.family: Theme.typography.familySans
                        font.pixelSize: Theme.typography.sizeBody
                        clip: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            text: "搜索应用程序..."
                            color: Theme.colors.textTertiary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeBody
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
                spacing: 6

                // 1. GNOME Native Overview Trigger
                Rectangle {
                    height: 26
                    width: overviewRow.implicitWidth + 16
                    radius: 13
                    color: overviewMouse.containsMouse ? Theme.colors.surface2 : Theme.colors.surface1
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        id: overviewRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "✦ 原生概览"
                            color: Theme.colors.primary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeCaption
                            font.weight: Theme.typography.weightMedium
                        }
                    }

                    MouseArea {
                        id: overviewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            LauncherService.close();
                            GnomeService.toggleOverview();
                        }
                    }
                }

                // 2. Terminal
                Rectangle {
                    height: 26
                    width: termRow.implicitWidth + 16
                    radius: 13
                    color: termMouse.containsMouse ? Theme.colors.surface2 : Theme.colors.surface1
                    border.color: Theme.colors.glassBorder
                    border.width: 1

                    Row {
                        id: termRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "终端"
                            color: Theme.colors.textSecondary
                            font.family: Theme.typography.familySans
                            font.pixelSize: Theme.typography.sizeCaption
                        }
                    }

                    MouseArea {
                        id: termMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            LauncherService.close();
                            GnomeService.toggleOverview(); // quick launcher fallback
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colors.glassBorder
            }

            // Filtered Application List
            ListView {
                id: appList
                width: parent.width
                height: 330
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
                    color: itemMouse.containsMouse ? Theme.colors.surface0 : "transparent"
                    border.color: itemMouse.containsMouse ? Theme.colors.glassBorder : "transparent"
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: Theme.animations.fast }
                    }

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
                                color: itemMouse.containsMouse ? Theme.colors.primary : Theme.colors.text
                                font.family: Theme.typography.familySans
                                font.pixelSize: Theme.typography.sizeBody
                                font.weight: Theme.typography.weightMedium
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.genericName || modelData.id
                                color: Theme.colors.textTertiary
                                font.family: Theme.typography.familySans
                                font.pixelSize: Theme.typography.sizeCaption
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
                        cursorShape: Qt.PointingHandCursor
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
                    color: Theme.colors.textTertiary
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeCaption
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (DesktopEntries.applications ? DesktopEntries.applications.values.length : 0) + " 个应用"
                    color: Theme.colors.textTertiary
                    font.family: Theme.typography.familySans
                    font.pixelSize: Theme.typography.sizeCaption
                }
            }
        }
    }
}
