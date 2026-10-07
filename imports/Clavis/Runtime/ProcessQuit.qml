import QtQuick

QtObject {
    id: root

    function prepare(pids) {
        return true;
    }

    function confirm() {
        return true;
    }

    function cancel() {}
}
