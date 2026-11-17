#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIX="${CLAVIS_NIX:-$HOME/.nix-profile/bin/nix}"
# No extension/GSettings changes and no process-name kills. GNOME remains owner.
exec "$NIX" develop "$ROOT" --command "$ROOT/scripts/run-shell.sh" "$@"
