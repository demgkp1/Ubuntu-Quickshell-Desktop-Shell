#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NIX="${CLAVIS_NIX:-$HOME/.nix-profile/bin/nix}"
exec "$NIX" develop "$ROOT" --command "$ROOT/scripts/build-native.sh"
