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

echo "[Test] 2. Checking initial RegionSelectionService.active via IPC..."
IS_ACTIVE_INIT=$(qs_ipc call regionselector isActive)
echo "Initial isActive: '$IS_ACTIVE_INIT'"
if [ "$IS_ACTIVE_INIT" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_ACTIVE_INIT'"
    exit 1
fi

echo "[Test] 3. Inspecting X11 Window Tree for 2048x1152 geometry..."
xwininfo -root -tree | grep -E "2048x1152" | head -n 10

echo "[Test] 4. Triggering region screenshot via IPC..."
REGION_RESULT=$(qs_ipc call screenshot region)
echo "screenshot region result: '$REGION_RESULT'"
if [ "$REGION_RESULT" != "\"REGION\"" ] && [ "$REGION_RESULT" != "REGION" ]; then
    echo "[Test] ERROR: Expected REGION, got '$REGION_RESULT'"
    exit 1
fi

sleep 0.5

echo "[Test] 5. Checking isActive state during selection..."
IS_ACTIVE_SELECT=$(qs_ipc call regionselector isActive)
echo "During selection isActive: '$IS_ACTIVE_SELECT'"
if [ "$IS_ACTIVE_SELECT" != "true" ]; then
    echo "[Test] ERROR: Expected true, got '$IS_ACTIVE_SELECT'"
    exit 1
fi

echo "[Test] 6. Cancelling selection via IPC..."
CANCEL_RESULT=$(qs_ipc call regionselector cancel)
echo "cancel result: '$CANCEL_RESULT'"

sleep 0.5

echo "[Test] 7. Checking isActive state after cancel..."
IS_ACTIVE_AFTER_CANCEL=$(qs_ipc call regionselector isActive)
echo "After cancel isActive: '$IS_ACTIVE_AFTER_CANCEL'"
if [ "$IS_ACTIVE_AFTER_CANCEL" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_ACTIVE_AFTER_CANCEL'"
    exit 1
fi

echo "[Test] 8. Triggering full screen screenshot via IPC..."
BEFORE_COUNT=$(find "$HOME/Pictures/Screenshots" -type f -name "*.png" 2>/dev/null | wc -l)
SCREEN_RESULT=$(qs_ipc call screenshot screen)
echo "screenshot screen result: '$SCREEN_RESULT'"

sleep 1.5

AFTER_COUNT=$(find "$HOME/Pictures/Screenshots" -type f -name "*.png" 2>/dev/null | wc -l)
echo "Screenshot count: before=$BEFORE_COUNT, after=$AFTER_COUNT"
if [ "$AFTER_COUNT" -le "$BEFORE_COUNT" ]; then
    echo "[Test] ERROR: Expected new screenshot file in ~/Pictures/Screenshots!"
    exit 1
fi
LATEST_SS=$(ls -t "$HOME/Pictures/Screenshots"/*.png | head -n1)
echo "Latest screenshot created: $LATEST_SS ($(ls -lh "$LATEST_SS" | awk '{print $5}'))"

echo "[Test] 9. Triggering color picker via IPC..."
COLOR_RESULT=$(qs_ipc call screenshot color)
echo "screenshot color result: '$COLOR_RESULT'"
sleep 0.5
IS_ACTIVE_COLOR=$(qs_ipc call regionselector isActive)
echo "Color picker active: '$IS_ACTIVE_COLOR'"
if [ "$IS_ACTIVE_COLOR" != "true" ]; then
    echo "[Test] ERROR: Expected true, got '$IS_ACTIVE_COLOR'"
    exit 1
fi

qs_ipc call regionselector cancel >/dev/null
sleep 0.5
IS_ACTIVE_FINAL=$(qs_ipc call regionselector isActive)
echo "Final isActive: '$IS_ACTIVE_FINAL'"
if [ "$IS_ACTIVE_FINAL" != "false" ]; then
    echo "[Test] ERROR: Expected false, got '$IS_ACTIVE_FINAL'"
    exit 1
fi

echo "[Test] SUCCESS: Milestone 13 E2E verification passed completely!"
