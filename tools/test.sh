#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p "$PROJECT_DIR/builds"
# 2.0.31: 새로 합성한 효과음(기본 SFX 9종 + 도술 30종)의 클리핑·고주파·스펙트럼 검사.
# numpy/scipy가 없는 환경(일부 CI)에서는 건너뛰고 Godot 쪽 로드 검사로 대신한다.
if python3 -c "import numpy, scipy" >/dev/null 2>&1; then
 python3 "$PROJECT_DIR/tools/verify_v31_audio.py" --json "$PROJECT_DIR/builds/audio-v31.json" > "$PROJECT_DIR/builds/audio-v31-verify.txt"
 tail -n 1 "$PROJECT_DIR/builds/audio-v31-verify.txt"
else
 echo "AUDIO VERIFY SKIPPED: numpy/scipy unavailable" | tee "$PROJECT_DIR/builds/audio-v31-verify.txt"
fi
# Current 2.5D scope only. Retired RPG/voting/wardrobe UI tests live in backup history.
for suite in cleanup_2d character_codex survival_v13 survival_bots_v13 seowon_ingame lobby_hub room_ui_v20 original_sprite practice spell_integrity playfeel_v20 v28_skills v30_skills_audit skill_sound_v31 minimap_touch; do
 XDG_DATA_HOME="${TMPDIR:-/tmp}/dosa-current-$suite" python3 "$PROJECT_DIR/tools/run_godot_checked.py" "$PROJECT_DIR/builds/$suite-results.txt" "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "res://tests/$suite.gd"
done
cat "$PROJECT_DIR/builds/cleanup_2d-results.txt" "$PROJECT_DIR/builds/character_codex-results.txt" "$PROJECT_DIR/builds/survival_v13-results.txt" "$PROJECT_DIR/builds/survival_bots_v13-results.txt" "$PROJECT_DIR/builds/seowon_ingame-results.txt" "$PROJECT_DIR/builds/lobby_hub-results.txt" "$PROJECT_DIR/builds/room_ui_v20-results.txt" "$PROJECT_DIR/builds/original_sprite-results.txt" "$PROJECT_DIR/builds/practice-results.txt" "$PROJECT_DIR/builds/spell_integrity-results.txt" "$PROJECT_DIR/builds/playfeel_v20-results.txt" "$PROJECT_DIR/builds/v28_skills-results.txt" "$PROJECT_DIR/builds/v30_skills_audit-results.txt" "$PROJECT_DIR/builds/skill_sound_v31-results.txt" "$PROJECT_DIR/builds/minimap_touch-results.txt" > "$PROJECT_DIR/builds/test-results.txt"
cp "$PROJECT_DIR/builds/cleanup_2d-results.txt" "$PROJECT_DIR/builds/touch-test-results.txt"
