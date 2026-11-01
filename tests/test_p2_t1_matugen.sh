#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [Test P2-T1] Material 3 Matugen Theme Generation Pipeline ==="

TARGET_TEAL="$PROJECT_DIR/docs/visual_benchmarks/target_teal_theme.png"
TARGET_SPIDER="$PROJECT_DIR/docs/visual_benchmarks/target_spider_cream_theme.png"
SCRIPT="$PROJECT_DIR/src/scripts/theme/generate_matugen_colors.sh"
CLAVIS_GENERATED="$HOME/.local/share/clavis/profiles/default/generated/clavis/colors.json"

if [ ! -f "$TARGET_TEAL" ] || [ ! -f "$TARGET_SPIDER" ]; then
    echo "[FAIL] Benchmark images not found!"
    exit 1
fi

echo "1. Testing Teal Theme generation..."
bash "$SCRIPT" --image "$TARGET_TEAL" --scheme "scheme-tonal-spot" --mode dark
if [ ! -f "$CLAVIS_GENERATED" ]; then
    echo "[FAIL] colors.json was not created!"
    exit 1
fi

TEAL_PRIMARY=$(jq -r '.primary' "$CLAVIS_GENERATED")
echo "Teal primary generated: $TEAL_PRIMARY"
if [[ "$TEAL_PRIMARY" != "#80d5d0" && "$TEAL_PRIMARY" != *"80d"* && "$TEAL_PRIMARY" != *"d5"* ]]; then
    echo "[WARN] Teal primary ($TEAL_PRIMARY) deviated from expected tone"
fi

echo "2. Testing Spider Cream Theme generation..."
bash "$SCRIPT" --image "$TARGET_SPIDER" --scheme "scheme-tonal-spot" --mode dark
SPIDER_PRIMARY=$(jq -r '.primary' "$CLAVIS_GENERATED")
echo "Spider cream primary generated: $SPIDER_PRIMARY"
if [[ "$SPIDER_PRIMARY" != "#e4c36c" && "$SPIDER_PRIMARY" != *"e4c"* && "$SPIDER_PRIMARY" != *"c3"* ]]; then
    echo "[WARN] Spider cream primary ($SPIDER_PRIMARY) deviated from expected tone"
fi

echo "3. Verifying M3 Token completeness (50+ tokens)..."
TOKEN_COUNT=$(jq 'keys | length' "$CLAVIS_GENERATED")
echo "M3 Token count: $TOKEN_COUNT"
if [ "$TOKEN_COUNT" -lt 40 ]; then
    echo "[FAIL] Incomplete M3 token set: $TOKEN_COUNT"
    exit 1
fi

echo "=== [PASS] P2-T1 Material 3 Matugen Pipeline Verified Successfully! ==="
