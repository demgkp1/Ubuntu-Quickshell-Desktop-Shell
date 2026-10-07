pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dndEnabled: false
    property bool darkMode: true
    property string language: "en_US"
    property string weatherTemperatureUnit: "celsius"
    property string systemTemperatureUnit: "celsius"
    property string weatherMapBaseProvider: "openfreemap"
    property string weatherMapOverlayProvider: "rainviewer"
    property string systemMonitorGpuId: "auto"
    property string systemMonitorDiskDevice: ""
    property string systemMonitorNetworkInterface: ""
    property string storageCapacityDiskDevice: "follow-io"
    property int systemMonitorIntervalMs: 2000
    property bool useTwelveHourClock: false
    property string sidebarClockStyle: "digital"
    property int sidebarCookieSides: 14
    property bool sidebarCookieConstantlyRotate: false
    property bool sidebarCookieHourMarks: false
    property bool sidebarCookieTimeIndicators: true
    property string sidebarCookieDialStyle: "full"
    property string sidebarCookieHourHandStyle: "fill"
    property string sidebarCookieMinuteHandStyle: "medium"
    property string sidebarCookieSecondHandStyle: "dot"
    property string sidebarCookieDateStyle: "bubble"
    property bool preferencesReady: true
    property var drawerGridLayout: ({})
    property var systemCards: ({})

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }

    function setDndEnabled(val) {
        dndEnabled = !!val;
    }

    function setDarkMode(val) {
        darkMode = !!val;
    }

    function weatherTemperature(c) {
        return c;
    }

    function systemTemperature(c) {
        return c;
    }

    function weatherTemperatureSymbol() {
        return weatherTemperatureUnit === "fahrenheit" ? "°F" : "°C";
    }

    function systemTemperatureSymbol() {
        return systemTemperatureUnit === "fahrenheit" ? "°F" : "°C";
    }

    function setCardLayouts(cards, layout) {
        try {
            root.systemCards = JSON.parse(JSON.stringify(cards || {}));
            root.drawerGridLayout = JSON.parse(JSON.stringify(layout || {}));
        } catch (e) {
            console.warn("UiPreferences setCardLayouts error:", e);
        }
    }

    function setSystemCards(cards) {
        try {
            root.systemCards = JSON.parse(JSON.stringify(cards || {}));
        } catch (e) {
            console.warn("UiPreferences setSystemCards error:", e);
        }
    }
}
