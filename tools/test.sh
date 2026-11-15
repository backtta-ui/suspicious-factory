#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Keep test preferences separate from the player's saved outfit.
export XDG_DATA_HOME="${TMPDIR:-/tmp}/suspicious-factory-tests"
"${GODOT_BIN:-godot}" --headless --editor --path "$PROJECT_DIR" --import --quit
"${GODOT_BIN:-godot}" --headless --path "$PROJECT_DIR" --script res://tests/stage1.gd

"${GODOT_BIN:-godot}" --headless --path "$PROJECT_DIR" --script res://tests/touch_ui.gd
