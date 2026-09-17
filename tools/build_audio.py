"""Original synthesized first-pass audio, no samples."""
import math, random, struct, wave, pathlib
r=random.Random(17);root=pathlib.Path(__file__).resolve().parents[1]/'project/assets/audio'
for name,duration,freq in [('hit',.12,210),('bow',.18,900),('gate',.35,80),('collapse',1.1,45),('coin',.18,1100),('horn',1.2,196),('victory',1.5,392),('defeat',1.2,147)]:
 samples=[];rate=22050
 for i in range(int(rate*duration)):
  t=i/rate;env=min(1,t/.015)*max(0,1-t/duration)**1.6
  f=freq*(1 if name in ['horn','victory','defeat'] else 1-.4*t/duration)
  if name=='victory':f*= [1,1.25,1.5,2][min(3,int(t/duration*4))]
  tonal=sum(math.sin(2*math.pi*f*k*t)/k**1.5 for k in range(1,5))*.4
  noise=r.uniform(-1,1)*(.65 if name in ['hit','gate','collapse','bow'] else .035)
  samples.append(int(max(-1,min(1,(tonal+noise)*env*.55))*32767))
 with wave.open(str(root/(name+'.wav')),'wb') as w:w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
