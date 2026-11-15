#!/usr/bin/env python3
"""Fail on runtime/parse errors even with exit 0; retain live diagnostics on timeout."""
import subprocess,sys
from pathlib import Path
log=Path(sys.argv[1]);log.parent.mkdir(parents=True,exist_ok=True)
timed_out=False
with log.open('w',encoding='utf-8') as output:
 process=subprocess.Popen(sys.argv[2:],stdout=output,stderr=subprocess.STDOUT,text=True)
 try:
  returncode=process.wait(timeout=240)
 except subprocess.TimeoutExpired:
  timed_out=True;process.kill();process.wait();returncode=1
  output.write('\nFAIL: Godot test timed out\n')
text=log.read_text(encoding='utf-8',errors='replace')
print(text,end='')
failed=timed_out or returncode!=0 or 'SCRIPT ERROR:' in text or 'ERROR:' in text or 'FAIL:' in text
sys.exit(1 if failed else 0)
