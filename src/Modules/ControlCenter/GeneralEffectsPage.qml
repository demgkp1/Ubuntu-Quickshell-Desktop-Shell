import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets.common

StyledFlickable {
    id: root

    readonly property bool showStatusBanner: (!BlurService.runningOnNiri && (!BlurService.available || !CompositorBackend.connected || BlurService.lastError !== ""))
        || (BlurService.runningOnNiri && !effectsSetupPrompt.visible && BlurService.lastError !== "")

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + Metrics.pageMargin * 2

    Component.onCompleted: {
        if (BlurService.runningOnNiri)
            BlurService.refreshIntegrationState();
    }

    ColumnLayout {
        id: contentColumn

        width: Math.min(640, Math.max(0, root.width - Metrics.pageMargin * 2))
        x: Math.max(Metrics.pageMargin, (root.width - width) / 2)
        y: Metrics.pageMargin
        spacing: Metrics.spacingL

        NiriSetupPrompt {
            id: effectsSetupPrompt

            Layout.fillWidth: true
            visible: ThemeService.isNiriSession && BlurService.available
                && integrationState !== "ready"
                && (integrationState !== "loading" || error.length > 0)
            title: qsTr("Background effects")
            description: qsTr("Create or connect the Clavis X-Ray rules.")
            integrationState: NiriConfigService.state("effects")
            busy: BlurService.integrationBusy
            blocked: NiriConfigService.busy
            error: NiriConfigService.error
            onSetupRequested: BlurService.configureNiriIntegration()
        }

        InlineStatusBanner {
            id: effectsStatusBanner

            Layout.fillWidth: true
            visible: root.showStatusBanner
            tone: !BlurService.runningOnNiri
                ? (!CompositorBackend.connected ? "warning" : "info")
                : (BlurService.available ? "error" : "warning")
            message: !BlurService.runningOnNiri
                ? (!CompositorBackend.connected && CompositorBackend.lastError !== ""
                    ? qsTr("Background blur is read-only on GNOME (%1). Shell opacity uses color alpha only.").arg(CompositorBackend.lastError)
                    : (BlurService.lastError !== ""
                        ? BlurService.lastError
                        : qsTr("Background blur is read-only on GNOME; transparency uses color alpha only.")))
                : BlurService.lastError
        }

        SettingsSection {
            id: searchSection0
            Layout.fillWidth: true
            flat: true
            title: searchAnchor0.title
            SettingsSearchAnchor {
                id: searchAnchor0
                target: searchSection0
                declaration:
                    '{"id":"general.effects.section.background","route":"general.effects","title":"Background","context":"GeneralEffectsPage","icon":"blur_on","aliases":[]}'
            }
            iconName: "wallpaper"

            GeneralSliderSetting {
                title: qsTr("Background opacity")
                from: 0
                to: 100
                stepSize: 1
                suffix: "%"
                value: PersonalizationConfig.shellBackgroundOpacity * 100
                onMoved: value => PersonalizationConfig.setShellBackgroundOpacity(value / 100)
            }

            SettingsRow {
                Layout.fillWidth: true
                iconName: "blur_on"
                title: qsTr("Background blur")
                supportingText: !BlurService.runningOnNiri
                    ? qsTr("Read-only on GNOME; transparency uses color alpha only.")
                    : (!BlurService.available
                        ? qsTr("Requires Niri 26.4 or newer for live background blur.")
                        : qsTr("Blur desktop wallpaper and windows behind translucent shell surfaces"))

                trailing: StyledSwitch {
                    enabled: BlurService.available
                    checked: BlurService.enabled
                    Accessible.name: qsTr("Background blur")
                    onToggled: PersonalizationConfig.setShellBlurEnabled(checked)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                iconName: "filter_center_focus"
                title: qsTr("Blur wallpaper only")
                supportingText: !BlurService.runningOnNiri
                    ? qsTr("Read-only on GNOME; no live desktop or wallpaper blur backend is installed.")
                    : (!BlurService.available
                        ? qsTr("Requires Niri 26.4 or newer for X-Ray blur control.")
                        : (BlurService.niriIntegrationReady
                            ? qsTr("Turning this off also blurs windows and uses more resources")
                            : qsTr("Set up Niri background effects integration above first")))

                trailing: StyledSwitch {
                    enabled: BlurService.available && BlurService.niriIntegrationReady
                    checked: BlurService.available && PersonalizationConfig.shellBlurXray
                    Accessible.name: qsTr("Blur wallpaper only")
                    onToggled: PersonalizationConfig.setShellBlurXray(checked)
                }
            }
        }

        SettingsSection {
            id: searchSection1
            Layout.fillWidth: true
            flat: true
            title: searchAnchor1.title || qsTr("Window transparency")
            supportingText: CompositorBackend.supportsWindowOpacity
                ? qsTr("Configure separate opacity levels for focused and unfocused windows.")
                : (!CompositorBackend.connected && CompositorBackend.lastError !== ""
                    ? qsTr("Disabled: compositor bridge is unavailable (%1).").arg(CompositorBackend.lastError)
                    : qsTr("Disabled: the active compositor does not support per-window opacity control."))
            iconName: "opacity"

            SettingsSearchAnchor {
                id: searchAnchor1
                target: searchSection1
                declaration:
                    '{"id":"general.effects.section.window-transparency","route":"general.effects","title":"Window transparency","context":"GeneralEffectsPage","icon":"opacity","aliases":["window opacity","windowOpacityEnabled","activeWindowOpacity","inactiveWindowOpacity"]}'
            }

            SettingsSearchAnchor {
                id: searchAnchorWindowOpacityEnabled
                target: windowOpacityEnabledRow
                declaration:
                    '{"id":"general.effects.window-opacity-enabled","route":"general.effects","title":"Enable window transparency","context":"GeneralEffectsPage","icon":"opacity","aliases":["windowOpacityEnabled","window opacity","window transparency"]}'
            }

            SettingsSearchAnchor {
                id: searchAnchorActiveWindowOpacity
                target: activeWindowOpacitySlider
                declaration:
                    '{"id":"general.effects.active-window-opacity","route":"general.effects","title":"Focused window opacity","context":"GeneralEffectsPage","icon":"opacity","aliases":["activeWindowOpacity","active window opacity","focused window opacity"]}'
            }

            SettingsSearchAnchor {
                id: searchAnchorInactiveWindowOpacity
                target: inactiveWindowOpacitySlider
                declaration:
                    '{"id":"general.effects.inactive-window-opacity","route":"general.effects","title":"Unfocused window opacity","context":"GeneralEffectsPage","icon":"opacity","aliases":["inactiveWindowOpacity","inactive window opacity","unfocused window opacity"]}'
            }

            SettingsRow {
                id: windowOpacityEnabledRow

                Layout.fillWidth: true
                enabled: CompositorBackend.supportsWindowOpacity
                iconName: PersonalizationConfig.windowOpacityEnabled ? "opacity" : "layers_clear"
                title: qsTr("Enable window transparency")
                supportingText: CompositorBackend.supportsWindowOpacity
                    ? qsTr("Apply custom opacity rules to focused and unfocused windows")
                    : (!CompositorBackend.connected
                        ? qsTr("Unavailable while the compositor bridge is disconnected")
                        : qsTr("Unsupported by the active compositor"))

                trailing: StyledSwitch {
                    enabled: CompositorBackend.supportsWindowOpacity
                    checked: PersonalizationConfig.windowOpacityEnabled
                    Accessible.name: qsTr("Enable window transparency")
                    onToggled: PersonalizationConfig.setWindowOpacityEnabled(checked)
                }
            }

            GeneralSliderSetting {
                id: activeWindowOpacitySlider

                title: qsTr("Focused window opacity")
                description: qsTr("Opacity applied to the currently focused window")
                enabled: CompositorBackend.supportsWindowOpacity && PersonalizationConfig.windowOpacityEnabled
                from: 20
                to: 100
                stepSize: 1
                suffix: "%"
                value: Math.round(PersonalizationConfig.activeWindowOpacity * 100)
                onMoved: value => PersonalizationConfig.setActiveWindowOpacity(value / 100)
            }

            GeneralSliderSetting {
                id: inactiveWindowOpacitySlider

                title: qsTr("Unfocused window opacity")
                description: qsTr("Opacity applied to background unfocused windows")
                enabled: CompositorBackend.supportsWindowOpacity && PersonalizationConfig.windowOpacityEnabled
                from: 20
                to: 100
                stepSize: 1
                suffix: "%"
                value: Math.round(PersonalizationConfig.inactiveWindowOpacity * 100)
                onMoved: value => PersonalizationConfig.setInactiveWindowOpacity(value / 100)
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    iconName: "restart_alt"
                    text: qsTr("Reset")
                    onClicked: PersonalizationConfig.resetWindowOpacityDefaults()
                }
            }
        }
    }
}
