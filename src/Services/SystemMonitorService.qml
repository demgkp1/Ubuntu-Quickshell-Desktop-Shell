pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property int supportedSchemaVersion: 1
    readonly property int historyLimit: 60
    readonly property int maximumReconnectAttempts: 5
    readonly property int maximumDiagnosticLines: 20
    readonly property int maximumDiagnosticCharacters: 2048

    property int configuredIntervalMs: (typeof UiPreferences !== "undefined" && UiPreferences.systemMonitorIntervalMs) ? UiPreferences.systemMonitorIntervalMs : 2000
    property double sourceIntervalMs: 0
    readonly property int intervalMs: configuredIntervalMs
    property var _consumerModules: ({})
    property var effectiveModules: []
    property var _streamModules: []
    property bool _reconcilePending: false
    property var _streamProcess: firstStream
    property var _replacementProcess: null
    property int _replacementSnapshots: 0
    property double _replacementTimestampMs: -1
    property string state: "ready"
    property string errorMessage: ""
    property string errorDetails: ""

    property var cpu: ({
        usagePercent: 18.5,
        temperatureCelsius: 42.0,
        packageTemperatureCelsius: 42.0
    })
    property var memory: ({
        usagePercent: 32.5,
        usedBytes: 8589934592,
        totalBytes: 26422452224
    })
    property var gpus: [
        {
            id: "gpu0",
            name: "Integrated Graphics",
            utilizationPercent: 12.0,
            temperatureCelsius: 40.0,
            memoryUsedBytes: 536870912,
            memoryTotalBytes: 4294967296
        }
    ]
    property var disks: [
        {
            device: "/dev/sda1",
            mountPoint: "/",
            filesystem: "ext4",
            totalBytes: 512000000000,
            usedBytes: 160000000000,
            availableBytes: 352000000000,
            usagePercent: 31.25,
            readBytesPerSecond: 10240,
            writeBytesPerSecond: 20480
        }
    ]
    property var network: ({
        downloadBytesPerSecond: 128000,
        uploadBytesPerSecond: 32000
    })
    property var errors: []

    property var cpuHistory: [14, 15, 18, 22, 19, 16, 17, 20, 24, 21, 18, 19, 22, 25, 20, 18, 17, 19, 21, 18.5]
    property var memoryHistory: [32, 32.1, 32.2, 32.2, 32.3, 32.3, 32.4, 32.4, 32.4, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5, 32.5]
    property var gpuHistory: [8, 10, 12, 15, 14, 11, 9, 10, 12, 11, 13, 14, 12, 11, 10, 12, 13, 11, 10, 12]
    property var networkDownloadHistory: [64000, 80000, 120000, 95000, 110000, 150000, 130000, 125000, 140000, 128000]
    property var networkUploadHistory: [16000, 20000, 30000, 25000, 28000, 35000, 31000, 29000, 33000, 32000]
    property var diskReadHistories: ({"/dev/sda1": [1024, 2048, 4096, 8192, 4096, 2048, 1024, 4096, 8192, 10240]})
    property var diskWriteHistories: ({"/dev/sda1": [2048, 4096, 8192, 16384, 8192, 4096, 2048, 8192, 16384, 20480]})

    property double sourceTimestampMs: 0
    property double lastUpdatedMs: Date.now()
    property double sequence: -1
    property int reconnectAttempt: 0
    property int malformedLineCount: 0
    property int schemaMismatchCount: 0
    property var diagnostics: []

    property bool _hasData: true
    property bool _fatalError: false
    property bool _stopRequested: false
    property bool _timeoutRestartIssued: false
    property bool _terminationPending: false
    property string _forcedRestartReason: ""
    property double _streamStartedAtMs: 0
    property int _generationCounter: 0
    property int _streamGeneration: 0
    property int _startedGeneration: -1
    property int _handledGeneration: -1
    property int _retryDelayMs: 1000
    property int _forceStopProbeCount: 0
    property string _autoGpuId: "gpu0"
    property string _effectiveGpuId: "gpu0"

    readonly property bool active: effectiveModules.length > 0
    readonly property bool hasData: _hasData
    readonly property bool loading: state === "loading"
    readonly property bool ready: state === "ready"
    readonly property bool stale: state === "stale"
    readonly property bool error: state === "error"
    readonly property bool reconnecting: state === "reconnecting"
    readonly property bool partial: errors.length > 0
    readonly property bool processRunning: root._streamProcess.running
    readonly property string selectedGpuId: _effectiveGpuId
    readonly property var selectedGpu: _gpuById(root.gpus, root.selectedGpuId)
    readonly property string statusText: {
        switch (state) {
        case "loading":
            return qsTr("Connecting");
        case "ready":
            return partial ? qsTr("Some sensors cannot be read") : qsTr("Live");
        case "stale":
            return qsTr("Data is stale");
        case "reconnecting":
            return qsTr("Reconnecting");
        case "error":
            return qsTr("Service unavailable");
        default:
            return qsTr("Paused");
        }
    }

    function setConsumerModules(owner, modules) {
        const key = String(owner || "").trim();
        if (key === "")
            return;
        const allowed = ["cpu", "disk", "gpu", "memory", "network"];
        const unique = [];
        (Array.isArray(modules) ? modules : []).forEach(function (module) {
            const name = String(module || "").trim();
            if (allowed.indexOf(name) >= 0 && unique.indexOf(name) < 0)
                unique.push(name);
        });
        unique.sort();
        const next = Object.assign({}, root._consumerModules);
        if (unique.length > 0)
            next[key] = unique;
        else
            delete next[key];
        root._consumerModules = next;
        root._scheduleModuleReconcile();
    }

    function setConsumer(owner, modules, active) {
        if (active)
            setConsumerModules(owner, modules);
        else
            clearConsumer(owner);
    }

    function clearConsumer(owner) {
        root.setConsumerModules(owner, []);
    }

    function _scheduleModuleReconcile() {
        if (root._reconcilePending)
            return;
        root._reconcilePending = true;
        Qt.callLater(root._reconcileModules);
    }

    function _reconcileModules() {
        root._reconcilePending = false;
        const union = [];
        Object.keys(root._consumerModules).sort().forEach(function (owner) {
            root._consumerModules[owner].forEach(function (module) {
                if (union.indexOf(module) < 0)
                    union.push(module);
            });
        });
        union.sort();
        if (JSON.stringify(union) === JSON.stringify(root.effectiveModules))
            return;

        const previous = root.effectiveModules.slice();
        const changed = previous.filter(module => union.indexOf(module) < 0).concat(union.filter(module
                                                                                                 => previous.indexOf(
                                                                                                        module) < 0));
        root.effectiveModules = union;
        if (!root.active)
            root._stopStream();
        else if (root._streamProcess.running)
            root._prepareReplacement();
        else
            root._startStream();
    }

    function _cancelReplacement() {
        const pending = root._replacementProcess;
        root._replacementProcess = null;
        if (pending)
            pending.terminate();
    }

    function _prepareReplacement() {
        if (!root.active || !root._streamProcess.running || root._terminationPending || root._fatalError)
            return;
        const wanted = JSON.stringify(root.effectiveModules);
        if (wanted === JSON.stringify(root._streamModules)) {
            root._cancelReplacement();
            return;
        }
        if (root._replacementProcess && wanted === JSON.stringify(root._replacementProcess.modules))
            return;
        root._cancelReplacement();
        const next = root._streamProcess === firstStream ? secondStream : firstStream;
        if (next.running)
            return;
        next.generation = ++root._generationCounter;
        next.modules = root.effectiveModules.slice();
        next.startedAtMs = Date.now();
        next.didStart = false;
        next.malformedLines = 0;
        next.command = root._streamCommand(next.modules);
        root._replacementSnapshots = 0;
        root._replacementTimestampMs = -1;
        root._replacementProcess = next;
        next.running = true;
        Qt.callLater(function () {
            if (root._replacementProcess === next && !next.running && !next.didStart)
                root._terminateStream("failed_to_start");
        });
    }

    function _adoptReplacement() {
        const previous = root._streamProcess;
        const next = root._replacementProcess;
        root._replacementProcess = null;
        root._streamProcess = next;
        root._streamModules = next.modules.slice();
        root._streamGeneration = next.generation;
        root._startedGeneration = root._streamGeneration;
        root._handledGeneration = -1;
        root._streamStartedAtMs = next.startedAtMs;
        previous.terminate();
    }

    function retry() {
        root._fatalError = false;
        root.reconnectAttempt = 0;
        root._retryDelayMs = 1000;
        root.errorMessage = "";
        root.errorDetails = "";
        reconnectTimer.stop();
        if (root.active && !root._streamProcess.running)
            root._startStream();
    }

    function _streamCommand(modules) {
        return ["python3", Paths.shellDir + "/../scripts/sysmon_stream.py"];
    }

    function _startStream() {
        if (!root.active || root._streamProcess.running || root._fatalError)
            return;
        reconnectTimer.stop();
        forceStopTimer.stop();
        root._stopRequested = false;
        root._timeoutRestartIssued = false;
        root._terminationPending = false;
        root._forceStopProbeCount = 0;
        root._forcedRestartReason = "";
        root._streamGeneration = ++root._generationCounter;
        root._startedGeneration = -1;
        root._handledGeneration = -1;
        root._streamProcess.malformedLines = 0;
        root._streamStartedAtMs = Date.now();
        root._streamModules = root.effectiveModules.slice();
        root.state = root.hasData || root.reconnectAttempt > 0 ? "reconnecting" : "loading";
        root._streamProcess.modules = root._streamModules.slice();
        root._streamProcess.generation = root._streamGeneration;
        root._streamProcess.didStart = false;
        root._streamProcess.startedAtMs = root._streamStartedAtMs;
        root._streamProcess.command = root._streamCommand(root._streamModules);
        root._streamProcess.running = true;

        const generation = root._streamGeneration;
        Qt.callLater(function () {
            if (generation === root._streamGeneration && !root._streamProcess.running
                    && root._startedGeneration !== generation) {
                root._handleStreamStopped(generation, "failed_to_start", -1);
            }
        });
    }

    function _stopStream() {
        root._cancelReplacement();
        reconnectTimer.stop();
        root._stopRequested = true;
        if (root._streamProcess.running)
            root._terminateStream("");
        else {
            forceStopTimer.stop();
            root._terminationPending = false;
            root.state = root._fatalError ? "error" : (root.hasData ? "ready" : "idle");
        }
    }

    function _terminateStream(reason) {
        root._cancelReplacement();
        if (reason && root._forcedRestartReason === "")
            root._forcedRestartReason = reason;
        if (!root._streamProcess.running)
            return;
        if (root._terminationPending)
            return;
        root._terminationPending = true;
        root._forceStopProbeCount = 0;
        forceStopTimer.interval = 2000;
        root._streamProcess.running = false;
        forceStopTimer.start();
    }

    function _scheduleReconnect(reason) {
        if (!root.active || root._fatalError)
            return;

        if (root.reconnectAttempt >= root.maximumReconnectAttempts) {
            root.state = "error";
            if (!root.errorMessage)
                root.errorMessage = qsTr("System monitor service unavailable");
            root.errorDetails = root.errorDetails || qsTr(
                        "The automatic reconnect limit was reached. Check the system monitor backend and try again.");
            return;
        }

        root.reconnectAttempt += 1;
        root._retryDelayMs = Math.min(16000, 1000 * Math.pow(2, root.reconnectAttempt - 1));
        root.state = "reconnecting";
        if (!root.errorMessage) {
            root.errorMessage = reason === "failed_to_start" ? qsTr(
                                                                   "Could not start the system monitoring service") :
                                                               qsTr("The system monitor data stream was interrupted");
        }
        reconnectTimer.interval = root._retryDelayMs;
        reconnectTimer.restart();
    }

    function _handleStreamStopped(generation, reason, exitCode) {
        if (generation !== root._streamGeneration || root._handledGeneration === generation)
            return;

        root._handledGeneration = generation;
        forceStopTimer.stop();
        root._terminationPending = false;
        root._forceStopProbeCount = 0;
        const requestedStop = root._stopRequested;
        const intentionallyStopped = requestedStop || !root.active;
        root._stopRequested = false;

        if (intentionallyStopped) {
            root.state = root._fatalError ? "error" : (root.hasData ? "ready" : "idle");
            if (root.active && requestedStop)
                Qt.callLater(root._startStream);
            return;
        }

        if (exitCode < 0 || exitCode === 127 || exitCode === 255 || reason === "failed_to_start") {
            root._fatalError = true;
            root.reconnectAttempt = root.maximumReconnectAttempts;
            root.state = "error";
            return;
        }

        if (root._fatalError) {
            root.state = "error";
            return;
        }

        root._scheduleReconnect(reason);
    }

    function _isObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function _isFiniteNumber(value) {
        return typeof value === "number" && isFinite(value);
    }

    function _validateSnapshot(snapshot, modules) {
        if (!root._isObject(snapshot))
            return qsTr("The top-level JSON value must be an object");
        if (snapshot.schemaVersion !== root.supportedSchemaVersion)
            return "schemaVersion";
        if (!root._isFiniteNumber(snapshot.timestampMs) || !root._isFiniteNumber(snapshot.sequence) || !root._isFiniteNumber(
                    snapshot.intervalMs) || snapshot.intervalMs < 0)
            return qsTr("The timestamp, sequence number, or sampling interval is invalid");
        if (modules.indexOf("cpu") >= 0 && !root._isObject(snapshot.cpu))
            return qsTr("Missing or invalid CPU data fields");
        if (modules.indexOf("memory") >= 0 && !root._isObject(snapshot.memory))
            return qsTr("Missing or invalid memory data fields");
        if (modules.indexOf("network") >= 0 && !root._isObject(snapshot.network))
            return qsTr("Missing or invalid network data fields");
        if (modules.indexOf("gpu") >= 0 && !Array.isArray(snapshot.gpus))
            return qsTr("Missing or invalid GPU data fields");
        if (modules.indexOf("disk") >= 0 && !Array.isArray(snapshot.disks))
            return qsTr("Missing or invalid disk data fields");
        if (!Array.isArray(snapshot.errors))
            return qsTr("The devices and errors fields must be arrays");
        return "";
    }

    function _appendHistory(values, value) {
        if (!root._isFiniteNumber(value))
            return values;
        const next = values.slice(Math.max(0, values.length - root.historyLimit + 1));
        next.push(value);
        return next;
    }

    function _updateDiskHistories(devices) {
        const nextReads = Object.assign({}, root.diskReadHistories);
        const nextWrites = Object.assign({}, root.diskWriteHistories);
        for (let index = 0; index < devices.length; index += 1) {
            const disk = devices[index];
            const id = String(disk.device || disk.mountPoint || "");
            if (id === "")
                continue;
            nextReads[id] = root._appendHistory(nextReads[id] || [], disk.readBytesPerSecond || 0);
            nextWrites[id] = root._appendHistory(nextWrites[id] || [], disk.writeBytesPerSecond || 0);
        }
        root.diskReadHistories = nextReads;
        root.diskWriteHistories = nextWrites;
    }

    function _gpuId(gpu) {
        if (!root._isObject(gpu))
            return "";
        return String(gpu.id || "").trim();
    }

    function _gpuById(devices, id) {
        const wanted = String(id || "");
        for (let index = 0; index < devices.length; index += 1) {
            if (root._gpuId(devices[index]) === wanted)
                return devices[index];
        }
        return ({});
    }

    function _hasGpuId(devices, id) {
        return root._gpuId(root._gpuById(devices, id)) !== "";
    }

    function _resolveAutoGpuId(devices) {
        if (root._autoGpuId !== "" && root._hasGpuId(devices, root._autoGpuId))
            return root._autoGpuId;

        const ids = [];
        for (let index = 0; index < devices.length; index += 1) {
            const id = root._gpuId(devices[index]);
            if (id !== "")
                ids.push(id);
        }
        ids.sort();
        root._autoGpuId = ids.length > 0 ? ids[0] : "";
        return root._autoGpuId;
    }

    function _resolveSelectedGpuId(devices) {
        const preferred = String((typeof UiPreferences !== "undefined" && UiPreferences.systemMonitorGpuId) || "auto");
        if (preferred !== "auto" && root._hasGpuId(devices, preferred))
            return preferred;
        return root._resolveAutoGpuId(devices);
    }

    function _commitSnapshot(snapshot) {
        const requested = root.effectiveModules;
        snapshot = Object.assign({}, snapshot);
        const fields = {
            cpu: "cpu",
            memory: "memory",
            gpu: "gpus",
            disk: "disks",
            network: "network"
        };
        Object.keys(fields).forEach(function (module) {
            if (requested.length > 0 && requested.indexOf(module) < 0)
                delete snapshot[fields[module]];
        });
        const snapshotGpus = Array.isArray(snapshot.gpus) ? snapshot.gpus : root.gpus;
        const nextSelectedGpuId = root._resolveSelectedGpuId(snapshotGpus);
        root._effectiveGpuId = nextSelectedGpuId;
        if (snapshot.cpu)
            root.cpu = snapshot.cpu;
        if (snapshot.memory)
            root.memory = snapshot.memory;
        if (Array.isArray(snapshot.gpus) && snapshot.gpus.length > 0)
            root.gpus = snapshot.gpus.slice();
        if (Array.isArray(snapshot.disks) && snapshot.disks.length > 0) {
            root.disks = snapshot.disks.slice();
            root._updateDiskHistories(root.disks);
        }
        if (snapshot.network)
            root.network = snapshot.network;

        const cpuUsage = snapshot.cpu ? snapshot.cpu.usagePercent : undefined;
        if (cpuUsage !== undefined)
            root.cpuHistory = root._appendHistory(root.cpuHistory, cpuUsage);

        if (snapshot.memory && snapshot.memory.usagePercent !== undefined)
            root.memoryHistory = root._appendHistory(root.memoryHistory, snapshot.memory.usagePercent);

        const effectiveGpu = root._gpuById(snapshotGpus || [], nextSelectedGpuId);
        if (root._gpuId(effectiveGpu) !== "" && effectiveGpu.utilizationPercent !== undefined) {
            root.gpuHistory = root._appendHistory(root.gpuHistory, effectiveGpu.utilizationPercent);
        }
        if (snapshot.network) {
            root.networkDownloadHistory = root._appendHistory(root.networkDownloadHistory, snapshot.network.downloadBytesPerSecond);
            root.networkUploadHistory = root._appendHistory(root.networkUploadHistory, snapshot.network.uploadBytesPerSecond);
        }

        root.sourceTimestampMs = snapshot.timestampMs;
        root.lastUpdatedMs = Date.now();
        root.sequence = snapshot.sequence;
        root.sourceIntervalMs = snapshot.intervalMs;
        root._hasData = true;
        root._timeoutRestartIssued = false;
        root.reconnectAttempt = 0;
        root._retryDelayMs = 1000;
        root.errorMessage = "";
        root.errorDetails = "";
        root.state = "ready";
    }

    function _consumeLine(line, process) {
        if (root._terminationPending || (process !== root._streamProcess && process !== root._replacementProcess))
            return;
        const text = String(line || "").trim();
        if (text.length === 0)
            return;

        let snapshot;
        try {
            snapshot = JSON.parse(text);
        } catch (exception) {
            root.malformedLineCount += 1;
            process.malformedLines += 1;
            return;
        }

        const validationError = root._validateSnapshot(snapshot, process.modules);
        if (validationError === "schemaVersion") {
            root.schemaMismatchCount += 1;
            return;
        }
        if (validationError !== "") {
            root.malformedLineCount += 1;
            process.malformedLines += 1;
            return;
        }

        process.malformedLines = 0;
        if (process === root._replacementProcess) {
            if (snapshot.timestampMs <= root._replacementTimestampMs)
                return;
            root._replacementTimestampMs = snapshot.timestampMs;
            root._replacementSnapshots += 1;
            if (root._replacementSnapshots < 2 || snapshot.timestampMs <= root.sourceTimestampMs)
                return;
            root._adoptReplacement();
        }
        root._commitSnapshot(snapshot);
    }

    function _consumeDiagnostic(line, process) {
        if (process !== root._streamProcess && process !== root._replacementProcess)
            return;
        const text = String(line || "").trim();
        if (text.length === 0)
            return;

        const next = root.diagnostics.slice(Math.max(0, root.diagnostics.length - root.maximumDiagnosticLines + 1));
        next.push(text.slice(0, 256));
        root.diagnostics = next;
    }

    Timer {
        id: reconnectTimer
        repeat: false
        onTriggered: root._startStream()
    }

    Timer {
        id: forceStopTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (root._streamProcess.running) {
                root._streamProcess.signal(9);
            }
        }
    }

    component MonitorStream: Process {
        id: collector

        property var modules: []
        property int generation: -1
        property bool didStart: false
        property int malformedLines: 0
        property double startedAtMs: 0
        property Timer terminationTimer: Timer {
            interval: 2000
            onTriggered: {
                if (collector.running)
                    collector.signal(9);
            }
        }

        function terminate() {
            if (!collector.running)
                return;
            collector.running = false;
            collector.terminationTimer.restart();
        }

        function stopped(reason, exitCode) {
            if (collector === root._streamProcess) {
                root._handleStreamStopped(collector.generation, reason, exitCode);
            } else if (collector === root._replacementProcess) {
                root._terminateStream(reason);
            } else {
                Qt.callLater(root._prepareReplacement);
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root._consumeLine(line, collector)
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: line => root._consumeDiagnostic(line, collector)
        }

        onStarted: {
            collector.didStart = true;
            collector.startedAtMs = Date.now();
            if (collector === root._replacementProcess)
                return;
            if (collector !== root._streamProcess) {
                collector.terminate();
                return;
            }
            root._startedGeneration = collector.generation;
            root._streamStartedAtMs = collector.startedAtMs;
        }
        onExited: (exitCode, exitStatus) => {
            collector.terminationTimer.stop();
            collector.stopped(root._forcedRestartReason || "unexpected_exit", exitCode);
        }
        onRunningChanged: {
            if (running)
                return;
            const generation = collector.generation;
            Qt.callLater(function () {
                if (generation !== collector.generation || collector.running)
                    return;
                collector.stopped(collector.didStart ? (root._forcedRestartReason || "unexpected_exit") : "failed_to_start", -1);
            });
        }
    }

    MonitorStream {
        id: firstStream
    }
    MonitorStream {
        id: secondStream
    }
}
