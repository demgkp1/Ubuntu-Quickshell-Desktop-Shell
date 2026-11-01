#!/usr/bin/env python3
"""
x11_desktop_helper.py
Ubuntu Mutter X11 desktop companion daemon for Quickshell.

Features:
1. Window Management:
   - Tracks running client windows (_NET_CLIENT_LIST, _NET_ACTIVE_WINDOW, WM_CLASS, _NET_WM_STATE)
     and streams JSON events to Quickshell via stdout.
   - Automatically removes Mutter SSD (Server-Side Decoration) titlebars and frames from
     Quickshell FloatingWindows via _MOTIF_WM_HINTS.
   - Provides EWMH window activation (_NET_ACTIVE_WINDOW), minimization, and closing.
2. Ayatana StatusNotifierItem Bridge:
   - Detects compound Ayatana items (Clash Verge, reboot notifier, update notifier) from
     org.kde.StatusNotifierWatcher that Quickshell's native C++ SNI parser drops due to '@'.
   - Streams them to Quickshell and handles activation.
3. Notification Interception:
   - Monitors DBus notifications and forwards them to Quickshell's M3 notification manager.
"""

import os
import sys
import re
import json
import time
import select
import signal
import ctypes
import threading
import subprocess

# Ensure child process exits automatically when parent (Quickshell) dies
try:
    PR_SET_PDEATHSIG = 1
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
except Exception:
    pass

# Load libX11
try:
    x11 = ctypes.CDLL("libX11.so.6")
except Exception as e:
    sys.stderr.write(f"Failed to load libX11.so.6: {e}\n")
    sys.exit(1)

# X11 structures
class XClientMessageEvent(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_int),
        ("serial", ctypes.c_ulong),
        ("send_event", ctypes.c_int),
        ("display", ctypes.c_void_p),
        ("window", ctypes.c_ulong),
        ("message_type", ctypes.c_ulong),
        ("format", ctypes.c_int),
        ("data", ctypes.c_long * 5)
    ]

# Thread-safe stdout write
stdout_lock = threading.Lock()
def safe_print(obj):
    with stdout_lock:
        sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
        sys.stdout.flush()

