"""Original bodywork impact: damped chassis thump and brief metal rattle.
No recordings or third-party source. Deterministic mono PCM, no looping.
"""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SR = 32000
t = np.arange(round(.58*SR))/SR
rng = np.random.default_rng(8102026)
noise = rng.normal(0,1,len(t))
spectrum = np.fft.rfft(noise)
freq = np.fft.rfftfreq(len(t),1/SR)
spectrum *= np.exp(-(freq/3600)**2)*np.minimum(freq/180,1)
noise = np.fft.irfft(spectrum,len(t))
noise /= np.std(noise)
y = .62*np.sin(2*np.pi*(73*t-13*t*t))*np.exp(-t*19)
y += .22*np.sin(2*np.pi*147*t)*np.exp(-t*25)
y += .11*np.sin(2*np.pi*311*t)*np.exp(-t*31)
y += .12*noise*np.exp(-t*38)
for onset, strength in [(.055,.09),(.106,.065),(.174,.04)]:
    age=np.maximum(0,t-onset)
    y += strength*noise*np.exp(-age*40)*(t>=onset)
y -= y.mean()
y *= np.minimum(t/.0025,1)*np.minimum((t[-1]-t)/.025,1)
y *= .74/np.max(np.abs(y))
out=ROOT/'assets/audio/pickup_impact.wav'
with wave.open(str(out),'wb') as stream:
    stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(SR)
    stream.writeframes(np.round(y*32767).astype('<i2').tobytes())
report={'seconds':len(t)/SR,'peak':float(np.max(np.abs(y))),
        'rms':float(np.sqrt(np.mean(y*y))),
        'tail_rms':float(np.sqrt(np.mean(y[-3200:]**2))),
        'source':'Original deterministic synthesis: tools/build_pickup_impact.py'}
(ROOT/'art/source/pickup_impact.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
manifest_path=ROOT/'assets/audio/audio_manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf8'))
manifest['pickup_impact']={**report,'loop':False,'channels':1,'boundary_jump':0.0}
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print('PICKUP_IMPACT_SOURCE_OK',report)
