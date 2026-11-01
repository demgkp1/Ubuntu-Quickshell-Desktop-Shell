pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool quickSettingsOpen: false
    property string quickSettingsView: "settings"
    property string quickSettingsScreenName: ""
    property bool dashboardSidebarOpen: false
    property string dashboardSidebarView: "info"

    // The shared host owns both panels on the same retained output.
    property string sidebarScreenName: ""
    property bool sidebarPresentationActive: false
    property bool sessionLocked: false

    function sidebarHasPriority(screenName) {
        return screenName !== "" && sidebarPresentationActive && sidebarScreenName === screenName;
    }

    signal transientSurfacesDismissRequested

    function closeAllPopups() {
        quickSettingsOpen = false;
        dashboardSidebarOpen = false;
        transientSurfacesDismissRequested();
    }

    onSessionLockedChanged: {
        if (sessionLocked)
            closeAllPopups();
    }

    onQuickSettingsOpenChanged: {
        if (!quickSettingsOpen)
            quickSettingsScreenName = "";
    }
}
