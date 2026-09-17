"""Original synthetic giant roar and stone-maul impact. No sampled recordings."""
import numpy as np
from build_ogre_audio import RATE, write

def build():
 rng=np.random.default_rng(2510075)
 t=np.arange(int(RATE*1.28))/RATE
 phase=np.cumsum(93+20*np.sin(t*3.1)-34*t)*2*np.pi/RATE
 voice=np.sin(phase)+.48*np.sin(phase*2.01)+.25*np.sin(phase*3.03)
 grit=np.convolve(rng.normal(0,1,len(t)),np.ones(15)/15,'same')
 envelope=np.minimum(t*9,1)*np.exp(-t*2.2)*(1+.12*np.sin(2*np.pi*t*14))
 write('boss_roar',(voice*.35+grit*.9)*envelope)
 t=np.arange(int(RATE*.94))/RATE
 rumble=np.sin(np.cumsum(42+112*np.exp(-t*13))*2*np.pi/RATE)*np.exp(-t*6)
 grit=rng.normal(0,1,len(t));stone=np.convolve(grit,np.ones(10)/10,'same')
 write('boss_slam',rumble*.44+stone*np.exp(-t*5)*.65+grit*.14*np.exp(-t*29))
if __name__=='__main__':build()
