import QtQuick

Item {
    id: root

    property var target: null
    property bool enabled: false
    property var keymap: ({})

    signal captured(string key)
    signal cancelled()
    signal failed(string reason)

    function currentModifiers() {
        return 0;
    }

    function captureMouse(button, modifiers) {
    }
}
