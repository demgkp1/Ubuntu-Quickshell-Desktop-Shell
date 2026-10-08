#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"
cd "$PROJECT_DIR"

if [ -f "/home/dkp/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "/home/dkp/.nix-profile/etc/profile.d/nix.sh"
fi

export XCURSOR_THEME="Yaru"
export XCURSOR_SIZE="24"
export XCURSOR_PATH="/usr/share/icons:/home/dkp/.icons"
export QT_QUICK_BACKEND="software"
export QT_QPA_PLATFORM="xcb"
export QML2_IMPORT_PATH="$PROJECT_DIR/imports:${QML2_IMPORT_PATH:-}"

cleanup() {
    echo "[Test] Cleaning up quickshell instances..."
    killall quickshell 2>/dev/null || true
}
trap cleanup EXIT INT TERM

qs_ipc() {
    nix develop "$PROJECT_DIR" --command quickshell ipc -p "$PROJECT_DIR/src/shell.qml" "$@" 2>/dev/null | grep -v "===" | grep -v "Quickshell" | tail -n 1 | tr -d '\r'
}

echo "[Test] 1. Launching Quickshell in background..."
nix develop "$PROJECT_DIR" --command quickshell -p "$PROJECT_DIR/src/shell.qml" &
QS_PID=$!

sleep 3

if ! kill -0 "$QS_PID" 2>/dev/null; then
    echo "[Test] ERROR: Quickshell failed to start!"
    exit 1
fi

echo "[Test] 2. Inspecting X11 Window Tree for 4x (8x8) HotCorner geometry..."
CORNER_WINDOWS=$(xwininfo -root -tree | grep -E "8x8\+[0-9]+\+[0-9]+" || true)
echo "$CORNER_WINDOWS"

COUNT_CORNERS=$(echo "$CORNER_WINDOWS" | grep -v "^$" | wc -l)
echo "Found $COUNT_CORNERS hot corner windows."
if [ "$COUNT_CORNERS" -lt 4 ]; then
    echo "[Test] ERROR: Expected at least 4 hot corner 8x8 windows, found $COUNT_CORNERS"
    exit 1
fi

# Verify specific corners exist on DP-1 (2048x1152)
echo "[Test] Verifying corner coordinates (0,0), (2040,0), (0,1144), (2040,1144)..."
echo "$CORNER_WINDOWS" | grep "8x8+0+0" >/dev/null || { echo "[Test] ERROR: Missing Top-Left (8x8+0+0)"; exit 1; }
echo "$CORNER_WINDOWS" | grep "8x8+2040+0" >/dev/null || { echo "[Test] ERROR: Missing Top-Right (8x8+2040+0)"; exit 1; }
echo "$CORNER_WINDOWS" | grep "8x8+0+1144" >/dev/null || { echo "[Test] ERROR: Missing Bottom-Left (8x8+0+1144)"; exit 1; }
echo "$CORNER_WINDOWS" | grep "8x8+2040+1144" >/dev/null || { echo "[Test] ERROR: Missing Bottom-Right (8x8+2040+1144)"; exit 1; }
echo "[Test] ✓ All 4 hot corner windows are accurately positioned at screen extremes."

echo "[Test] 3. Testing IPC queries and dynamic configuration..."
CORNER_IDS=$(qs_ipc call hotcorners getCornerIds)
echo "Corner IDs: $CORNER_IDS"
if [[ "$CORNER_IDS" != *"top-left"* ]] || [[ "$CORNER_IDS" != *"top-right"* ]]; then
    echo "[Test] ERROR: Invalid Corner IDs returned"
    exit 1
fi

TL_ACTION=$(qs_ipc call hotcorners getAction "top-left")
echo "Initial top-left action: $TL_ACTION"

echo "Configuring top-right corner to 'quicksettings:settings'..."
SET_RESULT=$(qs_ipc call hotcorners setAction "top-right" "quicksettings:settings")
echo "Set result: $SET_RESULT"
if [[ "$SET_RESULT" != *"quicksettings:settings"* ]]; then
    echo "[Test] ERROR: Failed to set top-right action"
    exit 1
fi

TR_ACTION=$(qs_ipc call hotcorners getAction "top-right")
echo "Verified top-right action: $TR_ACTION"

echo "[Test] 4. Testing IPC trigger action..."
TRIGGER_RES=$(qs_ipc call hotcorners trigger "quicksettings:settings" "DP-1")
echo "Trigger result: $TRIGGER_RES"
if [[ "$TRIGGER_RES" != *"TRIGGERED"* ]]; then
    echo "[Test] ERROR: Expected TRIGGERED, got $TRIGGER_RES"
    exit 1
fi

sleep 1

echo "[Test] 5. Testing Lock Screen / Avoidance mechanism..."
LOCKED_INIT=$(qs_ipc call hotcorners isLocked)
echo "Initial isLocked: $LOCKED_INIT"
if [ "$LOCKED_INIT" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$LOCKED_INIT'"
    exit 1
fi

echo "Simulating lock engagement..."
qs_ipc call lock open >/dev/null
sleep 0.8

LOCKED_ENGAGED=$(qs_ipc call hotcorners isLocked)
echo "During lock isLocked: $LOCKED_ENGAGED"
if [ "$LOCKED_ENGAGED" != "true" ]; then
    echo "[Test] ERROR: Expected true during lock, got '$LOCKED_ENGAGED'"
    exit 1
fi

echo "Unlocking session..."
qs_ipc call lock close >/dev/null
sleep 0.8

LOCKED_AFTER=$(qs_ipc call hotcorners isLocked)
echo "After unlock isLocked: $LOCKED_AFTER"
if [ "$LOCKED_AFTER" != "false" ]; then
    echo "[Test] ERROR: Expected false after unlock, got '$LOCKED_AFTER'"
    exit 1
fi
echo "[Test] ✓ Lock screen avoidance verified."

echo "[Test] 6. Testing Physical Mouse Dwell Engine via X11 pointer warping..."
# Python script to warp cursor to top-right corner and test dwell threshold
python3 -c "
import ctypes, time
x11 = ctypes.cdll.LoadLibrary('libX11.so.6')
d = x11.XOpenDisplay(None)
root = x11.XDefaultRootWindow(d)

print('[Python X11] Testing deliberate corner push (200ms dwell in top-right: 2045, 2)...')
x11.XWarpPointer(d, 0, root, 0, 0, 0, 0, 2045, 2)
x11.XFlush(d)
time.sleep(0.2)

# Warp away to center
print('[Python X11] Warping pointer back to center (500, 500)...')
x11.XWarpPointer(d, 0, root, 0, 0, 0, 0, 500, 500)
x11.XFlush(d)
x11.XCloseDisplay(d)
print('[Python X11] Done.')
"

sleep 1

echo "[Test] 7. Checking process health and stability..."
if ! kill -0 "$QS_PID" 2>/dev/null; then
    echo "[Test] ERROR: Quickshell crashed during hot corner physical interaction!"
    exit 1
fi

echo "=========================================================="
echo " [SUCCESS] Milestone 14 HotCorners E2E Test Suite PASSED! "
echo "=========================================================="
