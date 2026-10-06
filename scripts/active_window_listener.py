#!/usr/bin/env python3
"""
active_window_listener.py - Native Wayland/X11 Active Window Tracker via AT-SPI2

Listens for window:activate and state change events via AT-SPI2.
Outputs JSON lines to stdout with 0ms latency for Quickshell ActiveWindowPill.
"""
import sys
import json
import signal
import select

try:
    import gi
    gi.require_version('Atspi', '2.0')
    from gi.repository import Atspi, GLib
except Exception as e:
    print(json.dumps({"title": "Desktop", "appName": "Desktop"}), flush=True)
    sys.exit(0)

last_state = {"title": "", "appName": ""}

def get_active_window():
    try:
        desktop = Atspi.get_desktop(0)
        count = desktop.get_child_count()
        for i in range(count):
            app = desktop.get_child_at_index(i)
            if not app:
                continue
            for j in range(app.get_child_count()):
                win = app.get_child_at_index(j)
                if not win:
                    continue
                state = win.get_state_set()
                if state.contains(Atspi.StateType.ACTIVE):
                    title = win.get_name() or app.get_name() or "Desktop"
                    appName = app.get_name() or "Application"
                    return {"title": title, "appName": appName}
    except Exception:
        pass
    return {"title": "Desktop", "appName": "Desktop"}

def check_and_emit():
    global last_state
    current = get_active_window()
    if current["title"] != last_state["title"] or current["appName"] != last_state["appName"]:
        last_state = current
        print(json.dumps(current), flush=True)

def on_event(event):
    # Throttle slightly with idle
    GLib.idle_add(check_and_emit)

# Initial state
check_and_emit()

listener = Atspi.EventListener.new(on_event)
listener.register('window:activate')
listener.register('window:deactivate')
listener.register('object:state-changed:active')

# Watch parent PID so when Quickshell exits, we exit cleanly
import os
parent_pid = os.getppid()

def check_parent_alive():
    if os.getppid() != parent_pid or os.getppid() <= 1:
        loop.quit()
        return False
    return True

GLib.timeout_add(1000, check_parent_alive)

def handle_sig(*args):
    loop.quit()

signal.signal(signal.SIGTERM, handle_sig)
signal.signal(signal.SIGINT, handle_sig)

loop = GLib.MainLoop()
try:
    loop.run()
except KeyboardInterrupt:
    pass
