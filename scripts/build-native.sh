#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# Nix's unused dev-shell outputs/out library flags are not shell-escaped.
export NIX_LDFLAGS="${NIX_LDFLAGS//"-L$ROOT/outputs/out/lib"/}"
export NIX_LDFLAGS="${NIX_LDFLAGS//"-rpath $ROOT/outputs/out/lib"/}"
rm -f "$ROOT/build/qt-version"
cmake -S "$ROOT" -B "$ROOT/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$ROOT/build" --parallel "${CLAVIS_BUILD_JOBS:-4}"
pkg-config --modversion Qt6Core > "$ROOT/build/qt-version.tmp"
mv "$ROOT/build/qt-version.tmp" "$ROOT/build/qt-version"
