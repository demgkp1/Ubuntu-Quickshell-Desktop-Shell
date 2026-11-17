import QtQuick
import Quickshell
// Native imports are prepended dynamically by native-check.sh.

ShellRoot {
    id: root
    property int captured: 0
    property int paletteStage: 0
    property color firstPalette: "transparent"
    property bool paletteDone: false
    readonly property string output: Quickshell.env("CLAVIS_TEST_OUTPUT")
    function finish() {
        if (captured === 3 && paletteDone) {
            console.log("NATIVE_RUNTIME_VERIFIED");
            Qt.quit();
        }
    }
    FloatingWindow {
        id: probeWindow
        visible: true
        implicitWidth: 360
        implicitHeight: 120
        color: "#101010"
        Row {
            anchors.centerIn: parent
            spacing: 10
            MaterialShape { id: square; width: 96; height: 96; color: "#88d0ec"; shape: MaterialShape.Square }
            MaterialShape { id: cookie; width: 96; height: 96; color: "#88d0ec"; shape: MaterialShape.Cookie4Sided }
            MaterialShape { id: sunny; width: 96; height: 96; color: "#88d0ec"; shape: MaterialShape.Sunny }
        }
    }
    CavaProvider { id: cava; active: false }
    AudioLevelProvider { id: level; active: false; captureSink: true }
    Connections {
        target: MediaPalettePlugin
        function onPaletteChanged() {
            if (!MediaPalettePlugin.available) return;
            if (root.paletteStage === 1) {
                root.firstPalette = MediaPalettePlugin.primary;
                root.paletteStage = 2;
                MediaPalettePlugin.extract("file://" + root.output + "/blue.ppm", "#00ff00");
            } else if (root.paletteStage === 2) {
                if (String(root.firstPalette) === String(MediaPalettePlugin.primary)) throw new Error("Cover palette ignored image input");
                root.paletteDone = true;
                root.finish();
            }
        }
    }
    Timer {
        interval: 300
        running: true
        onTriggered: {
            if (cava.available || level.available) throw new Error("Inactive audio falsely available");
            if (!WindowDecoration.makeFrameless(probeWindow.contentItem)) throw new Error("Owned native window decoration flags failed");
            const startupIconTheme = IconThemeController.systemThemeName;
            IconThemeController.setThemeName("clavis-native-test-theme");
            if (IconThemeController.themeName !== "clavis-native-test-theme") throw new Error("Native Qt icon theme did not change");
            IconThemeController.setThemeName("");
            if (IconThemeController.themeName !== startupIconTheme) throw new Error("Qt default icon theme did not restore");
            for (const pair of [[square, "square"], [cookie, "cookie"], [sunny, "sunny"]]) {
                if (!pair[0].grabToImage(result => {
                    if (!result.saveToFile(root.output + "/" + pair[1] + ".png")) throw new Error("Shape capture failed");
                    root.captured++;
                    root.finish();
                })) throw new Error("Shape grab failed");
            }
            root.paletteStage = 1;
            MediaPalettePlugin.extract("file://" + root.output + "/red.ppm", "#00ff00");
        }
    }
    Timer { interval: 5000; running: true; onTriggered: { console.error("Native verification deadline exceeded"); Qt.quit(); } }
}
