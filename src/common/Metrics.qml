pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property real spacingXXS: 2
    readonly property real spacingXS: 4
    readonly property real spacingS: 8
    readonly property real spacingM: 12
    readonly property real spacingL: 16
    readonly property real spacingXL: 24

    readonly property real iconS: 16
    readonly property real iconM: 22
    readonly property real iconL: 32

    readonly property real controlHeightS: 32
    readonly property real controlHeightM: 40
    readonly property real controlHeightL: 48
    readonly property real controlHeightXL: 56

    readonly property real cornerXS: 4
    readonly property real cornerS: 12
    readonly property real cornerM: 17
    readonly property real cornerL: 23
    readonly property real cornerXL: 28

    readonly property real cardPadding: spacingL
    readonly property real panelPadding: 16
    readonly property real barHeight: 44
}
