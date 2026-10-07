pragma Singleton

import QtQuick

QtObject {
    id: root

    function provider(id) {
        return {
            maximumDisplayZoom: 18,
            name: String(id || "")
        };
    }
}
