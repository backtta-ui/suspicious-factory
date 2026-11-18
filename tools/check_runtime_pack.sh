#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
PACK_PATH="$(mktemp "$PROJECT_DIR/builds/.runtime-pack.XXXXXX.zip")"
trap 'rm -f "$PACK_PATH"' EXIT
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-pack 'Android Test' "$PACK_PATH" > "$PROJECT_DIR/builds/runtime-pack-export.log" 2>&1
(
 cd /tmp
 XDG_DATA_HOME="${TMPDIR:-/tmp}/dosa-packaged-smoke" python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/runtime-pack-smoke.txt" "$GODOT_BIN" --headless --main-pack "$PACK_PATH" --script "$PROJECT_DIR/tests/pack_smoke.gd"
)
