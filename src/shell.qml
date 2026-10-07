//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Components
import qs.Modules.Bar
import qs.Modules.Dock
import qs.Modules.Keystone
import qs.Modules.Launcher
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

    // Keystone Dynamic Island
    Keystone {
        id: keystone
    }

    // Floating fluid Dock
    DockHost {
        id: dockHost
    }

    // Spotlight Launcher Host Window
    LauncherWindow {
        id: spotlightLauncher
    }

    IpcHandler {
        target: "spotlight"

        function toggle(): string {
            spotlightLauncher.toggleWindow();
            return spotlightLauncher.windowPhase.toUpperCase();
        }

        function open(): string {
            spotlightLauncher.openSpotlight();
            return spotlightLauncher.windowPhase.toUpperCase();
        }

        function search(): string {
            spotlightLauncher.openSpotlight("search");
            return "SEARCH";
        }

        function close(): string {
            spotlightLauncher.requestClose();
            return spotlightLauncher.windowPhase.toUpperCase();
        }

        function web(): string {
            spotlightLauncher.openWebMode();
            return "WEB";
        }

        function command(name: string): string {
            return spotlightLauncher.runCommand(name);
        }

        function commands(): string {
            return openMode("commands");
        }

        function files(): string {
            return openMode("files");
        }

        function openMode(mode: string): string {
            if (spotlightLauncher.normalizedMode(mode || "") === "")
                return "INVALID_MODE";

            spotlightLauncher.openSpotlight(mode);
            return String(mode).toUpperCase();
        }
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

    // Interactive shortcuts to toggle Spotlight Launcher
    Shortcut {
        sequence: "Alt+Space"
        onActivated: {
            spotlightLauncher.toggleWindow();
            console.warn("[M9 Spotlight] Alt+Space toggled launcher:", spotlightLauncher.windowPhase);
        }
    }

    Shortcut {
        sequence: "F2"
        onActivated: {
            spotlightLauncher.toggleWindow();
            console.warn("[M9 Spotlight] F2 toggled launcher:", spotlightLauncher.windowPhase);
        }
    }
}