class X11Helper:
    def __init__(self):
        self.disp = x11.XOpenDisplay(None)
        if not self.disp:
            raise RuntimeError("Cannot open X11 display")
        self.root = x11.XDefaultRootWindow(self.disp)
        self.x_fd = x11.XConnectionNumber(self.disp)
        
        # Intern atoms
        self.atom_client_list = self.get_atom("_NET_CLIENT_LIST")
        self.atom_active_window = self.get_atom("_NET_ACTIVE_WINDOW")
        self.atom_wm_class = self.get_atom("WM_CLASS")
        self.atom_wm_name = self.get_atom("WM_NAME")
        self.atom_net_wm_name = self.get_atom("_NET_WM_NAME")
        self.atom_net_wm_state = self.get_atom("_NET_WM_STATE")
        self.atom_net_wm_state_hidden = self.get_atom("_NET_WM_STATE_HIDDEN")
        self.atom_motif_wm_hints = self.get_atom("_MOTIF_WM_HINTS")
        self.atom_wm_protocols = self.get_atom("WM_PROTOCOLS")
        self.atom_wm_delete_window = self.get_atom("WM_DELETE_WINDOW")
        self.atom_utf8_string = self.get_atom("UTF8_STRING")

        # Cache of stripped windows
        self.stripped_windows = set()

    def get_atom(self, name):
        return x11.XInternAtom(self.disp, name.encode("utf-8"), False)

    def get_window_prop(self, wid, atom, req_type=0):
        actual_type = ctypes.c_ulong()
        actual_format = ctypes.c_int()
        nitems = ctypes.c_ulong()
        bytes_after = ctypes.c_ulong()
        prop = ctypes.c_void_p()
        res = x11.XGetWindowProperty(
            self.disp, wid, atom, 0, 4096, False, req_type,
            ctypes.byref(actual_type), ctypes.byref(actual_format),
            ctypes.byref(nitems), ctypes.byref(bytes_after),
            ctypes.byref(prop)
        )
        if res == 0 and nitems.value > 0 and prop.value:
            return prop, nitems.value, actual_type.value, actual_format.value
        return None, 0, 0, 0

    def get_client_list(self):
        prop, nitems, _, _ = self.get_window_prop(self.root, self.atom_client_list)
        if not prop:
            return []
        ptrs = ctypes.cast(prop, ctypes.POINTER(ctypes.c_ulong))
        res = [ptrs[i] for i in range(nitems)]
        x11.XFree(prop)
        return res

    def get_active_window(self):
        prop, nitems, _, _ = self.get_window_prop(self.root, self.atom_active_window)
        if not prop or nitems == 0:
            return 0
        ptrs = ctypes.cast(prop, ctypes.POINTER(ctypes.c_ulong))
        res = ptrs[0]
        x11.XFree(prop)
        return res

    def get_wm_class(self, wid):
        prop, nitems, _, _ = self.get_window_prop(wid, self.atom_wm_class)
        if not prop:
            return ""
        raw = ctypes.string_at(prop, nitems)
        x11.XFree(prop)
        parts = [p.decode("utf-8", "replace") for p in raw.split(b"\x00") if p]
        return parts[0] if parts else ""

    def get_window_title(self, wid):
        prop, nitems, _, _ = self.get_window_prop(wid, self.atom_net_wm_name, self.atom_utf8_string)
        if prop:
            raw = ctypes.string_at(prop, nitems)
            x11.XFree(prop)
            return raw.decode("utf-8", "replace")
        prop, nitems, _, _ = self.get_window_prop(wid, self.atom_wm_name)
        if prop:
            raw = ctypes.string_at(prop, nitems)
            x11.XFree(prop)
            return raw.decode("utf-8", "replace")
        return ""

    def is_minimized(self, wid):
        prop, nitems, _, _ = self.get_window_prop(wid, self.atom_net_wm_state)
        if not prop:
            return False
        ptrs = ctypes.cast(prop, ctypes.POINTER(ctypes.c_ulong))
        hidden = any(ptrs[i] == self.atom_net_wm_state_hidden for i in range(nitems))
        x11.XFree(prop)
        return hidden

    def strip_window_decorations(self, wid):
        hints = (ctypes.c_long * 5)(2, 0, 0, 0, 0)
        x11.XChangeProperty(
            self.disp, wid, self.atom_motif_wm_hints, self.atom_motif_wm_hints,
            32, 0, ctypes.cast(hints, ctypes.POINTER(ctypes.c_ubyte)), 5
        )
        x11.XFlush(self.disp)
        self.stripped_windows.add(wid)

    def activate_window(self, wid):
        ev = XClientMessageEvent()
        ev.type = 33
        ev.window = wid
        ev.message_type = self.atom_active_window
        ev.format = 32
        ev.data[0] = 2
        ev.data[1] = 0
        ev.data[2] = 0
        ev.data[3] = 0
        ev.data[4] = 0
        mask = (1 << 20) | (1 << 19)
        x11.XSendEvent(self.disp, self.root, False, mask, ctypes.byref(ev))
        x11.XFlush(self.disp)
        return True

    def minimize_window(self, wid):
        x11.XIconifyWindow(self.disp, wid, 0)
        x11.XFlush(self.disp)
        return True

    def close_window(self, wid):
        ev = XClientMessageEvent()
        ev.type = 33
        ev.window = wid
        ev.message_type = self.atom_wm_protocols
        ev.format = 32
        ev.data[0] = self.atom_wm_delete_window
        ev.data[1] = 0
        mask = (1 << 20) | (1 << 19)
        x11.XSendEvent(self.disp, wid, False, mask, ctypes.byref(ev))
        x11.XFlush(self.disp)
        return True

    def query_windows(self):
        clients = self.get_client_list()
        active = self.get_active_window()
        windows = []
        for wid in clients:
            try:
                title = self.get_window_title(wid)
                wm_class = self.get_wm_class(wid)

                if "clavis" in wm_class.lower() or "quickshell" in wm_class.lower() or title.startswith("clavis-"):
                    if wid not in self.stripped_windows:
                        self.strip_window_decorations(wid)
                    if title in ("clavis-shell-topbar", "clavis-shell-sidebar", "clavis-shell-dock", "clavis-shell-keystone"):
                        continue

                minimized = self.is_minimized(wid)
                windows.append({
                    "id": wid,
                    "title": title,
                    "appId": wm_class,
                    "isFocused": (wid == active),
                    "isMinimized": minimized
                })
            except Exception:
                pass
        return windows

    def run_daemon(self):
        PropertyChangeMask = (1 << 22)
        x11.XSelectInput(self.disp, self.root, PropertyChangeMask)
        x11.XFlush(self.disp)

        # Start notification monitor thread
        notif_thread = threading.Thread(target=run_notification_monitor, daemon=True)
        notif_thread.start()

        # Start Ayatana tray GDBus signal watcher thread
        ayatana_thread = threading.Thread(target=run_ayatana_watcher, daemon=True)
        ayatana_thread.start()

        # Emit initial window state
        safe_print({"event": "windows", "data": self.query_windows()})

        event_buffer = (ctypes.c_byte * 256)()

        while True:
            try:
                # Always drain Xlib internal user-space event buffer before blocking in select()
                # to prevent race conditions where events are buffered but the kernel socket is empty.
                if x11.XPending(self.disp) > 0:
                    changed = False
                    while x11.XPending(self.disp) > 0:
                        x11.XNextEvent(self.disp, ctypes.byref(event_buffer))
                        ev_type = ctypes.c_int.from_buffer(event_buffer).value
                        if ev_type == 28: # PropertyNotify
                            changed = True
                    if changed:
                        safe_print({"event": "windows", "data": self.query_windows()})

                r, _, _ = select.select([self.x_fd, sys.stdin.fileno()], [], [])
                
                if sys.stdin.fileno() in r:
                    line = sys.stdin.readline()
                    if not line:
                        break
                    parts = line.strip().split()
                    if parts:
                        cmd = parts[0].lower()
                        if cmd == "activate" and len(parts) > 1:
                            self.activate_window(int(parts[1], 0))
                        elif cmd == "minimize" and len(parts) > 1:
                            self.minimize_window(int(parts[1], 0))
                        elif cmd == "close" and len(parts) > 1:
                            self.close_window(int(parts[1], 0))
                        elif cmd == "strip" and len(parts) > 1:
                            self.strip_window_decorations(int(parts[1], 0))
                        elif cmd == "ayatana_activate" and len(parts) > 2:
                            bus = parts[1]
                            path = parts[2]
                            subprocess.Popen([
                                "gdbus", "call", "--session", "-d", bus, "-o", path,
                                "-m", "org.kde.StatusNotifierItem.SecondaryActivate", "0", "0"
                            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        elif cmd == "refresh":
                            safe_print({"event": "windows", "data": self.query_windows()})

                if self.x_fd in r or x11.XPending(self.disp) > 0:
                    changed = False
                    while x11.XPending(self.disp) > 0:
                        x11.XNextEvent(self.disp, ctypes.byref(event_buffer))
                        ev_type = ctypes.c_int.from_buffer(event_buffer).value
                        if ev_type == 28: # PropertyNotify
                            changed = True
                    if changed:
                        safe_print({"event": "windows", "data": self.query_windows()})

            except (KeyboardInterrupt, BrokenPipeError):
                break
            except Exception as e:
                sys.stderr.write(f"Error in x11 loop: {e}\n")


# Ayatana StatusNotifier GDBus Signal-Driven Watcher Thread
def get_clean_ayatana_items_gdbus():
    try:
        from gi.repository import Gio, GLib
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        res = bus.call_sync(
            "org.kde.StatusNotifierWatcher",
            "/StatusNotifierWatcher",
            "org.freedesktop.DBus.Properties",
            "Get",
            GLib.Variant("(ss)", ("org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems")),
            None,
            Gio.DBusCallFlags.NONE,
            1000,
            None
        )
        raw_items = res.get_child_value(0).get_variant().unpack()
        items = []
        for r in raw_items:
            r = str(r).strip("\"").strip("'")
            if "@" in r:
                bus_name, path = r.split("@", 1)
            else:
                bus_name, path = r, "/StatusNotifierItem"
            
            def get_prop(prop_name):
                try:
                    val = bus.call_sync(
                        bus_name, path,
                        "org.freedesktop.DBus.Properties", "Get",
                        GLib.Variant("(ss)", ("org.kde.StatusNotifierItem", prop_name)),
                        None, Gio.DBusCallFlags.NONE, 500, None
                    )
                    return val.get_child_value(0).get_variant().unpack()
                except Exception:
                    return ""

            item_id = get_prop("Id") or path.split("/")[-1]
            title = get_prop("Title") or item_id
            icon = get_prop("IconName")
            if icon and str(icon).startswith("/"):
                icon = "file://" + str(icon)
            items.append({
                "bus": bus_name,
                "path": path,
                "id": str(item_id),
                "title": str(title),
                "icon": str(icon or "system-run"),
                "status": 1
            })
        return items
    except Exception:
        return []

def run_ayatana_watcher():
    last_json = ""
    def update():
        nonlocal last_json
        try:
            items = get_clean_ayatana_items_gdbus()
            cur_json = json.dumps(items)
            if cur_json != last_json:
                last_json = cur_json
                safe_print({"event": "ayatana", "data": items})
        except Exception:
            pass

    # Initial snapshot
    update()

    try:
        from gi.repository import Gio, GLib
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        loop = GLib.MainLoop()

        def on_signal(*args):
            update()

        bus.signal_subscribe(
            "org.kde.StatusNotifierWatcher",
            "org.kde.StatusNotifierWatcher",
            None,
            "/StatusNotifierWatcher",
            None,
            Gio.DBusSignalFlags.NONE,
            on_signal,
            None
        )
        loop.run()
    except Exception:
        # Fallback with relaxed interval (15s) if GLib/Gio fails
        while True:
            update()
            time.sleep(15)


# Notification Interception Thread
def run_notification_monitor():
    def set_death():
        try:
            ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)
        except Exception:
            pass

    try:
        import atexit
        proc = subprocess.Popen([
            "busctl", "--user", "monitor", "org.freedesktop.Notifications",
            "--match", "type='method_call',member='Notify'"
        ], stdout=subprocess.PIPE, text=True, bufsize=1, preexec_fn=set_death)
        atexit.register(lambda: proc.terminate() if proc.poll() is None else None)
    except Exception:
        return

    buffer = ""
    seen_hashes = set()

    for line in proc.stdout:
        buffer += line
        if "MESSAGE \"susssasa{sv}i\"" in buffer and "};" in buffer:
            # Complete message
            strings = re.findall(r'STRING\s+"([^"]*)"', buffer)
            if len(strings) >= 4:
                app_name = strings[0] or "System"
                icon = strings[1]
                summary = strings[2]
                body = strings[3]
                h = f"{app_name}:{summary}:{body}"
                if h not in seen_hashes:
                    seen_hashes.add(h)
                    if len(seen_hashes) > 100:
                        seen_hashes.clear()
                    safe_print({
                        "event": "notification",
                        "data": {
                            "appName": app_name,
                            "appIcon": icon,
                            "summary": summary,
                            "body": body
                        }
                    })
            buffer = ""


def main():
    helper = X11Helper()
    args = sys.argv[1:]
    if not args or args[0] == "daemon":
        helper.run_daemon()
    elif args[0] == "list":
        print(json.dumps(helper.query_windows(), indent=2))
    elif args[0] == "activate" and len(args) > 1:
        helper.activate_window(int(args[1], 0))
    elif args[0] == "minimize" and len(args) > 1:
        helper.minimize_window(int(args[1], 0))
    elif args[0] == "close" and len(args) > 1:
        helper.close_window(int(args[1], 0))
    elif args[0] == "strip" and len(args) > 1:
        helper.strip_window_decorations(int(args[1], 0))
    else:
        print("Usage: x11_desktop_helper.py [daemon|list|activate <wid>|minimize <wid>|close <wid>|strip <wid>]")

if __name__ == "__main__":
    main()
