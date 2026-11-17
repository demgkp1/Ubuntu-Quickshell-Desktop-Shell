pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property string currentWallpaper: root.normalizedPath(GnomeSession.desktop.wallpaper || "")
    property var wallpapers: [currentWallpaper]
    property bool busy: false
    property int wallpaperRequest: -1
    readonly property bool available: !!GnomeSession.desktop.wallpaperAvailable
    readonly property bool supportsTransitions: false
    readonly property bool supportsPerOutput: false
    readonly property bool supportsOverviewWallpaper: false
    readonly property string renderOwner: "GNOME Shell"
    property int revision: 0
    property int settingsRevision: 0
    property bool switching: false
    property bool scanning: false

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]
    property bool canUseAwww: false
    property string lastDesktopError: ""
    property string lastOverviewError: ""
    readonly property string desktopWallpaperBackend: "gnome"
    property string wallpaperTransitionType: "fade"
    property int transitionDurationMs: 300
    property string transitionBezierCurve: "easeInOutQuad"
    property string transitionEasingMode: "InOutQuad"
    property string wallpaperFolder: "/usr/share/backgrounds"
    property var overviewFillModes: ({})

    function wallpaperForScreen(screenName) {
        return root.currentWallpaper;
    }

    function overviewWallpaperForScreen(screenName) {
        return root.currentWallpaper;
    }

    function normalizedPath(path) {
        const value = String(path || "");
        if (!value.startsWith("file://")) return value;
        try { return decodeURIComponent(value.slice(7)); }
        catch (error) { return value.slice(7); }
    }

    function parentFolder(path) {
        if (!path) return "";
        const clean = root.normalizedPath(path);
        const idx = clean.lastIndexOf("/");
        return idx > 0 ? clean.substring(0, idx) : "/";
    }

    function sourceKind(path) {
        if (!path) return "file";
        return root.isColorSource(path) ? "palette" : "file";
    }

    function setCurrentWallpaper(path) {
        if (!root.available || !path || root.busy) return false;
        root.wallpaperRequest = GnomeSession.request("wallpaper", {path: root.normalizedPath(path)});
        root.busy = root.wallpaperRequest > 0;
        return root.busy;
    }

    function setWallpaper(path) {
        return root.setCurrentWallpaper(path);
    }

    function setWallpaperFromFile(path, output) {
        if (output) return root.unsupported(qsTr("GNOME uses one wallpaper selection for all outputs"));
        return root.setCurrentWallpaper(path);
    }

    function setOverviewWallpaper(path, output) {
        return root.unsupported(qsTr("GNOME owns the overview wallpaper"));
    }

    function clearOverviewWallpaper(output) {
        return root.unsupported(qsTr("GNOME owns the overview wallpaper"));
    }

    function refreshOverviewBackdropRule() {
        return root.available;
    }

    function setDesktopWallpaperBackend(val) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function setWallpaperTransitionType(type) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function setTransitionDurationMs(ms) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function setTransitionBezierCurve(curve) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function setTransitionEasingMode(mode) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function setWallpaperFolder(path) {
        if (!path)
            return;
        const clean = root.normalizedPath(path);
        root.wallpaperFolder = clean;
        root.scan();
    }

    function setOverviewFillModeForScreen(screen, mode) {
        return root.unsupported(qsTr("GNOME owns desktop rendering; Clavis custom transitions, easing and per-output overview settings are unavailable"));
    }

    function basename(path) {
        if (!path)
            return "";
        const value = String(path);
        if (root.isColorSource(value))
            return qsTr("Solid-color wallpaper ") + value;
        return value.substring(value.lastIndexOf("/") + 1);
    }

    function isImagePath(value) {
        if (!value)
            return false;
        const lower = String(value).toLowerCase();
        for (let i = 0; i < root.imageExtensions.length; i += 1) {
            if (lower.endsWith("." + root.imageExtensions[i]))
                return true;
        }
        return false;
    }

    function isColorSource(value) {
        return !!value && String(value).startsWith("#");
    }

    function primaryColor(value) {
        return root.isColorSource(value) ? String(value) : "";
    }

    function fillModeForScreen(screenName) {
        const modes = {zoom: "AspectCrop", scaled: "Fit", stretched: "Stretch", wallpaper: "Tile", centered: "Pad", spanned: "panorama"};
        return modes[GnomeSession.desktop.fill] || "AspectCrop";
    }

    function qtFillMode(modeName) {
        switch (modeName) {
        case "Stretch":
            return Image.Stretch;
        case "Fit":
        case "PreserveAspectFit":
            return Image.PreserveAspectFit;
        case "Fill":
        case "PreserveAspectCrop":
        case "panorama":
            return Image.PreserveAspectCrop;
        case "Tile":
            return Image.Tile;
        case "TileVertically":
            return Image.TileVertically;
        case "TileHorizontally":
            return Image.TileHorizontally;
        case "Pad":
            return Image.Pad;
        default:
            return Image.PreserveAspectCrop;
        }
    }

    function shaderFillMode(modeName) {
        switch (modeName) {
        case "Stretch":
            return 0;
        case "Fit":
        case "PreserveAspectFit":
            return 1;
        case "Fill":
        case "PreserveAspectCrop":
        case "panorama":
            return 2;
        case "Tile":
        case "TileVertically":
        case "TileHorizontally":
            return 3;
        case "Pad":
            return 4;
        default:
            return 2;
        }
    }

    function refresh() {
        return GnomeSession.helperRunning;
    }

    function setWallpaperFillModeForScreen(screenName, mode) {
        const modes = {AspectCrop: "zoom", Fill: "zoom", PreserveAspectCrop: "zoom", Fit: "scaled", PreserveAspectFit: "scaled", Stretch: "stretched", Tile: "wallpaper", Pad: "centered", panorama: "spanned"};
        if (!modes[mode] || !available) return root.unsupported(qsTr("Unsupported GNOME wallpaper fill mode"));
        return GnomeSession.request("fill", {mode: modes[mode]}) > 0;
    }

    function scan() {
        if (!scanProc.running)
            scanProc.running = true;
    }

    function applyCycle(action) {
        if (!root.wallpapers || root.wallpapers.length === 0)
            return false;
        let index = root.wallpapers.indexOf(root.currentWallpaper);
        let nextIndex = 0;
        if (action === "previous") {
            nextIndex = index >= 0 ? (index - 1 + root.wallpapers.length) % root.wallpapers.length : root.wallpapers.length - 1;
        } else if (action === "random") {
            if (root.wallpapers.length > 1) {
                do {
                    nextIndex = Math.floor(Math.random() * root.wallpapers.length);
                } while (nextIndex === index);
            }
        } else {
            nextIndex = index >= 0 ? (index + 1) % root.wallpapers.length : 0;
        }
        return root.setCurrentWallpaper(root.wallpapers[nextIndex]);
    }

    function cycleNext() { return root.applyCycle("next"); }
    function cyclePrevious() { return root.applyCycle("previous"); }
    function cycleRandom() { return root.applyCycle("random"); }
    function clearWallpaper(screenName) {
        return root.unsupported(qsTr("Select a wallpaper file or use GNOME Settings; no assumed default file is applied"));
    }

    Process {
        id: scanProc
        command: ["find", root.wallpaperFolder, "-maxdepth", "4", "-type", "f", "(", "-name", "*.png", "-o", "-name", "*.jpg", "-o", "-name", "*.webp", ")"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                const list = text.trim().split("\n").filter(p => p.length > 0);
                if (list.length > 0)
                    root.wallpapers = list;
            }
        }
    }

    function unsupported(message) {
        root.lastDesktopError = message;
        return root.supportsTransitions;
    }
    Connections {
        target: GnomeSession
        function onOperationFinished(id, accepted, error) {
            if (id !== root.wallpaperRequest) return;
            root.busy = false;
            root.lastDesktopError = accepted ? "" : error;
        }
        function onDesktopChanged() {
            if (!root.available) root.busy = false;
        }
    }
    onCurrentWallpaperChanged: {
        root.revision++;
        if (root.currentWallpaper) {
            PersonalizationConfig.setWallpaperPath(root.currentWallpaper);
            ThemeService.generateFromWallpaper(root.currentWallpaper);
        }
    }
}
