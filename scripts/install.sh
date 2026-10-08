#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================="
echo "    Installing Clavis Desktop Shell (Ubuntu Quickshell)   "
echo "=========================================================="

ENABLE_AUTOSTART=false
START_SERVICE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable|--autostart)
            ENABLE_AUTOSTART=true
            shift
            ;;
        --start)
            START_SERVICE=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: ./scripts/install.sh [--enable] [--start]"
            exit 1
            ;;
    esac
done

# 1. Check prerequisites
echo "[1/5] Checking prerequisites..."
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
fi

if ! command -v nix >/dev/null 2>&1; then
    echo "ERROR: 'nix' package manager not found. Please ensure Nix is installed."
    exit 1
fi
echo "  ✓ Nix environment detected."

# 2. Deploy user systemd unit
echo "[2/5] Deploying Systemd User Service..."
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_TARGET="$SYSTEMD_USER_DIR/clavis-desktop-shell.service"
cat << EOF > "$SERVICE_TARGET"
[Unit]
Description=Clavis Desktop Shell (Ubuntu Quickshell)
Documentation=https://github.com/demgkp1/Ubuntu-Quickshell-Desktop-Shell
PartOf=graphical-session.target
After=graphical-session.target gnome-session.target

[Service]
Type=simple
Environment="DISPLAY=:0"
Environment="QT_QUICK_BACKEND=software"
Environment="QT_QPA_PLATFORM=xcb"
ExecStart="$PROJECT_DIR/bin/clavis-desktop-shell"
Restart=on-failure
RestartSec=2
KillMode=mixed
TimeoutStopSec=5

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
echo "  ✓ Installed to $SERVICE_TARGET and reloaded systemd daemon."

# 3. Deploy XDG Autostart entry
echo "[3/5] Deploying XDG Autostart entry..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
DESKTOP_TARGET="$AUTOSTART_DIR/clavis-desktop-shell.desktop"

cat << EOF > "$DESKTOP_TARGET"
[Desktop Entry]
Type=Application
Name=Clavis Desktop Shell
Comment=Mutter X11 Desktop Shell built with Quickshell
Exec="$PROJECT_DIR/bin/clavis-desktop-shell"
Icon=preferences-desktop-theme
Terminal=false
Categories=System;Utility;
StartupNotify=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Phase=Applications
X-GNOME-Autostart-Delay=1
EOF
echo "  ✓ Installed to $DESKTOP_TARGET"

# 4. Deploy CLI symlinks to ~/.local/bin
echo "[4/5] Deploying CLI symlinks to ~/.local/bin..."
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

ln -sf "$PROJECT_DIR/scripts/clavisctl" "$LOCAL_BIN/clavisctl"
ln -sf "$PROJECT_DIR/bin/clavis-desktop-shell" "$LOCAL_BIN/clavis-desktop-shell"
echo "  ✓ Linked clavisctl and clavis-desktop-shell into $LOCAL_BIN"

# 5. Service configuration
echo "[5/5] Configuring service state..."
if [ "$ENABLE_AUTOSTART" = true ]; then
    echo "  Enabling systemd service autostart..."
    systemctl --user enable clavis-desktop-shell.service
    echo "  ✓ Systemd user unit enabled."
fi

if [ "$START_SERVICE" = true ]; then
    echo "  Starting systemd service now..."
    systemctl --user start clavis-desktop-shell.service
    echo "  ✓ Clavis Desktop Shell started."
fi

echo "=========================================================="
echo "      Installation Completed Successfully!               "
echo "=========================================================="
echo "You can manage the shell using:"
echo "  clavisctl status     # Check health and window tree"
echo "  clavisctl start      # Start shell service"
echo "  clavisctl stop       # Stop shell service"
echo "  clavisctl restart    # Restart shell"
echo "  clavisctl logs -f    # Watch live system logs"
echo ""
echo "To enable autostart on login:"
echo "  systemctl --user enable clavis-desktop-shell.service"
echo "=========================================================="
