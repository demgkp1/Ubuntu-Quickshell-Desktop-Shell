#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "    Uninstalling Clavis Desktop Shell (Ubuntu Quickshell) "
echo "=========================================================="

SERVICE_TARGET="$HOME/.config/systemd/user/clavis-desktop-shell.service"
DESKTOP_TARGET="$HOME/.config/autostart/clavis-desktop-shell.desktop"

# 1. Stop and disable service
echo "[1/4] Stopping and disabling Systemd service..."
systemctl --user stop clavis-desktop-shell.service 2>/dev/null || true
systemctl --user disable clavis-desktop-shell.service 2>/dev/null || true

# 2. Remove configuration files
echo "[2/4] Removing service and autostart files..."
if [ -f "$SERVICE_TARGET" ]; then
    rm -f "$SERVICE_TARGET"
    systemctl --user daemon-reload
    echo "  ✓ Removed $SERVICE_TARGET"
fi

if [ -f "$DESKTOP_TARGET" ]; then
    rm -f "$DESKTOP_TARGET"
    echo "  ✓ Removed $DESKTOP_TARGET"
fi

# 3. Remove binary symlinks
echo "[3/4] Removing CLI symlinks..."
rm -f "$HOME/.local/bin/clavisctl"
rm -f "$HOME/.local/bin/clavis-desktop-shell"
echo "  ✓ Removed symlinks from ~/.local/bin"

# 4. Clean up processes and restore GNOME native desktop
echo "[4/4] Cleaning up running processes and restoring GNOME topbar..."
killall quickshell 2>/dev/null || true
gnome-extensions disable "hidetopbar@mathieu.bidon.ca" 2>/dev/null || true
echo "  ✓ Restored GNOME topbar."

echo "=========================================================="
echo "    Uninstallation Completed! System is restored clean.  "
echo "=========================================================="
