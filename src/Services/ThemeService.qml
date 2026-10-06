pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property int iconThemeRevision: 0
    property bool isNiriSession: false
    property string effectiveMode: Appearance.effectiveMatugenMode
}
