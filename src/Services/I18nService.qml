pragma Singleton

import QtQuick
import Quickshell
import qs.Services

Singleton {
    id: root

    readonly property var supportedLanguages: [
        ({ code: "en_US", label: "English" }),
        ({ code: "zh_CN", label: "简体中文" }),
        ({ code: "zh_TW", label: "繁體中文" })
    ]
    readonly property string language: (typeof UiPreferences !== "undefined" && UiPreferences.language) ? UiPreferences.language : "en_US"
    property bool ready: true
    property string lastError: ""

    function initialize() {
        if (Qt.uiLanguage !== root.language)
            Qt.uiLanguage = root.language;
        root.ready = true;
        root.lastError = "";
        return true;
    }

    Component.onCompleted: root.initialize()

    Connections {
        target: UiPreferences

        function onLanguageChanged() {
            root.initialize();
        }
    }
}
