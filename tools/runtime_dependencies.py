#!/usr/bin/env python3
"""Resolve this game's script/scene dependencies, including dynamic literal loads.
Keeps reusable rendering code, not obsolete entry scenes or progression menus.
"""
from pathlib import Path
import re,json
root=Path(__file__).resolve().parents[1]
classes={}
for p in (root/'scripts').rglob('*.gd'):
 m=re.search(r'^class_name\s+(\w+)',p.read_text(),re.M)
 if m:classes[m[1]]=p
seen=set();todo=[root/'scenes/survival.tscn']
while todo:
 p=todo.pop()
 if p in seen:continue
 seen.add(p);source=p.read_text()
 for path in re.findall(r'''res://([^"'\s)]+)''',source):
  target=root/path
  if target.is_file() and target.suffix in ['.gd','.tscn','.gdshader','.tres']:todo.append(target)
 for token in set(re.findall(r'\b[A-Za-z_]\w*\b',source)):
  if token in classes and classes[token]!=p:todo.append(classes[token])
files=sorted(str(p.relative_to(root)) for p in seen)
for forbidden in ['scripts/main.gd','scripts/woo/rpg_state.gd','scripts/woo/adventure.gd','scripts/wardrobe/profile.gd','scripts/wardrobe/screen.gd','scripts/seal/client_ui.gd','scripts/seal/server.gd']:
 if forbidden in files:raise SystemExit('Retired feature dependency: '+forbidden)
(root/'scripts/survival/runtime-files.json').write_text(json.dumps(files,indent=2)+'\n')
preset=root/'export_presets.cfg';s=preset.read_text();filters='assets/*,scripts/survival/runtime-files.json,'+','.join(files)
s=re.sub(r'^include_filter="[^"]*"','include_filter="'+filters+'"',s,flags=re.M);preset.write_text(s)
print('Runtime scripts/scenes:',len(files));print('\n'.join(files))
