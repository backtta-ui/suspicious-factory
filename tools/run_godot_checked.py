#!/usr/bin/env python3
"""Fail on runtime/parse errors even with exit 0; retain live diagnostics on timeout."""
import subprocess,sys,time
from pathlib import Path
log=Path(sys.argv[1]);log.parent.mkdir(parents=True,exist_ok=True)
timed_out=False
with log.open('w',encoding='utf-8') as output:
 process=subprocess.Popen(sys.argv[2:],stdout=output,stderr=subprocess.STDOUT,text=True)
 deadline=time.monotonic()+240
 while process.poll() is None:
  time.sleep(.1)
  diagnostics=log.read_text(encoding='utf-8',errors='replace')
  if any(token in diagnostics for token in ['SCRIPT ERROR:','ERROR:','FAIL:']):
   process.terminate()
   try:process.wait(timeout=2)
   except subprocess.TimeoutExpired:process.kill();process.wait()
   break
  if time.monotonic()>deadline:
   timed_out=True;process.kill();process.wait();output.write('\nFAIL: Godot test timed out\n');break
 returncode=process.returncode
text=log.read_text(encoding='utf-8',errors='replace')
print(text,end='')
failed=timed_out or returncode!=0 or 'SCRIPT ERROR:' in text or 'ERROR:' in text or 'FAIL:' in text
sys.exit(1 if failed else 0)
