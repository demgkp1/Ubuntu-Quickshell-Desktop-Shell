//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Components
import qs.Modules.Bar
import qs.Modules.Sidebars
import qs.Services
import qs.Widgets.common

ShellRoot {
    id: shellRoot

    Scope {
        id: lifecycleManager

        Component.onCompleted: {
            Qt.callLater(() => {
                console.warn("================ M4 DUAL HOST WINDOW VALIDATION ================");
                console.warn("[M4 TopBar Host] width: " + (barWindow ? barWindow.width : 0) + ", height: " + (barWindow ? barWindow.height : 0));
                console.warn("[M4 TopBar Host] screen: " + (barWindow && barWindow.screen ? barWindow.screen.name : "none"));
                console.warn("[M4 Sidebar Host] width: " + (sidebarHost ? sidebarHost.width : 0) + ", height: " + (sidebarHost ? sidebarHost.height : 0));
                console.warn("[M4 Sidebar Host] screen: " + (sidebarHost && sidebarHost.screen ? sidebarHost.screen.name : "none"));
                console.warn("[M4 Initial State] quickSettingsOpen: " + WidgetState.quickSettingsOpen);
                console.warn("================================================================");
            });
        }

        // Trigger toggle via timer for smoke test verification of QuickSettings expansion
        Timer {
            id: testTriggerTimer
            interval: 500
            running: true
            repeat: false
            onTriggered: {
                console.warn("[M4 Test] Triggering QuickSettings open...");
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
                console.warn("[M4 Test] Triggering QuickSettings close...");
                WidgetState.quickSettingsOpen = false;
            }
        }

        Connections {
            target: WidgetState
            function onQuickSettingsOpenChanged() {
                console.warn("[M4 State Transition] WidgetState.quickSettingsOpen changed to:", WidgetState.quickSettingsOpen);
            }
        }
    }

    // Top permanent horizontal bar host window
    HorizontalBarWindow {
        id: barWindow
    }

    // Fullscreen transparent overlay sidebar host window
    SidebarHostWindow {
        id: sidebarHost
    }

    // Interactive shortcuts to toggle QuickSettings
    Shortcut {
        sequence: "F1"
        onActivated: {
            WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen;
            console.warn("[M4 Test] F1 toggled quickSettingsOpen:", WidgetState.quickSettingsOpen);
        }
    }

    Shortcut {
        sequence: "Ctrl+Alt+S"
        onActivated: {
            WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen;
            console.warn("[M4 Test] Ctrl+Alt+S toggled quickSettingsOpen:", WidgetState.quickSettingsOpen);
        }
    }
}
