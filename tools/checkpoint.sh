#!/usr/bin/env bash
# Required completion gate after each major gameplay change.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Reuse the already configured Cloud toolchain when present; no credentials in source.
if [[ -d /workspace/toolchain/android-sdk ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-/workspace/toolchain/android-sdk}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/toolchain/data}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/toolchain/config}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/toolchain/cache}"
  export GODOT_ANDROID_TEMPLATE="${GODOT_ANDROID_TEMPLATE:-/workspace/toolchain/data/godot/export_templates/4.6.3.stable/android_debug.apk}"
fi
mkdir -p "$PROJECT_DIR/builds"
# Pipefail preserves the failure status while recording the output.
bash "$PROJECT_DIR/tools/build_android.sh" 2>&1 | tee "$PROJECT_DIR/builds/android-build.log"
