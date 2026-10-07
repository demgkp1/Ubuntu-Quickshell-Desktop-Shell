pragma Singleton

import QtQuick

QtObject {
    id: root

    property string radarStatus: "idle"
    property string mapTilerStatus: "idle"
    property string status: "idle"
    property bool mapTilerConfigured: false
    property bool apiConfigured: false
    property bool credentialsReady: true
    property bool credentialBusy: false
    property string radarTileUrl: ""

    signal credentialOperationFinished(string operation, bool success, string message)

    function mapTilerStyleUrl(style) {
        return "https://tiles.openfreemap.org/styles/positron";
    }

    function openWeatherTileUrl(layer) {
        return "";
    }

    function refreshRadarMetadata() {
        root.radarStatus = "idle";
    }

    function storeApiKey(value) {
        root.apiConfigured = !!String(value || "").trim();
        root.credentialOperationFinished("openweather_store", true, "Stored");
        return true;
    }

    function clearApiKey() {
        root.apiConfigured = false;
        root.credentialOperationFinished("openweather_clear", true, "Cleared");
        return true;
    }

    function storeMapTilerApiKey(value) {
        root.mapTilerConfigured = !!String(value || "").trim();
        root.credentialOperationFinished("maptiler_store", true, "Stored");
        return true;
    }

    function clearMapTilerApiKey() {
        root.mapTilerConfigured = false;
        root.credentialOperationFinished("maptiler_clear", true, "Cleared");
        return true;
    }
}
