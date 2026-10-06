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
    property bool switching: false
    property bool scanning: false

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]

    function wallpaperForScreen(screenName) {
        return root.currentWallpaper;
    }

    function setCurrentWallpaper(path) {
        if (!path || path === root.currentWallpaper)
            return;
        root.currentWallpaper = path;
        root.revision += 1;
        ThemeService.generateFromWallpaper(path);
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

    Component.onCompleted: {
        ThemeService.generateFromWallpaper(root.currentWallpaper);
    }
}
