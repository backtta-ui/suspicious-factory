#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p "$PROJECT_DIR/builds"
# Each suite has separate preferences; process-restart suite deliberately shares one.
for suite in painting_worlds woo_core touch_ui save_recovery sound_performance plaza_v11 npc_title_v12 rpg_v13 v13_ai v13_touch action_v14 touch_v14 explore_v14 hero_v20 seal_rules wardrobe server_rewards seal_latest seal_tickets appearance_combinations practice practice_touch practice_return; do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-$suite" \
    python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/$suite-results.txt" \
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "res://tests/$suite.gd"
done
XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-v13_ai" \
  python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/v13_restart-results.txt" \
  "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/v13_restart.gd

python3 "$PROJECT_DIR/tools/test_seal_network.py"
python3 "$PROJECT_DIR/tools/test_seal_network.py" --ui-only
python3 "$PROJECT_DIR/tools/test_seal_network.py" --study-only

for mode in write read exit; do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-test-restart" \
    python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/restart-$mode-results.txt" \
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/restart.gd -- "--mode=$mode"
done

for mode in write read; do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/jeon-woochi-appearance-restart" \
    python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/appearance-process-$mode-results.txt" \
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/appearance_restart.gd -- "--mode=$mode"
done

cat "$PROJECT_DIR/builds/painting_worlds-results.txt" "$PROJECT_DIR/builds/practice_return-results.txt" "$PROJECT_DIR/builds/practice_touch-results.txt" "$PROJECT_DIR/builds/practice-results.txt" "$PROJECT_DIR/builds/appearance-process-write-results.txt" "$PROJECT_DIR/builds/appearance-process-read-results.txt" "$PROJECT_DIR/builds/appearance_combinations-results.txt" "$PROJECT_DIR/builds/seal_latest-results.txt" "$PROJECT_DIR/builds/seal_tickets-results.txt" "$PROJECT_DIR/builds/seal_acquisition-results.txt" "$PROJECT_DIR/builds/server_rewards-results.txt" "$PROJECT_DIR/builds/wardrobe-results.txt" "$PROJECT_DIR/builds/hero_v20-results.txt" "$PROJECT_DIR/builds/seal_rules-results.txt" "$PROJECT_DIR/builds/seal_network-results.txt" "$PROJECT_DIR/builds/seal_ui-results.txt" "$PROJECT_DIR/builds/explore_v14-results.txt" "$PROJECT_DIR/builds/touch_v14-results.txt" "$PROJECT_DIR/builds/action_v14-results.txt" "$PROJECT_DIR/builds/v13_touch-results.txt" "$PROJECT_DIR/builds/v13_ai-results.txt" "$PROJECT_DIR/builds/v13_restart-results.txt" "$PROJECT_DIR/builds/rpg_v13-results.txt" "$PROJECT_DIR/builds/npc_title_v12-results.txt" "$PROJECT_DIR/builds/plaza_v11-results.txt" "$PROJECT_DIR/builds/sound_performance-results.txt" "$PROJECT_DIR/builds/woo_core-results.txt" "$PROJECT_DIR/builds/save_recovery-results.txt" "$PROJECT_DIR/builds/restart-write-results.txt" "$PROJECT_DIR/builds/restart-read-results.txt" "$PROJECT_DIR/builds/restart-exit-results.txt" > "$PROJECT_DIR/builds/test-results.txt"
cp "$PROJECT_DIR/builds/touch_ui-results.txt" "$PROJECT_DIR/builds/touch-test-results.txt"

for world in moon_palace red_sea
do
 for mode in write read
 do
  XDG_DATA_HOME="${TMPDIR:-/tmp}/dosa-world-restart-$world" python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/world-$world-$mode-results.txt" "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/worlds_restart.gd -- "--mode=$mode-$world"
 done
done
cat "$PROJECT_DIR/builds/world-moon_palace-write-results.txt" "$PROJECT_DIR/builds/world-moon_palace-read-results.txt" "$PROJECT_DIR/builds/world-red_sea-write-results.txt" "$PROJECT_DIR/builds/world-red_sea-read-results.txt" >> "$PROJECT_DIR/builds/test-results.txt"
