"""Recorded farm sound palette. Python/numpy/scipy + ffmpeg; offline, deterministic.

Run after build_audio.py/build_companion_audio.py to replace their legacy synthesis.
Original CC0 recordings and checksums: art/audio/natural/sources.json.
"""
from pathlib import Path
import hashlib, json, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfiltfilt

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/audio/natural'
OUT = ROOT / 'assets/audio'
SR = 32000
REPORT = json.loads((OUT / 'audio_manifest.json').read_text())
SOURCES = {r['id']: r for r in json.loads((SOURCE / 'sources.json').read_text(encoding='utf8'))}
CACHE = {}

def source(ident):
    if ident not in CACHE:
        record = SOURCES[ident]
        path = SOURCE / (ident + Path(record['download']).suffix)
        assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256']
        raw = subprocess.check_output(['ffmpeg', '-nostdin', '-v', 'error', '-i', str(path),
                                       '-f', 'f32le', '-ac', '1', '-ar', str(SR), '-'])
        CACHE[ident] = np.frombuffer(raw, dtype='<f4').astype(float)
    return CACHE[ident]

def cut(ident, start=0, end=None):
    y = source(ident)
    return y[round(start*SR):round(end*SR) if end else len(y)].copy()

def save(name, y, ident, peak=.68, loop=False, stereo=False, highpass=55):
    y = sosfiltfilt(butter(2, highpass, 'highpass', fs=SR, output='sos'), y)
    y -= y.mean()
    if loop:
        # Overlap source tail into the head; equal-gain avoids a loud seam.
        n = min(round(.35*SR), len(y)//8)
        ramp = np.linspace(0, 1, n)
        head = y[-n:]*(1-ramp) + y[:n]*ramp
        y = np.concatenate([head, y[n:-n]])
        # Match the final sample without fading the whole ambience to silence.
        y[-32:] += np.linspace(0, y[0]-y[-1], 32)
    else:
        attack, release = min(64,len(y)//4), min(960,len(y)//4)
        y[:attack] *= np.linspace(0,1,attack)
        y[-release:] *= np.linspace(1,0,release)
    y *= peak / max(np.max(np.abs(y)), 1e-9)
    if stereo: y = np.column_stack([y, np.roll(y, 173)])
    if loop and stereo: y[-1] = y[0]
    pcm = np.round(y*32767).astype('<i2')
    with wave.open(str(OUT / (name+'.wav')), 'wb') as w:
        w.setparams((2 if stereo else 1, 2, SR, 0, 'NONE', 'not compressed'))
        w.writeframes(pcm.tobytes())
    REPORT[name] = dict(seconds=round(len(y)/SR,4), peak=round(float(np.max(np.abs(y))),4),
                        rms=round(float(np.sqrt(np.mean(y*y))),5), loop=loop,
                        channels=2 if stereo else 1, boundary_jump=round(float(np.max(np.abs(y[0]-y[-1]))),6),
                        source='BigSoundBank #'+ident+', '+SOURCES[ident]['author']+', CC0')

def build():
    save('engine_idle',cut('1145',4,12),'1145',loop=True,highpass=35)
    save('engine_load',cut('1146',16,21.6),'1146',loop=True,highpass=35)
    save('pistol_shot',cut('0437',0,1.55),'0437',peak=.76)
    save('pistol_reload',cut('1989'),'1989')
    save('pistol_cock',cut('1987'),'1987')
    save('cow',cut('2386'),'2386',peak=.60)
    for name,a,b in [('chicken',11.45,12.65),('chicken_1',16.1,17.2),('chicken_2',28,29.25)]:
        save(name,cut('0975',a,b),'0975',peak=.55,highpass=180)
    for i,(a,b) in enumerate([(0.12,.79),(.95,1.68),(3.08,3.79),(7.32,8.04)]):
        save('step_'+str(i),cut('0510',a,b),'0510',peak=.57)
    for i,(a,b) in enumerate([(.1,.75),(.95,1.6),(1.65,2.3),(2.55,3.2)]):
        save('grass_'+str(i),cut('0137',a,b),'0137',peak=.48,highpass=110)
    for i,a in enumerate([1.90,2.68,3.46,4.22]):
        save('hoof_'+str(i),cut('0496',a,a+.30),'0496',peak=.60)
    for name,a,b in [('plant',3.35,4.02),('harvest',6.1,6.8)]:
        save(name,cut('0137',a,b),'0137',peak=.50,highpass=110)
    save('build',cut('0005',6.3,6.82),'0005')
    for i,a in enumerate([4.5,5.1,6.3]):
        save('pickaxe_'+str(i),cut('0005',a,a+.48),'0005',peak=.7)
    save('water',cut('1529'),'1529',peak=.58)
    save('cat_purr',cut('0436',1,4.2),'0436',peak=.6,highpass=25)
    for i,(a,b) in enumerate([(0,1.0),(1,2),(2,3.11)]):
        save('bird_'+str(i),cut('1670',a,b),'1670',peak=.36,highpass=600)
    save('wind',cut('0908',10,34),'0908',peak=.35,loop=True,stereo=True,highpass=100)
    save('river',cut('1354',10,27),'1354',peak=.48,loop=True,stereo=True)
    save('waterfall',cut('1354',45,57),'1354',peak=.58,loop=True)
    # Keep the original musical theme, horse recordings, UI and human whistle.
    (OUT/'audio_manifest.json').write_text(json.dumps(REPORT,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('NATURAL_AUDIO_BUILT',len(REPORT))

if __name__ == '__main__': build()
