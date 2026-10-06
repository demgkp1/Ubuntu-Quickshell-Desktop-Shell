pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool loading: false
    readonly property bool normalsAvailable: false
    readonly property bool normalsLoading: false
    readonly property int normalsPeriodStartYear: 1991
    readonly property int normalsPeriodEndYear: 2020
    readonly property string normalsModel: ""
    readonly property bool hasValidData: false
    readonly property bool hasManualLocation: false
    readonly property string status: "idle"
    readonly property string errorMessage: ""
    readonly property string locationName: ""
    readonly property real latitude: 0.0
    readonly property real longitude: 0.0
    readonly property string lastUpdated: ""
    readonly property string nextRefreshAt: ""
    readonly property real currentTemperatureC: NaN
    readonly property real currentFeelsLikeC: NaN
    readonly property int currentWeatherCode: 0
    readonly property string currentWeatherText: ""
    readonly property string currentIconName: "cloud"
    readonly property real currentWindSpeedMs: 0.0
    readonly property real currentWindDirection: 0.0
    readonly property real currentWindGustsMs: 0.0
    readonly property real currentUvIndex: 0.0
    readonly property real currentRelativeHumidity: 0.0
    readonly property real currentDewPointC: NaN
    readonly property real currentPressureHpa: 1013.0
    readonly property real currentCloudCover: 0.0
    readonly property real currentVisibilityM: 10000.0
    readonly property var currentAirQuality: null
    readonly property var hourlyForecast: []
    readonly property var dailyForecast: []
    readonly property var dailyTrendForecast: []
    readonly property var minutelyForecast: []

    signal dataChanged()
    signal normalsChanged()

    function refresh() {}
    function setManualLocation(latitudeValue, longitudeValue, name) {}
    function clearManualLocation() {}
    function current() {
        return null;
    }
    function normalDaytimeTemperatureC(month) {
        return NaN;
    }
    function normalNighttimeTemperatureC(month) {
        return NaN;
    }
}
