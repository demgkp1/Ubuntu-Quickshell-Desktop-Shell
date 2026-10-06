pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property real shellBackgroundOpacity: 0.85
    property bool shellBlurEnabled: true
    property bool shellBlurXray: false
}
