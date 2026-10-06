//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import qs.Common

ShellRoot {
    Component.onCompleted: {
        console.log("[M1 Initial] colPrimary: " + Appearance.colors.colPrimary);
    }

    Connections {
        target: Appearance.m3colors
        function onM3primaryChanged() {
            console.log("[M1 FileView Dynamic Update] m3primary updated to: " + Appearance.m3colors.m3primary);
            console.log("[M1 Dynamic Layer0] colLayer0: " + Appearance.colors.colLayer0);
            console.log("[M1 Dynamic colPrimary] colPrimary: " + Appearance.colors.colPrimary);
        }
    }
}
