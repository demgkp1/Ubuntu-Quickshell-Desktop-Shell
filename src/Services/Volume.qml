pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property bool ready: Pipewire.ready
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var audioNodes: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.audio) : []
    readonly property var outputDevices: root.sortedNodes(root.audioNodes.filter(node => !node.isStream && node.isSink))
    readonly property var inputDevices: root.sortedNodes(root.audioNodes.filter(node => !node.isStream && !node.isSink))
    readonly property var playbackStreams: root.playbackNodes(playbackTracker.linkGroups)
    readonly property bool available: root.ready && (root.outputDevices.length > 0 || root.inputDevices.length > 0)
    readonly property bool outputAvailable: root.sink !== null && root.sink !== undefined
    readonly property bool inputAvailable: root.source !== null && root.source !== undefined
    readonly property bool busy: false

    readonly property bool isHeadphone: root.sink ? root.nodeIconName(root.sink) === "headphones" : false
    readonly property bool sinkMuted: (root.sink && root.sink.audio) ? root.nodeMuted(root.sink) : fallbackSinkMuted
    readonly property real sinkVolume: (root.sink && root.sink.audio) ? root.nodeVolume(root.sink) : fallbackSinkVolume
    readonly property bool sourceMuted: (root.source && root.source.audio) ? root.nodeMuted(root.source) : fallbackSourceMuted
    readonly property real sourceVolume: (root.source && root.source.audio) ? root.nodeVolume(root.source) : fallbackSourceVolume
    readonly property string sinkName: root.sink ? root.nodeDisplayName(root.sink) : "Built-in Audio"
    readonly property string sourceName: root.source ? root.nodeDisplayName(root.source) : "Internal Microphone"

    property real fallbackSinkVolume: 0.35
    property bool fallbackSinkMuted: false
    property real fallbackSourceVolume: 1.0
    property bool fallbackSourceMuted: false

    property string lastError: ""

    signal operationFailed(string operation, string message)

    PwObjectTracker {
        // PwNode properties and audio controls are only valid while tracked.
        objects: root.audioNodes
    }

    PwNodeLinkTracker {
        id: playbackTracker
        node: root.sink
    }

    Process {
        id: mixerProcess
        command: ["pavucontrol"]
    }

    function fail(operation, message) {
        root.lastError = message;
        root.operationFailed(operation, message);
        return false;
    }

    function clearError() {
        root.lastError = "";
    }

    function sortedNodes(nodes) {
        return nodes.slice().sort((left, right) => root.nodeDisplayName(left).localeCompare(root.nodeDisplayName(right)));
    }

    function playbackNodes(groups) {
        const streams = [];
        const seenIds = {};

        if (!groups)
            return streams;

        for (let index = 0; index < groups.length; index += 1) {
            const node = groups[index] ? groups[index].source : null;
            if (!node || !node.audio || !node.isStream)
                continue;

            const id = root.nodeId(node);
            if (seenIds[id])
                continue;

            seenIds[id] = true;
            streams.push(node);
        }

        return root.sortedNodes(streams);
    }

    function nodeId(node) {
        return node ? String(node.id) : "";
    }

    function sameNode(left, right) {
        return left && right && root.nodeId(left) === root.nodeId(right);
    }

    function nodeProperties(node) {
        return node && node.properties ? node.properties : ({});
    }

    function nodeDisplayName(node) {
        if (!node)
            return "";

        const properties = root.nodeProperties(node);
        return properties["application.name"] || node.description || node.nickname || node.name || qsTr("Unknown audio device");
    }

    function applicationDisplayName(node) {
        if (!node)
            return qsTr("Unknown application");

        const properties = root.nodeProperties(node);
        return properties["application.name"] || properties["application.process.binary"] || node.nickname || node.name || qsTr("Unknown application");
    }

    function nodeSupportingText(node) {
        if (!node)
            return "";

        const properties = root.nodeProperties(node);
        if (node.isStream) {
            const binary = properties["application.process.binary"] || properties["application.process.id"] || "";
            const mediaName = properties["media.name"] || "";
            return binary && binary !== root.nodeDisplayName(node) ? binary : mediaName;
        }

        const profile = properties["device.profile.description"] || properties["device.product.name"] || "";
        if (profile && profile !== root.nodeDisplayName(node))
            return profile;
        if (node.name && node.name !== root.nodeDisplayName(node))
            return node.name;
        return node.isSink ? qsTr("Audio output device") : qsTr("Audio input device");
    }

    function nodeIconName(node) {
        if (!node)
            return "volume_off";

        const properties = root.nodeProperties(node);
        const descriptor = [properties["device.icon-name"] || "", properties["media.icon-name"] || "", node.description || "", node.name || ""].join(" ").toLowerCase();

        if (node.isStream)
            return "music_note";
        if (descriptor.indexOf("headphone") >= 0 || descriptor.indexOf("headset") >= 0 || descriptor.indexOf(qsTr("Headphones")) >= 0)
            return "headphones";
        if (descriptor.indexOf("bluetooth") >= 0 || descriptor.indexOf("bluez") >= 0)
            return node.isSink ? "headphones" : "mic";
        if (descriptor.indexOf("hdmi") >= 0 || descriptor.indexOf("displayport") >= 0)
            return "tv";
        if (descriptor.indexOf("speaker") >= 0 || descriptor.indexOf(qsTr("Speakers")) >= 0)
            return "speaker";
        return node.isSink ? "volume_up" : "mic";
    }

    function applicationIconSource(node) {
        if (!node)
            return "";

        const properties = root.nodeProperties(node);
        const rawIcon = properties["application.icon-name"] || properties["application.process.binary"] || "";
        const iconAliases = {
            "zen": "zen-browser",
            "zen-bin": "zen-browser",
            "zen-alpha": "zen-browser"
        };
        const icon = iconAliases[String(rawIcon).toLowerCase()] || rawIcon;
        if (!icon)
            return "";
        if (String(icon).startsWith("file://"))
            return String(icon);
        if (String(icon).startsWith("/"))
            return "file://" + icon;
        return "image://icon/" + icon;
    }

    function nodeVolume(node) {
        return node && node.audio ? Math.max(0, Math.min(1, node.audio.volume)) : 0;
    }

    function nodeMuted(node) {
        return node && node.audio ? node.audio.muted : false;
    }

    function isDefaultOutput(node) {
        return root.sameNode(node, root.sink);
    }

    function isDefaultInput(node) {
        return root.sameNode(node, root.source);
    }

    function resolveNode(node, candidates) {
        const id = root.nodeId(node);
        for (let index = 0; index < candidates.length; index += 1) {
            if (root.nodeId(candidates[index]) === id)
                return candidates[index];
        }
        return null;
    }

    function setDefaultOutput(node) {
        const currentNode = root.resolveNode(node, root.outputDevices);
        if (!currentNode)
            return root.fail("set-default-output", qsTr("The selected output device is no longer available"));

        root.clearError();
        Pipewire.preferredDefaultAudioSink = currentNode;
        return true;
    }

    function setDefaultInput(node) {
        const currentNode = root.resolveNode(node, root.inputDevices);
        if (!currentNode)
            return root.fail("set-default-input", qsTr("The selected input device is no longer available"));

        root.clearError();
        Pipewire.preferredDefaultAudioSource = currentNode;
        return true;
    }

    function setNodeVolume(node, volume) {
        if (!node || !node.audio) {
            if (!node || node === root.sink)
                return setSinkVolume(volume);
            else if (node === root.source)
                return setSourceVolume(volume);
            return false;
        }

        const safeVolume = Math.max(0, Math.min(1, Number(volume)));
        if (isNaN(safeVolume))
            return root.fail("set-volume", qsTr("Invalid volume value"));

        root.clearError();
        node.audio.volume = safeVolume;
        if (node.audio.muted)
            node.audio.muted = false;
        return true;
    }

    function toggleNodeMute(node) {
        if (!node || !node.audio) {
            if (!node || node === root.sink)
                return toggleSinkMute();
            else if (node === root.source)
                return toggleSourceMute();
            return false;
        }

        root.clearError();
        node.audio.muted = !node.audio.muted;
        return true;
    }

    function toggleSinkMute() {
        if (root.sink && root.sink.audio)
            return root.toggleNodeMute(root.sink);
        fallbackSinkMuted = !fallbackSinkMuted;
        return true;
    }

    function setSinkVolume(volume) {
        if (root.sink && root.sink.audio)
            return root.setNodeVolume(root.sink, volume);
        fallbackSinkVolume = Math.max(0, Math.min(1, Number(volume)));
        return true;
    }

    function toggleSourceMute() {
        if (root.source && root.source.audio)
            return root.toggleNodeMute(root.source);
        fallbackSourceMuted = !fallbackSourceMuted;
        return true;
    }

    function setSourceVolume(volume) {
        if (root.source && root.source.audio)
            return root.setNodeVolume(root.source, volume);
        fallbackSourceVolume = Math.max(0, Math.min(1, Number(volume)));
        return true;
    }

    function openMixer() {
        mixerProcess.running = true;
    }
}
