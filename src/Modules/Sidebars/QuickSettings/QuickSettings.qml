import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services
import qs.Widgets.common

Item {
    id: root

    property var screen: null
    property bool foreground: false
    property string displayedView: ""
    readonly property string activeView: {
        switch (WidgetState.quickSettingsView) {
        case "network":
        case "bluetooth":
        case "idle":
        case "audio":
        case "microphone":
        case "night":
        case "window-opacity":
        case "settings":
            return WidgetState.quickSettingsView;
        default:
            return "settings";
        }
    }
    readonly property var activeViewLoader: activeView === "network" ? networkLoader : activeView
                                                                       === "bluetooth" ? bluetoothLoader :
                                                                                         activeView
                                                                                         === "idle"
                                                                                         ? idleLoader :
                                                                                           activeView
                                                                                           === "audio"
                                                                                           ? audioLoader :
                                                                                             activeView
                                                                                             === "microphone"
                                                                                             ? microphoneLoader :
                                                                                               activeView
                                                                                               === "night"
                                                                                               ? nightLoader :
                                                                                                 activeView
                                                                                                 === "window-opacity"
                                                                                                 ? windowOpacityLoader :
                                                                                                   settingsLoader
    readonly property bool readyForPresentation: activeViewLoader.active && activeViewLoader.status
                                                 === Loader.Ready && activeViewLoader.item !== null
                                                 && displayedView === activeView

    function syncDisplayedView() {
        if (activeViewLoader.active && activeViewLoader.status === Loader.Ready && activeViewLoader.item
                !== null) {
            displayedView = activeView;
        }
    }

    Component.onCompleted: syncDisplayedView()
    onActiveViewChanged: syncDisplayedView()

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "network"
        transitionsEnabled: root.foreground

        Loader {
            id: networkLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "network" || loadedOnce
            asynchronous: true
            sourceComponent: networkComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "bluetooth"
        transitionsEnabled: root.foreground

        Loader {
            id: bluetoothLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "bluetooth" || loadedOnce
            asynchronous: true
            sourceComponent: bluetoothComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "idle"
        transitionsEnabled: root.foreground

        Loader {
            id: idleLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "idle" || loadedOnce
            asynchronous: true
            sourceComponent: idleComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "audio"
        transitionsEnabled: root.foreground

        Loader {
            id: audioLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "audio" || loadedOnce
            asynchronous: true
            sourceComponent: audioComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "microphone"
        transitionsEnabled: root.foreground

        Loader {
            id: microphoneLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "microphone" || loadedOnce
            asynchronous: true
            sourceComponent: microphoneComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "night"
        transitionsEnabled: root.foreground

        Loader {
            id: nightLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "night" || loadedOnce
            asynchronous: true
            sourceComponent: nightComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "window-opacity"
        transitionsEnabled: root.foreground

        Loader {
            id: windowOpacityLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "window-opacity" || loadedOnce
            asynchronous: true
            sourceComponent: windowOpacityComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    PageTransitionLayer {
        anchors.fill: parent
        active: root.displayedView === "settings"
        hubPage: true
        transitionsEnabled: root.foreground

        Loader {
            id: settingsLoader

            property bool loadedOnce: false

            anchors.fill: parent
            active: root.activeView === "settings" || loadedOnce
            asynchronous: true
            sourceComponent: settingsComponent
            onLoaded: {
                loadedOnce = true;
                root.syncDisplayedView();
            }
        }
    }

    Component {
        id: networkComponent

        NetworkContent {
            foreground: root.foreground && root.activeView === "network"
        }
    }

    Component {
        id: bluetoothComponent

        BluetoothContent {
            foreground: root.foreground && root.activeView === "bluetooth"
        }
    }

    Component {
        id: idleComponent

        IdleContent {
            foreground: root.foreground && root.activeView === "idle"
        }
    }

    Component {
        id: audioComponent

        AudioContent {
            foreground: root.foreground && root.activeView === "audio"
        }
    }

    Component {
        id: microphoneComponent

        MicrophoneContent {
            foreground: root.foreground && root.activeView === "microphone"
        }
    }

    Component {
        id: nightComponent

        NightModeContent {}
    }

    component OpacitySliderRow: ColumnLayout {
        id: sliderRow

        property string title: ""
        property string materialSymbol: "opacity"
        property real opacityValue: 1.0
        property bool sliderEnabled: false

        signal opacityMoved(real newValue)

        Layout.fillWidth: true
        spacing: Metrics.spacingXS
        enabled: sliderRow.sliderEnabled
        opacity: enabled ? 1 : 0.45

        Text {
            Layout.fillWidth: true
            text: sliderRow.title
            color: Appearance.colors.colOnSurface
            font.family: Typography.titleSmall.family
            font.pixelSize: Typography.titleSmall.pixelSize
            font.weight: Typography.titleSmall.weight
        }

        QuickMaterialSlider {
            Accessible.name: sliderRow.title
            materialSymbol: sliderRow.materialSymbol
            animateWave: false
            from: 0.2
            to: 1.0
            stepSize: 0.01
            enabled: sliderRow.sliderEnabled
            value: sliderRow.opacityValue
            percentText: Math.round(value * 100) + "%"
            tooltipContent: Math.round(value * 100) + "%"
            onMoved: sliderRow.opacityMoved(value)
        }
    }

    Component {
        id: windowOpacityComponent

        WidgetPanel {
            id: opacityPanel

            readonly property bool foreground: root.foreground && root.activeView === "window-opacity"
            readonly property bool supported: CompositorBackend.supportsWindowOpacity
            readonly property bool controlsEnabled: supported && PersonalizationConfig.windowOpacityEnabled

            title: qsTr("Window Opacity")
            icon: supported && PersonalizationConfig.windowOpacityEnabled ? "opacity" : "layers_clear"
            showBackButton: true
            backAction: () => WidgetState.quickSettingsView = "settings"

            headerTools: IconButton {
                controlSize: 40
                iconName: "open_in_new"
                iconSize: 20
                iconColor: Appearance.colors.colOnLayer2
                accessibleName: qsTr("Open transparency settings")
                hoverStateLayerColor: Appearance.colors.colLayer2Hover
                pressedStateLayerColor: Appearance.colors.colLayer2Active
                onClicked: {
                    WidgetState.closeAllPopups();
                    ControlCenterService.openSearch("general.effects.section.window-transparency");
                }
            }

            SidebarFlickable {
                id: opacityScroll

                Layout.fillWidth: true
                Layout.fillHeight: true
                motionEnabled: opacityPanel.foreground && opacityPanel.visible
                contentWidth: width
                contentHeight: opacityContent.implicitHeight + opacityScroll.contentTopInset

                ColumnLayout {
                    id: opacityContent

                    y: opacityScroll.contentTopInset
                    width: parent.width
                    spacing: Metrics.spacingL

                    InlineStatusBanner {
                        Layout.topMargin: opacityScroll.gapFor(0, 1)
                        Layout.fillWidth: true
                        visible: !opacityPanel.supported
                        tone: !CompositorBackend.connected && CompositorBackend.lastError !== "" ? "warning" : "info"
                        message: !CompositorBackend.connected && CompositorBackend.lastError !== ""
                            ? CompositorBackend.lastError
                            : qsTr("Window transparency is unsupported by the active compositor.")
                    }

                    SettingsSection {
                        pullExpansion: opacityScroll.detailExpansion
                        Layout.topMargin: opacityScroll.gapFor(1, 1)
                        Layout.fillWidth: true
                        title: qsTr("Window transparency")
                        iconName: "opacity"

                        SettingsRow {
                            Layout.fillWidth: true
                            iconName: opacityPanel.supported && PersonalizationConfig.windowOpacityEnabled
                                ? "opacity"
                                : "layers_clear"
                            title: qsTr("Enable window transparency")
                            supportingText: opacityPanel.supported
                                ? (PersonalizationConfig.windowOpacityEnabled
                                    ? qsTr("Focused %1% · Unfocused %2%")
                                        .arg(Math.round(PersonalizationConfig.activeWindowOpacity * 100))
                                        .arg(Math.round(PersonalizationConfig.inactiveWindowOpacity * 100))
                                    : qsTr("Off"))
                                : qsTr("Unavailable on current compositor")

                            trailing: StyledSwitch {
                                enabled: opacityPanel.supported
                                checked: opacityPanel.supported && PersonalizationConfig.windowOpacityEnabled
                                Accessible.name: qsTr("Enable window transparency")
                                onToggled: PersonalizationConfig.setWindowOpacityEnabled(checked)
                            }
                        }

                        OpacitySliderRow {
                            title: qsTr("Focused window opacity")
                            materialSymbol: "opacity"
                            opacityValue: PersonalizationConfig.activeWindowOpacity
                            sliderEnabled: opacityPanel.controlsEnabled
                            onOpacityMoved: newValue => PersonalizationConfig.setActiveWindowOpacity(newValue)
                        }

                        OpacitySliderRow {
                            title: qsTr("Unfocused window opacity")
                            materialSymbol: "filter_none"
                            opacityValue: PersonalizationConfig.inactiveWindowOpacity
                            sliderEnabled: opacityPanel.controlsEnabled
                            onOpacityMoved: newValue => PersonalizationConfig.setInactiveWindowOpacity(newValue)
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Item {
                                Layout.fillWidth: true
                            }

                            ActionButton {
                                iconName: "restart_alt"
                                text: qsTr("Reset")
                                enabled: opacityPanel.supported
                                onClicked: PersonalizationConfig.resetWindowOpacityDefaults()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsComponent

        SettingsContent {
            screen: root.screen
            foreground: root.foreground && root.activeView === "settings"
        }
    }
}
