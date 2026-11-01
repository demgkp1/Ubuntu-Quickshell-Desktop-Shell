pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property bool apiConfigured: false
    readonly property bool mapTilerConfigured: false
    readonly property bool credentialsReady: true
    readonly property bool credentialBusy: false
    readonly property string status: "ready"
    readonly property string mapTilerStatus: "ready"
    readonly property string radarStatus: "idle"
    readonly property string radarTileUrl: ""

    signal credentialOperationFinished(string operation, bool success, string message)

    function storeApiKey(value) {
        root.credentialOperationFinished("openweather_store", false, qsTr("Weather map plugin is not available"));
        return false;
    }

    function clearApiKey() {
        root.credentialOperationFinished("openweather_clear", true, "");
        return true;
    }

    function storeMapTilerApiKey(value) {
        root.credentialOperationFinished("maptiler_store", false, qsTr("MapTiler plugin is not available"));
        return false;
    }

    function clearMapTilerApiKey() {
        root.credentialOperationFinished("maptiler_clear", true, "");
        return true;
    }

    function mapTilerStyleUrl(style) {
        const dark = String(style || "").indexOf("dark") !== -1;
        return "https://tiles.openfreemap.org/styles/" + (dark ? "dark" : "positron");
    }

    function openWeatherTileUrl(layer) {
        return "";
    }
}
