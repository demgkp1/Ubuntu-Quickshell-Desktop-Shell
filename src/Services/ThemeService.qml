pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    property int iconThemeRevision: 0
    property bool isNiriSession: false
    property string effectiveMode: Appearance.effectiveMatugenMode
    property bool generating: false
    property string lastSource: ""
    property string generationError: ""
    property string externalGenerationError: ""
    property bool coreReloaded: false
    property var pendingGeneration: null

    function applyConfigToAppearance() {
        if (typeof PersonalizationConfig !== "undefined") {
            Appearance.matugenScheme = PersonalizationConfig.matugenScheme || "scheme-tonal-spot";
            Appearance.matugenMode = PersonalizationConfig.themeMode || "dark";
        }
    }

    function setThemeMode(mode) {
        if (typeof PersonalizationConfig !== "undefined" && PersonalizationConfig.setThemeMode) {
            PersonalizationConfig.setThemeMode(mode);
        }
        effectiveMode = mode === "light" ? "light" : "dark";
        Appearance.matugenMode = effectiveMode;
        if (typeof UiPreferences !== "undefined" && UiPreferences.setDarkMode) {
            UiPreferences.setDarkMode(effectiveMode === "dark");
        }
        root.regenerateFromCurrentWallpaper();
    }

    function generateFromWallpaper(path) {
        if (!path || path === "")
            return;

        root.applyConfigToAppearance();
        root.lastSource = path;
        let cleanPath = String(path);
        if (cleanPath.startsWith("file://"))
            cleanPath = cleanPath.substring(7);

        const mode = (typeof PersonalizationConfig !== "undefined" && PersonalizationConfig.themeMode) ? PersonalizationConfig.themeMode : "dark";
        const scheme = (typeof PersonalizationConfig !== "undefined" && PersonalizationConfig.matugenScheme) ? PersonalizationConfig.matugenScheme : "scheme-tonal-spot";

        const script = Paths.scriptPath("theme", "generate_matugen_colors.sh");
        const command = ["bash", script, "--image", cleanPath, "--scheme", scheme, "--mode", mode];
        root.startGeneration(command);
    }

    function generateFromColor(colorHex) {
        if (!colorHex || colorHex === "")
            return;

        root.applyConfigToAppearance();
        root.lastSource = colorHex;
        const mode = (typeof PersonalizationConfig !== "undefined" && PersonalizationConfig.themeMode) ? PersonalizationConfig.themeMode : "dark";
        const scheme = (typeof PersonalizationConfig !== "undefined" && PersonalizationConfig.matugenScheme) ? PersonalizationConfig.matugenScheme : "scheme-tonal-spot";

        const script = Paths.scriptPath("theme", "generate_matugen_colors.sh");
        const command = ["bash", script, "--color", colorHex, "--scheme", scheme, "--mode", mode];
        root.startGeneration(command);
    }

    function regenerateFromCurrentWallpaper() {
        const path = (typeof WallpaperService !== "undefined" && WallpaperService.currentWallpaper) ? WallpaperService.currentWallpaper : "/usr/share/backgrounds/ubuntu-wallpaper-d.png";
        if (path && path.startsWith("#"))
            root.generateFromColor(path);
        else if (path)
            root.generateFromWallpaper(path);
    }

    function startGeneration(command) {
        if (generateColorsProcess.running) {
            root.pendingGeneration = command;
            return;
        }
        root.pendingGeneration = null;
        root.generationError = "";
        root.externalGenerationError = "";
        root.coreReloaded = false;
        root.generating = true;
        generateColorsProcess.command = command;
        generateColorsProcess.running = true;
    }

    Process {
        id: generateColorsProcess

        stderr: StdioCollector {
            id: generationStderr
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    const status = JSON.parse(data);
                    if (status.schemaVersion !== 1)
                        return;
                    if (status.event === "core-ready") {
                        root.coreReloaded = true;
                        Appearance.reloadColors();
                    } else if (status.event === "core-error") {
                        root.generationError = status.error;
                    }
                } catch (e) {
                    // Ignore non-json lines
                }
            }
        }

        onExited: exitCode => {
            root.generating = false;
            if ((exitCode === 0 || exitCode === 3) && !root.coreReloaded) {
                Appearance.reloadColors();
            } else if (exitCode !== 0 && exitCode !== 3) {
                root.generationError = generationStderr.text.trim() || qsTr("Failed to generate Matugen colors");
            }
            if (root.pendingGeneration) {
                const nextCmd = root.pendingGeneration;
                root.pendingGeneration = null;
                Qt.callLater(() => root.startGeneration(nextCmd));
            }
        }
    }
}
