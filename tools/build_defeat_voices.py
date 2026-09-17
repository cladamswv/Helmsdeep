"""Original, nonverbal cartoon defeat voices made with source/filter synthesis.

Three human oofs, three rough orc exhalations and three deep ogre grunts.
No sampled actor, speech model, external recording or third-party sound asset.
Offline dependencies: numpy/scipy. The game loads short mono PCM WAVs.
"""
from pathlib import Path
import json, wave
import numpy as np
from scipy.signal import lfilter, butter, sosfilt

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'project/assets/audio/voices'
RATE=24000

def resonance(source, frequency, bandwidth):
    radius=np.exp(-np.pi*bandwidth/RATE)
    return lfilter([1-radius], [1,-2*radius*np.cos(2*np.pi*frequency/RATE),radius*radius],source)

def grunt(kind, variant):
    rng=np.random.default_rng(9401+variant+{'human':0,'orc':20,'ogre':40}[kind])
    duration={'human':.44,'orc':.48,'ogre':.58}[kind]+variant*.025
    t=np.arange(round(duration*RATE))/RATE;u=t/duration
    start={'human':198,'orc':151,'ogre':118}[kind]+variant*9
    pitch=start*(.86-.28*u)+np.sin(t*39)*2.1+rng.normal(0,.7,len(t))
    phase=np.cumsum(pitch)/RATE
    # Asymmetric glottal opening/closure, with air in the exhalation.
    cycle=phase%1
    glottis=np.where(cycle<.42,np.sin(np.pi*cycle/.42)**2,
                     np.where(cycle<.68,.18*np.sin(np.pi*(cycle-.42)/.26)**2,0.))
    source=np.concatenate([[0.],np.diff(glottis)])
    source += rng.normal(0,.012 if kind=='human' else .025,len(t))
    if kind!='human':source *= .76+.24*np.sin(phase*np.pi)
    # UH -> OO: two parallel vocal-tract filters crossfade as the mouth closes.
    formants=([580,1320,2750],[420,960,2480]) if kind=='human' else ([590,1230,2570],[465,920,2250])
    if kind=='ogre':formants=([510,1170,2460],[400,910,2060])
    vowels=[]
    for bank in formants:
        filtered=sum(resonance(source,f,b)*amp for f,b,amp in zip(bank,[90,125,180],[1,1.05,.55]))
        vowels.append(filtered)
    closing=np.clip((u-.06)/.48,0,1)
    voice=vowels[0]*(1-closing)+vowels[1]*closing
    envelope=(1-np.exp(-t*130))*np.exp(-u*1.25)*np.clip((.88-u)/.20,0,1)
    voice *= envelope
    breath=sosfilt(butter(2,[1300,4600],fs=RATE,btype='bandpass',output='sos'),rng.normal(0,1,len(t)))
    breath*=np.exp(-((u-.77)/.11)**2)*(.012 if kind=='human' else .007)
    result=voice+breath
    # Remove inaudible rumble, then compress the body of the vocal rather than
    # normalizing a lone transient. Higher formants carry on phone speakers.
    result=sosfilt(butter(2,170,fs=RATE,btype='highpass',output='sos'),result)
    result-=np.mean(result)
    result=np.tanh(result/max(.000001,float(np.sqrt(np.mean(result**2))))*.47)
    result*=.88/max(.001,float(np.max(np.abs(result))))
    fade=240;result[:fade]*=np.linspace(0,1,fade);result[-fade:]*=np.linspace(1,0,fade)
    return result

def build():
    OUT.mkdir(parents=True,exist_ok=True);report=[]
    for kind in ['human','orc','ogre']:
        for i in range(3):
            samples=grunt(kind,i);name=f'{kind}_defeat_{i+1}.wav'
            with wave.open(str(OUT/name),'wb') as file:
                file.setnchannels(1);file.setsampwidth(2);file.setframerate(RATE)
                file.writeframes(np.rint(samples*32767).astype('<i2').tobytes())
            report.append({'file':name,'seconds':len(samples)/RATE,
                           'peak':round(float(np.abs(samples).max()),4),
                           'rms':round(float(np.sqrt(np.mean(samples**2))),4)})
    (ROOT/'docs/defeat-voice-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Authored nine short voiced exhalations:',sum((OUT/r['file']).stat().st_size for r in report),'bytes')

if __name__=='__main__':build()
