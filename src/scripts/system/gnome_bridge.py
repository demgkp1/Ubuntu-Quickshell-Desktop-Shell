#!/usr/bin/python3
"""Event-driven GNOME bridge; no Eval, EWMH window model, polling or screenshots.

Run with Ubuntu's /usr/bin/python3 (Gio/GLib), not the Nix Qt environment.
NDJSON stdin commands; stdout snapshots and correlated operation results.
"""
import ctypes
import json
import math
import os
from pathlib import Path
import signal
import sys

from gi.repository import Gio, GLib, GLibUnix

NAME = "org.clavis.GnomeBridge"
PATH = "/org/clavis/GnomeBridge"


PR_SET_PDEATHSIG = 1

def bind_parent():
    parent = os.getppid()
    if ctypes.CDLL(None).prctl(PR_SET_PDEATHSIG, signal.SIGTERM, 0, 0, 0) != 0:
        raise RuntimeError("Cannot bind bridge lifetime to parent")
    if parent == 1 or os.getppid() != parent:
        raise SystemExit(1)


def emit(kind, **data):
    print(json.dumps(dict(event=kind, **data), ensure_ascii=False), flush=True)


class Bridge:
    def __init__(self):
        self.loop = GLib.MainLoop()
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.owner = ""
        self.generation = 0
        self.cookie = 0
        self.pending = 0
        self.locked = None
        self.saver_active = None
        self.login_session = None
        self.saver_generation = 0
        self.lock_available = False
        self.idle_available = False
        self.background = Gio.Settings.new("org.gnome.desktop.background")
        self.interface = Gio.Settings.new("org.gnome.desktop.interface")
        self.session = Gio.Settings.new("org.gnome.desktop.session")
        self.power = Gio.Settings.new("org.gnome.settings-daemon.plugins.power")
        for settings in (self.background, self.interface, self.power, self.session):
            settings.connect("changed", lambda *_: self.desktop())
        Gio.bus_watch_name_on_connection(self.bus, NAME, Gio.BusNameWatcherFlags.NONE,
                                        self.appeared, self.vanished)
        Gio.bus_watch_name_on_connection(self.bus, "org.gnome.ScreenSaver",
                                        Gio.BusNameWatcherFlags.NONE,
                                        self.lock_appeared, self.lock_vanished)
        Gio.bus_watch_name_on_connection(self.bus, "org.gnome.SessionManager",
                                        Gio.BusNameWatcherFlags.NONE,
                                        self.idle_appeared, self.idle_vanished)
        self.bus.signal_subscribe(None, NAME, "Changed", PATH, None,
                                  Gio.DBusSignalFlags.NONE, self.changed)
        self.bus.signal_subscribe("org.gnome.ScreenSaver", "org.gnome.ScreenSaver",
                                  "ActiveChanged", "/org/gnome/ScreenSaver", None,
                                  Gio.DBusSignalFlags.NONE, self.lock_changed)
        self.channel = GLib.IOChannel.unix_new(sys.stdin.fileno())
        GLib.io_add_watch(self.channel, GLib.PRIORITY_DEFAULT,
                         GLib.IOCondition.IN | GLib.IOCondition.HUP, self.read)
        self.observe_lock_hint()
        self.desktop()

    def observe_lock_hint(self):
        # GetActive means screensaver activation, NOT necessarily a secure lock.
        # GNOME publishes its actual screenShield.locked via logind LockedHint.
        try:
            bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
            user_path = bus.call_sync("org.freedesktop.login1", "/org/freedesktop/login1",
                                     "org.freedesktop.login1.Manager", "GetUser",
                                     GLib.Variant("(u)", (os.getuid(),)), None,
                                     Gio.DBusCallFlags.NONE, 3000, None).unpack()[0]
            self.login_user = Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
                                                    "org.freedesktop.login1", user_path,
                                                    "org.freedesktop.login1.User", None)
            self.login_user.connect("g-properties-changed", lambda *_: self.attach_login_session(bus))
            self.attach_login_session(bus)
        except GLib.Error:
            self.locked = None

    def attach_login_session(self, bus):
        display = self.login_user.get_cached_property("Display")
        if not display or not display.unpack()[0]:
            self.locked = None
            self.desktop()
            return
        path = display.unpack()[1]
        if self.login_session and self.login_session.get_object_path() == path:
            return
        try:
            self.login_session = Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
                                                       "org.freedesktop.login1", path,
                                                       "org.freedesktop.login1.Session", None)
            self.login_session.connect("g-properties-changed", lambda *_: self.update_lock_hint())
            self.update_lock_hint()
        except GLib.Error:
            self.locked = None
            self.desktop()

    def update_lock_hint(self):
        hint = self.login_session.get_cached_property("LockedHint")
        self.locked = bool(hint.unpack()) if hint is not None else None
        self.desktop()

    def desktop(self):
        dark = self.interface.get_string("color-scheme") == "prefer-dark"
        uri = self.background.get_string("picture-uri-dark" if dark else "picture-uri")
        emit("desktop", wallpaper=uri, fill=self.background.get_string("picture-options"),
             wallpaperAvailable=True, locked=self.locked, screensaverActive=self.saver_active, lockAvailable=self.lock_available,
             idleAvailable=self.idle_available, inhibited=bool(self.cookie),
             idleDelay=self.session.get_uint("idle-delay"),
             idleDim=self.power.get_boolean("idle-dim"))

    def call(self, destination, path, interface, method, parameters, callback):
        def done(connection, result):
            try:
                value = connection.call_finish(result).unpack()
            except GLib.Error as error:
                callback(None, str(error))
            else:
                callback(value, "")
        self.bus.call(destination, path, interface, method, parameters, None,
                      Gio.DBusCallFlags.NONE, 3000, None, done)

    def appeared(self, _bus, _name, owner):
        self.owner = owner
        self.generation += 1
        generation = self.generation
        emit("compositor", state="pending", error="")
        def result(value, error):
            if generation != self.generation:
                return
            if error:
                emit("compositor", state="unavailable", error=error)
            else:
                self.snapshot(value[0])
        self.call(owner, PATH, NAME, "Snapshot", None, result)

    def vanished(self, *_):
        self.owner = ""
        self.generation += 1
        emit("compositor", state="unavailable", error="GNOME bridge extension is not enabled")

    def snapshot(self, payload):
        try:
            data = json.loads(payload)
            if data.get("version") != 1 or data.get("backend") != "gnome":
                raise ValueError("Unsupported bridge protocol")
            for key in ("windows", "workspaces", "outputs"):
                if not isinstance(data[key], list):
                    raise ValueError("Invalid " + key)
            emit("compositor", state="ready", data=data, error="")
        except (ValueError, KeyError, TypeError) as error:
            emit("compositor", state="unavailable", error=str(error))

    def changed(self, _bus, sender, *_args):
        if sender == self.owner:
            self.snapshot(_args[-1].unpack()[0])

    def lock_appeared(self, *_):
        self.saver_generation += 1
        generation = self.saver_generation
        def result(value, error):
            if generation != self.saver_generation:
                return
            self.lock_available = not bool(error)
            self.saver_active = bool(value[0]) if value else None
            self.desktop()
        self.call("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver",
                  "org.gnome.ScreenSaver", "GetActive", None, result)

    def lock_vanished(self, *_):
        self.saver_generation += 1
        self.lock_available = False
        self.saver_active = None
        self.desktop()

    def lock_changed(self, _bus, _sender, *_args):
        self.saver_active = bool(_args[-1].unpack()[0])
        self.lock_available = True
        self.desktop()

    def idle_appeared(self, *_):
        self.idle_available = True
        self.desktop()

    def idle_vanished(self, *_):
        self.idle_available = False
        self.cookie = 0
        self.pending = 0
        self.desktop()

    def result(self, command, accepted, error=""):
        emit("result", id=command.get("id"), accepted=accepted, error=error)

    @staticmethod
    def _validated_opacity(value, name):
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f"Invalid {name} opacity")
        num = float(value)
        if not math.isfinite(num) or not 0.2 <= num <= 1.0:
            raise ValueError(f"{name.capitalize()} opacity must be between 0.20 and 1.0")
        return round(num, 4)

    @classmethod
    def _window_opacity_payload(cls, command):
        enabled = command.get("enabled")
        if not isinstance(enabled, bool):
            raise ValueError("Invalid window_opacity enabled flag")
        active = command.get("active")
        inactive = command.get("inactive")
        if enabled:
            if active is None or inactive is None:
                raise ValueError("window_opacity requires active and inactive values")
            active_val = cls._validated_opacity(active, "active")
            inactive_val = cls._validated_opacity(inactive, "inactive")
        else:
            active_val = 0.92 if active is None else cls._validated_opacity(active, "active")
            inactive_val = 0.82 if inactive is None else cls._validated_opacity(inactive, "inactive")
        return json.dumps(
            {"enabled": enabled, "active": active_val, "inactive": inactive_val},
            separators=(",", ":"),
        )

    def _forward_extension_action(self, command, kind, argument):
        if not self.owner:
            self.result(command, False, "GNOME bridge unavailable")
            return
        def result(value, error):
            if error:
                self.result(command, False, error)
            else:
                try:
                    reply = json.loads(value[0])
                    self.result(command, bool(reply["accepted"]), reply.get("error", ""))
                except (ValueError, KeyError, IndexError, TypeError):
                    self.result(command, False, "Invalid action response")
        self.call(self.owner, PATH, NAME, "Action",
                  GLib.Variant("(ss)", (kind, argument)), result)

    def dispatch(self, command):
        kind = command.get("action")
        if kind in ("focus", "restore", "minimize", "close", "workspace"):
            self._forward_extension_action(command, kind, str(command.get("target", "")))
        elif kind == "window_opacity":
            try:
                payload = self._window_opacity_payload(command)
            except ValueError as error:
                self.result(command, False, str(error))
                return
            self._forward_extension_action(command, kind, payload)
        elif kind == "lock":
            self.call("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver",
                      "org.gnome.ScreenSaver", "Lock", None,
                      lambda value, error: self.result(command, not bool(error), error))
        elif kind == "wallpaper":
            try:
                path = Path(command["path"]).expanduser().resolve(strict=True)
                if not path.is_file():
                    raise ValueError("Wallpaper must be a file")
                uri = path.as_uri()
                self.background.delay()
                if not self.background.set_string("picture-uri", uri) or not self.background.set_string("picture-uri-dark", uri):
                    self.background.revert()
                    raise ValueError("Background settings are not writable")
                self.background.apply()
                self.result(command, True)
                self.desktop()
            except (OSError, ValueError, KeyError) as error:
                self.result(command, False, str(error))
        elif kind == "fill":
            mode = command.get("mode")
            if mode not in ("none", "wallpaper", "centered", "scaled", "stretched", "zoom", "spanned"):
                self.result(command, False, "Unsupported GNOME fill mode")
            else:
                ok = self.background.set_string("picture-options", mode)
                self.result(command, ok, "" if ok else "Background settings are not writable")
                self.desktop()
        elif kind == "inhibit":
            self.inhibit(command)
        else:
            self.result(command, False, "Unsupported action on GNOME")

    def inhibit(self, command):
        desired = bool(command.get("value"))
        if self.pending or not self.idle_available:
            self.result(command, False, "Idle service unavailable or busy")
            return
        if desired == bool(self.cookie):
            self.result(command, True)
            return
        self.pending = 1
        method = "Inhibit" if desired else "Uninhibit"
        params = GLib.Variant("(susu)", ("Clavis", 0, "User requested idle inhibition", 8)) if desired else GLib.Variant("(u)", (self.cookie,))
        def result(value, error):
            self.pending = 0
            if not error:
                self.cookie = value[0] if desired else 0
            self.result(command, not bool(error), error)
            self.desktop()
        self.call("org.gnome.SessionManager", "/org/gnome/SessionManager",
                  "org.gnome.SessionManager", method, params, result)

    def read(self, channel, condition):
        if condition & GLib.IOCondition.HUP:
            self.loop.quit()
            return False
        status, line, *_ = channel.read_line()
        if status == GLib.IOStatus.EOF:
            self.loop.quit()
            return False
        if status == GLib.IOStatus.NORMAL:
            try:
                command = json.loads(line)
                if not isinstance(command, dict):
                    raise ValueError("Commands must be JSON objects")
                self.dispatch(command)
            except (ValueError, TypeError) as error:
                emit("result", accepted=False, error=str(error))
        return True


if __name__ == "__main__":
    bind_parent()
    bridge = Bridge()
    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM,
                         lambda: (bridge.loop.quit(), False)[1])
    bridge.loop.run()
