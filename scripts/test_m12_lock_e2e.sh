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

# Wait for quickshell to start up
sleep 3

if ! kill -0 "$QS_PID" 2>/dev/null; then
    echo "[Test] ERROR: Quickshell failed to start!"
    exit 1
fi

echo "[Test] 2. Checking initial isLocked state via IPC..."
IS_LOCKED_INIT=$(qs_ipc call lock isLocked)
echo "Initial isLocked: '$IS_LOCKED_INIT'"
if [ "$IS_LOCKED_INIT" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_LOCKED_INIT'"
    exit 1
fi

echo "[Test] 3. Inspecting X11 Window Tree for 2048x1152 geometry..."
xwininfo -root -tree | grep -E "2048x1152" | head -n 10

echo "[Test] 4. Triggering lock open via IPC..."
LOCK_RESULT=$(qs_ipc call lock open)
echo "open result: '$LOCK_RESULT'"
if [ "$LOCK_RESULT" != "\"LOCKED\"" ] && [ "$LOCK_RESULT" != "LOCKED" ]; then
    echo "[Test] ERROR: Expected LOCKED, got '$LOCK_RESULT'"
    exit 1
fi

sleep 1

echo "[Test] 5. Checking isLocked state after open..."
IS_LOCKED_OPEN=$(qs_ipc call lock isLocked)
echo "After open isLocked: '$IS_LOCKED_OPEN'"
if [ "$IS_LOCKED_OPEN" != "true" ]; then
    echo "[Test] ERROR: Expected true, got '$IS_LOCKED_OPEN'"
    exit 1
fi

echo "[Test] 6. Triggering lock unlock via IPC..."
UNLOCK_RESULT=$(qs_ipc call lock unlock)
echo "unlock result: '$UNLOCK_RESULT'"

sleep 1

echo "[Test] 7. Checking isLocked state after unlock..."
IS_LOCKED_AFTER=$(qs_ipc call lock isLocked)
echo "After unlock isLocked: '$IS_LOCKED_AFTER'"
if [ "$IS_LOCKED_AFTER" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_LOCKED_AFTER'"
    exit 1
fi

echo "[Test] 8. Testing PowerMenu linkage: open powermenu -> trigger lock..."
PM_OPEN=$(qs_ipc call powermenu open)
echo "powermenu open: '$PM_OPEN'"
sleep 0.5
PM_TRIGGER=$(qs_ipc call powermenu trigger "lock")
echo "powermenu trigger lock: '$PM_TRIGGER'"
sleep 1

IS_LOCKED_PM=$(qs_ipc call lock isLocked)
echo "After powermenu lock trigger isLocked: '$IS_LOCKED_PM'"
if [ "$IS_LOCKED_PM" != "true" ]; then
    echo "[Test] ERROR: Expected true after powermenu lock trigger, got '$IS_LOCKED_PM'"
    exit 1
fi

echo "[Test] 9. Final unlock..."
qs_ipc call lock unlock >/dev/null
sleep 0.5
IS_LOCKED_FINAL=$(qs_ipc call lock isLocked)
echo "Final isLocked: '$IS_LOCKED_FINAL'"
if [ "$IS_LOCKED_FINAL" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_LOCKED_FINAL'"
    exit 1
fi

echo "[Test] SUCCESS: Milestone 12 E2E verification passed completely!"
