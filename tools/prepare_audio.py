#!/usr/bin/env python3
"""Prepare licensed audio from downloaded upstream originals; never runs on a phone.
Usage: python3 tools/prepare_audio.py /path/to/audio-v11
Sources and attribution: assets/audio/NOTICE.txt.
"""
from pathlib import Path
import sys,subprocess,wave,numpy as np,json,hashlib
source=Path(sys.argv[1]);target=Path(__file__).resolve().parents[1]/'assets/audio'
def convert(inp,out,filters,duration=None):
 cmd=['ffmpeg','-v','error','-y','-i',str(inp),'-af',filters,'-ar','32000','-ac','1']
 if duration:cmd+=['-t',str(duration)]
 subprocess.run(cmd+[str(target/out)],check=True)
kenney=source/'kenney/OGG'
base='silenceremove=start_periods=1:start_threshold=-45dB,highpass=f=90,lowpass=f=6000'
convert(kenney/'cloth4.ogg','button.wav',base+',volume=0.65,afade=t=out:st=0.12:d=0.06',.18)
convert(kenney/'bookFlip2.ogg','dialogue.wav',base+',volume=0.5,afade=t=out:st=0.23:d=0.09',.32)
for i,name in enumerate(['step','step2','step3']):
 convert(kenney/f'footstep0{i+1}.ogg',name+'.wav',base+',volume=0.7,afade=t=out:st=0.18:d=0.06',.24)
convert(kenney/'metalPot2.ogg','jar_step.wav',base+',lowpass=f=1800,volume=0.24,afade=t=out:st=0.14:d=0.08',.22)
# Recorded cloth swish + softly ringing Korean bell, no synthesized beeps.
subprocess.run(['ffmpeg','-v','error','-y','-i',str(kenney/'cloth1.ogg'),'-i',str(source/'bell-source'),'-filter_complex','[0:a]atrim=0:0.65,highpass=f=100,volume=0.7[a];[1:a]silenceremove=start_periods=1:start_threshold=-40dB,atrim=0:0.85,highpass=f=500,lowpass=f=6000,volume=0.35,afade=t=out:st=0.35:d=0.5[b];[a][b]amix=inputs=2:normalize=0,alimiter=limit=0.75,afade=t=out:st=0.7:d=0.15','-ar','32000','-ac','1','-t','0.85',str(target/'spell.wav')],check=True)
subprocess.run(['ffmpeg','-v','error','-y','-i',str(source/'gugak131.mp3'),'-ar','32000','-ac','2',str(source/'music-decoded.wav')],check=True)
with wave.open(str(source/'music-decoded.wav')) as w:
 samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float32).reshape(-1,2)/32768
n=32000*3;fade=np.linspace(0,1,n)[:,None]
loop=np.concatenate([samples[n:-n],samples[-n:]*(1-fade)+samples[:n]*fade])
loop=np.clip(loop*.84,-.97,.97)
with wave.open(str(source/'music-loop.wav'),'wb') as w:
 w.setparams((2,2,32000,0,'NONE',''));w.writeframes((loop*32767).astype('<i2').tobytes())
subprocess.run(['ffmpeg','-v','error','-y','-i',str(source/'music-loop.wav'),'-c:a','libvorbis','-q:a','4',str(target/'moonlit_plaza.ogg')],check=True)
# Match quiet foley to the mix, with a strict peak ceiling (no clipping).
for path in target.glob('*.wav'):
 with wave.open(str(path)) as w:
  params=w.getparams();values=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float64)/32768
 rms=float(np.sqrt(np.mean(values*values)));peak=float(np.max(np.abs(values)))
 desired=10**((-25 if path.stem in ['button','dialogue','jar_step'] else -23)/20)
 gain=min(desired/max(rms,1e-8),.85/max(peak,1e-8))
 with wave.open(str(path),'wb') as w:
  w.setparams(params);w.writeframes((values*gain*32767).astype('<i2').tobytes())
manifest={p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in target.glob('*') if p.suffix in ['.ogg','.wav']}
(target/'provenance.json').write_text(json.dumps(manifest,indent=2))
print('Prepared sampled SFX and Korean BGM loop')
