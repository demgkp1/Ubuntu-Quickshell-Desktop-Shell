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

    IpcHandler {
        target: "diagnostics"
        function snapshot(): string {
            const panels = [];
            for (const variants of [barVariants, verticalBarVariants]) {
                for (let index = 0; index < variants.instances.length; ++index)
                    panels.push(variants.instances[index].placementSnapshot());
            }
            return JSON.stringify({
                backend: CompositorBackend.name, state: CompositorBackend.state,
                windows: CompositorBackend.windows.length,
                workspaces: CompositorBackend.workspaces.length,
                blur: BlurService.enabled, locked: sessionLocker.active,
                bars: barVariants.instances.length + verticalBarVariants.instances.length,
                panels: panels.concat(keystone.placementSnapshots(), dockHost.placementSnapshots(), [sidebarHost.placementSnapshot()]),
                quickSettings: WidgetState.quickSettingsOpen,
                dashboard: WidgetState.dashboardSidebarOpen,
                sidebarPresented: sidebarHost.isPresented,
                quickSettingsPresented: sidebarHost.quickSettingsPresented,
                dashboardPresented: sidebarHost.dashboardPresented,
                sidebarWidth: sidebarHost.width, sidebarHeight: sidebarHost.height,
                controlCenter: !!ControlCenterService.controlCenterWindow && ControlCenterService.controlCenterWindow.visible,
                wallpaperOwner: WallpaperService.renderOwner
            });
        }
    }

    // Track A: Per-screen horizontal top bar variants
    Variants {
        id: barVariants
        model: ["top", "bottom"].includes(PersonalizationConfig.barPosition) ? Quickshell.screens : []

        HorizontalBarWindow {
            required property var modelData
            screen: modelData
            edge: PersonalizationConfig.barPosition
        }
    }

    Variants {
        id: verticalBarVariants
        model: ["left", "right"].includes(PersonalizationConfig.barPosition) ? Quickshell.screens : []
        VerticalBarWindow {
            required property var modelData
            screen: modelData
            edge: PersonalizationConfig.barPosition
        }
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
        Component.onCompleted: ApplicationService.openLauncherHandler = () => spotlightLauncher.toggleWindow()
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

        function section(page: string, section: string): bool {
            const window = ControlCenterService.controlCenterWindow;
            return !!window && window.openPageSection(page, section);
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
                if (CompositorBackend.name === "niri")
                    Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
                else
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
                if (CompositorBackend.name === "niri") {
                    WidgetState.closeAllPopups();
                    Niri.toggleOverview();
                } else {
                    Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.gnome.Shell", "--object-path", "/org/gnome/Shell", "--method", "org.freedesktop.DBus.Properties.Set", "org.gnome.Shell", "OverviewActive", "<true>"]);
                }
                return;
            }

            if (action.indexOf(":") !== -1) {
                const parts = action.split(":");
                const role = parts[0];
                const view = parts[1];
                if (CompositorBackend.name === "niri" && Niri.inOverview)
                    Niri.toggleOverview();
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

