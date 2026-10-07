pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    property int trashCount: 0
    property bool trashAvailable: true
    property bool busy: false

    signal trashChanged()
    signal filesChanged()
    signal finished(string action, int succeeded, var errors)

    function info(url) {
        if (!url) {
            return {
                url: "",
                path: "",
                name: "",
                available: false,
                readable: false,
                isDirectory: false,
                isLink: false,
                kind: "file",
                mimeType: "application/octet-stream",
                icon: "text-x-generic",
                genericIcon: "text-x-generic",
                typeName: "",
                size: 0
            };
        }
        const sUrl = String(url);
        const path = sUrl.replace(/^file:\/\//, "");
        const parts = path.split("/");
        const name = parts.length > 0 ? parts[parts.length - 1] : path;
        const isDir = path.indexOf(".") < 0 || name.startsWith(".");
        return {
            url: sUrl,
            path: path,
            name: name || "/",
            available: true,
            readable: true,
            isDirectory: isDir,
            isLink: false,
            kind: isDir ? "folder" : "file",
            mimeType: isDir ? "inode/directory" : "text/plain",
            icon: isDir ? "folder" : "text-x-generic",
            genericIcon: isDir ? "folder" : "text-x-generic",
            typeName: isDir ? "Folder" : "File",
            size: 0
        };
    }

    function thumbnail(url) {
        return "";
    }

    function watchUrls(urls) {}

    function moveToTrash(urls) {
        if (urls && urls.length > 0) {
            for (let i = 0; i < urls.length; ++i) {
                const path = String(urls[i]).replace(/^file:\/\//, "");
                Quickshell.execDetached(["gio", "trash", path]);
            }
        }
        return true;
    }

    function emptyTrash() {
        Quickshell.execDetached(["gio", "trash", "--empty"]);
        root.trashCount = 0;
        root.trashChanged();
        return true;
    }

    function defaultApplicationForFile(url) {
        return "";
    }

    function canOpenWith(desktopId) {
        return true;
    }

    function openWith(desktopId, urls) {
        if (urls && urls.length > 0) {
            const path = String(urls[0]).replace(/^file:\/\//, "");
            Quickshell.execDetached(["xdg-open", path]);
        }
        return true;
    }

    function refreshTrash() {
        root.trashChanged();
    }
}
