pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property bool connected: false
    readonly property string socketPath: ""
    readonly property string lastError: ""
    readonly property var workspaces: []
    readonly property var windows: []
    readonly property var outputs: []
    readonly property var focusedWindow: null
    readonly property var focusedWorkspace: null
    readonly property string currentOutput: ""
    readonly property bool inOverview: false
    readonly property var keyboardLayoutNames: []
    readonly property string currentKeyboardLayoutName: ""
    readonly property bool supportsMinimize: false
    readonly property bool supportsMinimizeEffects: false
    readonly property bool supportsMinimizeAnimation: false
    readonly property var minimizeEffects: []
    readonly property int connectionGeneration: 0

    function searchWindows(query) {
        return [];
    }

    function switchWorkspace(name) {}
    function closeWindow(id) {}
    function toggleOverview() {}
    function focusWindow(id) {}
}
