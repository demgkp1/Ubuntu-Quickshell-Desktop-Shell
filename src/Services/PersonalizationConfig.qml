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
}
