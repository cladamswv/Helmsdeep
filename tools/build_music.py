"""The Valley Watch: original 80-second, 6/8 modal instrumental for Castlehold.

Written melody and arrangement, synthesized lute/dulcimer/recorder/drums.
No samples, downloaded compositions or runtime synthesis dependencies.
Authoring dependencies: NumPy, SciPy and ffmpeg (Vorbis/MP3 encoding).
"""
from pathlib import Path
import json, math, subprocess, tempfile, wave
import numpy as np
from scipy.signal import butter, sosfilt

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'project/assets/audio/music'
SR=44100
EIGHTH=5/12
BARS=32
LENGTH=BARS*6*EIGHTH
COUNT=round(LENGTH*SR)
mix=np.zeros((COUNT,2),dtype=np.float64)
rng=np.random.default_rng(2718)

def frequency(note):return 440*2**((note-69)/12)

def add(samples,start,gain,pan):
    start=round(start*SR)%COUNT
    stereo=samples[:,None]*gain*np.array([math.cos((pan+1)*math.pi/4),math.sin((pan+1)*math.pi/4)])
    # Fold releases into the next repetition, keeping the encoded loop continuous.
    while len(stereo):
        n=min(len(stereo),COUNT-start);mix[start:start+n]+=stereo[:n];stereo=stereo[n:];start=0

def pluck(note,duration=2.4,bright=False):
    t=np.arange(round(duration*SR))/SR;f=frequency(note);result=np.zeros(len(t))
    for k in range(1,15 if bright else 11):
        damping=(1.0+.35*k) if bright else (1.5+.52*k)
        amp=(math.sin(k*.24*math.pi)**2+.08)/k**(1.3 if bright else 1.65)
        partial=f*k*math.sqrt(1+(.00012 if bright else .00003)*k*k)
        result+=amp*np.sin(2*math.pi*partial*t)*np.exp(-t*damping)
        if bright:result+=amp*.12*np.sin(2*math.pi*partial*1.0018*t)*np.exp(-t*damping)
    result*=np.minimum(1,t/.0025)
    result+=sosfilt(butter(2,1800,fs=SR,output='sos'),rng.normal(0,.025,len(t)))*np.exp(-t*110)
    result*=np.minimum(1,np.maximum(0,duration-t)/.06)
    return result

def recorder(note,duration,soft=False):
    release=.12;t=np.arange(round((duration+release)*SR))/SR;f=frequency(note)
    vib=np.sin(2*math.pi*4.7*t)*np.minimum(1,t/.27)*.003
    phase=2*math.pi*f*np.cumsum(1+vib)/SR
    tone=np.sin(phase)+.25*np.sin(2*phase)+.095*np.sin(3*phase)+.075*np.sin(4*phase)
    air=sosfilt(butter(2,[900,2600],btype='bandpass',fs=SR,output='sos'),rng.normal(0,1,len(t)))*.026
    env=np.minimum(1,t/.07)**1.4*np.clip((duration+release-t)/release,0,1)
    env*=.90+.06*np.sin(2*math.pi*2.1*t)
    return (tone+air)*env*(.78 if soft else 1)

def bowed(note,duration):
    t=np.arange(round((duration+.30)*SR))/SR;f=frequency(note);result=np.zeros(len(t))
    for k in range(1,7):
        result+=np.sin(2*math.pi*f*k*t+.018*np.sin(2*math.pi*3.1*t))/k**2.0
    env=np.minimum(1,t/.19)*np.clip((duration+.3-t)/.40,0,1)
    return result*env

def drum(accent):
    t=np.arange(round(.45*SR))/SR
    phase=2*math.pi*(78*t+30*(1-np.exp(-t*32))/32)
    tone=np.sin(phase)*np.exp(-t*11)+.25*np.sin(phase*1.51)*np.exp(-t*22)
    skin=sosfilt(butter(2,1800,fs=SR,output='sos'),rng.normal(0,.4,len(t)))*np.exp(-t*36)
    return (tone+skin)*np.minimum(1,t/.002)*(1.0 if accent else .55)

def shaker():
    t=np.arange(round(.15*SR))/SR
    n=sosfilt(butter(2,[4500,9500],btype='bandpass',fs=SR,output='sos'),rng.normal(0,1,len(t)))
    return n*np.minimum(1,t/.003)*np.exp(-t*38)

