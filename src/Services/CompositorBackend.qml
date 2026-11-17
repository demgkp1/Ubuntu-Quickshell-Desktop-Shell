pragma Singleton
import QtQuick
import Quickshell
import Clavis.Niri as NativeNiri
import qs.Services

Singleton {
    id: root

    readonly property string forcedBackend: String(Quickshell.env("CLAVIS_SESSION_BACKEND") || "").trim().toLowerCase()
    readonly property string desktopEnv: String(Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    readonly property string sessionEnv: String(Quickshell.env("DESKTOP_SESSION") || "").toLowerCase()
    readonly property string niriSocketEnv: String(Quickshell.env("NIRI_SOCKET") || "").trim()
    readonly property bool isNiriSession: forcedBackend === "niri"
        || (forcedBackend !== "gnome" && forcedBackend !== "disabled"
            && (niriSocketEnv !== "" || desktopEnv.includes("niri") || sessionEnv.includes("niri")))

    readonly property string name: isNiriSession ? "niri" : "gnome"
    readonly property string state: isNiriSession
        ? (NativeNiri.Niri.connected ? "ready" : (NativeNiri.Niri.lastError !== "" ? "unavailable" : "pending"))
        : GnomeSession.state
    readonly property bool available: isNiriSession ? NativeNiri.Niri.connected : GnomeSession.connected
    readonly property bool connected: available
    readonly property string lastError: isNiriSession ? NativeNiri.Niri.lastError : GnomeSession.lastError

    property var _niriOutputs: []
    property var _niriWorkspaces: []
    property var _niriWindows: []

    readonly property var gnomeCapabilities: GnomeSession.snapshot.capabilities || ({})
    readonly property var capabilities: isNiriSession
        ? ({
            windows: true,
            workspaces: true,
            outputs: true,
            overview: true,
            displayConfig: true,
            minimize: NativeNiri.Niri.supportsMinimize,
            minimizeAnimation: NativeNiri.Niri.supportsMinimizeAnimation,
            backgroundBlur: true,
            windowOpacity: true,
            gamma: false
        })
        : Object.assign({}, gnomeCapabilities, {
            overview: false,
            displayConfig: false,
            backgroundBlur: !!gnomeCapabilities.backgroundBlur,
            windowOpacity: !!gnomeCapabilities.windowOpacity
        })

    readonly property bool supportsMinimize: isNiriSession ? NativeNiri.Niri.supportsMinimize : !!capabilities.minimize
    readonly property bool supportsMinimizeAnimation: isNiriSession ? NativeNiri.Niri.supportsMinimizeAnimation : !!capabilities.minimizeAnimation
    readonly property bool supportsWindowOpacity: isNiriSession || (connected && !!capabilities.windowOpacity)
    readonly property var minimizeEffects: isNiriSession ? _toArray(NativeNiri.Niri.minimizeEffects) : []

    readonly property var windows: isNiriSession ? _niriWindows : _gnomeWindows
    readonly property var workspaces: isNiriSession ? _niriWorkspaces : _gnomeWorkspaces
    readonly property var outputs: isNiriSession ? _niriOutputs : _gnomeOutputs
    readonly property var focusedWindow: isNiriSession ? _normalizeNiriWindow(NativeNiri.Niri.focusedWindow) : windowById(GnomeSession.snapshot.focusedId)
    readonly property var focusedWorkspace: isNiriSession ? _normalizeNiriWorkspace(NativeNiri.Niri.focusedWorkspace) : (workspaces.find(w => w.isActive || w.active) || null)
    readonly property string currentOutput: isNiriSession
        ? NativeNiri.Niri.currentOutput
        : (focusedWindow && focusedWindow.output ? focusedWindow.output : ((outputs.find(o => o.primary) || outputs[0] || {}).name || ""))
    readonly property int connectionGeneration: isNiriSession ? Number(NativeNiri.Niri.connectionGeneration || 0) : GnomeSession.generation
    readonly property bool inOverview: isNiriSession ? NativeNiri.Niri.inOverview : false
    readonly property var keyboardLayoutNames: isNiriSession ? _toArray(NativeNiri.Niri.keyboardLayoutNames) : []
    readonly property string currentKeyboardLayoutName: isNiriSession ? NativeNiri.Niri.currentKeyboardLayoutName : ""

    property var _gnomeOutputs: []
    property var _gnomeWorkspaces: []
    property var _gnomeWindows: []

    signal errorChanged()
    signal overviewChanged()
    signal keyboardLayoutChanged()
    signal outputRequestFinished(string requestId, bool success, string error)

    function _toArray(listLike) {
        if (!listLike) return [];
        if (Array.isArray(listLike)) return listLike;
        const len = Number(listLike.length);
        if (!isFinite(len) || len <= 0) return [];
        const arr = [];
        for (let i = 0; i < len; ++i)
            arr.push(listLike[i]);
        return arr;
    }

    function _normalizeNiriWindow(w) {
        if (!w || w.id === undefined || w.id === null) return null;
        return Object.assign({}, w, {
            app_id: w.appId || "",
            workspace_id: w.workspaceId,
            is_focused: !!w.isFocused,
            is_minimized: !!w.isMinimized
        });
    }

    function _normalizeNiriWorkspace(ws) {
        if (!ws || ws.id === undefined || ws.id === null) return null;
        return Object.assign({}, ws, {
            active: !!ws.isActive,
            is_active: !!ws.isActive,
            is_focused: !!ws.isFocused,
            idx: ws.index !== undefined ? ws.index : ws.idx,
            icons: _toArray(ws.icons)
        });
    }

    function _normalizeNiriOutputs(rawList) {
        const list = _toArray(rawList);
        const focusedOut = NativeNiri.Niri.currentOutput || "";
        return list.map((o, idx) => Object.assign({}, o, {
            enabled: o.enabled !== undefined ? !!o.enabled : (o.outputEnabled !== undefined ? !!o.outputEnabled : true),
            primary: o.primary !== undefined ? !!o.primary : (focusedOut !== "" ? o.name === focusedOut : idx === 0),
            modes: _toArray(o.modes)
        }));
    }

    function _rebuildNiriOutputs() {
        if (!isNiriSession) {
            _niriOutputs = [];
            return;
        }
        _niriOutputs = _normalizeNiriOutputs(NativeNiri.Niri.outputSnapshot());
    }

    function _rebuildNiriWindows() {
        if (!isNiriSession) {
            _niriWindows = [];
            return;
        }
        _niriWindows = _toArray(NativeNiri.Niri.searchWindows("")).map(_normalizeNiriWindow).filter(w => w !== null);
    }

    function _rebuildNiriWorkspaces() {
        if (!isNiriSession) {
            _niriWorkspaces = [];
            return;
        }
        if (typeof NativeNiri.Niri.workspaceSnapshot === "function") {
            _niriWorkspaces = _toArray(NativeNiri.Niri.workspaceSnapshot()).map(_normalizeNiriWorkspace).filter(ws => ws !== null);
            return;
        }
        const collected = [];
        const seen = {};
        const outs = _niriOutputs.length > 0 ? _niriOutputs : _normalizeNiriOutputs(NativeNiri.Niri.outputSnapshot());
        for (let i = 0; i < outs.length; ++i) {
            const perOut = _toArray(NativeNiri.Niri.workspacesForOutput(outs[i].name || ""));
            for (let j = 0; j < perOut.length; ++j) {
                const ws = _normalizeNiriWorkspace(perOut[j]);
                if (ws && !seen[String(ws.id)]) {
                    seen[String(ws.id)] = true;
                    collected.push(ws);
                }
            }
        }
        _niriWorkspaces = collected;
    }

    function _rebuildGnomeSnapshot() {
        if (isNiriSession || !GnomeSession.connected) {
            _gnomeOutputs = [];
            _gnomeWindows = [];
            _gnomeWorkspaces = [];
            return;
        }
        const snap = GnomeSession.snapshot || ({});
        const rawOuts = Array.isArray(snap.outputs) ? snap.outputs : [];
        const rawWins = Array.isArray(snap.windows) ? snap.windows : [];
        const rawWs = Array.isArray(snap.workspaces) ? snap.workspaces : [];

        _gnomeOutputs = rawOuts.map((o, idx) => {
            const lx = Number(o.logicalX !== undefined ? o.logicalX : (o.x || 0));
            const ly = Number(o.logicalY !== undefined ? o.logicalY : (o.y || 0));
            const lw = Number(o.logicalWidth !== undefined ? o.logicalWidth : (o.width || 0));
            const lh = Number(o.logicalHeight !== undefined ? o.logicalHeight : (o.height || 0));
            const sc = Number(o.scale || 1);
            return Object.assign({}, o, {
                index: o.index !== undefined ? o.index : idx,
                enabled: o.enabled !== undefined ? !!o.enabled : true,
                primary: !!o.primary,
                logicalX: lx,
                logicalY: ly,
                logicalWidth: lw,
                logicalHeight: lh,
                scale: sc,
                transform: o.transform || "Normal",
                currentMode: o.currentMode !== undefined ? o.currentMode : 0,
                modes: Array.isArray(o.modes) ? o.modes : (lw > 0 && lh > 0 ? [{ width: Math.round(lw * sc), height: Math.round(lh * sc), refreshMilliHz: 60000, preferred: true }] : [])
            });
        });

        const focusedIdStr = snap.focusedId !== undefined && snap.focusedId !== null ? String(snap.focusedId) : "";
        _gnomeWindows = rawWins.map(w => {
            const wid = w.workspaceId !== undefined ? w.workspaceId : w.workspace_id;
            const appIdVal = w.appId !== undefined ? w.appId : (w.app_id || "");
            const focusedVal = w.isFocused !== undefined ? !!w.isFocused : (w.is_focused !== undefined ? !!w.is_focused : (focusedIdStr !== "" && String(w.id) === focusedIdStr));
            const minVal = w.isMinimized !== undefined ? !!w.isMinimized : !!w.is_minimized;
            return Object.assign({}, w, {
                appId: appIdVal,
                app_id: appIdVal,
                appName: w.appName || appIdVal,
                workspaceId: wid,
                workspace_id: wid,
                isFocused: focusedVal,
                is_focused: focusedVal,
                isMinimized: minVal,
                is_minimized: minVal,
                isFloating: !!w.isFloating,
                iconPath: w.iconPath || "",
                pid: w.pid !== undefined ? w.pid : 0
            });
        });

        const primaryOut = (_gnomeOutputs.find(o => o.primary) || _gnomeOutputs[0] || {}).name || "";
        _gnomeWorkspaces = rawWs.map((ws, idx) => {
            const activeVal = ws.isActive !== undefined ? !!ws.isActive : (ws.active !== undefined ? !!ws.active : !!ws.is_active);
            const focusedVal = ws.isFocused !== undefined ? !!ws.isFocused : (ws.is_focused !== undefined ? !!ws.is_focused : activeVal);
            const count = _gnomeWindows.filter(w => w.workspaceId === ws.id || w.onAllWorkspaces).length;
            return Object.assign({}, ws, {
                index: ws.index !== undefined ? ws.index : (ws.idx !== undefined ? ws.idx : idx),
                idx: ws.idx !== undefined ? ws.idx : (ws.index !== undefined ? ws.index : idx),
                output: ws.output || primaryOut,
                isActive: activeVal,
                active: activeVal,
                is_active: activeVal,
                isFocused: focusedVal,
                is_focused: focusedVal,
                windowCount: ws.windowCount !== undefined ? ws.windowCount : count
            });
        });
    }

    Connections {
        target: NativeNiri.Niri
        enabled: root.isNiriSession
        function onConnectedChanged() {
            root._rebuildNiriOutputs();
            root._rebuildNiriWindows();
            root._rebuildNiriWorkspaces();
        }
        function onErrorChanged() { root.errorChanged(); }
        function onOutputsChanged() {
            root._rebuildNiriOutputs();
            root._rebuildNiriWorkspaces();
        }
        function onWindowsChanged() {
            root._rebuildNiriWindows();
        }
        function onWorkspacesChanged() {
            root._rebuildNiriWorkspaces();
        }
        function onOverviewChanged() { root.overviewChanged(); }
        function onKeyboardLayoutChanged() { root.keyboardLayoutChanged(); }
        function onOutputRequestFinished(requestId, success, error) {
            root.outputRequestFinished(requestId, success, error);
        }
    }

    Connections {
        target: GnomeSession
        enabled: !root.isNiriSession
        function onStateChanged() {
            root._rebuildGnomeSnapshot();
            root.errorChanged();
        }
        function onSnapshotChanged() {
            root._rebuildGnomeSnapshot();
        }
        function onLastErrorChanged() { root.errorChanged(); }
    }

    Component.onCompleted: {
        if (isNiriSession) {
            _rebuildNiriOutputs();
            _rebuildNiriWindows();
            _rebuildNiriWorkspaces();
        } else {
            _rebuildGnomeSnapshot();
        }
    }

    function outputSnapshot() {
        return outputs;
    }

    function searchWindows(query) {
        if (isNiriSession) {
            return _toArray(NativeNiri.Niri.searchWindows(String(query || ""))).map(_normalizeNiriWindow).filter(w => w !== null);
        }
        const needle = String(query || "").toLowerCase();
        return windows.filter(w => (String(w.title || "") + " " + String(w.appId || "")).toLowerCase().includes(needle));
    }

    function windowById(id) {
        if (id === undefined || id === null || id === "") return null;
        return windows.find(w => String(w.id) === String(id)) || null;
    }

    function workspaceById(id) {
        if (id === undefined || id === null || id === "") return null;
        return workspaces.find(ws => String(ws.id) === String(id)) || null;
    }

    function workspacesForOutput(name) {
        if (isNiriSession) {
            return _toArray(NativeNiri.Niri.workspacesForOutput(String(name || ""))).map(_normalizeNiriWorkspace).filter(ws => ws !== null);
        }
        return outputs.some(o => o.name === name) ? workspaces : [];
    }

    function activeWorkspaceForOutput(name) {
        const list = workspacesForOutput(name);
        return list.find(w => w.isActive || w.active) || null;
    }

    function windowsForWorkspace(id) {
        return windows.filter(w => String(w.workspaceId) === String(id) || !!w.onAllWorkspaces);
    }

    function windowsForOutput(name) {
        if (isNiriSession) {
            return _toArray(NativeNiri.Niri.windowsForOutput(String(name || ""))).map(_normalizeNiriWindow).filter(w => w !== null);
        }
        return windows.filter(w => w.output === name);
    }

    function workspaceIcons(workspaceId, groupApps) {
        if (isNiriSession) {
            return _toArray(NativeNiri.Niri.workspaceIcons(Number(workspaceId), groupApps === undefined ? true : !!groupApps));
        }
        const wins = windowsForWorkspace(workspaceId);
        return wins.map(w => ({
            appId: w.appId || "",
            appName: w.appName || w.appId || "",
            iconPath: w.iconPath || "",
            count: 1,
            active: !!w.isFocused
        }));
    }

    function _gnomeAction(kind, id) {
        if (!GnomeSession.connected) return false;
        return GnomeSession.request(kind, { target: String(id) }) > 0;
    }

    function focusWindow(id) {
        return isNiriSession ? NativeNiri.Niri.focusWindow(Number(id)) : _gnomeAction("focus", id);
    }

    function minimizeWindow(id) {
        if (isNiriSession) return NativeNiri.Niri.minimizeWindow(Number(id));
        return supportsMinimize && _gnomeAction("minimize", id);
    }

    function restoreWindow(id, outputName) {
        if (isNiriSession) return NativeNiri.Niri.restoreWindow(Number(id), String(outputName || ""));
        return _gnomeAction("restore", id);
    }

    function closeWindow(id) {
        return isNiriSession ? NativeNiri.Niri.closeWindow(Number(id)) : _gnomeAction("close", id);
    }

    function closeFocusedWindow() {
        if (isNiriSession) return NativeNiri.Niri.closeFocusedWindow();
        const fw = focusedWindow;
        return fw ? closeWindow(fw.id) : false;
    }

    function focusWorkspace(id) {
        return isNiriSession ? NativeNiri.Niri.focusWorkspaceById(Number(id)) : _gnomeAction("workspace", id);
    }

    function focusWorkspaceById(id) {
        return focusWorkspace(id);
    }

    function focusWorkspaceByIndex(index) {
        if (isNiriSession) return NativeNiri.Niri.focusWorkspaceByIndex(Number(index));
        const ws = workspaces.find(w => Number(w.index) === Number(index) || Number(w.idx) === Number(index));
        return ws ? _gnomeAction("workspace", ws.id) : false;
    }

    function focusWorkspaceByName(wsName) {
        if (isNiriSession) return NativeNiri.Niri.focusWorkspaceByName(String(wsName || ""));
        const ws = workspaces.find(w => String(w.name || "") === String(wsName || ""));
        return ws ? _gnomeAction("workspace", ws.id) : false;
    }

    function toggleOverview() {
        if (isNiriSession) return NativeNiri.Niri.toggleOverview();
        GnomeSession.lastError = qsTr("Overview toggle requires Niri backend");
        return false;
    }

    function setFloatingParallaxOffsets(offsets) {
        if (isNiriSession) {
            NativeNiri.Niri.setFloatingParallaxOffsets(offsets || ({}));
            return true;
        }
        GnomeSession.lastError = qsTr("GNOME does not expose Clavis floating-window parallax");
        return !!capabilities.parallax;
    }

    function configureOutput(requestId, outputName, actionPayload) {
        if (isNiriSession) {
            NativeNiri.Niri.configureOutput(String(requestId || ""), String(outputName || ""), actionPayload);
            return true;
        }
        root.outputRequestFinished(String(requestId || ""), false, qsTr("Display configuration via Clavis requires Niri backend"));
        return false;
    }

    function refreshOutputs() {
        if (isNiriSession) {
            NativeNiri.Niri.refreshOutputs();
            return true;
        }
        return connected;
    }

    function setWindowOpacity(enabled, activeOpacity, inactiveOpacity) {
        if (isNiriSession) {
            return true;
        }
        if (!GnomeSession.connected || !capabilities.windowOpacity) {
            return false;
        }
        return GnomeSession.request("window_opacity", {
            enabled: !!enabled,
            active: Number(activeOpacity),
            inactive: Number(inactiveOpacity)
        }) > 0;
    }

    function powerOffMonitors() {
        if (isNiriSession) return NativeNiri.Niri.powerOffMonitors();
        GnomeSession.lastError = qsTr("Monitor DPMS control via Niri IPC requires Niri backend");
        return false;
    }

    function powerOnMonitors() {
        if (isNiriSession) return NativeNiri.Niri.powerOnMonitors();
        GnomeSession.lastError = qsTr("Monitor DPMS control via Niri IPC requires Niri backend");
        return false;
    }

    function cycleKeyboardLayout() {
        if (isNiriSession) return NativeNiri.Niri.cycleKeyboardLayout();
        GnomeSession.lastError = qsTr("Keyboard layout cycling via Niri IPC requires Niri backend");
        return false;
    }

    function doScreenTransition(delayMs) {
        if (isNiriSession) return NativeNiri.Niri.doScreenTransition(delayMs === undefined ? 0 : Number(delayMs));
        return false;
    }
}
