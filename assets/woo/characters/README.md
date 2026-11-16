# Directional character sources

Created for this project with image generation from the existing character design.
All original game artwork remains in its previous location.

- `<character>_core.png`: complete clean body/face/native clothing, front/back/left/right; idle, left contact, right contact, tucked jump.
- `<character>_actions.png`: four genuinely different attacks, casting, defensive hurt/landing pose, in the same four directions.
- `hair_front`, `hair_back`, `hats`, `accessories`: corresponding 4-direction interchangeable gear.
- `moon_*`, `night_*`: actual headless clothing animation replacements; the chosen character supplies its own face and head.
- `base_<character>_*`: complete native hair/clothes/headwear assemblies rendered through the gameplay renderer. Native state uses these complete resources directly.

Columns are always front/back/left/right. Source row spacing is not uniform; never divide the original PNG into equal cells. `tools/measure_characters.py` detects complete connected sprites and transparent inter-row valleys, emitting normalized source rectangles, polygons, head and boot anchors. Pose anatomy is calibrated against that character's native idle head before native atlas baking. This is source-density normalization, not jump scaling. The runtime baked cell is always 96 world units, foot (48,84). The world shadow is not baked and remains on the ground during jumps.

Rebuild: install Python Pillow, NumPy, SciPy; run `python3 tools/measure_characters.py`, then run Godot with a rendering display using `--script res://tools/bake_character_bases.gd`; reimport resources. Ordinary Android/CI builds use committed assets/metadata and do not need image-generation services, SciPy, or a display.

Supported animated outfits: basic / moon / night. Other five outfit IDs and ownership records remain intact, but their unavailable directional combinations are disabled. Existing saved unavailable outfits show the selected character's native clothing with an explicit preparation notice in the wardrobe.

Remaining art limits: four directions, two walk contact poses plus neutral, one tucked jump pose, one shared hurt/landing pose; no distinct 8-direction or every jump-phase artwork. Original source art still needs hand-authored pixel cleanup in a few hair/tress and defensive-pose boot edges. Do not describe this as final commercial animation polish.
