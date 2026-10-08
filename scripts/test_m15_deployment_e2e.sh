#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"
cd "$PROJECT_DIR"

if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

cleanup() {
    echo "[Test] Cleaning up any remaining test services..."
    systemctl --user stop clavis-desktop-shell.service 2>/dev/null || true
    systemctl --user disable clavis-desktop-shell.service 2>/dev/null || true
    killall quickshell 2>/dev/null || true
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=========================================================="
echo "    Milestone 15 Deployment & Autostart E2E Test Suite    "
echo "=========================================================="

echo "[Phase 1] Testing scripts/install.sh --enable..."
./scripts/install.sh --enable

# Check files
SERVICE_FILE="$HOME/.config/systemd/user/clavis-desktop-shell.service"
DESKTOP_FILE="$HOME/.config/autostart/clavis-desktop-shell.desktop"
BIN_CTL="$HOME/.local/bin/clavisctl"
BIN_LAUNCHER="$HOME/.local/bin/clavis-desktop-shell"

test -f "$SERVICE_FILE" || { echo "ERROR: Missing service file"; exit 1; }
test -f "$DESKTOP_FILE" || { echo "ERROR: Missing desktop file"; exit 1; }
test -x "$BIN_CTL" || { echo "ERROR: Missing executable clavisctl"; exit 1; }
test -x "$BIN_LAUNCHER" || { echo "ERROR: Missing executable clavis-desktop-shell"; exit 1; }

IS_ENABLED=$(systemctl --user is-enabled clavis-desktop-shell.service 2>/dev/null || echo "disabled")
echo "Systemd unit is-enabled: $IS_ENABLED"
if [ "$IS_ENABLED" != "enabled" ]; then
    echo "ERROR: Expected service to be enabled, got '$IS_ENABLED'"
    exit 1
fi
echo "[Phase 1] ✓ Installation files and systemd enablement verified."

echo "[Phase 2] Testing Systemd Service Start..."
systemctl --user start clavis-desktop-shell.service
sleep 4

IS_ACTIVE=$(systemctl --user is-active clavis-desktop-shell.service 2>/dev/null || echo "inactive")
echo "Systemd unit is-active: $IS_ACTIVE"
if [ "$IS_ACTIVE" != "active" ]; then
    echo "ERROR: Expected service to be active, got '$IS_ACTIVE'"
    journalctl --user -u clavis-desktop-shell.service -n 30 --no-pager
    exit 1
fi
echo "[Phase 2] ✓ Service started and active under systemd user session."

echo "[Phase 3] Testing clavisctl status and X11 window tree..."
STATUS_OUTPUT=$("$BIN_CTL" status)
echo "$STATUS_OUTPUT"

if [[ "$STATUS_OUTPUT" != *"ACTIVE (running)"* ]]; then
    echo "ERROR: clavisctl status did not report ACTIVE"
    exit 1
fi

WINDOWS=$(xwininfo -root -tree | grep -E "quickshell|HorizontalBar" || true)
echo "Inspecting root window tree:"
echo "$WINDOWS"
echo "$WINDOWS" | grep -E "2048x88" >/dev/null || { echo "ERROR: TopBar window not found in X11 tree"; exit 1; }
echo "[Phase 3] ✓ Health check and window tree verified."

echo "[Phase 4] Testing clavisctl IPC interactions..."
LOCK_STATUS=$("$BIN_CTL" ipc lock isLocked | tr -d '[:space:]')
echo "Lock status via clavisctl: '$LOCK_STATUS'"
if [ "$LOCK_STATUS" != "false" ]; then
    echo "ERROR: Expected false, got '$LOCK_STATUS'"
    exit 1
fi

echo "Triggering Spotlight toggle via clavisctl..."
SPOT_STATUS=$("$BIN_CTL" toggle spotlight)
echo "Spotlight response: $SPOT_STATUS"

echo "[Phase 4] ✓ IPC controls responsive through clavisctl."

echo "[Phase 5] Testing clavisctl restart..."
OLD_PID=$(pgrep -f "quickshell.*src/shell.qml" || pgrep -x "quickshell" | head -n1)
echo "Old PID: $OLD_PID"

"$BIN_CTL" restart
sleep 4

IS_ACTIVE_AFTER_RESTART=$(systemctl --user is-active clavis-desktop-shell.service 2>/dev/null || echo "inactive")
echo "Active after restart: $IS_ACTIVE_AFTER_RESTART"
if [ "$IS_ACTIVE_AFTER_RESTART" != "active" ]; then
    echo "ERROR: Service failed to restart"
    exit 1
fi

NEW_PID=$(pgrep -f "quickshell.*src/shell.qml" || pgrep -x "quickshell" | head -n1)
echo "New PID: $NEW_PID"
if [ "$OLD_PID" = "$NEW_PID" ]; then
    echo "ERROR: PID did not change after restart!"
    exit 1
fi
echo "[Phase 5] ✓ Service restarted smoothly with new PID."

echo "[Phase 6] Testing clavisctl stop..."
"$BIN_CTL" stop
sleep 2

IS_STOPPED=$(systemctl --user is-active clavis-desktop-shell.service 2>/dev/null || true)
echo "State after stop: '$IS_STOPPED'"
if [ "$IS_STOPPED" != "inactive" ]; then
    echo "ERROR: Expected inactive, got '$IS_STOPPED'"
    exit 1
fi
echo "[Phase 6] ✓ Service stopped cleanly."

echo "[Phase 7] Testing scripts/uninstall.sh..."
./scripts/uninstall.sh

test ! -f "$SERVICE_FILE" || { echo "ERROR: Service file was not removed"; exit 1; }
test ! -f "$DESKTOP_FILE" || { echo "ERROR: Desktop file was not removed"; exit 1; }
test ! -L "$BIN_CTL" || { echo "ERROR: clavisctl symlink was not removed"; exit 1; }
test ! -L "$BIN_LAUNCHER" || { echo "ERROR: clavis-desktop-shell symlink was not removed"; exit 1; }
echo "[Phase 7] ✓ Uninstaller completely and cleanly restored the environment."

echo "=========================================================="
echo " [SUCCESS] Milestone 15 Deployment E2E Test Suite PASSED! "
echo "=========================================================="
