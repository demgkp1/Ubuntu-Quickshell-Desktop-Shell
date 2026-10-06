pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property real sinkVolume: 0.35
    property bool sinkMuted: false
    property string sinkName: "Built-in Audio"
    property bool outputAvailable: true

    property real sourceVolume: 1.0
    property bool sourceMuted: false
    property string sourceName: "Internal Microphone"
    property bool inputAvailable: true

    readonly property bool ready: true
    readonly property bool available: true
    readonly property bool busy: false
    readonly property bool isHeadphone: false

    property var sink: ({
        id: 1,
        name: root.sinkName,
        description: root.sinkName,
        volume: root.sinkVolume,
        muted: root.sinkMuted
    })
    property var source: ({
        id: 2,
        name: root.sourceName,
        description: root.sourceName,
        volume: root.sourceVolume,
        muted: root.sourceMuted
    })
    property var outputDevices: [sink]
    property var inputDevices: [source]
    property var playbackStreams: []
    property string lastError: ""

    signal operationFailed(string operation, string message)

    function setSinkVolume(v) {
        sinkVolume = Math.max(0, Math.min(1, v));
    }

    function setSourceVolume(v) {
        sourceVolume = Math.max(0, Math.min(1, v));
    }

    function toggleSinkMute() {
        sinkMuted = !sinkMuted;
    }

    function toggleSourceMute() {
        sourceMuted = !sourceMuted;
    }

    function toggleNodeMute(node) {
        if (!node || node === sink)
            toggleSinkMute();
        else if (node === source)
            toggleSourceMute();
    }

    function setNodeVolume(node, volume) {
        if (!node || node === sink)
            setSinkVolume(volume);
        else if (node === source)
            setSourceVolume(volume);
    }

    function isDefaultOutput(node) {
        return true;
    }

    function isDefaultInput(node) {
        return true;
    }

    function setDefaultOutput(node) {}
    function setDefaultInput(node) {}

    function nodeDisplayName(node) {
        return node ? (node.description || node.name || "") : "";
    }

    function applicationDisplayName(node) {
        return nodeDisplayName(node);
    }

    function nodeSupportingText(node) {
        return "";
    }

    function nodeIconName(node) {
        return node === source ? "mic" : "volume_up";
    }

    function applicationIconSource(node) {
        return "";
    }

    function nodeVolume(node) {
        return node ? (node === source ? sourceVolume : sinkVolume) : 0;
    }

    function nodeMuted(node) {
        return node ? (node === source ? sourceMuted : sinkMuted) : false;
    }

    function openMixer() {
        console.log("Volume.openMixer requested");
    }
}
