import QtQuick
import Quickshell
import qs.Services

PowerMenuWindow {
    id: powerMenuWindow

    targetScreen: {
        if (PowerMenuService.targetScreenName && PowerMenuService.targetScreenName !== "") {
            if (Quickshell.screens) {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    if (Quickshell.screens[i].name === PowerMenuService.targetScreenName)
                        return Quickshell.screens[i];
                }
            }
        }
        return Quickshell.focusedScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
}
