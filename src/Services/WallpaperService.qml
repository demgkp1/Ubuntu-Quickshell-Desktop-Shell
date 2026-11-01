pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    property string currentWallpaper: "/usr/share/backgrounds/ubuntu-wallpaper-d.png"
    property var wallpapers: [currentWallpaper]
    property bool busy: false
    property int revision: 0
    property int settingsRevision: 0
    property bool switching: false
    property bool scanning: false

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]
    property bool canUseAwww: false
    property string lastDesktopError: ""
    property string lastOverviewError: ""
    property string desktopWallpaperBackend: "gnome"
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
        return String(path || "").replace(/^file:\/\//, "");
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
        if (!path)
            return;
        const cleanPath = root.normalizedPath(path);
        root.currentWallpaper = cleanPath;
        root.revision += 1;

        // Persist to PersonalizationConfig
        PersonalizationConfig.setWallpaperPath(cleanPath);

        // Write to GNOME desktop background (Mutter X11)
        const fileUri = "file://" + cleanPath;
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.background", "picture-uri", fileUri]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.background", "picture-uri-dark", fileUri]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.background", "picture-options", "zoom"]);

        ThemeService.generateFromWallpaper(cleanPath);
    }

    function setWallpaper(path) {
        root.setCurrentWallpaper(path);
        return true;
    }

    function setWallpaperFromFile(path, output) {
        root.setCurrentWallpaper(path);
        return true;
    }

    function setOverviewWallpaper(path, output) {
        root.setCurrentWallpaper(path);
        return true;
    }

    function clearOverviewWallpaper(output) {
        root.clearWallpaper(output);
    }

    function refreshOverviewBackdropRule() {
        root.revision += 1;
        return true;
    }

    function setDesktopWallpaperBackend(val) {
        if (!val || root.desktopWallpaperBackend === val)
            return;
        root.desktopWallpaperBackend = String(val);
        root.settingsRevision += 1;
    }

    function setWallpaperTransitionType(type) {
        if (!type || root.wallpaperTransitionType === type)
            return;
        root.wallpaperTransitionType = String(type);
        root.settingsRevision += 1;
    }

    function setTransitionDurationMs(ms) {
        const val = Number(ms);
        if (!isFinite(val) || val < 0)
            return;
        root.transitionDurationMs = val;
        root.settingsRevision += 1;
    }

    function setTransitionBezierCurve(curve) {
        if (!curve)
            return;
        root.transitionBezierCurve = String(curve);
        root.settingsRevision += 1;
    }

    function setTransitionEasingMode(mode) {
        if (!mode)
            return;
        root.transitionEasingMode = String(mode);
        root.settingsRevision += 1;
    }

    function setWallpaperFolder(path) {
        if (!path)
            return;
        const clean = root.normalizedPath(path);
        root.wallpaperFolder = clean;
        root.scan();
    }

    function setOverviewFillModeForScreen(screen, mode) {
        if (!screen || !mode)
            return;
        const copy = Object.assign({}, root.overviewFillModes);
        copy[screen] = String(mode);
        root.overviewFillModes = copy;
        root.settingsRevision += 1;
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
        return "AspectCrop";
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
        gsettingsDarkProc.running = true;
    }

    Process {
        id: gsettingsDarkProc
        command: ["gsettings", "get", "org.gnome.desktop.background", "picture-uri-dark"]
        running: true

        stdout: StdioCollector {
            onTextChanged: {
                let out = text.trim();
                out = out.replace(/^'file:\/\//, "").replace(/'$/, "").replace(/^'/, "");
                if (out && out.length > 0 && out !== root.currentWallpaper) {
                    root.currentWallpaper = out;
                    root.revision += 1;
                    ThemeService.generateFromWallpaper(out);
                }
            }
        }
    }

    function setWallpaperFillModeForScreen(screenName, mode) {
        root.revision += 1;
        return true;
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
        root.setCurrentWallpaper(root.wallpapers[nextIndex]);
        return true;
    }

    function cycleNext() { return root.applyCycle("next"); }
    function cyclePrevious() { return root.applyCycle("previous"); }
    function cycleRandom() { return root.applyCycle("random"); }
    function clearWallpaper(screenName) {
        root.setCurrentWallpaper("/usr/share/backgrounds/ubuntu-wallpaper-d.png");
    }

    Process {
        id: scanProc
        command: ["find", "/usr/share/backgrounds", "-type", "f", "(", "-name", "*.png", "-o", "-name", "*.jpg", "-o", "-name", "*.webp", ")"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                const list = text.trim().split("\n").filter(p => p.length > 0);
                if (list.length > 0)
                    root.wallpapers = list;
            }
        }
    }

    Component.onCompleted: {
        ThemeService.generateFromWallpaper(root.currentWallpaper);
    }
}
