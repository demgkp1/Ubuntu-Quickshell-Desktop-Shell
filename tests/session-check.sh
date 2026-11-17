#!/usr/bin/env bash
# No visible window, no settings writes or desktop actions.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d)"
OUT="$ROOT/build/gnome-session-validation"
mkdir -p "$OUT"
trap 'rm -rf "$TEMP"' EXIT
for dir in Common Services scripts; do ln -s "$ROOT/src/$dir" "$TEMP/$dir"; done
cp "$ROOT/tests/session/shell.qml" "$TEMP/shell.qml"
export QT_QPA_PLATFORM="${CLAVIS_TEST_QPA_PLATFORM:-offscreen}"
case "$QT_QPA_PLATFORM" in
    offscreen) ;;
    xcb) [[ -n "${DISPLAY:-}" ]] || { echo "Inherit the real DISPLAY for the XWayland check." >&2; exit 1; } ;;
    *) echo "CLAVIS_TEST_QPA_PLATFORM must be offscreen or xcb." >&2; exit 1 ;;
esac
export QML_IMPORT_PATH="$ROOT/build/qml:$CLAVIS_QML_DEPS"
unset QML2_IMPORT_PATH CLAVIS_SESSION_BACKEND
# shellcheck source=scripts/graphics-env.sh
source "$ROOT/scripts/graphics-env.sh"
python3 "$ROOT/scripts/run-instance.py" quickshell -p "$TEMP/shell.qml" >"$OUT/qml.log" 2>&1
python3 - "$OUT/qml.log" <<'PY'
import json,re,sys
text=open(sys.argv[1]).read()
assert not re.search(r'FATAL|ERROR|ReferenceError|TypeError|has crashed|deadline exceeded',text),text
match=re.search(r'GNOME_QML_STATE (\{.*\})',text)
assert match,text
state=json.loads(match.group(1))
assert isinstance(state['locked'],bool) and state['wallpaper']
if not state['connected']: assert state['windows']==0 and state['workspaces']==0
print('Read-only real GNOME state reached the QML backend:',state['state'])
PY
