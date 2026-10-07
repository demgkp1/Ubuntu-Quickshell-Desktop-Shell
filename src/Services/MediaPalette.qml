pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property color primary: Appearance.colors.colPrimary
    property color onPrimary: Appearance.colors.colOnPrimary
    property color track: Appearance.colors.colSecondaryContainer

    function extract(artUrl, fallback) {
        const safeFallback = fallback === undefined || fallback === null ? Appearance.colors.colPrimary : fallback;
        root.primary = safeFallback;
    }
}
