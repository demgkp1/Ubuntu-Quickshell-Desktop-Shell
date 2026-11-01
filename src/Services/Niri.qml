pragma Singleton

import QtQuick
import Quickshell
import qs.Services

QtObject {
    id: root

    readonly property bool available: true
    readonly property bool connected: true
    readonly property bool supportsMinimize: true
    readonly property bool supportsMinimizeAnimation: true
    readonly property var minimizeEffects: ["scale", "genie"]
    readonly property var workspaces: [
        { id: 1, name: "1", active: true },
        { id: 2, name: "2", active: false },
        { id: 3, name: "3", active: false },
        { id: 4, name: "4", active: false }
    ]
    readonly property var windows: typeof X11WindowService !== "undefined" ? X11WindowService.windows : []
    property var outputs: root.outputSnapshot()
    readonly property var focusedWindow: root.windows.length > 0 ? root.windows[0] : null
    property int connectionGeneration: 1
    property var floatingParallaxOffsets: ({})

    function searchWindows(query) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.searchWindows(query);
        return [];
    }

    function windowById(id) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.windowById(id);
        return null;
    }

    function workspacesForOutput(screenName) {
        return root.workspaces.map(ws => Object.assign({}, ws, { output: screenName }));
    }

    function activeWorkspaceForOutput(screenName) {
        const list = root.workspacesForOutput(screenName);
        return list.length > 0 ? list[0] : null;
    }

    function windowsForWorkspace(workspaceId) {
        return root.windows;
    }

    function focusWindow(id) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.activateWindow(id);
        return false;
    }

    function minimizeWindow(id) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.minimizeWindow(id);
        return false;
    }

    function restoreWindow(id, outputName) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.activateWindow(id);
        return false;
    }

    function closeWindow(id) {
        if (typeof X11WindowService !== "undefined")
            return X11WindowService.closeWindow(id);
        return false;
    }

    function setFloatingParallaxOffsets(offsets) {
        root.floatingParallaxOffsets = offsets || {};
        return true;
    }

    function outputSnapshot() {
        if (!Quickshell.screens)
            return [];
        return Quickshell.screens.map(s => ({
            name: s.name || "default",
            width: s.geometry ? s.geometry.width : (s.width || 1920),
            height: s.geometry ? s.geometry.height : (s.height || 1080),
            scale: 1.0
        }));
    }

    function refreshOutputs() {
        root.outputs = root.outputSnapshot();
        root.connectionGeneration += 1;
        return true;
    }
}