# D Dorian: open fifths, modal cadences and a restrained dance pulse.
chords={
    'd':(38,[50,57,62,65,69]),'c':(36,[48,55,60,64,67]),
    'g':(43,[50,55,59,62,67]),'a':(45,[52,57,60,64,69]),
    'f':(41,[48,53,57,60,65])}
progression=list('ddcgd cad'.replace(' ',''))+list('fcgadcgd')
progression*=2
# Each phrase totals six eighth-note beats. A written tune, not random pitches.
melody=[
 [(74,2),(77,1),(76,1),(74,2)],[(69,1),(72,1),(74,3),(76,1)],
 [(76,2),(79,1),(76,1),(74,1),(72,1)],[(71,2),(74,2),(79,2)],
 [(77,1),(76,1),(74,2),(69,2)],[(72,2),(76,1),(74,1),(72,2)],
 [(69,2),(72,1),(71,1),(69,2)],[(74,4),(None,2)],
 [(77,2),(81,1),(79,1),(77,2)],[(76,1),(79,1),(76,2),(72,2)],
 [(74,2),(79,1),(77,1),(74,2)],[(76,2),(72,2),(69,2)],
 [(74,1),(76,1),(77,2),(76,1),(74,1)],[(72,2),(76,2),(79,2)],
 [(79,1),(77,1),(74,2),(71,2)],[(74,4),(None,2)],
]
assert len(progression)==32 and all(sum(n[1] for n in row)==6 for row in melody)
for bar,chord in enumerate(progression):
    base=bar*6*EIGHTH;bass,notes=chords[chord]
    add(bowed(bass,6*EIGHTH),base,.042,0)
    add(bowed(notes[1],6*EIGHTH),base,.016,-.18)
    for beat,index in enumerate([0,2,3,1,2,4]):
        timing=base+beat*EIGHTH+(.010 if beat%3 else 0)
        add(pluck(notes[index]),timing,.15*(1 if beat%3==0 else .78),-.34)
    if bar>=8:
        for beat,index in [(0,3),(2,4),(3,2),(5,3)]:
            add(pluck(notes[index]+12,2.8,True),base+beat*EIGHTH+.022,.041 if bar<24 else .055,.37)
    cursor=base
    for note,beats in melody[bar%16]:
        duration=beats*EIGHTH*.91
        if note is not None:
            # Middle section drops an octave; the closing phrase returns gently.
            pitch=note-12 if 16<=bar<24 else note
            add(recorder(pitch,duration,bar<4),cursor+.018,.085,.09)
        cursor+=beats*EIGHTH
    for beat in [0,3]:add(drum(beat==0),base+beat*EIGHTH,.062 if bar<8 else .080,-.08)
    if bar>=4:
        for beat in [2,5]:add(shaker(),base+beat*EIGHTH,.015,.48)

# Small stone-hall reflections, circular so releases survive the loop boundary.
dry=mix.copy()
for delay,gain in [(.079,.10),(.147,.08),(.231,.075),(.379,.055),(.487,.045),(.713,.032),(.970,.019)]:
    mix+=np.roll(dry,round(delay*SR),axis=0)[:,::-1]*gain
mix-=mix.mean(axis=0)
# Leave the music behind the original combat mix at the 35% default setting.
mix*=.79*10**(-5.2/20)/np.max(np.abs(mix))
# Bridge the circular seam over four milliseconds on each side, below a beat.
seam=round(.004*SR)
bridge=np.linspace(mix[-seam],mix[seam],seam*2,endpoint=False)
mix[-seam:]=bridge[:seam];mix[:seam]=bridge[seam:]
OUT.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    wav=Path(tmp)/'valley-watch.wav'
    with wave.open(str(wav),'wb') as out:
        out.setparams((2,2,SR,0,'NONE','not compressed'));out.writeframes((mix*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','4','-metadata','title=The Valley Watch','-metadata','artist=Castlehold Original Soundtrack',str(OUT/'valley_watch.ogg')],check=True)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libmp3lame','-b:a','160k','-metadata','title=The Valley Watch',str(ROOT.parent/'Castlehold-Medieval-Music.mp3')],check=True)
report={'title':'The Valley Watch','seconds':LENGTH,'time_signature':'6/8','quarter_note_bpm':72,'sample_rate':SR,'channels':2,'peak_dbfs':float(20*np.log10(np.abs(mix).max())),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(mix**2)))),'loop_seam_step':float(np.max(np.abs(mix[-1]-mix[0]))),'source':'Original written score and original synthesis; no external samples.'}
(ROOT/'docs/music-render-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
