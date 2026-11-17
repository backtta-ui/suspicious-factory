#!/usr/bin/env python3
"""Inventory only: source presence does not imply execution or visual correctness."""
import json,re,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
files=[]
for path in sorted((root/'scripts').rglob('*.gd')):
 text=path.read_text();files.append({'path':str(path.relative_to(root)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'class':re.findall(r'^class_name (\w+)',text,re.M),'methods':re.findall(r'^(?:static )?func (\w+)',text,re.M),'execution_claim':False})
assets={}
for path in (root/'assets').rglob('*'):
 if path.is_file() and path.suffix not in ['.import','.uid']:assets[path.suffix]=assets.get(path.suffix,0)+1
catalog=(root/'scripts/seal/catalog.gd').read_text();spells=re.findall(r'"(\w+)":\{"name":"([^"]+)"',catalog);spells.append(('talisman','부적술'))
report={'method':'Static inventory; not a PASS assertion','script_count':len(files),'files':files,'asset_types':assets,'registered_spells':[{'id':id,'name':name} for id,name in spells],'map_contracts':{'plaza':'safe social hub','fox_forest':'combat adventure','moon_palace':'noncombat glyph exploration','red_sea':'noncombat glyph exploration','offline_practice':'isolated local training','multiplayer':['village','forest']}}
(root/'docs/qa-2.0.8/inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(len(files),'scripts inventoried;',len(spells),'spells; presence is not verification')
