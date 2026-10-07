#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"

if [ -f "/home/dkp/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "/home/dkp/.nix-profile/etc/profile.d/nix.sh"
fi

PAGE="${1:-}"
if [ -n "$PAGE" ]; then
    if [[ "$PAGE" != *"."* && "$PAGE" != "account" && "$PAGE" != "general" && "$PAGE" != "wallpaper" && "$PAGE" != "theme" && "$PAGE" != "keystone" && "$PAGE" != "advanced" ]]; then
        PAGE="general.$PAGE"
    fi
    nix develop "$PROJECT_DIR" --command quickshell ipc -p "$PROJECT_DIR/src/" call controlcenter openSearch "$PAGE" >/dev/null 2>&1 || true
else
    nix develop "$PROJECT_DIR" --command quickshell ipc -p "$PROJECT_DIR/src/" call controlcenter toggle >/dev/null 2>&1 || true
fi
