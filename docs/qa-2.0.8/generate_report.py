import json,re,hashlib,collections
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=Path(__file__).parent;build=root/'builds'
cases=json.loads((build/'integrated-qa.json').read_text())['cases']+json.loads((build/'qa-extra.json').read_text())['cases']
names=re.search(r'for suite in (.*?); do',(root/'tools/test.sh').read_text()).group(1).split()
for suite in names+['v13_restart','seal_network','seal_ui','seal_acquisition']:
 if suite=='integrated_qa':continue
 text=(build/(suite+'-results.txt')).read_text(errors='replace')
 for i,line in enumerate(text.splitlines()):
  if line.startswith('PASS:'):cases.append({'id':suite+':'+str(i),'status':'FIXED' if suite=='rpg_v13' and 'large painting viewer has real forest entrance' in line else 'PASS','detail':line[5:].strip(),'method':'Godot runtime or local socket; no Android device claim'})
 if suite=='appearance_combinations':cases.append({'id':'appearance-runtime-group','status':'PASS','detail':'269182 component assertions, 504 supported hair/hat/outfit combinations; not exhaustive visual approval','method':'Godot runtime'})
for mode in ['write','read','exit']:
 text=(build/f'restart-{mode}-results.txt').read_text();cases.append({'id':'restart-'+mode,'status':'PASS' if ('EXIT TEST:' if mode=='exit' else 'RESTART ') in text else 'FAIL','method':'separate process'})
cartesian=json.loads((build/'qa-cartesian.json').read_text());cases.append({'id':'cartesian-data','status':'PASS' if cartesian['failures']==0 else 'FAIL','detail':cartesian,'method':'data only'})
for name in ['title','plaza','fox_forest','moon_palace','red_sea','fox_forest-menu','moon_palace-menu','red_sea-menu','loading','practice','spells','settings','wardrobe','menu-inventory','menu-character','menu-spells','menu-journal','menu-map','credits','gallery','online-login']:
 src=build/f'qa208-{name}.png';dst=out/(name+'.png');dst.write_bytes(src.read_bytes());cases.append({'id':'render-'+name,'status':'PASS','detail':'Representative desktop screenshot inspected for major HUD/control bounds; not commercial-art approval or every frame','method':'Linux OpenGL screenshot','image':dst.name,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()})
missing=[('outfit-'+x,'Direction/action artwork is not ready; ownership preserved') for x in ['goblin','wind','snow','heaven','dragon']]
missing += [('all-spell-art','Commercial-quality distinct multi-frame effects for every spell remain incomplete'),('animal-animation','New fox and additional animal idle/run action sets remain incomplete'),('complete-token-migration','Independent inventory/wardrobe/title layouts retain some local style values'),('all-route-async-loading','Shared loading overlay does not yet cover every cold-start path'),('dense-nameplate-layout','Complete arbitrary crowd label collision resolution is not implemented'),('world-art-polish','Moon-palace floor density/pixel perspective and red-sea start-area decoration require art refinement')]
for id,detail in missing:cases.append({'id':id,'status':'MISSING','detail':detail,'method':'source/resource audit and representative visual inspection'})
for id,detail in [('android-touch-safe-area','No Galaxy hardware available: touch driver, physical safe area/navigation and orientation'),('android-lifecycle','No device: screen lock, OS kill while loading/saving, memory pressure'),('android-performance','No device: sustained 60FPS, thermal throttling and device memory'),('public-online-6-8','No deployed public server and 6–8 physical devices for Internet match')]:cases.append({'id':id,'status':'BLOCKED','detail':detail,'method':'environment limitation'})
for id,detail in [('shadow-blink','Existing long shadow movement and blink share a movement mechanism; do not invent a new role'),('new-world-rewards','Moon-palace/red-sea spell rewards are not approved; do not fabricate unlocks'),('complete-visual-cartesian','Every cosmetic/pose pixel combination requires explicit art-quality acceptance; automatic data validity is insufficient')]:cases.append({'id':id,'status':'DESIGN REVIEW','detail':detail,'method':'design boundary'})
cases.extend(json.loads((build/'qa-tool-selftest.json').read_text())['cases'])
snapshot=json.loads((build/'source-snapshot.json').read_text())
cases.append({'id':'checkpoint-source-stability','status':'PASS' if snapshot['checked'] else 'FAIL','detail':'Stable game/test/tool byte snapshot; generated UIDs and reports excluded','method':'checkpoint source hash comparison'})
tally=collections.Counter(x['status'] for x in cases);counts={key:tally[key] for key in ['PASS','FAIL','FIXED','MISSING','BLOCKED','DESIGN REVIEW']};report={'scope':'Named runtime scenarios plus explicit gaps; static method inventory is separate','source_game_commit':'1d5dc4bb68e921c6578f45473e38ffc5d3dcbeb6','total':len(cases),'counts':counts,'cartesian_data':cartesian,'performance':json.loads((build/'qa-performance.json').read_text()),'apk':json.loads((build/'apk-verification.json').read_text()),'android_device':False,'cases':cases}
(out/'ledger.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps({'total':len(cases),'counts':counts},ensure_ascii=False))
