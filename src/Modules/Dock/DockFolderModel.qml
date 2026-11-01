import QtQuick
import Qt.labs.folderlistmodel
import qs.Services

QtObject {
    id: root

    property int revision: 0
    required property url folder
    property string sort: "name"

    readonly property alias model: listModel
    readonly property int count: directory.count
    readonly property bool ready: directory.status === FolderListModel.Ready
    readonly property bool loading: directory.status === FolderListModel.Loading
    readonly property var info: DesktopFiles.info(folder)
    readonly property bool available: !!info.available && !!info.isDirectory && !!info.readable

    function get(index) {
        if (index < 0 || index >= directory.count)
            return {};
        const urlStr = String(directory.get(index, "fileURL") || "");
        const path = String(directory.get(index, "filePath") || "");
        const name = String(directory.get(index, "fileName") || "");
        const isDir = Boolean(directory.get(index, "fileIsDir"));
        return {
            url: urlStr,
            path: path,
            name: name,
            isDirectory: isDir,
            isLink: false,
            available: true,
            icon: isDir ? "folder" : "text-x-generic"
        };
    }

    function _rebuildList() {
        listModel.clear();
        for (let i = 0; i < directory.count; i++) {
            listModel.append({ "fileInfo": root.get(i) });
        }
        root.revision++;
    }

    property FolderListModel directory: FolderListModel {
        id: dirModel
        folder: root.folder
        showDotAndDotDot: false
        showHidden: false
        sortField: root.sort === "time" ? FolderListModel.Time : (root.sort === "type" ? FolderListModel.Type : FolderListModel.Name)
        onStatusChanged: {
            if (status === FolderListModel.Ready)
                root._rebuildList();
        }
        onCountChanged: root._rebuildList()
    }

    property ListModel listModel: ListModel {
        id: listModel
    }
}
