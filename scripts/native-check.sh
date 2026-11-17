#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "${CLAVIS_NIX:-$HOME/.nix-profile/bin/nix}" develop "$ROOT" --command "$ROOT/tests/native-check.sh"
