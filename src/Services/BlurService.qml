pragma Singleton

import QtQuick
import Quickshell
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property bool runningOnNiri: false
    property bool compositorSupported: true
    readonly property bool available: true
    readonly property bool enabled: true
    readonly property bool xray: false

    function backgroundColor(baseColor) {
        return Appearance.applyAlpha(baseColor, PersonalizationConfig.shellBackgroundOpacity);
    }

    function opaqueBackgroundColor(baseColor) {
        return backgroundColor(Appearance.applyAlpha(baseColor, 1));
    }

    function solidBackgroundColor(baseColor) {
        return Appearance.applyAlpha(baseColor, 1);
    }
}
