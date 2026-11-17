pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Common
import "../Common/functions/DisplayConfiguration.js" as Config

Singleton {
    id: root

    readonly property bool supported: CompositorBackend.name === "niri" && !!CompositorBackend.capabilities.displayConfig
    readonly property bool available: supported && CompositorBackend.connected
    readonly property var backendOutputs: CompositorBackend.outputs
    property var live: _normalizedOutputs(CompositorBackend.outputs.length ? CompositorBackend.outputs : Niri.outputSnapshot())
    property var draft: []
    property var baseline: []
    property string revision: ""
    property string selection: ""
    property string error: ""
    property string completionNotice: ""
    property string token: ""
    property string phase: "idle"
    property int remaining: 0
    property bool identify: false
    // Keep ambiguous identities connector-bound for the current editing session.
    property var identityCollisions: []
    property string previousCombination: ""
    property string operationKind: ""
    property string commandPending: ""
    property int _outputRequestSeq: 0
    property string pendingOutputRequestId: ""
    readonly property bool busy: token !== "" || operation.running || pendingOutputRequestId !== ""
    readonly property bool confirming: phase === "confirming" && commandPending === "" && operationKind
                                       !== "keep"
    readonly property bool dirty: supported && Config.canonical(Config.patches(draft)) !== Config.canonical(Config.patches(
                                                                                                   baseline))
    readonly property var selected: draft.find(r => r.key === selection) || null
    readonly property string validation: {
        if (!supported)
            return "";
        const reason = Config.validation(draft);
        return reason === "last-output" ? qsTr("At least one connected display must remain enabled") : reason
                                          === "overlap" ? qsTr("Display rectangles overlap") : reason
                                                          === "mode" ? qsTr(
                                                                           "Select an available display mode") :
                                                                       "";
    }

    function _normalizedOutputs(rawOutputs) {
        const list = Array.isArray(rawOutputs) ? rawOutputs : [];
        return list.map((o, idx) => {
            const modes = Array.isArray(o.modes) ? o.modes : [];
            let modeText = typeof o.currentMode === "string" ? o.currentMode : "";
            if (!modeText && typeof o.currentMode === "number" && o.currentMode >= 0 && o.currentMode < modes.length)
                modeText = Config.modeString(modes[o.currentMode]);
            return Object.assign({}, o, {
                name: o.name || ("Display-" + (idx + 1)),
                make: o.make || "Unknown",
                model: o.model || "Unknown",
                serial: o.serial || "Unknown",
                currentMode: modeText,
                modes: modes,
                vrrSupported: !!o.vrrSupported
            });
        });
    }

    function _syncOutputs(rawOutputs) {
        const source = Array.isArray(rawOutputs) && rawOutputs.length ? rawOutputs : Niri.outputSnapshot();
        const next = _normalizedOutputs(source);
        recordCollisions(next);
        const combination = Config.combination(next, identityCollisions);
        const changed = previousCombination !== "" && combination !== previousCombination;
        previousCombination = combination;
        live = next;
        if (changed && dirty && !busy) {
            draft = draft.map(row => {
                const output = next.find(o => Config.stableKey(o, next, identityCollisions) === row.key);
                return Object.assign({}, row, {
                    connected: !!output,
                    live: output || null
                });
            });
            error = qsTr("Connected displays changed. Reload before applying.");
        }
        if (!busy && !dirty)
            reload(false);
    }

    function clearCompletionNotice() {
        if (completionNotice !== "" && error === completionNotice)
            error = "";
        completionNotice = "";
    }
    function refresh() {
        Niri.refreshOutputs();
        if (supported)
            NiriConfigService.refresh();
    }
    function reload(clearError) {
        if (busy)
            return;
        const source = CompositorBackend.outputs.length ? CompositorBackend.outputs : Niri.outputSnapshot();
        live = _normalizedOutputs(source);
        if (!supported) {
            baseline = Config.rows(live, [], identityCollisions).map(row => Object.assign({}, row, {
                editable: false,
                source: row.source || qsTr("GNOME Settings")
            }));
            draft = Config.clone(baseline);
            revision = "";
            if (!draft.some(r => r.key === selection))
                selection = draft.length ? draft[0].key : "";
            completionNotice = "";
            error = qsTr("Display configuration is read-only on GNOME; manage displays in GNOME Settings.");
            return;
        }
        baseline = Config.rows(live, NiriConfigService.outputs, identityCollisions);
        draft = Config.clone(baseline);
        revision = NiriConfigService.revision;
        if (!draft.some(r => r.key === selection))
            selection = draft.length ? draft[0].key : "";
        if (clearError !== false)
            error = "";
    }
    function edit(key, field, value) {
        if (!supported) {
            error = qsTr("Display configuration requires the Niri backend.");
            return;
        }
        if (busy)
            return;
        draft = draft.map(row => {
            if (row.key !== key || !row.editable)
                return row;
            const next = Config.clone(row);
            if (value === null)
                delete next.settings[field];
            else
                next.settings[field] = value;
            return next;
        });
    }
    function forget(key) {
        if (!supported) {
            error = qsTr("Display configuration requires the Niri backend.");
            return;
        }
        if (busy)
            return;
        draft = draft.map(row => row.key === key && !row.connected ? Object.assign({}, row, {
                                                                                       deleted: true
                                                                                   }) : row);
    }
    function configureOutput(outputName, actionPayload) {
        if (!supported) {
            error = qsTr("Display configuration requires the Niri backend.");
            return "";
        }
        const requestId = "display-" + (++_outputRequestSeq);
        pendingOutputRequestId = requestId;
        error = "";
        const accepted = Niri.configureOutput(requestId, String(outputName || ""), actionPayload);
        if (!accepted) {
            pendingOutputRequestId = "";
            error = CompositorBackend.lastError || qsTr("Display configuration request was rejected.");
            return "";
        }
        return requestId;
    }
    function apply() {
        if (!supported) {
            error = qsTr("Display configuration requires the Niri backend.");
            phase = "idle";
            return;
        }
        if (busy || !dirty || validation || !NiriConfigService.ready("outputs"))
            return;
        error = "";
        phase = "validating";
        invoke({
                   operation: "start",
                   revision: revision,
                   main: NiriConfigService.snapshot.main,
                   outputs: Config.changes(draft, baseline)
               });
    }
    function invoke(request) {
        if (!supported || operation.running)
            return;
        operationKind = request.operation;
        operation.command = ["python3", Paths.systemScriptsDir + "/display_preview.py", JSON.stringify(
                                 request)];
        operation.running = true;
    }
    function keep() {
        if (confirming) {
            phase = "saving";
            commandPending = "keep";
            poll();
        }
    }
    function revert() {
        if (token) {
            commandPending = "revert";
            poll();
        }
    }
    function poll() {
        if (!token || operation.running)
            return;
        const command = commandPending || "status";
        commandPending = "";
        invoke({
                   operation: command,
                   token: token
               });
    }
    function identifyDisplays() {
        identify = true;
        identifyTimer.restart();
    }
    function recordCollisions(outputs) {
        const duplicates = outputs.filter(o => outputs.filter(other => Config.identity(other) === Config.identity(
                                                                           o)).length > 1).map(
                  Config.identity);
        const merged = identityCollisions.concat(duplicates).filter((id, index, all) => all.indexOf(id)
                                                                                        === index);
        if (JSON.stringify(merged) !== JSON.stringify(identityCollisions)) {
            identityCollisions = merged;
        }
    }
    Connections {
        target: Niri
        function onConnectedChanged() {
            root._syncOutputs(CompositorBackend.outputs);
        }
        function onOutputsChanged() {
            root._syncOutputs(CompositorBackend.outputs);
        }
        function onOutputRequestFinished(requestId, success, requestError) {
            if (root.pendingOutputRequestId === "" || requestId !== root.pendingOutputRequestId)
                return;
            root.pendingOutputRequestId = "";
            if (!success) {
                root.error = requestError || qsTr("Failed to configure output.");
            } else {
                root.error = "";
                root.refresh();
            }
        }
    }
    Connections {
        target: NiriConfigService
        enabled: root.supported
        function onSnapshotChanged() {
            if (!root.busy && !root.dirty)
                root.reload(false);
            else if (!root.busy && root.revision !== NiriConfigService.revision)
                root.error = qsTr("Configuration changed externally. Reload before applying.");
        }
    }
    Timer {
        id: identifyTimer
        interval: 3500
        onTriggered: root.identify = false
    }
    Timer {
        interval: 400
        running: root.token !== ""
        repeat: true
        onTriggered: root.poll()
    }
    Process {
        id: operation
        stdout: StdioCollector {
            id: response
        }
        stderr: StdioCollector {
            id: diagnostic
        }
        onExited: code => {
            try {
                const result = JSON.parse(response.text);
                if (result.schemaVersion !== 1)
                    throw new Error("Unsupported preview response");
                if (code !== 0)
                    throw new Error(result.error || diagnostic.text);
                if (root.operationKind === "cleanup")
                    Qt.callLater(function () {
                        root.reload(false);
                    });
                if (result.token)
                    root.token = result.token;
                if (result.phase)
                    root.phase = result.phase;
                root.remaining = result.remaining || 0;
                if (result.phase === "kept" || result.phase === "reverted") {
                    const old = root.token;
                    root.token = "";
                    root.phase = "idle";
                    root.commandPending = "";
                    if (result.phase === "kept")
                        root.baseline = Config.clone(root.draft);
                    else
                        root.draft = Config.clone(root.baseline);
                    root.error = result.error || "";
                    if (result.restoreErrors && result.restoreErrors.length)
                        root.error += "\n" + result.restoreErrors.join("\n");
                    root.completionNotice = result.phase === "reverted" && result.error
                            === "Changes reverted" && !(result.restoreErrors && result.restoreErrors.length)
                            ? root.error : "";
                    root.refresh();
                    Qt.callLater(function () {
                        root.invoke({
                                        operation: "cleanup",
                                        token: old
                                    });
                    });
                }
            } catch (e) {
                root.error = String(e);
                if (!root.token)
                    root.phase = "idle";
            }
        }
    }
    Component.onCompleted: {
        _syncOutputs(CompositorBackend.outputs);
        refresh();
    }
}
