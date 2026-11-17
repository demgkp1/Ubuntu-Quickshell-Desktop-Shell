pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    readonly property string stateDir: Paths.stateHome
    readonly property string filePath: stateDir + "/todo.json"

    property bool storeReady: false
    property bool ready: false
    property var list: []

    function normalizeList(value) {
        if (!Array.isArray(value))
            return [];

        return value
            .filter(item => item && typeof item.content === "string")
            .map(item => ({
                "content": item.content,
                "done": item.done === true
            }));
    }

    function save() {
        if (!root.storeReady || !root.ready)
            return;
        todoFile.setText(JSON.stringify(root.list, null, 2));
    }

    function addTask(description) {
        const content = String(description || "").trim();
        if (content.length === 0)
            return false;

        root.list = [...root.list, {
            "content": content,
            "done": false
        }];
        root.save();
        return true;
    }

    function setDone(index, done) {
        if (index < 0 || index >= root.list.length)
            return;

        const updated = root.list.slice();
        updated[index] = {
            "content": updated[index].content,
            "done": done
        };
        root.list = updated;
        root.save();
    }

    function markDone(index) {
        root.setDone(index, true);
    }

    function markUnfinished(index) {
        root.setDone(index, false);
    }

    function deleteItem(index) {
        if (index < 0 || index >= root.list.length)
            return;

        const updated = root.list.slice();
        updated.splice(index, 1);
        root.list = updated;
        root.save();
    }

    Process {
        id: ensureStateDir

        command: ["mkdir", "-p", root.stateDir]
        running: true

        onExited: exitCode => {
            if (exitCode === 0) {
                root.storeReady = true;
            } else {
                console.warn("TodoService failed to create state directory:", root.stateDir, exitCode);
                root.list = [];
                root.ready = true;
            }
        }
    }

    FileView {
        id: todoFile

        path: root.storeReady ? root.filePath : ""
        blockWrites: true
        atomicWrites: true

        onLoaded: {
            try {
                root.list = root.normalizeList(JSON.parse(todoFile.text().trim() || "[]"));
            } catch (error) {
                console.warn("TodoService failed to load:", error);
                root.list = [];
            }

            root.ready = true;
        }

        onLoadFailed: error => {
            if (!root.storeReady)
                return;

            root.list = [];
            root.ready = true;
            if (error === FileViewError.FileNotFound) {
                root.save();
            } else {
                console.warn("TodoService failed to open:", error);
            }
        }

        onSaveFailed: error => console.warn("TodoService failed to save:", error)
    }
}
