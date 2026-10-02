#!/usr/bin/env python3
"""
esc_listener.py - Robust X11 Global Escape Key Listener for Quickshell Popups

Uses XGrabKey on XK_Escape to intercept the Escape key globally across
the desktop environment. Exits cleanly:
- When Escape is pressed (prints "ESC")
- When stdin closes / EOF (Quickshell closes the popup)
- When SIGTERM or SIGINT is received
"""
import ctypes
import sys
import select
import signal

x11 = ctypes.cdll.LoadLibrary('libX11.so.6')
display = x11.XOpenDisplay(None)
if not display:
    sys.exit(1)

root = x11.XDefaultRootWindow(display)
XK_Escape = 0xff1b
keycode = x11.XKeysymToKeycode(display, XK_Escape)
AnyModifier = 0x8000
xfd = x11.XConnectionNumber(display)

cleaned = False
def cleanup(*args):
    global cleaned
    if not cleaned:
        cleaned = True
        try:
            x11.XUngrabKey(display, keycode, AnyModifier, root)
            x11.XFlush(display)
            x11.XCloseDisplay(display)
        except:
            pass
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

# Grab the Escape key globally
x11.XGrabKey(display, keycode, AnyModifier, root, False, 1, 1)
x11.XFlush(display)
print("READY", flush=True)

class XEvent(ctypes.Structure):
    _fields_ = [('type', ctypes.c_int), ('pad', ctypes.c_char * 188)]

ev = XEvent()
stdin_fd = sys.stdin.fileno()

try:
    while True:
        # Check if events already queued in Xlib
        while x11.XPending(display) > 0:
            x11.XNextEvent(display, ctypes.byref(ev))
            if ev.type == 2: # KeyPress
                print("ESC", flush=True)
                cleanup()

        # Wait for either X11 events or stdin EOF
        rlist, _, _ = select.select([xfd, stdin_fd], [], [])
        if stdin_fd in rlist:
            # Check for EOF from parent
            chunk = sys.stdin.read(1)
            if not chunk: # EOF: parent closed or stopped
                cleanup()

        if xfd in rlist:
            while x11.XPending(display) > 0:
                x11.XNextEvent(display, ctypes.byref(ev))
                if ev.type == 2: # KeyPress
                    print("ESC", flush=True)
                    cleanup()
finally:
    cleanup()
