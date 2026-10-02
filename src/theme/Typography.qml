pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Font Families
    readonly property string familySans: "Ubuntu, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    readonly property string familyMono: "Ubuntu Mono, 'JetBrains Mono', 'Fira Code', monospace"

    // Font Weights
    readonly property int weightLight: Font.Light
    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightDemiBold: Font.DemiBold
    readonly property int weightBold: Font.Bold

    // Font Sizes
    readonly property int sizeCaption: 10
    readonly property int sizeBodySmall: 11
    readonly property int sizeBody: 12
    readonly property int sizeBodyLarge: 14
    readonly property int sizeTitleSmall: 16
    readonly property int sizeTitle: 18
    readonly property int sizeDisplay: 22
}
