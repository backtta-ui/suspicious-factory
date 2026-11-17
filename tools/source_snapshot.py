#!/usr/bin/env python3
"""Bind a checkpoint to stable game/test/tool bytes; generated UIDs and reports excluded."""
import hashlib,json,sys,subprocess,datetime
from pathlib import Path
root=Path(__file__).resolve().parents[1]
mode,target=sys.argv[1:3];target=Path(target)
if len(sys.argv)>3:root=Path(sys.argv[3])
files=[]
for directory in ['scripts','scenes','assets','tests','tools']:
 if (root/directory).exists():files.extend(p for p in (root/directory).rglob('*') if p.is_file() and p.suffix!='.uid')
files.extend(root/name for name in ['project.godot','export_presets.cfg'] if (root/name).exists())
current={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
if mode=='capture':
 try:head=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],stderr=subprocess.DEVNULL).decode().strip()
 except subprocess.CalledProcessError:head='fixture'
 target.write_text(json.dumps({'head':head,'files':current,'checked':False},indent=2)+'\n');print('SOURCE SNAPSHOT captured',len(current),'files')
elif mode=='check':
 recorded=json.loads(target.read_text());changed=[p for p in set(current)|set(recorded['files']) if current.get(p)!=recorded['files'].get(p)]
 if changed:raise SystemExit('SOURCE SNAPSHOT MISMATCH: '+', '.join(sorted(changed)))
 recorded['checked']=True;target.write_text(json.dumps(recorded,indent=2)+'\n');print('SOURCE SNAPSHOT stable',len(current),'files')
else:raise SystemExit('Use capture or check')
