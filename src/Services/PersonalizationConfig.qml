pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property real shellBackgroundOpacity: 0.85
    property bool shellBlurEnabled: true
    property bool shellBlurXray: false

    property var sidebarPositions: ({
        dashboard: "left",
        quickSettings: "right"
    })
    readonly property string dashboardSidebarSide: sidebarPositions.dashboard
    readonly property string quickSettingsSidebarSide: sidebarPositions.quickSettings
    property bool keepSidebarsLoaded: true
    property string themeMode: "dark"

    // Bar configuration properties
    property bool barEnabled: true
    property bool barOverlay: false
    property string barPosition: "top"
    property bool barShowValues: true
    property bool barShowNames: true
    readonly property var defaultBarLeadingComponents: ["information", "activeWindow"]
    readonly property var defaultBarTrailingComponents: ["quickSettings"]
    property var barLeadingComponents: defaultBarLeadingComponents.slice()
    property var barTrailingComponents: defaultBarTrailingComponents.slice()
    readonly property var barComponentIds: ["information", "activeWindow", "quickSettings"]
    readonly property var quickSettingsComponents: ["network", "bluetooth", "brightness", "volume", "microphone", "battery", "settings", "power"]

    function setThemeMode(mode) {
        themeMode = mode === "light" ? "light" : "dark";
    }

    function setDashboardSidebarSide(side) {
        sidebarPositions = {
            dashboard: side,
            quickSettings: root.quickSettingsSidebarSide
        };
    }

    function setQuickSettingsSidebarSide(side) {
        sidebarPositions = {
            dashboard: root.dashboardSidebarSide,
            quickSettings: side
        };
    }

    function setBarPosition(value) {
        barPosition = value;
    }

    function setBarOverlay(value) {
        barOverlay = !!value;
    }

    function setBarEnabled(value) {
        barEnabled = !!value;
    }

    function setBarShowValues(value) {
        barShowValues = !!value;
    }

    function setBarShowNames(value) {
        barShowNames = !!value;
    }
}
