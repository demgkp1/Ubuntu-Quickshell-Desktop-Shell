//@ pragma UseQApplication
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_BACKEND=software
//@ pragma Env QT_QPA_PLATFORM=xcb

import QtQuick
import Quickshell
import Quickshell.Io

import "common"
import "windows"
import "components"
import "services"

ShellRoot {
    // IPC bridge for global keyboard shortcuts and external automation
    IpcHandler {
        target: "shell"

        function toggleLauncher() {
            LauncherService.toggle();
        }

        function toggleControlCenter() {
            ControlCenterService.toggle();
        }

        function openOverview() {
            GnomeService.toggleOverview();
        }
    }

    // Global X11 Escape Key Grabber: Intercepts ESC across the entire OS when popups are open
    Process {
        id: escListenerProc
        running: ControlCenterService.isOpen || LauncherService.isOpen
        command: ["python3", Quickshell.env("HOME") + "/projects/Ubuntu Quickshell Desktop Shell/scripts/esc_listener.py"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "ESC") {
                    if (ControlCenterService.isOpen) ControlCenterService.close();
                    if (LauncherService.isOpen) LauncherService.close();
                }
            }
        }
    }

    // 1. TopBar Window for each connected screen
    Variants {
        model: Quickshell.screens

        TopBarWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            TopBarLayout {
                anchors.fill: parent

                // Leading: Workspaces + Application Launcher Trigger
                leading: [
                    WorkspacePill {},
                    LauncherPill {}
                ]

                // Center: Floating Luminous Clock (Clavis Style)
                center: ClockPill {
                    showDate: false
                    showSeconds: false
                }

                // Trailing: Hardware Status + Power Quick Action (Clavis Style)
                trailing: [
                    StatusPill {}
                ]
            }
        }
    }

    // 2. Floating Application Launcher / Start Menu Window
    Variants {
        model: Quickshell.screens

        LauncherWindow {
            required property var modelData
            screen: modelData
        }
    }

    // 3. Floating Quick Settings & Control Center Window (Clavis Style)
    Variants {
        model: Quickshell.screens

        ControlCenterWindow {
            required property var modelData
            screen: modelData
        }
    }
}
