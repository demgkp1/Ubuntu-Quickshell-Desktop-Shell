import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Components
import qs.Services
import qs.Widgets.common

PanelWindow {
    id: root

    required property var targetScreen
    readonly property real buttonSize: Math.max(72, Math.min(128, (width - 112 - actionRow.spacing * 5) / 6))

    property int selectedIndex: 0

    readonly property bool isTargetScreen: {
        if (!PowerMenuService.targetScreenName || PowerMenuService.targetScreenName === "")
            return targetScreen === (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
        return targetScreen && targetScreen.name === PowerMenuService.targetScreenName;
    }

    readonly property bool isActive: PowerMenuService.active && isTargetScreen

    readonly property var actions: [
        {
            "action": "lock",
            "icon": "lock",
            "label": qsTr("Lock screen")
        },
        {
            "action": "logout",
            "icon": "logout",
            "label": qsTr("Log out")
        },
        {
            "action": "suspend",
            "icon": "bedtime",
            "label": qsTr("Suspend")
        },
        {
            "action": "poweroff",
            "icon": "power_settings_new",
            "label": qsTr("Shut down")
        },
        {
            "action": "hibernate",
            "icon": "mode_night",
            "label": qsTr("Hibernate")
        },
        {
            "action": "reboot",
            "icon": "restart_alt",
            "label": qsTr("Restart")
        }
    ]

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    property int x: targetScreen && targetScreen.geometry ? targetScreen.geometry.x : 0
    property int y: targetScreen && targetScreen.geometry ? targetScreen.geometry.y : 0
    implicitWidth: targetScreen && targetScreen.geometry ? targetScreen.geometry.width : 1920
    implicitHeight: targetScreen && targetScreen.geometry ? targetScreen.geometry.height : 1080

    // Persistent mapping under Mutter X11 to avoid compositor recreate/unmap failures.
    visible: true
    color: "transparent"
    exclusiveZone: 0

    // WlrLayershell attached properties break window attachment under Mutter XCB.
    // WlrLayershell.namespace: "clavis-shell-power-menu"
    // WlrLayershell.layer: WlrLayer.Overlay
    // WlrLayershell.exclusionMode: ExclusionMode.Ignore
    // WlrLayershell.keyboardFocus: root.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Item {
        id: emptyMaskRegion
        width: 0
        height: 0
    }

    Item {
        id: fullInteractionRegion
        anchors.fill: parent
    }

    mask: Region {
        item: root.isActive ? fullInteractionRegion : emptyMaskRegion
    }

    Connections {
        target: root
        function onIsActiveChanged() {
            if (root.isActive) {
                root.selectedIndex = 0;
                Qt.callLater(() => {
                    interactionArea.forceActiveFocus(Qt.OtherFocusReason);
                });
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: root.isActive
        onActivated: PowerMenuService.close()
    }

    Item {
        id: interactionArea

        anchors.fill: parent
        focus: root.isActive
        opacity: root.isActive ? 1.0 : 0.0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.expressiveFastEffects.duration
                easing.type: Appearance.animation.expressiveFastEffects.type
                easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
            }
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_Up:
                root.selectedIndex = (root.selectedIndex + root.actions.length - 1) % root.actions.length;
                break;
            case Qt.Key_Right:
            case Qt.Key_Down:
                root.selectedIndex = (root.selectedIndex + 1) % root.actions.length;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (!event.isAutoRepeat && root.selectedIndex >= 0 && root.selectedIndex < root.actions.length)
                    PowerMenuService.trigger(root.actions[root.selectedIndex].action);
                break;
            case Qt.Key_Escape:
                PowerMenuService.close();
                break;
            case Qt.Key_L:
                PowerMenuService.trigger("lock");
                break;
            case Qt.Key_E:
                PowerMenuService.trigger("logout");
                break;
            case Qt.Key_U:
                PowerMenuService.trigger("suspend");
                break;
            case Qt.Key_S:
                PowerMenuService.trigger("poweroff");
                break;
            case Qt.Key_H:
                PowerMenuService.trigger("hibernate");
                break;
            case Qt.Key_R:
                PowerMenuService.trigger("reboot");
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // Dim backdrop / scrim
        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                onClicked: PowerMenuService.close()
            }
        }

        Rectangle {
            id: menuBackground

            anchors.centerIn: parent
            width: actionRow.implicitWidth + 56
            height: actionRow.implicitHeight + 56
            radius: Appearance.rounding.extraLarge
            color: BlurService.backgroundColor(Appearance.colors.colLayer0)

            scale: root.isActive ? 1.0 : 0.95
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.animation.expressiveFastEffects.duration
                    easing.type: Appearance.animation.expressiveFastEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
            }

            RowLayout {
                id: actionRow

                anchors.centerIn: parent
                spacing: 16

                Repeater {
                    id: actionRepeater
                    model: root.actions

                    delegate: Rectangle {
                        id: actionButton

                        required property int index
                        required property var modelData
                        readonly property bool selected: root.selectedIndex === index

                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label
                        Accessible.focused: selected && interactionArea.activeFocus
                        Accessible.onPressAction: PowerMenuService.trigger(modelData.action)

                        Layout.preferredWidth: root.buttonSize
                        Layout.preferredHeight: root.buttonSize
                        radius: Appearance.rounding.large
                        color: actionMouse.pressed ? Appearance.colors.colPrimaryActive : (
                                                         actionButton.selected
                                                         ? Appearance.colors.colPrimaryHover :
                                                           Appearance.colors.colLayer1)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 60

                                MaterialSymbol {
                                    id: actionIcon

                                    anchors.centerIn: parent
                                    text: actionButton.modelData.icon
                                    iconSize: 54
                                    fill: 0
                                    color: actionButton.selected ? Appearance.colors.colOnPrimary :
                                                                   Appearance.colors.colOnLayer1
                                    scale: actionMouse.pressed ? 50 / 54 : (actionButton.selected ? 1 : 44
                                                                                                    / 54)
                                    transformOrigin: Item.Center
                                    smooth: true
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.mipmap: true

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Appearance.animation.expressiveSlowEffects.duration
                                            easing.type: Appearance.animation.expressiveSlowEffects.type
                                            easing.bezierCurve:
                                                Appearance.animation.expressiveSlowEffects.bezierCurve
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Appearance.animation.expressiveFastEffects.duration
                                            easing.type: Appearance.animation.expressiveFastEffects.type
                                            easing.bezierCurve:
                                                Appearance.animation.expressiveFastEffects.bezierCurve
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: actionButton.modelData.label
                                color: actionButton.selected ? Appearance.colors.colOnPrimary :
                                                               Appearance.colors.colOnLayer1
                                font.family: Fonts.ui
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: actionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.ArrowCursor
                            onEntered: root.selectedIndex = actionButton.index
                            onClicked: PowerMenuService.trigger(actionButton.modelData.action)
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Appearance.animation.expressiveFastEffects.duration
                                easing.type: Appearance.animation.expressiveFastEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
                            }
                        }
                    }
                }
            }
        }

        CompositorBlurRegion {
            targetWindow: root
            backgroundItem: menuBackground
            radius: menuBackground.radius
        }
    }
}
