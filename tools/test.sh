#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p "$PROJECT_DIR/builds"
# Each suite has separate preferences; process-restart suite deliberately shares one.
for suite in woo_core touch_ui save_recovery sound_performance plaza_v11 npc_title_v12 rpg_v13 v13_ai v13_touch action_v14 touch_v14 explore_v14 hero_v20 seal_rules; do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-$suite" \
    python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/$suite-results.txt" \
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "res://tests/$suite.gd"
done
XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-v13_ai" \
  python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/v13_restart-results.txt" \
  "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/v13_restart.gd

python3 "$PROJECT_DIR/tools/test_seal_network.py"
python3 "$PROJECT_DIR/tools/test_seal_network.py" --ui-only

for mode in write read exit; do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-restart" \
    python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/restart-$mode-results.txt" \
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/restart.gd -- "--mode=$mode"
done

cat "$PROJECT_DIR/builds/hero_v20-results.txt" "$PROJECT_DIR/builds/seal_rules-results.txt" "$PROJECT_DIR/builds/seal_network-results.txt" "$PROJECT_DIR/builds/seal_ui-results.txt" "$PROJECT_DIR/builds/explore_v14-results.txt" "$PROJECT_DIR/builds/touch_v14-results.txt" "$PROJECT_DIR/builds/action_v14-results.txt" "$PROJECT_DIR/builds/v13_touch-results.txt" "$PROJECT_DIR/builds/v13_ai-results.txt" "$PROJECT_DIR/builds/v13_restart-results.txt" "$PROJECT_DIR/builds/rpg_v13-results.txt" "$PROJECT_DIR/builds/npc_title_v12-results.txt" "$PROJECT_DIR/builds/plaza_v11-results.txt" "$PROJECT_DIR/builds/sound_performance-results.txt" "$PROJECT_DIR/builds/woo_core-results.txt" "$PROJECT_DIR/builds/save_recovery-results.txt" "$PROJECT_DIR/builds/restart-write-results.txt" "$PROJECT_DIR/builds/restart-read-results.txt" "$PROJECT_DIR/builds/restart-exit-results.txt" > "$PROJECT_DIR/builds/test-results.txt"
cp "$PROJECT_DIR/builds/touch_ui-results.txt" "$PROJECT_DIR/builds/touch-test-results.txt"
