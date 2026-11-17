pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property bool runningOnNiri: CompositorBackend.name === "niri"
    property bool niriCompositorSupported: false
    readonly property bool compositorSupported: root.runningOnNiri
        ? root.niriCompositorSupported
        : (CompositorBackend.connected && !!CompositorBackend.capabilities.backgroundBlur)
    readonly property bool available: root.compositorSupported
    readonly property bool enabled: root.available && PersonalizationConfig.shellBlurEnabled
    readonly property bool xray: root.runningOnNiri && PersonalizationConfig.shellBlurXray
    readonly property bool integrationBusy: root.runningOnNiri && NiriConfigService.busy
        && NiriConfigService.activeFeature === "effects"
    readonly property bool niriIntegrationReady: root.runningOnNiri && NiriConfigService.ready("effects")
    property string versionErrorText: ""
    readonly property string lastError: root.runningOnNiri
        ? (root.versionErrorText || NiriConfigService.error)
        : qsTr("GNOME background blur is unavailable. Transparency is color alpha only, not live desktop or wallpaper blur.")
    property string niriVersion: ""

    signal integrationConfigured
    signal integrationFailed(string message)

    function backgroundColor(baseColor) {
        return Appearance.applyAlpha(baseColor, PersonalizationConfig.shellBackgroundOpacity);
    }

    function opaqueBackgroundColor(baseColor) {
        return backgroundColor(Appearance.applyAlpha(baseColor, 1));
    }

    function solidBackgroundColor(baseColor) {
        return Appearance.applyAlpha(baseColor, 1);
    }

    function supportsVersion(versionText) {
        const match = String(versionText || "").match(/(?:^|\s)(\d+)\.(\d+)(?:\D|$)/);
        if (!match)
            return false;
        const major = Number(match[1]);
        const minor = Number(match[2]);
        return major > 26 || (major === 26 && minor >= 4);
    }

    function refreshIntegrationState() {
        if (root.runningOnNiri)
            NiriConfigService.refresh();
    }

    function writeEffectsConfig() {
        if (root.runningOnNiri && root.available)
            NiriConfigService.update("effects");
    }

    function configureNiriIntegration() {
        if (root.runningOnNiri)
            NiriConfigService.setup("effects");
    }

    Connections {
        target: PersonalizationConfig

        function onShellBlurXrayChanged() {
            root.writeEffectsConfig();
        }

        function onShellBlurEnabledChanged() {
            root.writeEffectsConfig();
        }
    }

    Connections {
        target: NiriConfigService
        enabled: root.runningOnNiri

        function onSaved() {
            if (NiriConfigService.ready("effects"))
                root.integrationConfigured();
        }

        function onErrorChanged() {
            if (NiriConfigService.errorFeature === "effects" && NiriConfigService.error !== "")
                root.integrationFailed(NiriConfigService.error);
        }
    }

    Process {
        id: versionProcess

        command: ["niri", "--version"]
        running: root.runningOnNiri

        stdout: StdioCollector {
            id: versionOutput
        }

        stderr: StdioCollector {
            id: versionError
        }

        onExited: exitCode => {
            root.niriVersion = versionOutput.text.trim();
            root.niriCompositorSupported = exitCode === 0 && root.supportsVersion(root.niriVersion);
            if (!root.niriCompositorSupported) {
                root.versionErrorText = exitCode === 0
                    ? qsTr("The current Niri version does not support background blur")
                    : (versionError.text.trim() || qsTr("Unable to detect the Niri version"));
                return;
            }

            root.versionErrorText = "";
            root.refreshIntegrationState();
        }
    }
}
