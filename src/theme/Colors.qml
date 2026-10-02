pragma Singleton
import QtQuick
import Quickshell

/**
 * Colors - Material You / Matugen Tonal Palette (Sage & Mint Glass)
 *
 * Inspired by Clavis Desktop Shell's dynamic wallpaper-extracted theme:
 * Translucent frosted teal/slate glass surfaces, luminous mint accents (#72D5BE),
 * deep contrast text on bright surfaces, and delicate physical glass rims.
 */
Singleton {
    id: root

    // ==========================================
    // 1. Accent & Hero Colors (Luminous Mint / Cyan)
    // ==========================================
    readonly property color primary: "#72d5be"            // Bright luminous mint/cyan (Hero accent)
    readonly property color primaryHover: "#88e6d0"       // Hovered primary state
    readonly property color primaryActive: "#56c3b1"      // Pressed/active state
    readonly property color accent: primary               // Accent alias for backward compatibility
    readonly property color textOnPrimary: "#00382e"          // Deep forest dark teal (High contrast text on primary)
    readonly property color primaryContainer: "#005143"   // Deep teal accent container
    readonly property color textOnPrimaryContainer: "#9df2dc" // Luminous text on container

    readonly property color secondary: "#b3cad5"         // Soft slate-teal secondary
    readonly property color textOnSecondary: "#1e333c"

    // ==========================================
    // 2. Base & Solid Surfaces (Deep Forest Slate)
    // ==========================================
    readonly property color crust: "#0a1415"             // Deepest slate-black
    readonly property color mantle: "#0f1e20"            // Panel backing
    readonly property color base: "#142628"              // Card base
    readonly property color surface0: "#1c3539"          // Subtle card surface
    readonly property color surface1: "#25464b"          // Elevated card surface
    readonly property color surface2: "#30585f"          // Highlighted card surface

    // ==========================================
    // 3. Frosted Glassmorphism Surfaces (Translucent)
    // ==========================================
    readonly property color glassBackground: Qt.rgba(0.08, 0.17, 0.19, 0.72)        // Frosted dark teal glass
    readonly property color glassBackgroundHover: Qt.rgba(0.12, 0.24, 0.26, 0.85)   // Hovered glass
    readonly property color glassBackgroundActive: Qt.rgba(0.16, 0.32, 0.35, 0.92)  // Active glass
    readonly property color glassBorder: Qt.rgba(0.45, 0.84, 0.75, 0.22)            // Fine mint glass rim
    readonly property color glassBorderHover: Qt.rgba(0.55, 0.92, 0.82, 0.45)       // Hovered glowing rim
    readonly property color glassShadow: Qt.rgba(0.0, 0.04, 0.05, 0.38)             // Subtle ambient shadow

    // Legacy borders (retained for backward compatibility)
    readonly property color borderSubtle: glassBorder
    readonly property color border: Qt.rgba(0.45, 0.84, 0.75, 0.35)
    readonly property color borderHighlight: primary

    // ==========================================
    // 4. Typography Colors
    // ==========================================
    readonly property color text: "#e0f2ed"              // Soft luminous white-mint
    readonly property color textSecondary: "#9bbdb6"     // Soft muted sage
    readonly property color textTertiary: "#6f918b"      // Low contrast text
    readonly property color textMuted: "#4d6e68"         // Hints & subtle separators

    // ==========================================
    // 5. Semantic / Status Colors
    // ==========================================
    readonly property color success: "#72d5be"           // Mint green
    readonly property color warning: "#f5ca7b"           // Warm amber / golden
    readonly property color error: "#ff8a80"             // Coral red (power button accent)
    readonly property color info: "#82b1ff"              // Ice blue

    // ==========================================
    // 6. Utility Functions
    // ==========================================
    function alpha(c, a) {
        var baseColor = Qt.color(c);
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Math.max(0, Math.min(1, a)));
    }
}
