#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p "$PROJECT_DIR/builds"
# Current 2.5D scope only. Retired RPG/voting/wardrobe UI tests live in backup history.
for suite in cleanup_2d survival_v13 survival_bots_v13 original_sprite practice spell_integrity; do
 XDG_DATA_HOME="${TMPDIR:-/tmp}/dosa-current-$suite" python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/$suite-results.txt" "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "res://tests/$suite.gd"
done
cat "$PROJECT_DIR/builds/cleanup_2d-results.txt" "$PROJECT_DIR/builds/survival_v13-results.txt" "$PROJECT_DIR/builds/survival_bots_v13-results.txt" "$PROJECT_DIR/builds/original_sprite-results.txt" "$PROJECT_DIR/builds/practice-results.txt" "$PROJECT_DIR/builds/spell_integrity-results.txt" > "$PROJECT_DIR/builds/test-results.txt"
cp "$PROJECT_DIR/builds/cleanup_2d-results.txt" "$PROJECT_DIR/builds/touch-test-results.txt"
