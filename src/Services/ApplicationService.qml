pragma Singleton

import QtQuick
import Quickshell
import qs.Services

Singleton {
    id: root

    property var applications: []
    readonly property string settingsIconName: {
        const revision = typeof ThemeService !== "undefined" ? ThemeService.iconThemeRevision : 0;
        for (const name of ["preferences-system", "preferences-desktop"]) {
            if (Quickshell.hasThemeIcon(name))
                return name;
        }
        return "";
    }

    readonly property var launcherAppItem: ({
        id: "org.clavis.Launcher",
        name: qsTranslate("LauncherWindow", "Applications"),
        genericName: "Launchpad",
        keywords: ["Launchpad", "apps", "search", "spotlight", "launcher"],
        symbol: "apps",
        icon: "view-app-grid"
    })

    readonly property var settingsApplication: ({
        id: "org.clavis.Settings",
        name: qsTranslate("ControlCenterWindow", "Settings"),
        genericName: "Clavis",
        keywords: ["Clavis", "settings", "preferences", "control center"],
        symbol: root.settingsIconName ? "" : "settings",
        icon: root.settingsIconName
    })

    readonly property var spaceApplication: ({
        id: "org.clavis.Space",
        name: qsTr("Space"),
        genericName: qsTr("Drag to Dock to add a blank space"),
        keywords: ["space", "spacer", "blank", "dock"],
        symbol: "check_box_outline_blank",
        icon: "",
        dragOnly: true
    })

    readonly property var smallSpaceApplication: ({
        id: "org.clavis.SmallSpace",
        name: qsTr("Small Space"),
        genericName: qsTr("Drag to Dock to add a blank space"),
        keywords: ["space", "spacer", "blank", "dock", "small", "narrow"],
        symbol: "check_box_outline_blank",
        icon: "",
        dragOnly: true
    })

    readonly property var launcherApplications: applications.concat([launcherAppItem, settingsApplication, spaceApplication, smallSpaceApplication])

    function launchCommand(command, workingDirectory) {
        const argv = Array.from(command || []);
        if (argv.length === 0 || !String(argv[0]).trim())
            return false;

        Quickshell.execDetached(argv);
        return true;
    }

    function launchApplication(application) {
        if (!application || application.dragOnly)
            return false;
        if (application.id === root.launcherAppItem.id) {
            Quickshell.execDetached(["/home/dkp/projects/Ubuntu Quickshell Desktop Shell/scripts/toggle_spotlight.sh"]);
            return true;
        }
        if (application.id === root.settingsApplication.id) {
            if (typeof ControlCenterService !== "undefined" && ControlCenterService.openOrFocus)
                return ControlCenterService.openOrFocus();
            return false;
        }
        return root.launchApplicationCommand(application, application.command);
    }

    function actionsForApplication(identifier) {
        const application = root.findById(identifier);
        const actions = Array.from(application ? application.actions || [] : []);
        return actions.filter(action => {
            if (!action || !String(action.id || "").trim() || !String(action.name || "").trim())
                return false;
            return action.command && action.command.length > 0 && String(action.command[0]).trim() !== "";
        });
    }

    function launchApplicationAction(identifier, actionId) {
        const application = root.findById(identifier);
        if (!application || application.dragOnly)
            return false;
        const action = root.actionsForApplication(identifier).find(candidate => candidate.id === actionId);
        return !!action && root.launchApplicationCommand(application, action.command);
    }

    function launchApplicationCommand(application, argumentsList) {
        const command = Array.from(argumentsList || []);
        if (command.length === 0 || !String(command[0]).trim())
            return false;
        return root.launchCommand(command, application.workingDirectory);
    }

    function openUrl(url) {
        const value = String(url || "");
        if (!value)
            return false;
        Quickshell.execDetached(["xdg-open", value]);
        return true;
    }

    function isVisibleApplication(application) {
        if (!application)
            return false;
        if (application.noDisplay === true || application.hidden === true)
            return false;
        return String(application.id || "").trim() !== "" && String(application.execString || application.exec || "").trim() !== "";
    }

    function refresh() {}

    function getVisibleApplications() {
        return root.applications.slice();
    }

    function findById(identifier) {
        const value = String(identifier || "");
        if (value === root.smallSpaceApplication.id)
            return root.smallSpaceApplication;
        if (value === root.spaceApplication.id)
            return root.spaceApplication;
        if (value === root.settingsApplication.id)
            return root.settingsApplication;
        const withoutSuffix = value.endsWith(".desktop") ? value.substring(0, value.length - ".desktop".length) : value;
        for (const application of root.applications) {
            const id = String(application.id || "");
            if (id === value || id === withoutSuffix || id === withoutSuffix + ".desktop") {
                return application;
            }
        }
        return null;
    }

    function iconSource(iconName) {
        const value = String(iconName || "");
        if (value.startsWith("file://") || value.startsWith("image://"))
            return value;
        if (value.startsWith("/"))
            return "file://" + value;
        const resolved = Quickshell.iconPath(value || "application-x-executable", "application-x-executable");
        return resolved && resolved !== "" ? resolved : "image://icon/application-x-executable";
    }

    function iconSourceForEntry(entry) {
        if (!entry)
            return root.iconSource("");
        const application = root.findById(entry.id);
        if (application && application.icon)
            return root.iconSource(application.icon);
        if (entry.icon)
            return root.iconSource(entry.icon);
        return root.iconSource("");
    }
}
