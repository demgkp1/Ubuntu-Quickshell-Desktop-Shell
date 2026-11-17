#!/usr/bin/env python3
"""Validate actual X11 geometry/properties, not strings in QML source files."""
import json
import math
from pathlib import Path
import re
import subprocess
import sys

out = Path(sys.argv[1])
state = json.loads((out / "panels-initial.json").read_text())
roles = {panel["role"]: panel for panel in state["panels"]}
assert {"bar", "keystone", "dock", "sidebar"} <= roles.keys(), "Missing live native panel observations"

for role, panel in roles.items():
    assert panel["available"], (role, panel)
    native = panel["nativeRect"]
    monitor = panel["monitorRect"]
    dpr = panel["dpr"]
    assert dpr > 0 and native["width"] > 0 and native["height"] > 0
    # Independently read the native property from the running X server.
    raw = subprocess.check_output(["/usr/bin/xprop", "-id", panel["nativeId"], "_NET_WM_STRUT_PARTIAL"], text=True)
    match = re.search(r"= (.+)", raw)
    actual = [int(value) for value in match.group(1).split(",")] if match else []
    assert actual == panel["strut"], (role, actual, panel["strut"])
    if panel["thickness"] > 0:
        side = ["left", "right", "top", "bottom"].index(panel["edge"])
        assert len(actual) == 12
        assert actual[side] >= math.ceil(panel["thickness"] * dpr), (role, actual, panel)
        along = "height" if side < 2 else "width"
        origin = "y" if side < 2 else "x"
        assert actual[4 + side * 2] == monitor[origin]
        assert actual[5 + side * 2] == monitor[origin] + monitor[along] - 1
    else:
        assert not actual, (role, "Overlay must not reserve any workspace", actual)
    if role in ("keystone", "sidebar"):
        assert native == monitor, (role, "The canvas was shifted/shrunk by another panel's exclusion", panel)

island = roles["keystone"]
visual = island["visualRect"]
monitor = island["monitorRect"]
assert abs(visual["y"] - monitor["y"] - island["edgeMargin"] * island["dpr"]) <= 2, ("Clock moved below the top bar", island)
assert abs(visual["x"] + visual["width"] / 2 - monitor["x"] - monitor["width"] / 2) <= 2, ("Clock is not centered on its physical output", island)

dock = roles["dock"]
visual = dock["visualRect"]
monitor = dock["monitorRect"]
assert abs(visual["x"] + visual["width"] / 2 - monitor["x"] - monitor["width"] / 2) <= 2, ("Dock is not centered", dock)
assert abs(monitor["y"] + monitor["height"] - visual["y"] - visual["height"] - 8 * dock["dpr"]) <= 2, ("Dock lost its bottom edge margin", dock)

# A real, owned Qt window asks the private WM to maximize. Its client geometry
# and its actual WM frame must match the published work area. Never assume
# that a Qt frameless hint was honored, or compare a decorated client to the
# whole work area (the native frame extents must be accounted for).
log = (out / "maximized-window.log").read_text()
assert not re.search(r"FATAL|ERROR|ReferenceError|TypeError|has crashed", log), log
match = re.search(r"MAXIMIZED_WINDOW (\{.*\})", log)
assert match, log
maximized = json.loads(match.group(1))
workarea = subprocess.check_output(["/usr/bin/xprop", "-root", "_NET_WORKAREA"], text=True)
values = [int(value) for value in workarea.split("=", 1)[1].split(",")[:4]]
actual = maximized["nativeRect"]
assert len(maximized["frameExtents"]) == 4, ("WM frame extents were not read back", maximized)
frame = maximized["frameRect"]
assert [frame[name] for name in ("x", "y", "width", "height")] == values, (maximized, workarea)
assert actual["x"] >= values[0] and actual["y"] >= values[1]
assert actual["x"] + actual["width"] <= values[0] + values[2]
assert actual["y"] + actual["height"] <= values[1] + values[3]
bar = roles["bar"]
assert values[1] >= math.ceil(bar["thickness"] * bar["dpr"]), ("Maximized window overlaps the reserved bar", values, bar)
assert values[1] + values[3] <= monitor["height"] - math.ceil(dock["thickness"] * dock["dpr"])
(out / "layout-verified.json").write_text(json.dumps({
    "dpr": bar["dpr"], "root": bar["rootRect"], "workarea": values,
    "clockVisual": island["visualRect"], "dockVisual": dock["visualRect"],
    "maximizedNative": actual, "maximizedFrame": frame, "frameExtents": maximized["frameExtents"],
}, indent=2) + "\n")
print(f'Actual panel placement, scaled native struts, and owned-window maximization verified at Qt DPR {bar["dpr"]}.')
