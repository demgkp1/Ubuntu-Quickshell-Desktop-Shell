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
import qs.Modules.ControlCenter
import qs.Modules.DesktopCards
import qs.Modules.Dock
import qs.Modules.HotCorners
import qs.Modules.Keystone
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.PowerMenu
import qs.Modules.RegionSelector
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

    // Desktop interactive cards host
    DesktopCardHost {
        id: desktopCardHost
    }

    // Floating fluid Dock
    DockHost {
        id: dockHost
    }

    IpcHandler {
        target: "dock"

        function setIconSize(size: int): int {
            DockService.setOption("iconSize", size);
            return DockService.iconSize;
        }

        function getIconSize(): int {
            return DockService.iconSize;
        }

        function setMagnification(scale: real): real {
            DockService.setOption("magnificationScale", scale);
            return DockService.magnificationScale;
        }
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

    // Lazy-loaded Control Center Window
    LazyLoader {
        id: controlCenterLoader

        active: false
        Component.onCompleted: ControlCenterService.registerLoader(controlCenterLoader)
        onItemChanged: {
            if (item)
                ControlCenterService.registerWindow(item);
        }

        ControlCenterWindow {
            id: controlCenterWindow

            onPopoutClosed: ControlCenterService.windowClosed(controlCenterWindow)
        }
    }

    IpcHandler {
        target: "controlcenter"

        function open(pageId: string): string {
            ControlCenterService.open(pageId || "");
            return "OPEN";
        }

        function openSearch(targetId: string): string {
            ControlCenterService.openSearch(targetId || "");
            return "SEARCH";
        }

        function toggle(): string {
            ControlCenterService.toggle();
            return "TOGGLE";
        }

        function close(): string {
            ControlCenterService.close();
            return "CLOSE";
        }
    }

    // Lock subsystem
    Lock {
        id: sessionLocker
    }

    // Power Menu subsystem
    PowerMenu {
        id: powerMenu
    }

    Connections {
        target: PowerMenuService
        function onActionRequested(action) {
            console.log("[PowerMenu] Action requested:", action);
            switch (action) {
            case "lock":
                sessionLocker.open();
                break;
            case "logout":
                Quickshell.execDetached(["gnome-session-quit", "--logout", "--no-prompt"]);
                break;
            case "suspend":
                Quickshell.execDetached(["systemctl", "suspend"]);
                break;
            case "poweroff":
                Quickshell.execDetached(["systemctl", "poweroff"]);
                break;
            case "hibernate":
                Quickshell.execDetached(["systemctl", "hibernate"]);
                break;
            case "reboot":
                Quickshell.execDetached(["systemctl", "reboot"]);
                break;
            }
        }
    }

    IpcHandler {
        target: "powermenu"

        function open(): string {
            PowerMenuService.open();
            return "OPEN";
        }

        function toggle(): string {
            PowerMenuService.toggle();
            return "TOGGLE";
        }

        function close(): string {
            PowerMenuService.close();
            return "CLOSE";
        }

        function trigger(action: string): string {
            PowerMenuService.trigger(action || "");
            return String(action).toUpperCase();
        }
    }

    IpcHandler {
        target: "lock"

        function open(): string {
            return sessionLocker.open();
        }

        function unlock(): string {
            return sessionLocker.unlock();
        }

        function close(): string {
            return sessionLocker.close();
        }

        function isLocked(): bool {
            return sessionLocker.isLocked();
        }
    }

    // Region selection & screenshot subsystem
    RegionSelector {
        id: regionSelector
    }

    IpcHandler {
        target: "screenshot"

        function region(): string {
            ScreenshotService.captureRegion();
            return "REGION";
        }

        function screen(): string {
            ScreenshotService.captureScreen();
            return "SCREEN";
        }

        function color(): string {
            ScreenshotService.pickColor();
            return "COLOR";
        }
    }

    IpcHandler {
        target: "regionselector"

        function begin(action: string): string {
            RegionSelectionService.begin(action || "screenshot");
            return "BEGIN";
        }

        function cancel(): string {
            RegionSelectionService.cancel();
            return "CANCEL";
        }

        function isActive(): bool {
            return RegionSelectionService.active;
        }
    }

    // Hot corners subsystem
    HotCorners {
        id: hotCorners
        locked: sessionLocker.active || RegionSelectionService.active

        onTriggered: (action, screenName) => {
            console.warn("[HotCorners] Handling action:", action, "on screen:", screenName);
            if (!action || action === "disabled")
                return;

            if (action === "overview") {
                Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.gnome.Shell", "--object-path", "/org/gnome/Shell", "--method", "org.freedesktop.DBus.Properties.Set", "org.gnome.Shell", "OverviewActive", "<true>"]);
                return;
            }

            if (action.indexOf(":") !== -1) {
                const parts = action.split(":");
                const role = parts[0];
                const view = parts[1];
                const targetScreen = screenName || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
                sidebarHost.openOnScreen(role, view, targetScreen);
                return;
            }

            if (action === "spotlight") {
                spotlightLauncher.toggleWindow();
                return;
            }
        }
    }

    IpcHandler {
        target: "hotcorners"

        function trigger(action: string, screenName: string): string {
            if (!action || action === "disabled")
                return "DISABLED";
            const targetScreen = screenName || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
            hotCorners.triggered(action, targetScreen);
            return "TRIGGERED";
        }

        function getAction(corner: string): string {
            return (PersonalizationConfig.hotCornerActions && PersonalizationConfig.hotCornerActions[corner]) || "disabled";
        }

        function setAction(corner: string, action: string): string {
            PersonalizationConfig.setHotCornerAction(corner, action);
            return (PersonalizationConfig.hotCornerActions && PersonalizationConfig.hotCornerActions[corner]) || "disabled";
        }

        function getCornerIds(): string {
            return JSON.stringify(PersonalizationConfig.hotCornerIds);
        }

        function isLocked(): bool {
            return hotCorners.locked;
        }
    }

    // Interactive shortcuts to toggle QuickSettings
    Shortcut {
        sequence: "Ctrl+Alt+S"
        onActivated: {
            WidgetState.quickSettingsOpen = !WidgetState.quickSettingsOpen;
            console.warn("[M4 Test] Ctrl+Alt+S toggled quickSettingsOpen:", WidgetState.quickSettingsOpen);
        }
    }
}

