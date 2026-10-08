#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"

VERSION="${1:-$(cat "$PROJECT_DIR/VERSION" 2>/dev/null || echo "1.0.0")}"
VERSION="${VERSION#v}"
PKG_NAME="clavis-desktop-shell-v${VERSION}-ubuntu24.04"
ARCHIVE_NAME="${PKG_NAME}.tar.gz"

echo "=========================================================="
echo " Packaging Clavis Desktop Shell for Public Release"
echo " Package Version: v${VERSION}"
echo " Target Archive:  dist/${ARCHIVE_NAME}"
echo "=========================================================="

mkdir -p "$DIST_DIR"
TEMP_DIR="$(mktemp -d "/tmp/clavis-release.XXXXXX")"
cleanup() {
    rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

STAGE_DIR="$TEMP_DIR/$PKG_NAME"
mkdir -p "$STAGE_DIR"

echo "[1/4] Collecting release artifacts..."
cp -a "$PROJECT_DIR/bin" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/autostart" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/systemd" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/scripts" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/src" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/imports" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/docs" "$STAGE_DIR/"
if [ -d "$PROJECT_DIR/tools" ]; then
    cp -a "$PROJECT_DIR/tools" "$STAGE_DIR/"
fi
cp -a "$PROJECT_DIR/flake.nix" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/flake.lock" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/README.md" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/LICENSE" "$STAGE_DIR/"
cp -a "$PROJECT_DIR/VERSION" "$STAGE_DIR/"

echo "[2/4] Cleaning build artifacts, temporary caches, and test logs..."
find "$STAGE_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$STAGE_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
find "$STAGE_DIR" -type f -name "*~" -delete 2>/dev/null || true
find "$STAGE_DIR" -type f -name "*.swp" -delete 2>/dev/null || true

# Ensure all scripts and binaries have proper execution permissions
chmod +x "$STAGE_DIR"/bin/*
chmod +x "$STAGE_DIR"/scripts/*

echo "[3/4] Creating compressed tarball..."
tar -czf "$DIST_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" "$PKG_NAME"

echo "[4/4] Generating SHA256 checksums..."
cd "$DIST_DIR"
sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
if [ -f "SHA256SUMS" ]; then
    grep -v "$ARCHIVE_NAME" "SHA256SUMS" > "SHA256SUMS.tmp" 2>/dev/null || true
    mv "SHA256SUMS.tmp" "SHA256SUMS"
fi
sha256sum "$ARCHIVE_NAME" >> "SHA256SUMS"

echo "=========================================================="
echo " Package successfully built!"
echo " Archive:   $DIST_DIR/$ARCHIVE_NAME ($(ls -lh "$DIST_DIR/$ARCHIVE_NAME" | awk '{print $5}'))"
echo " Checksum:  $(cat "$DIST_DIR/${ARCHIVE_NAME}.sha256")"
echo "=========================================================="
