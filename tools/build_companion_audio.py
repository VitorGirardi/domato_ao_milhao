"""Original synthesized purr and two-note human whistle, PCM mono, no downloads."""
import math, random, wave, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SR=32000
def save(name,values):
    peak=max(abs(x) for x in values)
    values=[x*.65/max(peak,.001) for x in values]
    with wave.open(str(ROOT/'assets/audio'/f'{name}.wav'),'wb') as f:
        f.setparams((1,2,SR,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',round(x*32767)) for x in values))
    print(name,len(values)/SR,'seconds',max(abs(x) for x in values))
rng=random.Random(2917);noise=0;values=[]
for i in range(int(SR*3.2)):
    t=i/SR;noise=noise*.88+rng.uniform(-1,1)*.12
    breath=.55+.45*math.sin(math.pi*t/1.1)**2
    pulse=(.5+.5*math.sin(math.tau*26*t))**2
    fade=min(1,t/.18,(3.2-t)/.35)
    values.append(fade*breath*(noise*.7+math.sin(math.tau*104*t)*.11)*pulse)
save('cat_purr',values)
values=[];phase=0
for i in range(int(SR*1.35)):
    t=i/SR;note=t if t<.55 else t-.68
    length=.50 if t<.55 else .60
    active=0<=note<length
    env=max(0,min(1,note/.06,(length-note)/.12)) if active else 0
    freq=(1550+620*min(1,note/.18)) if t<.55 else (2170-600*max(0,note)/.60)
    phase+=math.tau*freq/SR
    values.append(env*(math.sin(phase+.024*math.sin(math.tau*5*t))+.02*rng.uniform(-1,1)))
save('companion_whistle',values)
