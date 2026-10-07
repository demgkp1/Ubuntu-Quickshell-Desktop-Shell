pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool hasWritableRemote: false
    readonly property bool uploadActive: false
    readonly property int uploadJobCount: uploadJobs.length
    readonly property bool hasPendingUploads: false
    property var uploadJobs: []
    property bool uploadsPaused: false
    property string lastMessage: ""
    property string lastMessageTone: "neutral"

    function hasLocalUrls(urls) {
        return false;
    }

    function enqueueUrls(urls) {
        return 0;
    }

    function clearCompletedUploads() {
        uploadJobs = [];
    }

    function toggleUploadsPaused() {
        uploadsPaused = !uploadsPaused;
    }

    function removeCompletedUpload(jobId) {}

    function retryUpload(jobId) {}

    function cancelUpload(jobId) {}

    function isActivePath(path) {
        return false;
    }
}
