pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property real backgroundTransparency: 0.15
    property real contentTransparency: 0.90

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function mix(color1, color2, percentage) {
        const amount = percentage === undefined ? 0.5 : percentage;
        const c1 = Qt.color(color1);
        const c2 = Qt.color(color2);
        return Qt.rgba(
            amount * c1.r + (1 - amount) * c2.r,
            amount * c1.g + (1 - amount) * c2.g,
            amount * c1.b + (1 - amount) * c2.b,
            amount * c1.a + (1 - amount) * c2.a
        );
    }

    function transparentize(color, percentage) {
        const amount = percentage === undefined ? 1 : percentage;
        const c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - amount));
    }

    function applyAlpha(color, alpha) {
        const c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, clamp01(alpha));
    }

    // Material 3 / Clavis Palette (Teal & Sage theme matching reference media_1790914244054.png)
    property QtObject m3colors: QtObject {
        property color m3background: "#101618"
        property color m3surface: "#101618"
        property color m3surfaceContainerLowest: "#0c1113"
        property color m3surfaceContainerLow: "#182023"
        property color m3surfaceContainer: "#1e262a"
        property color m3surfaceContainerHigh: "#273136"
        property color m3surfaceContainerHighest: "#323d42"
        property color m3onSurface: "#e1e9ec"
        property color m3onSurfaceVariant: "#bfcbcf"
        property color m3outline: "#899599"
        property color m3outlineVariant: "#404a4e"

        // Hero Cyan / Mint Accent
        property color m3primary: "#64d3c3"
        property color m3onPrimary: "#003831"
        property color m3primaryContainer: "#005047"
        property color m3onPrimaryContainer: "#84f1e0"

        property color m3secondary: "#b1ccc6"
        property color m3onSecondary: "#1c3531"
        property color m3secondaryContainer: "#324b47"
        property color m3onSecondaryContainer: "#cde9e2"

        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3shadow: "#000000"
    }

    property QtObject colors: QtObject {
        property color colLayer0Base: root.m3colors.m3surfaceContainerLowest
        property color colLayer0: root.applyAlpha(colLayer0Base, 0.88)
        property color colLayer0Border: Qt.rgba(1, 1, 1, 0.08)

        property color colLayer1: root.applyAlpha(root.m3colors.m3surfaceContainerLow, 0.85)
        property color colLayer1Hover: root.applyAlpha(root.m3colors.m3surfaceContainer, 0.90)
        property color colLayer1Active: root.applyAlpha(root.m3colors.m3surfaceContainerHigh, 0.95)
        property color colOnLayer1: root.m3colors.m3onSurfaceVariant

        property color colLayer2: root.applyAlpha(root.m3colors.m3surfaceContainer, 0.90)
        property color colLayer2Hover: root.applyAlpha(root.m3colors.m3surfaceContainerHigh, 0.95)
        property color colLayer2Active: root.applyAlpha(root.m3colors.m3surfaceContainerHighest, 1.0)
        property color colLayer2Disabled: root.applyAlpha(root.m3colors.m3surfaceContainerLow, 0.5)
        property color colOnLayer2: root.m3colors.m3onSurface

        property color colLayer3: root.applyAlpha(root.m3colors.m3surfaceContainerHigh, 0.95)
        property color colOnLayer3: root.m3colors.m3onSurface

        // Primary Active Accents
        property color colPrimary: root.m3colors.m3primary
        property color colOnPrimary: root.m3colors.m3onPrimary
        property color colPrimaryHover: root.mix(colPrimary, "#ffffff", 0.85)
        property color colPrimaryActive: root.mix(colPrimary, "#000000", 0.85)
        property color colPrimaryContainer: root.m3colors.m3primaryContainer
        property color colOnPrimaryContainer: root.m3colors.m3onPrimaryContainer

        // Secondary / Split Slider Tracks
        property color colSecondaryContainer: root.m3colors.m3secondaryContainer
        property color colOnSecondaryContainer: root.m3colors.m3onSecondaryContainer

        property color colOnSurface: root.m3colors.m3onSurface
        property color colOnSurfaceVariant: root.m3colors.m3onSurfaceVariant
        property color colOutline: root.m3colors.m3outline
        property color colOutlineVariant: root.m3colors.m3outlineVariant
        property color colShadow: root.applyAlpha(root.m3colors.m3shadow, 0.35)
        property color colError: root.m3colors.m3error
        property color colOnError: root.m3colors.m3onError
    }

    property QtObject rounding: QtObject {
        property int extraSmall: 4
        property int small: 12
        property int normal: 17
        property int large: 23
        property int extraLarge: 28
        property int full: 9999
    }

    property QtObject spacing: QtObject {
        property int panelPadding: 16
        property int small: 8
        property int medium: 16
        property int large: 24
    }

    property QtObject animation: Animations.animation
}
