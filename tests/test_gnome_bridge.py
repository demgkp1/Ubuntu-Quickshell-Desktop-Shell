#!/usr/bin/python3
"""Read-only GNOME behavior and real process-lifetime tests. No desktop actions."""
import importlib.util
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import unittest
from unittest import mock
from gi.repository import Gio, GLib

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "src/scripts/system/gnome_bridge.py"
ENV = dict(os.environ)
ENV.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
ENV.setdefault("DBUS_SESSION_BUS_ADDRESS", f"unix:path={ENV['XDG_RUNTIME_DIR']}/bus")


def _load_gnome_bridge():
    spec = importlib.util.spec_from_file_location("gnome_bridge", HELPER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ReadOnlyGnome(unittest.TestCase):
    def test_snapshot_and_rejection(self):
        process = subprocess.Popen(["/usr/bin/python3", str(HELPER)], stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=ENV)
        try:
            time.sleep(.3)
            self.assertIsNone(process.poll())
            process.stdin.write(json.dumps({"id": 1, "action": "wallpaper", "path": "/this-file-does-not-exist-clavis.png"}) + "\n")
            process.stdin.write(json.dumps({"id": 2, "action": "unsupported-operation"}) + "\n")
            process.stdin.flush()
            time.sleep(.2)
            process.terminate()
            output, errors = process.communicate(timeout=3)
            self.assertEqual(errors, "")
            messages = [json.loads(line) for line in output.splitlines()]
            desktop = [item for item in messages if item["event"] == "desktop"][-1]
            background = Gio.Settings.new("org.gnome.desktop.background")
            interface = Gio.Settings.new("org.gnome.desktop.interface")
            dark = interface.get_string("color-scheme") == "prefer-dark"
            self.assertEqual(desktop["wallpaper"], background.get_string("picture-uri-dark" if dark else "picture-uri"))
            self.assertEqual(desktop["fill"], background.get_string("picture-options"))
            self.assertTrue(desktop["lockAvailable"])
            bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
            saver = bus.call_sync("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver", "org.gnome.ScreenSaver", "GetActive", None,
                                 None, Gio.DBusCallFlags.NONE, 3000, None).unpack()[0]
            self.assertEqual(desktop["screensaverActive"], saver)
            for id in (1, 2):
                self.assertFalse(next(item for item in messages if item.get("id") == id)["accepted"])
            # Do not treat a missing extension as a functioning window model.
            states = [item for item in messages if item["event"] == "compositor"]
            self.assertTrue(states)
            if states[-1]["state"] != "ready":
                self.assertNotIn("data", states[-1])
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

    def test_real_parent_death(self):
        parent = subprocess.Popen(["/usr/bin/python3", "-c", """
import subprocess,sys,time
child=subprocess.Popen(['/usr/bin/python3',sys.argv[1]],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
print(child.pid,flush=True)
time.sleep(10)
""", str(HELPER)], stdout=subprocess.PIPE, text=True, env=ENV)
        child_pid = int(parent.stdout.readline())
        try:
            time.sleep(.2)
            os.kill(parent.pid, signal.SIGKILL)
            parent.wait(timeout=1)
            start = time.monotonic()
            def alive():
                try:
                    state = Path(f"/proc/{child_pid}/stat").read_text().rsplit(")", 1)[1].split()[0]
                    return state != "Z"
                except FileNotFoundError:
                    return False
            while alive() and time.monotonic() - start < .5:
                time.sleep(.005)
            self.assertFalse(alive(), "Bridge survived parent SIGKILL beyond 500 ms")
        finally:
            if parent.poll() is None:
                parent.kill()
                parent.wait()
            try:
                os.kill(child_pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            parent.stdout.close()


class WindowOpacityBridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gnome_bridge = _load_gnome_bridge()

    def _make_bridge(self, owner=":1.99"):
        bridge = self.gnome_bridge.Bridge.__new__(self.gnome_bridge.Bridge)
        bridge.owner = owner
        bridge.bus = mock.MagicMock()
        emitted = []
        bridge.result = lambda command, accepted, error="": emitted.append(
            {"id": command.get("id"), "accepted": accepted, "error": error}
        )
        return bridge, emitted

    def test_window_opacity_forwards_dbus_action_with_3000ms_timeout(self):
        bridge, emitted = self._make_bridge()
        bridge.dispatch({
            "id": 10,
            "action": "window_opacity",
            "enabled": True,
            "active": 0.92,
            "inactive": 0.82,
        })
        self.assertEqual(bridge.bus.call.call_count, 1)
        args = bridge.bus.call.call_args[0]
        self.assertEqual(args[0], ":1.99")
        self.assertEqual(args[1], self.gnome_bridge.PATH)
        self.assertEqual(args[2], self.gnome_bridge.NAME)
        self.assertEqual(args[3], "Action")
        self.assertEqual(args[4].unpack(), ("window_opacity", '{"enabled":true,"active":0.92,"inactive":0.82}'))
        self.assertEqual(args[7], 3000)

        callback = args[9]
        conn = mock.MagicMock()
        conn.call_finish.return_value = GLib.Variant("(s)", ('{"accepted":true}',))
        callback(conn, mock.MagicMock())
        self.assertEqual(emitted, [{"id": 10, "accepted": True, "error": ""}])

    def test_window_opacity_disable_defaults_and_extension_error(self):
        bridge, emitted = self._make_bridge()
        bridge.dispatch({"id": 11, "action": "window_opacity", "enabled": False})
        self.assertEqual(bridge.bus.call.call_count, 1)
        variant = bridge.bus.call.call_args[0][4]
        self.assertEqual(variant.unpack(), ("window_opacity", '{"enabled":false,"active":0.92,"inactive":0.82}'))

        callback = bridge.bus.call.call_args[0][9]
        conn = mock.MagicMock()
        conn.call_finish.return_value = GLib.Variant("(s)", ('{"accepted":false,"error":"Session is locked"}',))
        callback(conn, mock.MagicMock())
        self.assertEqual(emitted, [{"id": 11, "accepted": False, "error": "Session is locked"}])

    def test_window_opacity_invalid_reply_and_dbus_error(self):
        bridge, emitted = self._make_bridge()
        bridge.dispatch({"id": 12, "action": "window_opacity", "enabled": True, "active": 1.0, "inactive": 0.5})
        callback = bridge.bus.call.call_args[0][9]
        conn = mock.MagicMock()
        conn.call_finish.return_value = GLib.Variant("(s)", ("not-json",))
        callback(conn, mock.MagicMock())

        bridge.dispatch({"id": 13, "action": "window_opacity", "enabled": True, "active": 0.9, "inactive": 0.8})
        callback2 = bridge.bus.call.call_args[0][9]
        conn2 = mock.MagicMock()
        conn2.call_finish.side_effect = GLib.Error("DBus timeout")
        callback2(conn2, mock.MagicMock())

        self.assertEqual(emitted[0], {"id": 12, "accepted": False, "error": "Invalid action response"})
        self.assertFalse(emitted[1]["accepted"])
        self.assertIn("DBus timeout", emitted[1]["error"])

    def test_window_opacity_unavailable_and_validation_boundaries(self):
        bridge_no_owner, emitted_no_owner = self._make_bridge(owner="")
        bridge_no_owner.dispatch({
            "id": 20,
            "action": "window_opacity",
            "enabled": True,
            "active": 0.92,
            "inactive": 0.82,
        })
        self.assertEqual(bridge_no_owner.bus.call.call_count, 0)
        self.assertEqual(emitted_no_owner, [{"id": 20, "accepted": False, "error": "GNOME bridge unavailable"}])

        invalid_commands = [
            {"id": 21, "action": "window_opacity"},
            {"id": 22, "action": "window_opacity", "enabled": "true", "active": 0.9, "inactive": 0.8},
            {"id": 23, "action": "window_opacity", "enabled": True, "active": 0.9},
            {"id": 24, "action": "window_opacity", "enabled": True, "active": 0.19, "inactive": 0.8},
            {"id": 25, "action": "window_opacity", "enabled": True, "active": 0.9, "inactive": 1.01},
            {"id": 26, "action": "window_opacity", "enabled": True, "active": True, "inactive": 0.8},
            {"id": 27, "action": "window_opacity", "enabled": True, "active": math.nan, "inactive": 0.8},
        ]
        bridge, emitted = self._make_bridge()
        for cmd in invalid_commands:
            bridge.dispatch(cmd)
        self.assertEqual(bridge.bus.call.call_count, 0)
        self.assertEqual(len(emitted), len(invalid_commands))
        for item in emitted:
            self.assertFalse(item["accepted"])
            self.assertTrue(item["error"])

    def test_isolated_dbus_subprocess_window_opacity_roundtrip(self):
        harness = f"""
import json, subprocess, sys
from gi.repository import Gio, GLib

NAME = "org.clavis.GnomeBridge"
PATH = "/org/clavis/GnomeBridge"
XML = '''<node><interface name="org.clavis.GnomeBridge">
<method name="Snapshot"><arg type="s" direction="out"/></method>
<method name="Action"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="s" direction="out"/></method>
<signal name="Changed"><arg type="s"/></signal>
</interface></node>'''

received = []
loop = GLib.MainLoop()
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
info = Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0]

def on_call(_conn, _sender, _path, _iface, method, params, invocation):
    if method == "Snapshot":
        snap = json.dumps({{
            "version": 1, "backend": "gnome", "locked": False, "panelHeight": 0,
            "capabilities": {{"windows": True, "workspaces": True, "minimize": True,
                             "minimizeAnimation": False, "backgroundBlur": False,
                             "parallax": False, "windowOpacity": True}},
            "outputs": [], "focusedId": "", "workspaces": [], "windows": []
        }})
        invocation.return_value(GLib.Variant("(s)", (snap,)))
    elif method == "Action":
        kind, arg = params.unpack()
        received.append((kind, arg))
        invocation.return_value(GLib.Variant("(s)", ('{{"accepted":true}}',)))

bus.register_object(PATH, info, on_call, None, None)
proc = None
results = []

def on_acquired(_conn, _name):
    global proc
    proc = subprocess.Popen(
        ["/usr/bin/python3", {str(HELPER)!r}],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    proc.stdin.write(json.dumps({{"id": 101, "action": "window_opacity", "enabled": True, "active": 0.9, "inactive": 0.75}}) + "\\n")
    proc.stdin.write(json.dumps({{"id": 102, "action": "window_opacity", "enabled": False, "active": 0.9, "inactive": 0.75}}) + "\\n")
    proc.stdin.flush()
    GLib.timeout_add(400, lambda: (proc.terminate(), loop.quit(), False)[2])

Gio.bus_own_name_on_connection(bus, NAME, Gio.BusNameOwnerFlags.NONE, on_acquired, None)
GLib.timeout_add(4000, lambda: (loop.quit(), False)[1])
loop.run()
out, err = proc.communicate(timeout=3)
assert err == "", err
msgs = [json.loads(line) for line in out.splitlines()]
res = [m for m in msgs if m.get("event") == "result"]
assert len(res) == 2 and all(m["accepted"] for m in res), res
assert received == [
    ("window_opacity", '{{"enabled":true,"active":0.9,"inactive":0.75}}'),
    ("window_opacity", '{{"enabled":false,"active":0.9,"inactive":0.75}}'),
], received
print("OK")
"""
        run = subprocess.run(
            ["dbus-run-session", "--", "/usr/bin/python3", "-c", harness],
            capture_output=True, text=True, timeout=10
        )
        self.assertEqual(run.returncode, 0, msg=run.stderr or run.stdout)
        self.assertIn("OK", run.stdout)


if __name__ == "__main__":
    unittest.main()
