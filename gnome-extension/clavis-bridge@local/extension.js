import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const NAME = 'org.clavis.GnomeBridge';
const PATH = '/org/clavis/GnomeBridge';
const XML = `<node><interface name="${NAME}">
<method name="Snapshot"><arg type="s" direction="out"/></method>
<method name="Action"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="s" direction="out"/></method>
<signal name="Changed"><arg type="s"/></signal>
</interface></node>`;

export default class ClavisBridge extends Extension {
    enable() {
        this._signals = [];
        this._windowSignals = new Map();
        this._modifiedActors = new Map();
        this._idleSources = new Set();
        this._opacityConfig = {enabled: false, active: 0.92, inactive: 0.82};
        this._pending = 0;
        this._tracker = Shell.WindowTracker.get_default();
        this._object = Gio.DBusExportedObject.wrapJSObject(XML, this);
        this._object.export(Gio.DBus.session, PATH);
        this._owner = Gio.bus_own_name_on_connection(Gio.DBus.session, NAME,
            Gio.BusNameOwnerFlags.NONE, null, null);
        this._watch(global.display, 'window-created', (_display, window) => {
            this._queue();
            if (!this._opacityConfig.enabled)
                return;
            this._applyOpacityToWindow(window);
            const sourceId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                this._idleSources.delete(sourceId);
                if (this._opacityConfig.enabled)
                    this._applyOpacityToWindow(window);
                return GLib.SOURCE_REMOVE;
            });
            this._idleSources.add(sourceId);
        });
        this._watch(global.display, 'notify::focus-window', () => {
            this._queue();
            if (this._opacityConfig.enabled)
                this._applyWindowOpacity();
        });
        for (const signal of ['active-workspace-changed', 'notify::n-workspaces'])
            this._watch(global.workspace_manager, signal, () => this._queue());
        this._watch(Main.layoutManager, 'monitors-changed', () => this._queue());
        this._watch(Main.layoutManager.panelBox, 'notify::height', () => this._queue());
        this._watch(Main.layoutManager.panelBox, 'notify::visible', () => this._queue());
        this._watch(Main.screenShield, 'locked-changed', () => {
            this._queue();
            if (Main.screenShield.locked)
                this._restoreWindowOpacity();
            else if (this._opacityConfig.enabled)
                this._applyWindowOpacity();
        });
        this._queue();
    }

    _watch(object, signal, callback) {
        this._signals.push([object, object.connect(signal, callback)]);
    }

    _windows() {
        // Includes Wayland and XWayland windows; no EWMH-only fallback.
        return global.get_window_actors().map(actor => actor.meta_window)
            .filter(window => !window.is_override_redirect());
    }

    _syncWindowSignals(windows) {
        const live = new Set(windows);
        for (const [window, ids] of this._windowSignals) {
            if (!live.has(window)) {
                for (const id of ids) window.disconnect(id);
                this._windowSignals.delete(window);
            }
        }
        for (const window of windows) {
            if (this._windowSignals.has(window)) continue;
            const ids = ['notify::title', 'notify::minimized', 'workspace-changed',
                'position-changed', 'size-changed', 'unmanaged'].map(signal =>
                window.connect(signal, () => this._queue()));
            this._windowSignals.set(window, ids);
        }
    }

    _queue() {
        if (this._pending) return;
        // Coalesce events; never capture the screen or poll the compositor.
        this._pending = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
            this._pending = 0;
            this._object.emit_signal('Changed', new GLib.Variant('(s)', [this.Snapshot()]));
            return GLib.SOURCE_REMOVE;
        });
    }

    Snapshot() {
        const windows = this._windows();
        this._syncWindowSignals(windows);
        const manager = global.workspace_manager;
        const active = manager.get_active_workspace_index();
        const monitorManager = global.backend.get_monitor_manager();
        const connectors = monitorManager.get_monitors().map(monitor => monitor.get_connector());
        const outputs = Main.layoutManager.monitors.map(monitor => ({
            name: connectors.find(connector => monitorManager.get_monitor_for_connector(connector) === monitor.index) ?? '',
            index: monitor.index, x: monitor.x, y: monitor.y,
            width: monitor.width, height: monitor.height,
            scale: global.display.get_monitor_scale(monitor.index),
            primary: monitor.index === Main.layoutManager.primaryIndex,
        }));
        const focus = global.display.focus_window;
        return JSON.stringify({version: 1, backend: 'gnome',
            locked: Main.screenShield.locked,
            panelHeight: Main.layoutManager.panelBox.visible ? Main.layoutManager.panelBox.height : 0,
            capabilities: {windows: true, workspaces: true, minimize: true,
                minimizeAnimation: false, backgroundBlur: false, parallax: false,
                windowOpacity: true},
            outputs, focusedId: focus ? String(focus.get_stable_sequence()) : '',
            workspaces: Array.from({length: manager.n_workspaces}, (_, index) => ({
                id: index, idx: index + 1, name: String(index + 1),
                active: index === active, is_active: index === active,
                is_focused: index === active,
            })),
            windows: windows.filter(window => !window.skip_taskbar).map(window => {
                const app = this._tracker.get_window_app(window);
                const rect = window.get_frame_rect();
                const workspace = window.get_workspace();
                const output = outputs.find(item => item.index === window.get_monitor());
                const appId = app?.get_id() ?? window.get_wm_class() ?? '';
                return {id: String(window.get_stable_sequence()), title: window.title ?? '',
                    app_id: appId, appId, workspace_id: workspace?.index() ?? null,
                    isFocused: window === focus, is_focused: window === focus,
                    isMinimized: window.minimized, is_minimized: window.minimized,
                    output: output?.name ?? '', onAllWorkspaces: window.is_on_all_workspaces(),
                    x: rect.x, y: rect.y, width: rect.width, height: rect.height};
            }),
        });
    }

    _isClavisWindow(window) {
        const title = (window.get_title?.() ?? window.title ?? '').toLowerCase();
        if (title.startsWith('clavis-'))
            return true;
        const wmClass = (window.get_wm_class?.() ?? '').toLowerCase();
        const wmInstance = (window.get_wm_class_instance?.() ?? '').toLowerCase();
        const gtkAppId = (window.get_gtk_application_id?.() ?? '').toLowerCase();
        const appId = (this._tracker?.get_window_app(window)?.get_id() ?? '').toLowerCase();
        for (const identifier of [wmClass, wmInstance, gtkAppId, appId]) {
            if (!identifier)
                continue;
            if (identifier.startsWith('org.clavis.') || identifier === 'quickshell'
                || identifier === 'org.quickshell' || identifier === 'clavis')
                return true;
        }
        return false;
    }

    _shouldManageOpacity(window) {
        if (!window || Main.screenShield?.locked)
            return false;
        if (window.is_override_redirect() || window.skip_taskbar)
            return false;
        const type = window.get_window_type();
        if (type === Meta.WindowType.DESKTOP || type === Meta.WindowType.DOCK
            || type === Meta.WindowType.SPLASHSCREEN || type === Meta.WindowType.NOTIFICATION
            || type === Meta.WindowType.TOOLTIP || type === Meta.WindowType.MENU
            || type === Meta.WindowType.DROPDOWN_MENU || type === Meta.WindowType.POPUP_MENU
            || type === Meta.WindowType.COMBO || type === Meta.WindowType.DND
            || type === Meta.WindowType.OVERRIDE_OTHER)
            return false;
        if (this._isClavisWindow(window))
            return false;
        return true;
    }

    _setActorOpacity(actor, opacityByte) {
        if (!actor)
            return;
        const clamped = Math.max(0, Math.min(255, Math.round(opacityByte)));
        if (clamped >= 255) {
            if (this._modifiedActors.has(actor)) {
                const destroyId = this._modifiedActors.get(actor);
                try {
                    actor.set_opacity(255);
                    if (destroyId)
                        actor.disconnect(destroyId);
                } catch (_e) {
                }
                this._modifiedActors.delete(actor);
            }
            return;
        }
        if (!this._modifiedActors.has(actor)) {
            const destroyId = actor.connect('destroy', () => {
                this._modifiedActors.delete(actor);
            });
            this._modifiedActors.set(actor, destroyId);
        }
        try {
            actor.set_opacity(clamped);
        } catch (_e) {
        }
    }

    _restoreWindowOpacity() {
        for (const [actor, destroyId] of Array.from(this._modifiedActors.entries())) {
            try {
                actor.set_opacity(255);
                if (destroyId)
                    actor.disconnect(destroyId);
            } catch (_e) {
            }
            this._modifiedActors.delete(actor);
        }
    }

    _applyOpacityToWindow(window) {
        if (!this._opacityConfig.enabled || !window)
            return false;
        const actor = window.get_compositor_private?.();
        if (!actor)
            return false;
        if (!this._shouldManageOpacity(window)) {
            if (this._modifiedActors.has(actor))
                this._setActorOpacity(actor, 255);
            return true;
        }
        const focus = global.display.focus_window;
        const val = window === focus ? this._opacityConfig.active : this._opacityConfig.inactive;
        this._setActorOpacity(actor, Math.round(val * 255));
        return true;
    }

    _applyWindowOpacity() {
        if (!this._opacityConfig.enabled || Main.screenShield?.locked) {
            this._restoreWindowOpacity();
            return;
        }
        const focus = global.display.focus_window;
        const activeByte = Math.round(this._opacityConfig.active * 255);
        const inactiveByte = Math.round(this._opacityConfig.inactive * 255);
        const seenActors = new Set();
        for (const actor of global.get_window_actors()) {
            const window = actor.meta_window;
            if (!this._shouldManageOpacity(window)) {
                if (this._modifiedActors.has(actor))
                    this._setActorOpacity(actor, 255);
                continue;
            }
            seenActors.add(actor);
            this._setActorOpacity(actor, window === focus ? activeByte : inactiveByte);
        }
        for (const actor of Array.from(this._modifiedActors.keys())) {
            if (!seenActors.has(actor))
                this._setActorOpacity(actor, 255);
        }
    }

    Action(kind, id) {
        try {
            if (Main.screenShield.locked) throw new Error('Session is locked');
            if (kind === 'window_opacity') {
                let payload;
                try {
                    payload = JSON.parse(id);
                } catch (_e) {
                    throw new Error('Invalid window_opacity payload');
                }
                if (!payload || typeof payload !== 'object' || Array.isArray(payload)
                    || typeof payload.enabled !== 'boolean')
                    throw new Error('Invalid window_opacity payload');
                const enabled = payload.enabled;
                const active = payload.active === undefined ? 0.92 : Number(payload.active);
                const inactive = payload.inactive === undefined ? 0.82 : Number(payload.inactive);
                if (!Number.isFinite(active) || active < 0.2 || active > 1.0
                    || !Number.isFinite(inactive) || inactive < 0.2 || inactive > 1.0)
                    throw new Error('Window opacity must be between 0.20 and 1.0');
                this._opacityConfig = {enabled, active, inactive};
                this._applyWindowOpacity();
                return JSON.stringify({accepted: true});
            }
            const timestamp = global.get_current_time();
            if (kind === 'workspace') {
                const index = Number(id);
                if (!Number.isInteger(index) || index < 0 || index >= global.workspace_manager.n_workspaces)
                    throw new Error('Workspace no longer exists');
                global.workspace_manager.get_workspace_by_index(index).activate(timestamp);
            } else {
                const window = this._windows().find(item => String(item.get_stable_sequence()) === id);
                if (!window) throw new Error('Window no longer exists');
                switch (kind) {
                case 'focus': case 'restore': Main.activateWindow(window, timestamp); break;
                case 'minimize':
                    if (!window.can_minimize()) throw new Error('Window cannot be minimized');
                    window.minimize(); break;
                case 'close': window.delete(timestamp); break;
                default: throw new Error('Unsupported action');
                }
            }
            this._queue();
            // Submission is not confirmation; the next snapshot is authoritative.
            return JSON.stringify({accepted: true});
        } catch (error) {
            return JSON.stringify({accepted: false, error: error.message});
        }
    }

    disable() {
        if (this._pending) GLib.source_remove(this._pending);
        this._pending = 0;
        for (const sourceId of this._idleSources) GLib.source_remove(sourceId);
        this._idleSources.clear();
        this._restoreWindowOpacity();
        for (const [object, id] of this._signals) object.disconnect(id);
        this._signals = [];
        for (const [window, ids] of this._windowSignals)
            for (const id of ids) window.disconnect(id);
        this._windowSignals.clear();
        Gio.bus_unown_name(this._owner);
        this._object.unexport();
        this._object = null;
    }
}
