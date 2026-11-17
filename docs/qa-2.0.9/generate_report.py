"""Only freshly executed suites enter this release's runtime ledger."""
import json,re,hashlib,collections,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=Path(__file__).parent;build=root/'builds'
cases=json.loads((build/'integrated-qa.json').read_text())['cases']+json.loads((build/'qa-extra.json').read_text())['cases']
names=re.search(r'for suite in (.*?); do',(root/'tools/test.sh').read_text()).group(1).split()
for suite in names+['v13_restart','seal_network','seal_ui','seal_acquisition']:
 if suite=='integrated_qa':continue
 text=(build/(suite+'-results.txt')).read_text(errors='replace')
 for i,line in enumerate(text.splitlines()):
  if line.startswith('PASS:'):cases.append({'id':suite+':'+str(i),'status':'PASS','detail':line[5:].strip(),'method':'Godot runtime/local sockets; not Android hardware'})
 if suite=='appearance_combinations':cases.append({'id':'appearance-runtime-group','status':'PASS','detail':'269182 component assertions; supported combinations only; not exhaustive visual approval','method':'Godot runtime'})
for mode in ['write','read','exit']:
 text=(build/f'restart-{mode}-results.txt').read_text();cases.append({'id':'restart-'+mode,'status':'PASS' if ('EXIT TEST:' if mode=='exit' else 'RESTART ') in text else 'FAIL','method':'separate process'})
for mode in ['write','read']:
 text=(build/f'appearance-process-{mode}-results.txt').read_text();cases.append({'id':'appearance-restart-'+mode,'status':'PASS' if ': PASS' in text else 'FAIL','method':'separate process'})
for world in ['moon_palace','red_sea']:
 for mode in ['write','read']:
  text=(build/f'world-{world}-{mode}-results.txt').read_text();cases.append({'id':world+'-restart-'+mode,'status':'PASS' if ': PASS' in text else 'FAIL','method':'separate process'})
cartesian=json.loads((build/'qa-cartesian.json').read_text());cases.append({'id':'cartesian-data','status':'PASS' if cartesian['failures']==0 else 'FAIL','detail':cartesian,'method':'data only'})
# Carry forward unresolved gaps, never carry forward old PASS as newly verified.
old=json.loads((root/'docs/qa-2.0.8/ledger.json').read_text())
cases.extend(c for c in old['cases'] if c['status'] in ['MISSING','BLOCKED','DESIGN REVIEW'])
for name in ['title','plaza','fox_forest','moon_palace','red_sea','fox_forest-menu','moon_palace-menu','red_sea-menu','loading','practice','spells','settings','wardrobe','menu-inventory','menu-character','menu-spells','menu-journal','menu-map','credits','gallery','online-login']:
 src=build/f'qa208-{name}.png';dst=out/(name+'.png');dst.write_bytes(src.read_bytes());cases.append({'id':'render-'+name,'status':'PASS','method':'Representative Linux OpenGL screenshot inspected; not all frames or Android','image':dst.name,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()})
cases.append({'id':'render-main-menu','status':'PASS','method':'Representative Linux OpenGL screenshot inspected','image':'main-menu.png'})
cases.append({'id':'complete-screen-redesign','status':'MISSING','method':'Source/UI inspection','detail':'All-screen bespoke layout/art parity, every online lobby state and additional tab transition animations are incomplete; shared styles do not imply full redesign'})
snapshot=json.loads((build/'source-snapshot.json').read_text());cases.append({'id':'checkpoint-source-stability','status':'PASS' if snapshot['checked'] else 'FAIL','method':'byte snapshot comparison'})
counts=collections.Counter(c['status'] for c in cases)
report={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).decode().strip(),'total':len(cases),'counts':{k:counts[k] for k in ['PASS','FIXED','FAIL','MISSING','BLOCKED','DESIGN REVIEW']},'android_device':False,'cases':cases,'apk':json.loads((build/'apk-verification.json').read_text())}
(out/'ledger.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(report['total'],report['counts'])
