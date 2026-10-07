import QtQuick
import Qt.labs.folderlistmodel

Item {
    id: root

    property var sourceModel: null
    property string order: "name"
    readonly property int count: sourceModel ? sourceModel.count : 0

    signal modelReset()
    signal rowsInserted(int first, int last)
    signal rowsRemoved(int first, int last)
    signal dataChanged()
    signal layoutChanged()

    Connections {
        target: root.sourceModel
        function onCountChanged() {
            root.modelReset();
        }
        function onStatusChanged() {
            root.modelReset();
        }
    }

    function get(index) {
        if (!sourceModel || index < 0 || index >= sourceModel.count)
            return {};
        const url = sourceModel.get(index, "fileURL") || sourceModel.get(index, "filePath");
        const name = sourceModel.get(index, "fileName");
        const isDir = sourceModel.get(index, "fileIsDir");
        const size = sourceModel.get(index, "fileSize") || 0;
        const modified = sourceModel.get(index, "fileModified");
        return {
            name: name,
            url: url,
            path: String(url).replace(/^file:\/\//, ""),
            available: true,
            readable: true,
            isDirectory: isDir,
            isLink: false,
            kind: isDir ? "folder" : "file",
            mimeType: isDir ? "inode/directory" : "text/plain",
            icon: isDir ? "folder" : "text-x-generic",
            genericIcon: isDir ? "folder" : "text-x-generic",
            typeName: isDir ? "Folder" : "File",
            size: size,
            modified: modified
        };
    }
}
