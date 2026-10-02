pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * GnomeService - GNOME Shell DBus Bridge
 *
 * Communicates with GNOME Shell session over DBus:
 * - Toggles Overview / Activities (native application launcher & workspace switcher)
 */
Singleton {
    id: root

    // Non-blocking process to toggle GNOME Overview
    Process {
        id: overviewProc
        command: [
            "bash", "-c",
            "curr=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.freedesktop.DBus.Properties.Get org.gnome.Shell OverviewActive 2>/dev/null); if [[ $curr == *true* ]]; then next=\"<false>\"; else next=\"<true>\"; fi; gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.freedesktop.DBus.Properties.Set org.gnome.Shell OverviewActive \"$next\""
        ]
    }

    // Toggle GNOME Activities / Overview
    function toggleOverview() {
        if (!overviewProc.running) {
            overviewProc.running = true;
        }
    }
}
