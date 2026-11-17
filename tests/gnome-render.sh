#!/usr/bin/env bash
# Isolated Xvfb/QML behavior check, NOT GNOME Wayland desktop validation.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${CLAVIS_TEST_OUTPUT:-$ROOT/build/gnome-validation}"
mkdir -p "$OUTPUT"
rm -f "$OUTPUT"/*.jpg "$OUTPUT"/*.json "$OUTPUT"/*.pixels
TEMP="$(mktemp -d)"
qp=""; xp=""; bp=""; wp=""; cp=""
cleanup() {
    if [[ -n "$qp" ]]; then kill -TERM "$qp" 2>/dev/null || true; wait "$qp" 2>/dev/null || true; fi
    for pid in "$cp" "$wp" "$bp"; do if [[ -n "$pid" ]]; then kill -TERM "$pid" 2>/dev/null || true; fi; done
    if [[ -n "$xp" ]]; then kill -TERM "$xp" 2>/dev/null || true; wait "$xp" 2>/dev/null || true; fi
    rm -rf "$TEMP"
}
trap cleanup EXIT
Xvfb -displayfd 3 -screen 0 "${CLAVIS_TEST_XVFB_GEOMETRY:-1600x900x24}" 3>"$TEMP/display" >"$OUTPUT/xvfb.log" 2>&1 &
xp=$!
for _ in {1..60}; do [[ -s "$TEMP/display" ]] && break; sleep .1; done
[[ -s "$TEMP/display" ]] || { echo "Xvfb failed"; exit 1; }
DISPLAY=":$(cat "$TEMP/display")"
export DISPLAY
unset WAYLAND_DISPLAY
export CLAVIS_SESSION_BACKEND=disabled
export CLAVIS_CONFIG_HOME="$TEMP/config" CLAVIS_DATA_HOME="$TEMP/data" CLAVIS_STATE_HOME="$TEMP/state" CLAVIS_CACHE_HOME="$TEMP/cache"
export CLAVIS_PROFILE_CONFIG_HOME="$TEMP/profile/config" CLAVIS_PROFILE_HOME="$TEMP/profile/data"
export XDG_RUNTIME_DIR="$TEMP/runtime"
mkdir -m 700 "$XDG_RUNTIME_DIR"
# A private session bus and X11 compositor isolate the real desktop.
/usr/bin/dbus-daemon --config-file=/usr/share/dbus-1/session.conf --fork --print-address=3 --print-pid=4 3>"$TEMP/bus-address" 4>"$TEMP/bus-pid"
bp="$(cat "$TEMP/bus-pid")"
DBUS_SESSION_BUS_ADDRESS="$(cat "$TEMP/bus-address")"
export DBUS_SESSION_BUS_ADDRESS
openbox >"$OUTPUT/openbox.log" 2>&1 &
wp=$!
picom --backend xrender --no-vsync >"$OUTPUT/picom.log" 2>&1 &
cp=$!
sleep .5
"$ROOT/scripts/run-shell.sh" >"$OUTPUT/shell.log" 2>&1 &
qp=$!
ipc() { quickshell ipc -p "$ROOT/src/shell.qml" call "$@"; }
ready=false
for _ in {1..100}; do
    kill -0 "$qp" 2>/dev/null || { cat "$OUTPUT/shell.log"; exit 1; }
    if ipc diagnostics snapshot >"$OUTPUT/initial.json" 2>/dev/null && python3 -c 'import json,sys; assert isinstance(json.load(open(sys.argv[1])),dict)' "$OUTPUT/initial.json" 2>/dev/null; then ready=true; break; fi
    sleep .1
 done
$ready || { cat "$OUTPUT/shell.log"; echo "No QML IPC readiness"; exit 1; }
python3 - "$OUTPUT/initial.json" <<'PY'
import json,sys
state=json.loads(open(sys.argv[1]).read().strip())
assert state['bars'] > 0
assert state['windows'] == 0 and state['workspaces'] == 0
assert state['blur'] is False and state['locked'] is False
assert state['wallpaperOwner'] == 'GNOME Shell'
PY
capture() {
    local name="$1"
    magick import -window root "$TEMP/frame.png"
    magick "$TEMP/frame.png" -resize '1280x720>' -quality 65 "$OUTPUT/$name.jpg"
    [[ $(stat -c %s "$OUTPUT/$name.jpg") -le 200000 ]] || { echo "Screenshot exceeds user limit"; exit 1; }
    magick "$TEMP/frame.png" -format '%[fx:standard_deviation]\n' info: >"$OUTPUT/$name.pixels"
    python3 - "$OUTPUT/$name.pixels" <<'PY'
import sys
assert float(open(sys.argv[1]).read()) > 0.01, 'Blank framebuffer'
PY
}
sleep 1
ipc diagnostics snapshot >"$OUTPUT/panels-initial.json"
# Record native X11 geometry/reservations. These are not QML constants, and
# are particularly important when the simulated Qt DPR is greater than one.
/usr/bin/xwininfo -root -tree >"$OUTPUT/window-tree.txt"
/usr/bin/xprop -root _NET_WORKAREA >"$OUTPUT/workarea.txt"
python3 - "$OUTPUT" <<'PY'
from pathlib import Path
import re,subprocess,sys
out=Path(sys.argv[1]); tree=(out/'window-tree.txt').read_text()
ids=re.findall(r'^\s+(0x[0-9a-f]+) .*quickshell',tree,re.M|re.I)
with (out/'window-properties.txt').open('w') as file:
 for wid in ids:
  file.write(wid+'\n')
  file.write(subprocess.check_output(['/usr/bin/xprop','-id',wid,'_NET_WM_PID','_NET_WM_STRUT_PARTIAL'],text=True))
PY
capture topbar
(
    # This second owned instance needs the same native Qt/GL paths; the
    # main launcher's per-process environment does not propagate to its caller.
    # shellcheck source=scripts/graphics-env.sh
    source "$ROOT/scripts/graphics-env.sh"
    export QML_IMPORT_PATH="$ROOT/build/qml:$CLAVIS_QML_DEPS"
    python3 "$ROOT/scripts/run-instance.py" quickshell -p "$ROOT/tests/session/workarea-window.qml"
) >"$OUTPUT/maximized-window.log" 2>&1
python3 "$ROOT/tests/check_panel_layout.py" "$OUTPUT"
ipc sidebar open quicksettings >"$OUTPUT/sidebar-action.txt"
sleep 1
ipc diagnostics snapshot >"$OUTPUT/quicksettings.json"
python3 - "$OUTPUT/quicksettings.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]));assert s['quickSettings'] and s['quickSettingsPresented'] and s['sidebarWidth'] > 0 and s['sidebarHeight'] > 0
PY
capture quicksettings
ipc sidebar close quicksettings >/dev/null
ipc sidebar open dashboard >/dev/null
sleep 1
ipc diagnostics snapshot >"$OUTPUT/dashboard.json"
python3 - "$OUTPUT/dashboard.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]));assert s['dashboard'] and s['dashboardPresented']
PY
capture dashboard
python3 - "$OUTPUT/topbar.jpg" "$OUTPUT/quicksettings.jpg" "$OUTPUT/dashboard.jpg" <<'PY'
import subprocess,sys
for path in sys.argv[2:]:
 p=subprocess.run(["magick","compare","-metric","AE",sys.argv[1],path,"null:"],capture_output=True,text=True)
 assert p.returncode in (0,1) and float(p.stderr.strip().split()[0]) > 20000, "Sidebar was not actually rendered"
PY
ipc sidebar close dashboard >/dev/null
ipc controlcenter open general >/dev/null
sleep 1
ipc diagnostics snapshot >"$OUTPUT/controlcenter.json"
python3 - "$OUTPUT/controlcenter.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]));assert s['controlCenter']
PY
capture controlcenter
ipc controlcenter open wallpaper >/dev/null
sleep .5
capture wallpaper-settings
ipc controlcenter open general >/dev/null
ipc controlcenter section general effects >/dev/null
sleep .5
capture effects-settings
ipc controlcenter section general displays.gamma >/dev/null
sleep .3
capture gnome-color-settings
ipc controlcenter close >/dev/null
ipc sidebar open quicksettings >/dev/null
sleep .1
capture animation
# Exercise the launcher's crash path while Xvfb is still alive. Record exactly
# this instance's descendants; never select or kill by a global process name.
python3 - "$qp" "$OUTPUT/owned-pids.json" <<'PYTEST'
from pathlib import Path
import json,sys
pids=[]
def children(pid):
 try: items=Path(f"/proc/{pid}/task/{pid}/children").read_text().split()
 except FileNotFoundError: return
 for child in map(int,items): pids.append(child);children(child)
children(int(sys.argv[1]));Path(sys.argv[2]).write_text(json.dumps(pids))
PYTEST
kill -KILL "$qp"; wait "$qp" 2>/dev/null || true; qp=""
python3 - "$OUTPUT/owned-pids.json" <<'PYTEST'
from pathlib import Path
import json,sys,time
pids=json.load(open(sys.argv[1]))
def alive(pid):
 try: return Path(f"/proc/{pid}/stat").read_text().rsplit(")",1)[1].split()[0] != "Z"
 except FileNotFoundError: return False
end=time.monotonic()+3
while any(alive(pid) for pid in pids) and time.monotonic()<end: time.sleep(.01)
assert not any(alive(pid) for pid in pids), 'Owned Quickshell descendants survived launcher SIGKILL'
PYTEST
python3 - "$OUTPUT" <<'PYTEST'
from pathlib import Path
import json,subprocess,sys,time
out=Path(sys.argv[1]);root=json.load(open(out/'panels-initial.json'))['panels'][0]['rootRect']
expected=[0,0,int(root['width']),int(root['height'])]
deadline=time.monotonic()+1
while True:
 text=subprocess.check_output(['/usr/bin/xprop','-root','_NET_WORKAREA'],text=True)
 actual=[int(value) for value in text.split('=',1)[1].split(',')[:4]]
 if actual==expected or time.monotonic()>=deadline: break
 time.sleep(.01)
assert actual==expected, ('Owned panel reservations survived shutdown',actual,expected)
(out/'workarea-after-stop.txt').write_text(text)
PYTEST
python3 - "$OUTPUT/shell.log" <<'PY'
import re,sys
text=open(sys.argv[1]).read()
# A lifecycle notice ("INFO: Crash handling disabled.") is not a crash.
# Keep actual crash/reporter events and every fatal graphics/QML error fatal.
errors=re.findall(r'^.*(?:FATAL|Could not initialize GLX|Failed to initialize graphics backend|qglx_findConfig|Failed to load configuration|Type .* unavailable|is not a type|ReferenceError|TypeError|Cannot assign|Cannot read property|is not a function|[Ss]egmentation fault|has crashed|[Cc]rashed|[Cc]rashing|[Cc]rash reporter).*$' , text, re.M)
assert not errors, '\n'.join(errors)
PY
echo "Isolated Xvfb behavior and framebuffer checks passed. Output: $OUTPUT"
