pragma Singleton

import QtQuick
import Quickshell
import qs.Common
import qs.Services

Singleton {
    id: root

    property int iconThemeRevision: 0
    property bool isNiriSession: false
    property string effectiveMode: Appearance.effectiveMatugenMode

    function setThemeMode(mode) {
        PersonalizationConfig.setThemeMode(mode);
        effectiveMode = mode === "light" ? "light" : "dark";
        Appearance.matugenMode = effectiveMode;
        if (typeof UiPreferences !== "undefined" && UiPreferences.setDarkMode) {
            UiPreferences.setDarkMode(effectiveMode === "dark");
        }
    }
}
