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
}
