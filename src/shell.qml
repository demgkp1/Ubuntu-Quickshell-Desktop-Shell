//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        id: root
        title: "Ubuntu Shell PoC"
        visible: true
        color: "#1E1E2E"

        implicitWidth: 360
        implicitHeight: 60

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#1E1E2E"
            border.color: "#A6E3A1"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "Ubuntu Shell PoC (Nix + GNOME)"
                color: "#CDD6F4"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
