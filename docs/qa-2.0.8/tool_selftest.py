import tempfile,subprocess,sys,json,time
from pathlib import Path
root=Path(__file__).resolve().parents[2];cases=[]
with tempfile.TemporaryDirectory() as d:
 p=Path(d);(p/'scripts').mkdir();f=p/'scripts/a.gd';f.write_text('before');snapshot=p/'snapshot.json';base=[sys.executable,str(root/'tools/source_snapshot.py')]
 subprocess.run(base+['capture',str(snapshot),str(p)],check=True)
 ok=subprocess.run(base+['check',str(snapshot),str(p)]).returncode==0;cases.append({'id':'qa-tool-stable','status':'PASS' if ok else 'FAIL','method':'isolated source fixture'})
 f.write_text('after');ok=subprocess.run(base+['check',str(snapshot),str(p)]).returncode!=0;cases.append({'id':'qa-tool-mutation','status':'PASS' if ok else 'FAIL','method':'deliberate fixture change must be rejected'})
 start=time.monotonic();bad=subprocess.run([sys.executable,str(root/'tools/run_godot_checked.py'),str(p/'bad.txt'),sys.executable,'-c','import time; print("SCRIPT ERROR: expected fixture",flush=True); time.sleep(30)']);elapsed=time.monotonic()-start
 ok=bad.returncode!=0 and elapsed<5;cases.append({'id':'qa-tool-error-child','status':'PASS' if ok else 'FAIL','elapsed_seconds':elapsed,'method':'hanging diagnostic child must fail fast'})
(root/'builds/qa-tool-selftest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
assert all(c['status']=='PASS' for c in cases)
print('QA TOOL FIXTURES PASSED')
