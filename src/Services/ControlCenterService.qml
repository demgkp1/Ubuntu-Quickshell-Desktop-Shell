pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property int searchSerial: 0

    function registerSearchAnchor(item) {}
    function unregisterSearchAnchor(item) {}
    function retrySearch() {}
}
