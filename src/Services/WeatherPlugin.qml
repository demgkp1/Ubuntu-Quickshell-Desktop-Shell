pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool loading: false
    readonly property bool normalsAvailable: true
    readonly property bool normalsLoading: false
    readonly property int normalsPeriodStartYear: 1991
    readonly property int normalsPeriodEndYear: 2020
    readonly property string normalsModel: "ECMWF"
    readonly property bool hasValidData: true
    readonly property bool hasManualLocation: true
    readonly property string status: "ready"
    readonly property string errorMessage: ""
    readonly property string locationName: "Guangzhou"
    readonly property real latitude: 23.1291
    readonly property real longitude: 113.2644
    readonly property string lastUpdated: new Date().toISOString()
    readonly property string nextRefreshAt: new Date(Date.now() + 1800000).toISOString()
    readonly property real currentTemperatureC: 25.0
    readonly property real currentFeelsLikeC: 26.0
    readonly property int currentWeatherCode: 1
    readonly property string currentWeatherText: "Partly Cloudy"
    readonly property string currentIconName: "partly_cloudy_day"
    readonly property real currentWindSpeedMs: 3.2
    readonly property real currentWindDirection: 135.0
    readonly property real currentWindGustsMs: 5.1
    readonly property real currentUvIndex: 4.0
    readonly property real currentRelativeHumidity: 68.0
    readonly property real currentDewPointC: 18.5
    readonly property real currentPressureHpa: 1013.0
    readonly property real currentCloudCover: 35.0
    readonly property real currentVisibilityM: 10000.0

    readonly property var currentAirQuality: ({
        aqi: 35,
        pm25: 12,
        pm10: 25,
        o3: 40,
        ozone: 40,
        no2: 18,
        nitrogenDioxide: 18,
        so2: 6,
        sulphurDioxide: 6,
        co: 0.6,
        carbonMonoxide: 0.6
    })

    function _wrapList(items) {
        var list = items.slice();
        list.count = function() { return list.length; };
        list.get = function(i) { return list[i] || null; };
        return list;
    }

    readonly property var hourlyForecast: {
        const now = new Date();
        const startEpoch = Math.floor(now.getTime() / 1000);
        const hours = [];
        const baseTemps = [25, 25, 26, 27, 28, 28, 27, 26, 25, 24, 23, 22, 21, 21, 20, 20, 21, 22, 23, 24, 25, 26, 26, 25];

        for (let i = 0; i < 24; i++) {
            const date = new Date((startEpoch + i * 3600) * 1000);
            const hour = date.getHours();
            const isDay = (hour >= 6 && hour < 18);
            const temp = baseTemps[i % baseTemps.length];
            hours.push({
                time: startEpoch + i * 3600,
                temperatureC: temp,
                feelsLikeC: temp + 1,
                iconName: isDay ? (temp > 26 ? "sunny" : "partly_cloudy_day") : "partly_cloudy_night",
                weatherText: isDay ? "Partly Cloudy" : "Clear",
                isDaylight: isDay,
                relativeHumidity: 65 + (isDay ? 0 : 10),
                dewPointC: 18.0,
                precipitationMm: 0.0,
                precipitationProbability: 10,
                windSpeedMs: 3.0,
                windDirection: 130,
                uvIndex: isDay ? (hour >= 11 && hour <= 14 ? 6 : 3) : 0,
                pressureHpa: 1013,
                cloudCover: 30,
                visibilityM: 10000
            });
        }
        return root._wrapList(hours);
    }

    readonly property var dailyForecast: {
        const now = new Date();
        const todayEpoch = Math.floor(new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000);
        const days = [];
        const conditions = [
            { text: "Partly Cloudy", icon: "partly_cloudy_day", min: 20, max: 28 },
            { text: "Sunny", icon: "sunny", min: 21, max: 29 },
            { text: "Cloudy", icon: "cloud", min: 20, max: 27 },
            { text: "Light Rain", icon: "rainy", min: 19, max: 25 },
            { text: "Partly Cloudy", icon: "partly_cloudy_day", min: 19, max: 26 },
            { text: "Sunny", icon: "sunny", min: 20, max: 28 },
            { text: "Sunny", icon: "sunny", min: 21, max: 29 }
        ];

        for (let i = 0; i < 7; i++) {
            const epoch = todayEpoch + i * 86400;
            const d = new Date(epoch * 1000);
            const yyyy = d.getFullYear();
            const mm = String(d.getMonth() + 1).padStart(2, '0');
            const dd = String(d.getDate()).padStart(2, '0');
            const dateStr = yyyy + "-" + mm + "-" + dd;
            const cond = conditions[i % conditions.length];

            days.push({
                time: epoch,
                date: dateStr,
                temperatureMinC: cond.min,
                temperatureMaxC: cond.max,
                iconName: cond.icon,
                weatherText: cond.text,
                moonPhaseAngle: (0.15 + i * 0.08) % 1.0,
                sunrise: epoch + 6 * 3600 + 15 * 60,
                sunset: epoch + 18 * 3600 + 30 * 60,
                day: {
                    temperatureC: cond.max,
                    feelsLikeC: cond.max + 1,
                    iconName: cond.icon,
                    weatherText: cond.text,
                    precipitationMm: cond.text.indexOf("Rain") >= 0 ? 3.5 : 0.0,
                    uvIndex: 5,
                    relativeHumidity: 65,
                    windSpeedMs: 3.2,
                    windDirection: 135
                },
                night: {
                    temperatureC: cond.min,
                    feelsLikeC: cond.min,
                    iconName: "clear_night",
                    weatherText: "Clear",
                    precipitationMm: 0.0,
                    uvIndex: 0,
                    relativeHumidity: 78,
                    windSpeedMs: 2.1,
                    windDirection: 120
                }
            });
        }
        return root._wrapList(days);
    }

    readonly property var dailyTrendForecast: {
        // Trend includes yesterday (index 0) through next 8 days
        const now = new Date();
        const todayEpoch = Math.floor(new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000);
        const days = [];
        const conditions = [
            { text: "Sunny", icon: "sunny", min: 19, max: 27 },
            { text: "Partly Cloudy", icon: "partly_cloudy_day", min: 20, max: 28 },
            { text: "Sunny", icon: "sunny", min: 21, max: 29 },
            { text: "Cloudy", icon: "cloud", min: 20, max: 27 },
            { text: "Light Rain", icon: "rainy", min: 19, max: 25 },
            { text: "Partly Cloudy", icon: "partly_cloudy_day", min: 19, max: 26 },
            { text: "Sunny", icon: "sunny", min: 20, max: 28 },
            { text: "Sunny", icon: "sunny", min: 21, max: 29 },
            { text: "Partly Cloudy", icon: "partly_cloudy_day", min: 20, max: 28 }
        ];

        for (let i = 0; i < conditions.length; i++) {
            // i=0 is yesterday (todayEpoch - 86400)
            const epoch = todayEpoch + (i - 1) * 86400;
            const d = new Date(epoch * 1000);
            const yyyy = d.getFullYear();
            const mm = String(d.getMonth() + 1).padStart(2, '0');
            const dd = String(d.getDate()).padStart(2, '0');
            const dateStr = yyyy + "-" + mm + "-" + dd;
            const cond = conditions[i];

            days.push({
                time: epoch,
                date: dateStr,
                temperatureMinC: cond.min,
                temperatureMaxC: cond.max,
                iconName: cond.icon,
                weatherText: cond.text,
                moonPhaseAngle: (0.12 + i * 0.08) % 1.0,
                sunrise: epoch + 6 * 3600 + 15 * 60,
                sunset: epoch + 18 * 3600 + 30 * 60,
                day: {
                    temperatureC: cond.max,
                    feelsLikeC: cond.max + 1,
                    iconName: cond.icon,
                    weatherText: cond.text,
                    precipitationMm: cond.text.indexOf("Rain") >= 0 ? 3.5 : 0.0,
                    uvIndex: 5,
                    relativeHumidity: 65,
                    windSpeedMs: 3.2,
                    windDirection: 135
                },
                night: {
                    temperatureC: cond.min,
                    feelsLikeC: cond.min,
                    iconName: "clear_night",
                    weatherText: "Clear",
                    precipitationMm: 0.0,
                    uvIndex: 0,
                    relativeHumidity: 78,
                    windSpeedMs: 2.1,
                    windDirection: 120
                }
            });
        }
        return root._wrapList(days);
    }

    readonly property var minutelyForecast: root._wrapList([])

    signal dataChanged()
    signal normalsChanged()

    function refresh() {
        root.dataChanged();
    }

    function setManualLocation(latitudeValue, longitudeValue, name) {
        root.dataChanged();
    }

    function clearManualLocation() {
        root.dataChanged();
    }

    function current() {
        const now = Math.floor(Date.now() / 1000);
        return {
            time: now,
            temperatureC: root.currentTemperatureC,
            feelsLikeC: root.currentFeelsLikeC,
            weatherCode: root.currentWeatherCode,
            weatherText: root.currentWeatherText,
            iconName: root.currentIconName,
            windSpeedMs: root.currentWindSpeedMs,
            windDirection: root.currentWindDirection,
            windGustsMs: root.currentWindGustsMs,
            uvIndex: root.currentUvIndex,
            relativeHumidity: root.currentRelativeHumidity,
            dewPointC: root.currentDewPointC,
            pressureHpa: root.currentPressureHpa,
            cloudCover: root.currentCloudCover,
            visibilityM: root.currentVisibilityM,
            sunrise: Math.floor(now / 86400) * 86400 + 6 * 3600 + 15 * 60,
            sunset: Math.floor(now / 86400) * 86400 + 18 * 3600 + 30 * 60,
            isDaylight: true
        };
    }

    function normalDaytimeTemperatureC(month) {
        return 26.0;
    }

    function normalNighttimeTemperatureC(month) {
        return 20.0;
    }
}
