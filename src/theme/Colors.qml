pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Background & Surface
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    // Borders & Dividers
    readonly property color borderSubtle: "#22ffffff"
    readonly property color border: "#313244"
    readonly property color borderHighlight: "#a6e3a1"

    // Text & Typography
    readonly property color text: "#cdd6f4"
    readonly property color textSecondary: "#bac2de"
    readonly property color textTertiary: "#a6adc8"
    readonly property color textMuted: "#6c7086"

    // Brand & Accents
    readonly property color primary: "#e95420"         // Ubuntu Warm Orange
    readonly property color primaryHover: "#ff6e38"
    readonly property color secondary: "#cba6f7"       // Mauve

    // Semantic States
    readonly property color success: "#a6e3a1"         // Green
    readonly property color warning: "#f9e2af"         // Yellow
    readonly property color error: "#f38ba8"           // Red
    readonly property color info: "#89b4fa"            // Blue

    // Alpha helper function
    function alpha(c, a) {
        var baseColor = Qt.color(c);
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Math.max(0, Math.min(1, a)));
    }
}
