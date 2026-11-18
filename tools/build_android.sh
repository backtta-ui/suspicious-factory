#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
: "${GODOT_ANDROID_TEMPLATE:?Set this to Godot 4.6.3 android_debug.apk export template}"
: "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK directory}"
BUILD_TOOLS_DIR="${ANDROID_BUILD_TOOLS_DIR:-$ANDROID_HOME/build-tools/36.0.0}"
APK_VERSION="$(python3 - "$PROJECT_DIR/project.godot" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
match = re.search(r'^config/version="([0-9]+\.[0-9]+\.[0-9]+)"$', text, re.M)
if not match:
    raise SystemExit('project.godot must contain a semantic config/version')
print(match.group(1))
PY
)"
APK_PATH="$PROJECT_DIR/builds/jeon-woochi-$APK_VERSION.apk"
mkdir -p "$PROJECT_DIR/builds"
# A failed new build must not be confused with an earlier APK or success report.
rm -f "$PROJECT_DIR/builds/apk-verification.json" "$PROJECT_DIR/builds/apk-verification.txt"
python3 "$PROJECT_DIR/tools/runtime_dependencies.py" > "$PROJECT_DIR/builds/runtime-dependencies.txt"
python3 "$PROJECT_DIR/tools/prepare_android_template.py" "$GODOT_ANDROID_TEMPLATE"
"$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --import --quit
python3 "$PROJECT_DIR/tools/source_snapshot.py" capture "$PROJECT_DIR/builds/source-snapshot.json"
# Mandatory native touch, gameplay, saving and real process-restart checks.
bash "$PROJECT_DIR/tools/test.sh"
python3 "$PROJECT_DIR/tools/source_snapshot.py" check "$PROJECT_DIR/builds/source-snapshot.json"
bash "$PROJECT_DIR/tools/check_runtime_pack.sh"
# Export to a temporary directory; preserve the last working APK on failure.
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/builds/.android-export.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-debug 'Android Test' "$STAGING_DIR/game.apk"
python3 "$PROJECT_DIR/tools/verify_apk.py" "$STAGING_DIR/game.apk" \
  --build-tools "$BUILD_TOOLS_DIR" --output-dir "$STAGING_DIR"
python3 - "$PROJECT_DIR" "$APK_VERSION" <<'PY'
import configparser, sys
from pathlib import Path
cfg = configparser.ConfigParser()
cfg.read(Path(sys.argv[1]) / 'export_presets.cfg')
if cfg['preset.0.options']['version/name'].strip('"') != sys.argv[2]:
    raise SystemExit('Version mismatch: update export_presets.cfg to match project.godot')
PY
python3 "$PROJECT_DIR/tools/source_snapshot.py" check "$PROJECT_DIR/builds/source-snapshot.json"
mv "$STAGING_DIR/game.apk" "$APK_PATH"
if [[ -f "$STAGING_DIR/game.apk.idsig" ]]; then
  mv "$STAGING_DIR/game.apk.idsig" "$APK_PATH.idsig"
else
  rm -f "$APK_PATH.idsig"
fi
# Regenerate reports with the exact final file path and filename.
python3 "$PROJECT_DIR/tools/verify_apk.py" "$APK_PATH" \
  --build-tools "$BUILD_TOOLS_DIR" --output-dir "$PROJECT_DIR/builds"
chmod 644 "$APK_PATH"
printf 'BUILD AND VERIFICATION PASSED: %s\n' "$APK_PATH"
