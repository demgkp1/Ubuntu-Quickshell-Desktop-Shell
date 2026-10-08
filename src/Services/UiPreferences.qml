pragma Singleton

import QtQuick
import QtCore
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

    // Cloud backup properties (1:1 with reference/StatIndet-quickshell L51-L56)
    property bool cloudBackupFoldersInitialized: true
    property int cloudBackupFoldersVersion: 3
    property var cloudBackupFolders: []
    property string cloudDefaultRemoteName: ""
    property string cloudBackupRoot: "Backups"
    property string cloudUploadRoot: "Uploads"

    // Recording directory paths (1:1 with reference/StatIndet-quickshell L57-L72)
    readonly property string defaultRecordingVideoDirectory: StandardPaths.writableLocation(StandardPaths.MoviesLocation) + "/Recordings"
    readonly property string defaultRecordingGifDirectory: StandardPaths.writableLocation(StandardPaths.PicturesLocation) + "/GIFs"
    readonly property string defaultRecordingMicrophoneDirectory: StandardPaths.writableLocation(StandardPaths.MusicLocation) + "/Recordings/Microphone"
    readonly property string defaultRecordingSystemAudioDirectory: StandardPaths.writableLocation(StandardPaths.MusicLocation) + "/Recordings/System"

    property string recordingVideoDirectory: defaultRecordingVideoDirectory
    property string recordingGifDirectory: defaultRecordingGifDirectory
    property string recordingMicrophoneDirectory: defaultRecordingMicrophoneDirectory
    property string recordingSystemAudioDirectory: defaultRecordingSystemAudioDirectory

    property string spotlightSearchEngine: "google"
    property string spotlightAppOrder: "name"
    property string spotlightAppStyle: "list"
    property string spotlightClipboardStyle: "default"

    function setSpotlightSearchEngine(value) {
        spotlightSearchEngine = value || "google";
    }

    function setSpotlightAppOrder(value) {
        spotlightAppOrder = value || "name";
    }

    function setSpotlightAppStyle(value) {
        spotlightAppStyle = value === "grid" ? "grid" : "list";
    }

    function setSpotlightClipboardStyle(value) {
        spotlightClipboardStyle = value || "default";
    }

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

    function shortTime(value) {
        return Qt.formatDateTime(value, root.useTwelveHourClock ? "hh:mm AP" : "HH:mm");
    }

    function hourTime(value) {
        return Qt.formatDateTime(value, root.useTwelveHourClock ? "hh AP" : "HH:00");
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

    // Cloud backup methods (1:1 with reference/StatIndet-quickshell L474-L521)
    function normalizedCloudRemoteName(value) {
        return String(value || "").trim().replace(/:+$/, "");
    }

    function setCloudDefaultRemoteName(value) {
        root.cloudDefaultRemoteName = root.normalizedCloudRemoteName(value);
    }

    function normalizedCloudBackupRoot(value) {
        let normalized = String(value || "").trim().replace(/^\/+|\/+$/g, "");
        normalized = normalized.replace(/\/{2,}/g, "/");
        if (normalized === "" || normalized.indexOf(":") >= 0)
            return "Backups";
        return normalized;
    }

    function setCloudBackupRoot(value) {
        root.cloudBackupRoot = root.normalizedCloudBackupRoot(value);
    }

    function normalizedCloudUploadRoot(value) {
        let normalized = String(value || "").trim().replace(/^\/+|\/+$/g, "");
        normalized = normalized.replace(/\/{2,}/g, "/");
        if (normalized === "" || normalized.indexOf(":") >= 0)
            return "Uploads";
        return normalized;
    }

    function setCloudUploadRoot(value) {
        root.cloudUploadRoot = root.normalizedCloudUploadRoot(value);
    }

    function setCloudBackupFolders(folders) {
        const normalized = [];
        for (const folder of (folders || [])) {
            if (folder && folder.path) {
                normalized.push({
                    "path": folder.path,
                    "enabled": folder.enabled === undefined ? true : !!folder.enabled,
                    "kind": String(folder.kind || "custom")
                });
            }
        }
        root.cloudBackupFolders = normalized;
        root.cloudBackupFoldersInitialized = true;
    }

    function setRecordingDirectory(key, value) {
        if (key in root)
            root[key] = value || "";
        return true;
    }

    function setLanguage(val) { root.language = val || "en_US"; }
    function setSidebarClockStyle(val) { root.sidebarClockStyle = val || "digital"; }
    function setSidebarCookieSides(val) { root.sidebarCookieSides = Number(val) || 14; }
    function setSidebarCookieConstantlyRotate(val) { root.sidebarCookieConstantlyRotate = !!val; }
    function setSidebarCookieHourMarks(val) { root.sidebarCookieHourMarks = !!val; }
    function setSidebarCookieTimeIndicators(val) { root.sidebarCookieTimeIndicators = !!val; }
    function setSidebarCookieDialStyle(val) { root.sidebarCookieDialStyle = val || "full"; }
    function setSidebarCookieHourHandStyle(val) { root.sidebarCookieHourHandStyle = val || "fill"; }
    function setSidebarCookieMinuteHandStyle(val) { root.sidebarCookieMinuteHandStyle = val || "medium"; }
    function setSidebarCookieSecondHandStyle(val) { root.sidebarCookieSecondHandStyle = val || "dot"; }
    function setSidebarCookieDateStyle(val) { root.sidebarCookieDateStyle = val || "bubble"; }
    function setUseTwelveHourClock(val) { root.useTwelveHourClock = !!val; }
    function setWeatherTemperatureUnit(val) { root.weatherTemperatureUnit = val; }
    function setSystemTemperatureUnit(val) { root.systemTemperatureUnit = val; }
    function setWeatherMapBaseProvider(val) { root.weatherMapBaseProvider = val; }
    function setWeatherMapOverlayProvider(val) { root.weatherMapOverlayProvider = val; }
    function setSystemMonitorGpuId(val) { root.systemMonitorGpuId = val; }
    function setSystemMonitorDiskDevice(val) { root.systemMonitorDiskDevice = val; }
    function setSystemMonitorNetworkInterface(val) { root.systemMonitorNetworkInterface = val; }
    function setStorageCapacityDiskDevice(val) { root.storageCapacityDiskDevice = val; }
    function setSystemMonitorIntervalMs(val) { root.systemMonitorIntervalMs = Number(val) || 2000; }
}
