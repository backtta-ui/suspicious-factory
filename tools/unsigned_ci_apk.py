#!/usr/bin/env python3
"""Remove CI-only signatures before private signing in the existing Cloud workspace.
The temporary CI key is never used for an installable public artifact.
"""
from pathlib import Path
import zipfile,json,hashlib,re,sys
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]/'builds'
report=json.loads((root/'apk-verification.json').read_text())
if report['status']!='passed':raise SystemExit('CI staging build did not pass verification')
source=Path(report['apk']);target=root/(source.stem+'.unsigned.apk')
with zipfile.ZipFile(source) as src,zipfile.ZipFile(target,'w') as out:
 for item in src.infolist():
  if re.match(r'^META-INF/(MANIFEST\.MF|[^/]+\.(SF|RSA|DSA|EC))$',item.filename,re.I):continue
  # Rebuilding the ZIP also drops the v2/v3 APK Signing Block outside ZIP entries.
  out.writestr(item,src.read(item.filename))
with zipfile.ZipFile(target) as out:
 if out.testzip() is not None:raise SystemExit('Unsigned intermediate ZIP corrupt')
(root/'ci-staging-verification.json').write_text(json.dumps(report,indent=2))
unsigned={'status':'unsigned_intermediate_not_for_installation','version':report['version'],'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'filename':target.name,'final_signing':'Existing persistent Cloud key; no repository secret needed for unsigned compilation'}
(root/'unsigned-build.json').write_text(json.dumps(unsigned,indent=2))
source.unlink();source.with_suffix('.apk.idsig').unlink(missing_ok=True)
(root/'apk-verification.json').unlink();(root/'apk-verification.txt').unlink(missing_ok=True);(root/'SHA256SUMS.txt').unlink(missing_ok=True)
print(json.dumps(unsigned,indent=2))
