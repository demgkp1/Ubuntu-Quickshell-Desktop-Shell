#!/usr/bin/env bash
PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"

if command -v quickshell >/dev/null 2>&1; then
    QS_BIN="quickshell"
elif [ -x "/nix/store/j450rbc9izgdrgzh5lycl0126jsvnfpj-quickshell-wrapped-0.3.1/bin/quickshell" ]; then
    QS_BIN="/nix/store/j450rbc9izgdrgzh5lycl0126jsvnfpj-quickshell-wrapped-0.3.1/bin/quickshell"
else
    QS_BIN="nix develop \"$PROJECT_DIR\" --command quickshell"
fi

$QS_BIN ipc -p "$PROJECT_DIR/src/shell.qml" call powermenu toggle
