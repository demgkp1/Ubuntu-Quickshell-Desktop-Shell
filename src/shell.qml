//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Components
import qs.Widgets.common

ShellRoot {
    Component.onCompleted: {
        console.log("================ M2 COMPONENTS & WIDGETS VALIDATION ================");
        console.log("[M2 Symbol] text: " + testSymbol.text + ", size: " + testSymbol.iconSize);
        console.log("[M2 SplitSlider] value: " + testSlider.value + ", trackWidth: " + testSlider.trackWidth);
        console.log("[M2 SplitSlider] highlightColor: " + testSlider.highlightColor);
        console.log("[M2 QuickToggle] toggled: " + testToggle.toggled + ", title: " + testToggle.title);
        console.log("[M2 WidgetPanel] radius: " + testPanel.radius);
        console.log("[M2 TopBarPill] radius: " + testPill.radius);
        console.log("=====================================================================");
    }

    Item {
        id: container
        visible: false

        MaterialSymbol {
            id: testSymbol
            text: "volume_up"
            iconSize: 24
        }

        MaterialSplitSlider {
            id: testSlider
            value: 0.35
            width: 200
            height: 40
        }

        QuickToggleButton {
            id: testToggle
            title: "Wi-Fi"
            subtitle: "Connected"
            iconName: "wifi"
            toggled: true
        }

        WidgetPanel {
            id: testPanel
            width: 300
            height: 200
        }

        TopBarPill {
            id: testPill
            width: 100
            height: Sizes.barPillThickness
        }
    }
}
