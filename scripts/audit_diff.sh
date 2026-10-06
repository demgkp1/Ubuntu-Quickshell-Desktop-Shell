#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/dkp/projects/Ubuntu Quickshell Desktop Shell"
cd "$PROJECT_DIR"

REF_DIR="$PROJECT_DIR/reference/StatIndet-quickshell"
SRC_DIR="$PROJECT_DIR/src"

echo "=================================================="
echo " Quickshell 1:1 Porting Diff Audit Report"
echo "=================================================="

if [ ! -d "$SRC_DIR" ] || [ -z "$(ls -A "$SRC_DIR" 2>/dev/null)" ]; then
    echo "src/ is currently clean / empty. Ready for Milestone 1."
    exit 0
fi

TOTAL_FILES=0
IDENTICAL_FILES=0
MODIFIED_FILES=0

find "$SRC_DIR" -type f | while read -r src_file; do
    rel_path="${src_file#$SRC_DIR/}"
    # Map lowercase to upstream PascalCase if needed
    ref_file="$REF_DIR/$rel_path"
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    if [ -f "$ref_file" ]; then
        if diff -u "$ref_file" "$src_file" > /dev/null 2>&1; then
            echo "[IDENTICAL] $rel_path"
            IDENTICAL_FILES=$((IDENTICAL_FILES + 1))
        else
            echo "[MODIFIED]  $rel_path"
            MODIFIED_FILES=$((MODIFIED_FILES + 1))
        fi
    else
        echo "[NEW/CUSTOM] $rel_path"
        MODIFIED_FILES=$((MODIFIED_FILES + 1))
    fi
done

echo "=================================================="
echo "Audit complete."
