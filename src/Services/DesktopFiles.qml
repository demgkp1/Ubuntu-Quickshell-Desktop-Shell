pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property bool trashAvailable: true
    readonly property int trashCount: 0
    readonly property bool busy: false

    signal filesChanged
    signal trashChanged
    signal finished(string action, int succeeded, var errors)

    function info(fileUrl) {
        const urlStr = String(fileUrl || "");
        const path = urlStr.replace(/^file:\/\//, "");
        const parts = path.split("/").filter(Boolean);
        const base = parts.length > 0 ? parts[parts.length - 1] : "";
        const isTrash = path.indexOf(".local/share/Trash") !== -1 || urlStr === "trash:///";
        const isDir = isTrash || !base.includes(".");
        return {
            available: true,
            exists: true,
            readable: true,
            isDirectory: isDir,
            isTrash: isTrash,
            name: isTrash ? qsTr("Trash") : (base || qsTr("Files")),
            path: path,
            url: urlStr,
            icon: isTrash ? "user-trash" : (isDir ? "folder" : "text-x-generic")
        };
    }

    function thumbnail(url) {
        return "";
    }

    function emptyTrash() {
        Quickshell.execDetached(["gio", "trash", "--empty"]);
        return true;
    }

    function moveToTrash(urls) {
        if (!urls || urls.length === 0)
            return false;
        const clean = urls.map(u => String(u).replace(/^file:\/\//, ""));
        Quickshell.execDetached(["gio", "trash", ...clean]);
        return true;
    }

    function canOpenWith(url, app) {
        return true;
    }

    function openWith(urls, app) {
        if (!urls || urls.length === 0)
            return false;
        Quickshell.execDetached(["gio", "open", String(urls[0])]);
        return true;
    }

    function watchUrls(urls) {
        return true;
    }
}
