import QtQuick
import Quickshell
import qs.Common
import qs.Services

Item {
    id: root

    property bool locked: false
    signal triggered(string action, string screenName)

    readonly property var cornerIds: PersonalizationConfig.hotCornerIds

    readonly property var cornerList: {
        const list = [];
        const corners = root.cornerIds || ["top-left", "top-right", "bottom-left", "bottom-right"];
        const screens = Quickshell.screens || [];
        for (let s = 0; s < screens.length; s++) {
            for (let c = 0; c < corners.length; c++) {
                list.push({ screen: screens[s], corner: corners[c] });
            }
        }
        return list;
    }

    Variants {
        model: root.cornerList

        delegate: Component {
            HotCornerWindow {
                required property var modelData

                targetScreen: modelData.screen
                corner: modelData.corner
                action: (PersonalizationConfig.hotCornerActions && PersonalizationConfig.hotCornerActions[modelData.corner]) || "disabled"
                locked: root.locked

                onTriggered: (action, screenName) => root.triggered(action, screenName)
            }
        }
    }
}
