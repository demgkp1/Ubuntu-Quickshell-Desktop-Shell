pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    property bool busy: false
    property string lastScreenshotPath: ""
    property string lastColorPicked: ""

    signal screenshotSaved(string path)
    signal colorPicked(string hex)
    signal captureFailed(string reason)

    function captureRegion(options) {
        if (busy || RegionSelectionService.active)
            return false;
        return RegionSelectionService.begin("screenshot", options || {});
    }

    function captureScreen(options) {
        if (busy || RegionSelectionService.active)
            return false;
        return executeScreenshot("fullscreen", options || {});
    }

    function pickColor(options) {
        if (busy || RegionSelectionService.active)
            return false;
        return RegionSelectionService.begin("colorpicker", options || {});
    }

    function cancel() {
        if (RegionSelectionService.active)
            return RegionSelectionService.cancel();
        return false;
    }

    function executeScreenshot(geometry, options) {
        if (busy)
            return false;

        const opt = options || {};
        const copyClipboard = opt.copyClipboard !== false ? "true" : "false";
        const customPath = opt.outputPath || "";

        busy = true;
        screenshotProcess.command = [
            "bash",
            Paths.captureScriptsDir + "/screenshot_region.sh",
            String(geometry || "fullscreen"),
            customPath,
            copyClipboard
        ];
        screenshotProcess.running = true;
        return true;
    }

    function executeColorPick(geometry, options) {
        if (busy)
            return false;

        let coordX = "0";
        let coordY = "0";
        const geomStr = String(geometry || "");
        const match = geomStr.match(/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/);
        if (match) {
            coordX = match[3];
            coordY = match[4];
        }

        busy = true;
        colorPickProcess.command = [
            "bash",
            Paths.captureScriptsDir + "/pick_color.sh",
            coordX,
            coordY
        ];
        colorPickProcess.running = true;
        return true;
    }

    Connections {
        target: RegionSelectionService

        function onSelectionAccepted(action, geometry, options) {
            if (action === "screenshot") {
                root.executeScreenshot(geometry, options);
            } else if (action === "colorpicker") {
                root.executeColorPick(geometry, options);
            }
        }
    }

    Process {
        id: screenshotProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.busy = false;
            if (exitCode === 0) {
                const path = screenshotProcess.stdout.text.trim();
                root.lastScreenshotPath = path;
                root.screenshotSaved(path);
                Quickshell.execDetached([
                    "notify-send",
                    "-a", "Clavis Shell",
                    "-i", "accessories-screenshot",
                    qsTr("Screenshot Saved"),
                    path
                ]);
            } else {
                const err = screenshotProcess.stderr.text.trim() || qsTr("Failed to capture screenshot");
                root.captureFailed(err);
            }
        }
    }

    Process {
        id: colorPickProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: exitCode => {
            root.busy = false;
            if (exitCode === 0) {
                const hex = colorPickProcess.stdout.text.trim();
                root.lastColorPicked = hex;
                Quickshell.clipboardText = hex;
                root.colorPicked(hex);
                Quickshell.execDetached([
                    "notify-send",
                    "-a", "Clavis Shell",
                    "-i", "color-picker",
                    qsTr("Color Picked"),
                    qsTr("Copied to clipboard: ") + hex
                ]);
            } else {
                const err = colorPickProcess.stderr.text.trim() || qsTr("Failed to pick color");
                root.captureFailed(err);
            }
        }
    }
}
