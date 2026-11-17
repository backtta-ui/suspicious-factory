#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/build_original_sprites.py
python3 tools/build_diagonal_extension.py
python3 tools/build_native_rig_parts.py
python3 tools/build_original_dye_masks.py
