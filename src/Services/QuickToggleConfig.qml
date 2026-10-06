pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var toggles: defaultToggles()

    function defaultToggles() {
        return [
            { "type": "network", "size": 2 },
            { "type": "bluetooth", "size": 2 },
            { "type": "caffeine", "size": 1 },
            { "type": "mic", "size": 1 },
            { "type": "audio", "size": 2 },
            { "type": "theme", "size": 2 },
            { "type": "dnd", "size": 1 },
            { "type": "night", "size": 2 }
        ];
    }

    function toggleSize(type) {
        const index = toggles.findIndex(t => t.type === type);
        if (index === -1)
            return;
        const copy = toggles.slice();
        copy[index] = {
            type: copy[index].type,
            size: copy[index].size === 2 ? 1 : 2
        };
        toggles = copy;
    }

    function move(type, dir) {
        const index = toggles.findIndex(t => t.type === type);
        const target = index + dir;
        if (index === -1 || target < 0 || target >= toggles.length)
            return;
        const copy = toggles.slice();
        const tmp = copy[index];
        copy[index] = copy[target];
        copy[target] = tmp;
        toggles = copy;
    }
}
