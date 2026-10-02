pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // 4px Base Grid
    readonly property int gridUnit: 4

    // Spacing
    readonly property int spacingXxs: 2
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24
    readonly property int spacingXxl: 32

    // Corner Radii
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 20
    readonly property int radiusCard: 16
    readonly property int radiusPill: 9999

    // Bar & Capsule Dimensions (Calibrated to Ubuntu GNOME 32px standard)
    readonly property int topBarHeight: 32
    readonly property int topBarFloatingMarginTop: 3
    readonly property int pillHeight: 26
    readonly property int pillPaddingHorizontal: 10
    readonly property int pillPaddingVertical: 3
    readonly property int pillSpacing: 6

    // Icons
    readonly property int iconSizeSm: 14
    readonly property int iconSizeMd: 16
    readonly property int iconSizeLg: 20
}
