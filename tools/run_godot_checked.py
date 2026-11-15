#!/usr/bin/env python3
"""Godot can exit 0 on script errors: treat runtime/parse errors as failures too."""
import subprocess,sys
from pathlib import Path
log=Path(sys.argv[1]); log.parent.mkdir(parents=True,exist_ok=True)
try:
 result=subprocess.run(sys.argv[2:],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=240)
 output=result.stdout
 log.write_text(output,encoding='utf-8')
 print(output,end='')
 failed=result.returncode!=0 or 'SCRIPT ERROR:' in output or 'ERROR:' in output or 'FAIL:' in output
 sys.exit(1 if failed else 0)
except subprocess.TimeoutExpired as error:
 output=error.stdout or b''
 if isinstance(output,bytes):output=output.decode(errors='replace')
 log.write_text(output+'\nFAIL: test timed out\n',encoding='utf-8')
 print('FAIL: Godot test timed out',file=sys.stderr)
 sys.exit(1)
