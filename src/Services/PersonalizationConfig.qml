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
    property string themeMode: "light"
    property bool quickSettingsSlidersDetailed: false

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
    property var hotCornerActions: ({
        "top-left": "disabled",
        "top-right": "disabled",
        "bottom-left": "disabled",
        "bottom-right": "disabled"
    })

    // Keystone configuration properties
    property bool keystoneEnabled: true
    property bool keystoneOverlay: false
    property string keystoneStyle: "bangs" // 'bangs', 'pill', 'long'
    property string keystonePosition: "top"
    property bool keystoneCapsLockOsd: true
    property bool keystoneNumLockOsd: true
    property bool keystoneHideDate: false
    property bool keystoneLongShowNames: true
    property bool keystoneLongShowMonitorValues: true
    property bool keystoneLongShowValues: true
    property string keystoneHoverAction: "peak"
    property int keystoneHoverOpenDelay: 150
    property int keystoneHoverCloseDelay: 250
    property string keystoneLeftClickAction: "media"
    property string keystoneMiddleClickAction: "media"
    property string keystoneMediaProgressStyle: "wavy"
    property string keystoneMediaCoverStyle: "circle"
    property string keystoneMediaColorStyle: "vibrant"
    property string keystoneKeyholeCard: "clock"

    readonly property var horizontalClockAxisDefaults: ({
        "wght": 900,
        "wdth": 85,
        "opsz": 18,
        "GRAD": 0,
        "ROND": 25,
        "slnt": 0
    })
    readonly property var horizontalClockAxisMinimums: ({
        "wght": 1,
        "wdth": 25,
        "opsz": 6,
        "GRAD": 0,
        "ROND": 0,
        "slnt": -10
    })
    readonly property var horizontalClockAxisMaximums: ({
        "wght": 1000,
        "wdth": 151,
        "opsz": 144,
        "GRAD": 100,
        "ROND": 100,
        "slnt": 0
    })
    readonly property var horizontalClockDigitDefaults: ({
        "separator": ({
            "x": 0,
            "y": 0,
            "rotation": 0,
            "colorRole": "primary",
            "customColor": ""
        }),
        "h0": ({
            "x": 0,
            "y": -2,
            "rotation": -3,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "h1": ({
            "x": 0,
            "y": 1,
            "rotation": 3,
            "colorRole": "primary",
            "customColor": ""
        }),
        "m0": ({
            "x": 0,
            "y": -1,
            "rotation": -2,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "m1": ({
            "x": 0,
            "y": 1,
            "rotation": 2,
            "colorRole": "primary",
            "customColor": ""
        }),
        "ap": ({
            "x": 1,
            "y": -2,
            "rotation": -2,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "periodM": ({
            "x": 1,
            "y": 1,
            "rotation": 2,
            "colorRole": "primary",
            "customColor": ""
        })
    })
    property int horizontalClockFontSize: 22
    property var horizontalClockAxes: ({
        "wght": 900,
        "wdth": 85,
        "opsz": 18,
        "GRAD": 0,
        "ROND": 25,
        "slnt": 0
    })
    property var horizontalClockDigits: ({
        "separator": ({
            "x": 0,
            "y": 0,
            "rotation": 0,
            "colorRole": "primary",
            "customColor": ""
        }),
        "h0": ({
            "x": 0,
            "y": -2,
            "rotation": -3,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "h1": ({
            "x": 0,
            "y": 1,
            "rotation": 3,
            "colorRole": "primary",
            "customColor": ""
        }),
        "m0": ({
            "x": 0,
            "y": -1,
            "rotation": -2,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "m1": ({
            "x": 0,
            "y": 1,
            "rotation": 2,
            "colorRole": "primary",
            "customColor": ""
        }),
        "ap": ({
            "x": 1,
            "y": -2,
            "rotation": -2,
            "colorRole": "inversePrimary",
            "customColor": ""
        }),
        "periodM": ({
            "x": 1,
            "y": 1,
            "rotation": 2,
            "colorRole": "primary",
            "customColor": ""
        })
    })

    readonly property var keystoneStyles: ["bangs", "pill", "long"]
    readonly property var defaultKeystoneLongLeading: ["workspaces", "media", "systemMonitor"]
    readonly property var defaultKeystoneLongTrailing: ["network", "bluetooth", "brightness", "volume", "microphone", "battery"]
    property var keystoneLongLeading: defaultKeystoneLongLeading.slice()
    property var keystoneLongTrailing: defaultKeystoneLongTrailing.slice()

    readonly property var keystoneActionOptions: [
        { value: "none", label: qsTr("Do not open") },
        { value: "media", label: qsTr("Media controls") },
        { value: "lyrics", label: qsTr("Lyrics") },
        { value: "dashboard", label: qsTr("Dashboard") },
        { value: "upload", label: qsTr("Upload") },
        { value: "weather", label: qsTr("Weather") },
        { value: "tools", label: qsTr("Tools") }
    ]

    readonly property var keystoneHoverActionOptions: [
        { value: "peak", label: qsTr("Peak") }
    ].concat(root.keystoneActionOptions)

    readonly property var availableKeystoneHoverActionOptions: keystoneStyle === "long"
                                                               ? keystoneActionOptions :
                                                                 keystoneHoverActionOptions

    readonly property string effectiveKeystoneHoverAction: keystoneStyle === "long" && keystoneHoverAction === "peak"
                                                           ? "none" : keystoneHoverAction

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

    // Keystone setter methods
    function setKeystoneEnabled(value) {
        keystoneEnabled = !!value;
    }

    function setKeystoneOverlay(value) {
        keystoneOverlay = !!value;
    }

    function setKeystoneStyle(value) {
        keystoneStyle = String(value || "bangs");
    }

    function setKeystonePosition(value) {
        keystonePosition = String(value || "top");
    }

    function setKeystoneCapsLockOsd(value) {
        keystoneCapsLockOsd = !!value;
    }

    function setKeystoneNumLockOsd(value) {
        keystoneNumLockOsd = !!value;
    }

    function setKeystoneHideDate(value) {
        keystoneHideDate = !!value;
    }

    function setKeystoneLongShowNames(value) {
        keystoneLongShowNames = !!value;
    }

    function setKeystoneLongShowMonitorValues(value) {
        keystoneLongShowMonitorValues = !!value;
    }

    function setKeystoneLongShowValues(value) {
        keystoneLongShowValues = !!value;
    }

    function setKeystoneKeyholeCard(value) {
        keystoneKeyholeCard = String(value || "clock");
    }

    function setKeystoneHoverAction(value) {
        keystoneHoverAction = String(value || "peak");
    }

    function setKeystoneLeftClickAction(value) {
        keystoneLeftClickAction = String(value || "media");
    }

    function setKeystoneMiddleClickAction(value) {
        keystoneMiddleClickAction = String(value || "media");
    }

    function setKeystoneAction(gesture, action) {
        if (gesture === "hover")
            setKeystoneHoverAction(action);
        else if (gesture === "left")
            setKeystoneLeftClickAction(action);
        else if (gesture === "middle")
            setKeystoneMiddleClickAction(action);
    }

    function setKeystoneHoverOpenDelay(value) {
        keystoneHoverOpenDelay = Math.max(0, Number(value) || 150);
    }

    function setKeystoneHoverCloseDelay(value) {
        keystoneHoverCloseDelay = Math.max(0, Number(value) || 250);
    }

    function setKeystoneMediaProgressStyle(value) {
        keystoneMediaProgressStyle = String(value || "wavy");
    }

    function setKeystoneMediaCoverStyle(value) {
        keystoneMediaCoverStyle = String(value || "circle");
    }

    function setKeystoneMediaColorStyle(value) {
        keystoneMediaColorStyle = String(value || "vibrant");
    }
}
