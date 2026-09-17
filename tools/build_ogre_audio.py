"""Original synthesized ember-cast and compact fire-impact effects."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]/'project/assets/audio'
RATE=24000
def write(name,samples):
 samples=np.tanh(samples)
 samples*=.58/max(.58,float(np.max(np.abs(samples))))
 samples[:120]*=np.linspace(0,1,120);samples[-300:]*=np.linspace(1,0,300)
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
  f.writeframes((samples*32767).astype('<i2').tobytes())
def build():
 rng=np.random.default_rng(31825)
 t=np.arange(int(RATE*.58))/RATE
 noise=rng.normal(0,1,len(t));soft=np.convolve(noise,np.ones(9)/9,'same')
 phase=np.cumsum(470-320*t/.58)*2*np.pi/RATE
 whoosh=soft*.48*np.sin(np.pi*t/.58)**1.6+np.sin(phase)*.11*np.exp(-t*5)
 write('fire_cast',whoosh)
 t=np.arange(int(RATE*.66))/RATE
 noise=rng.normal(0,1,len(t));soft=np.convolve(noise,np.ones(18)/18,'same')
 phase=np.cumsum(140*np.exp(-t*8)+47)*2*np.pi/RATE
 impact=np.sin(phase)*.30*np.exp(-t*9)+soft*.70*np.exp(-t*5)
 crackle=noise*np.maximum(0,np.sin(t*93))**10*.10*np.exp(-t*6)
 write('fire_impact',impact+crackle)
if __name__=='__main__':build()
