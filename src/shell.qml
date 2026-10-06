//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Components
import qs.Modules.Sidebars
import qs.Services
import qs.Widgets.common

ShellRoot {
    id: shellRoot

    Component.onCompleted: {
        console.log("================ M3 SIDEBAR HOST & QUICK SETTINGS VALIDATION ================");
        console.log("[M3 SidebarHost] width: " + sidebarHost.width + ", height: " + sidebarHost.height);
        console.log("[M3 SidebarHost] screen: " + (sidebarHost.screen ? sidebarHost.screen.name : "none"));
        console.log("[M3 State] quickSettingsOpen: " + WidgetState.quickSettingsOpen);
        console.log("=============================================================================");
    }

    SidebarHostWindow {
        id: sidebarHost
    }

    // Trigger toggle via timer for smoke test verification of QuickSettings expansion
    Timer {
        id: testTriggerTimer
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            console.log("[M3 Test] Triggering QuickSettings open...");
            WidgetState.quickSettingsOpen = true;
        }
    }

    // Trigger close via timer for verification of QuickSettings collapse
    Timer {
        id: testCloseTimer
        interval: 1800
        running: true
        repeat: false
        onTriggered: {
            console.log("[M3 Test] Triggering QuickSettings close...");
            WidgetState.quickSettingsOpen = false;
        }
    }

    Connections {
        target: WidgetState
        function onQuickSettingsOpenChanged() {
            console.log("[M3 State Transition] WidgetState.quickSettingsOpen changed to:", WidgetState.quickSettingsOpen);
        }
    }

    // Interactive shortcuts to toggle QuickSettings
    Shortcut {
        sequence: "F1"
        onActivated: {
            WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen;
            console.log("[M3 Test] F1 toggled quickSettingsOpen:", WidgetState.quickSettingsOpen);
        }
    }

    Shortcut {
        sequence: "Ctrl+Alt+S"
        onActivated: {
            WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen;
            console.log("[M3 Test] Ctrl+Alt+S toggled quickSettingsOpen:", WidgetState.quickSettingsOpen);
        }
    }
}
