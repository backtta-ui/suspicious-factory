from pathlib import Path
import subprocess, numpy as np
root=Path(__file__).resolve().parents[1]/'assets/audio'
import sys
if len(sys.argv)!=2: raise SystemExit('usage: prepare_v13_audio.py KENNEY_OGG_DIRECTORY')
src=Path(sys.argv[1])
clips={'grass':('cloth2.ogg','highpass=f=500,lowpass=f=6500'), 'dirt':('footstep04.ogg','lowpass=f=1100'), 'wood':('footstep08.ogg','highpass=f=150,lowpass=f=4500'), 'attack':('knifeSlice.ogg','highpass=f=300'), 'hit':('chop.ogg','lowpass=f=3000'), 'reward':('handleCoins.ogg','highpass=f=500')}
for name,(file,flt) in clips.items():
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(src/file),'-af',flt+',afade=t=out:st=0.25:d=0.10','-t','0.35','-ar','22050','-ac','1',str(root/(name+'.wav'))],check=True)
# Self-authored water foley: filtered deterministic noise splashes, no sine melody.
import wave
rng=np.random.default_rng(1301);rate=22050;t=np.arange(int(rate*.30))/rate
noise=rng.normal(0,1,len(t));sm=np.convolve(noise,np.ones(7)/7,'same')
env=np.exp(-t*18)*(1-np.exp(-t*250))+.23*np.exp(-((t-.09)/.035)**2)
x=sm*env;x=x/(np.max(np.abs(x))+.001)*.42
with wave.open(str(root/'water.wav'),'wb') as f:
 f.setparams((1,2,rate,len(x),'NONE','not compressed'));f.writeframes((x*32767).astype('<i2').tobytes())
