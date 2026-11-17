#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/native-validation"
TEMP="$(mktemp -d)"
mkdir -p "$OUT"
xp=""; qp=""
cleanup() {
    if [[ -n "$qp" ]]; then kill -TERM "$qp" 2>/dev/null || true; wait "$qp" 2>/dev/null || true; fi
    if [[ -n "$xp" ]]; then kill -TERM "$xp" 2>/dev/null || true; wait "$xp" 2>/dev/null || true; fi
    rm -rf "$TEMP"
}
trap cleanup EXIT
export CLAVIS_TEST_OUTPUT="$OUT" QT_QPA_PLATFORM=xcb
export QML_IMPORT_PATH="$ROOT/build/qml:$CLAVIS_QML_DEPS"
unset WAYLAND_DISPLAY QML2_IMPORT_PATH
# shellcheck source=scripts/graphics-env.sh
source "$ROOT/scripts/graphics-env.sh"
export XDG_RUNTIME_DIR="$TEMP/runtime"
mkdir -m 700 "$XDG_RUNTIME_DIR"
Xvfb -displayfd 3 -screen 0 640x360x24 3>"$TEMP/display" >"$OUT/xvfb.log" 2>&1 &
xp=$!
for _ in {1..60}; do [[ -s "$TEMP/display" ]] && break; sleep .1; done
[[ -s "$TEMP/display" ]] || exit 1
DISPLAY=":$(cat "$TEMP/display")"
export DISPLAY
python3 - "$ROOT" "$OUT" "$TEMP" <<'PY'
from pathlib import Path
import re,sys
root,out,temp=map(Path,sys.argv[1:])
# Load every first-party native URI used by the real source tree, not a whitelist.
uris={m.group(1) for p in (root/'src').rglob('*.qml') for m in re.finditer(r'^import\s+(Clavis\.[\w.]+)',p.read_text(),re.M)}
(temp/'shell.qml').write_text('\n'.join('import '+uri for uri in sorted(uris))+'\nimport M3Shapes\n'+(root/'tests/native/shell.qml').read_text())
for name,color in [('red','255 0 0'),('blue','0 0 255')]:
 (out/(name+'.ppm')).write_text('P3\n2 2\n255\n'+(color+'\n')*4)
PY
python3 "$ROOT/scripts/run-instance.py" quickshell -p "$TEMP/shell.qml" >"$OUT/runtime.log" 2>&1 &
qp=$!
wait "$qp"; qp=""
python3 - "$OUT" <<'PY'
from pathlib import Path
import re,subprocess,sys
out=Path(sys.argv[1]);text=(out/'runtime.log').read_text()
assert 'NATIVE_RUNTIME_VERIFIED' in text, text
assert not re.search(r'FATAL|ERROR|ReferenceError|TypeError|has crashed|deadline exceeded',text),text
for shape in ['cookie','sunny']:
 result=subprocess.run(['magick','compare','-metric','AE',str(out/'square.png'),str(out/(shape+'.png')),'null:'],capture_output=True,text=True)
 assert result.returncode in [0,1] and float(result.stderr.split()[0]) > 500, 'Shape collapsed to a rounded square'
for path in out.glob('*.png'): assert path.stat().st_size <= 200000
print('Native QML modules loaded; real shape silhouettes differ; decoded cover images change palette. Inactive audio is unavailable.')
PY
