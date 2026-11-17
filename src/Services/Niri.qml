pragma Singleton
import QtQuick
import Quickshell
import qs.Services

// Dual-backend compositor facade delegating to Niri IPC or GNOME bridge via CompositorBackend.
Singleton {
    id: root

    readonly property string backendName: CompositorBackend.name
    readonly property bool available: CompositorBackend.available
    readonly property bool connected: CompositorBackend.connected
    readonly property string lastError: CompositorBackend.lastError
    readonly property bool supportsMinimize: CompositorBackend.supportsMinimize
    readonly property bool supportsMinimizeAnimation: CompositorBackend.supportsMinimizeAnimation
    readonly property bool supportsWindowOpacity: CompositorBackend.supportsWindowOpacity
    readonly property var minimizeEffects: CompositorBackend.minimizeEffects
    readonly property var workspaces: CompositorBackend.workspaces
    readonly property var windows: CompositorBackend.windows
    readonly property var outputs: CompositorBackend.outputs
    readonly property var focusedWindow: CompositorBackend.focusedWindow
    readonly property var focusedWorkspace: CompositorBackend.focusedWorkspace
    readonly property string currentOutput: CompositorBackend.currentOutput
    readonly property int connectionGeneration: CompositorBackend.connectionGeneration
    readonly property bool inOverview: CompositorBackend.inOverview
    readonly property var keyboardLayoutNames: CompositorBackend.keyboardLayoutNames
    readonly property string currentKeyboardLayoutName: CompositorBackend.currentKeyboardLayoutName
    property var floatingParallaxOffsets: ({})

    signal capabilitiesChanged()
    signal errorChanged()
    signal overviewChanged()
    signal keyboardLayoutChanged()
    signal outputRequestFinished(string requestId, bool success, string error)

    Connections {
        target: CompositorBackend
        function onCapabilitiesChanged() { root.capabilitiesChanged(); }
        function onErrorChanged() { root.errorChanged(); }
        function onOverviewChanged() { root.overviewChanged(); }
        function onKeyboardLayoutChanged() { root.keyboardLayoutChanged(); }
        function onOutputRequestFinished(requestId, success, error) {
            root.outputRequestFinished(requestId, success, error);
        }
    }

    function outputSnapshot() { return CompositorBackend.outputSnapshot(); }
    function searchWindows(query) { return CompositorBackend.searchWindows(query); }
    function windowById(id) { return CompositorBackend.windowById(id); }
    function workspaceById(id) { return CompositorBackend.workspaceById(id); }
    function workspacesForOutput(name) { return CompositorBackend.workspacesForOutput(name); }
    function activeWorkspaceForOutput(name) { return CompositorBackend.activeWorkspaceForOutput(name); }
    function windowsForWorkspace(id) { return CompositorBackend.windowsForWorkspace(id); }
    function windowsForOutput(name) { return CompositorBackend.windowsForOutput(name); }
    function workspaceIcons(workspaceId, groupApps) { return CompositorBackend.workspaceIcons(workspaceId, groupApps); }
    function focusWindow(id) { return CompositorBackend.focusWindow(id); }
    function minimizeWindow(id) { return CompositorBackend.minimizeWindow(id); }
    function restoreWindow(id, output) { return CompositorBackend.restoreWindow(id, output); }
    function closeWindow(id) { return CompositorBackend.closeWindow(id); }
    function closeFocusedWindow() { return CompositorBackend.closeFocusedWindow(); }
    function focusWorkspace(id) { return CompositorBackend.focusWorkspace(id); }
    function focusWorkspaceById(id) { return CompositorBackend.focusWorkspaceById(id); }
    function focusWorkspaceByIndex(index) { return CompositorBackend.focusWorkspaceByIndex(index); }
    function focusWorkspaceByName(name) { return CompositorBackend.focusWorkspaceByName(name); }
    function toggleOverview() { return CompositorBackend.toggleOverview(); }
    function configureOutput(requestId, name, actionPayload) { return CompositorBackend.configureOutput(requestId, name, actionPayload); }
    function setFloatingParallaxOffsets(offsets) {
        root.floatingParallaxOffsets = offsets || ({});
        return CompositorBackend.setFloatingParallaxOffsets(offsets);
    }
    function refreshOutputs() { return CompositorBackend.refreshOutputs(); }
    function powerOffMonitors() { return CompositorBackend.powerOffMonitors(); }
    function powerOnMonitors() { return CompositorBackend.powerOnMonitors(); }
    function cycleKeyboardLayout() { return CompositorBackend.cycleKeyboardLayout(); }
    function doScreenTransition(delayMs) { return CompositorBackend.doScreenTransition(delayMs); }
}
