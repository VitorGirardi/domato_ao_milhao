"""Original deterministic farm score and sound design. Requires Python + NumPy.

Music and synthesized effects are original. Horse calls use bundled CC0 recordings. PCM WAVs
are deliberately kept as source assets so the Godot importer handles platforms.
"""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'
OUT.mkdir(parents=True, exist_ok=True)
SR = 32000
RNG = np.random.default_rng(27092026)
REPORT = {}


def noise(seconds, cutoff=2500):
    n = int(seconds * SR)
    spectrum = np.fft.rfft(RNG.normal(0, 1, n))
    f = np.fft.rfftfreq(n, 1 / SR)
    spectrum *= np.exp(-(f / cutoff) ** 2) * np.minimum(f / 80, 1)
    signal = np.fft.irfft(spectrum, n)
    return signal / max(np.std(signal), 1e-8)


def envelope(n, attack=.008, release=.06):
    e = np.ones(n)
    a, r = min(n // 2, int(attack * SR)), min(n // 2, int(release * SR))
    if a: e[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if r: e[-r:] = np.sin(np.linspace(np.pi / 2, 0, r)) ** 2
    return e


def note(midi, seconds, instrument='guitar'):
    t = np.arange(int(seconds * SR)) / SR
    f = 440 * 2 ** ((midi - 69) / 12)
    if instrument == 'flute':
        phase = 2 * np.pi * f * t + .024 * np.sin(2 * np.pi * 4.7 * t)
        y = np.sin(phase) + .14 * np.sin(phase * 2) + .035 * np.sin(phase * 3)
        y += noise(seconds, 4000) * .018
        y *= envelope(len(t), .07, .14) * (.84 + .16 * np.sin(np.pi * t / seconds))
    else:
        y = np.zeros_like(t)
        for h in range(1, 9 if instrument == 'guitar' else 5):
            # Nylon string harmonics lose high frequencies faster than the fundamental.
            y += np.sin(2 * np.pi * f * h * t + h * .16) * np.exp(-t * (1.7 + h * .85)) / h ** 1.7
        y *= envelope(len(t), .003, .035)
        if instrument == 'bass': y *= 1.2
    return y


def save(name, samples, peak=.7, loop=False):
    y = np.asarray(samples, dtype=np.float64)
    y -= np.mean(y, axis=0)
    maximum = np.max(np.abs(y))
    if maximum > 0: y *= peak / maximum
    if not loop: y *= envelope(len(y), .003, .018)[:, None] if y.ndim == 2 else envelope(len(y), .003, .018)
    assert np.all(np.isfinite(y)) and np.max(np.abs(y)) < 1
    pcm = np.round(y * 32767).astype('<i2')
    with wave.open(str(OUT / (name + '.wav')), 'wb') as w:
        w.setnchannels(2 if y.ndim == 2 else 1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    REPORT[name] = {'seconds': round(len(y)/SR, 3), 'peak': round(float(np.max(np.abs(y))), 4), 'rms': round(float(np.sqrt(np.mean(y*y))), 4), 'loop': loop, 'boundary_jump': round(float(np.max(np.abs(y[0]-y[-1]))), 5)}


def score():
    # "Manhã no Vale": original 32-bar pastoral theme, C major, 80 BPM, 4/4.
    beat = .75
    length = int(32 * 4 * beat * SR)
    mix = np.zeros((length, 2))
    def add(y, at, gain, pan=0):
        indices = (np.arange(len(y)) + int(at * SR)) % length
        mix[indices, 0] += y * gain * np.sqrt((1-pan)/2)
        mix[indices, 1] += y * gain * np.sqrt((1+pan)/2)
    chords = [(48, [60,64,67,71]), (43,[59,62,67,69]), (45,[60,64,69,71]), (41,[57,60,65,67]),
              (50,[57,62,65,69]), (43,[59,62,67,69]), (48,[60,64,67,72]), (43,[59,62,65,67])]
    # Explicit melodic phrases; rests leave room for play and environmental sounds.
    phrases = [ [(0,76,1), (1.5,79,.5), (2,74,1.3)],
                [(0,74,.7), (1,71,.7), (2.5,67,1)],
                [(0,72,1.2), (2,76,.7), (3,74,.6)],
                [(0,72,2.4)],
                [(0,69,.7), (1.5,74,1), (3,77,.6)],
                [(0,76,1), (1.5,74,.6), (2.5,71,1)],
                [(0,72,2.7)], [] ]
    for bar in range(32):
        root, chord = chords[bar % 8]
        start = bar * 4 * beat
        for offset in (0, 2): add(note(root, 1.3, 'bass'), start+offset*beat, .16, -.04)
        for k, index in enumerate([0,2,1,2,0,3,1,2]):
            add(note(chord[index], 1.8), start+(k*.5+.012*(k%2))*beat, .105 if k%2==0 else .075, -.35)
        if 4 <= bar < 28:
            for offset, midi, duration in phrases[bar % 8]:
                # Second statement with a quiet octave response, not a constant lead.
                pitch = midi - (12 if 16 <= bar < 20 else 0)
                add(note(pitch, duration*beat, 'flute'), start+offset*beat+.025, .065, .28)
        if 8 <= bar < 28:
            for offset in (1,3):
                brush = noise(.11, 6500) * np.exp(-np.arange(int(.11*SR))/SR*45)
                add(brush, start+offset*beat, .006, .4)
    # Short, circular reflections preserve the musical tail at the loop boundary.
    dry = mix.copy()
    for delay, gain in [(.113,.12),(.227,.08),(.389,.045)]:
        mix += np.roll(dry[:, ::-1], int(delay*SR), axis=0)*gain
    # A few milliseconds of circular seam smoothing, no artificial gap in music.
    for channel in range(2):
        seam = (mix[-1,channel]+mix[0,channel])/2
        n=160; ramp=np.linspace(0,1,n)
        mix[:n,channel]=seam*(1-ramp)+mix[:n,channel]*ramp
        mix[-n:,channel]=mix[-n:,channel]*(1-ramp)+seam*ramp
    save('manha_no_vale', mix, .56, True)


def effects():
    for i in range(4):
        t=np.arange(int(.19*SR))/SR
        y=noise(.19,1400+i*160)*np.exp(-t*26)*.5 + np.sin(2*np.pi*(105+i*9)*t)*np.exp(-t*40)*.2
        save('step_%d'%i,y,.43)
        t=np.arange(int(.20*SR))/SR
        y=np.sin(2*np.pi*(180+i*18)*t)*np.exp(-t*38)+noise(.2,2100)*np.exp(-t*65)*.36
        y+=np.sin(2*np.pi*430*t)*np.exp(-t*65)*.25
        save('hoof_%d'%i,y,.56)
    for name, tones in [('harvest',[72,76,79]),('build',[55,62]),('plant',[60,64]),('ui_confirm',[76,79]),('ui_back',[72])]:
        out=np.zeros(int(.65*SR))
        for i,tone in enumerate(tones):
            y=note(tone,.38);at=int(i*.075*SR);out[at:at+len(y)]+=y
        save(name,out,.52 if name!='ui_back' else .36)
    t=np.arange(int(.85*SR))/SR
    water=noise(.85,5500)*(.45+.2*np.sin(2*np.pi*13*t))*np.sin(np.pi*t/.85)**1.2
    save('water',water,.58)
    t=np.arange(int(.12*SR))/SR
    save('ui_tick',np.sin(2*np.pi*1050*t)*np.exp(-t*65),.28)
    for i in range(3):
        dur=.65+i*.1;t=np.arange(int(dur*SR))/SR
        gate=np.maximum(0,np.sin(2*np.pi*(3+i)*t))**3
        freq=2200+500*np.sin(t*17+i)+300*t
        chirp=np.sin(2*np.pi*np.cumsum(freq)/SR)*gate
        save('bird_%d'%i,chirp,.36)
    t=np.arange(int(1.1*SR))/SR
    f=330+65*np.sin(2*np.pi*6*t)*np.exp(-t*2)
    y=(np.sin(2*np.pi*np.cumsum(f)/SR)+.35*np.sin(4*np.pi*np.cumsum(f)/SR))
    y*=np.maximum(0,np.sin(2*np.pi*3.5*t))**3*np.exp(-t*1.5)
    save('chicken',y,.5)
    t=np.arange(int(1.8*SR))/SR
    f=105+22*np.sin(np.pi*t/1.8);phase=2*np.pi*np.cumsum(f)/SR
    y=sum(np.sin(phase*h)*np.exp(-((h-4)/3)**2)/h for h in range(1,13))
    y*=np.sin(np.pi*t/1.8)**2
    save('cow',y,.6)
    t=np.arange(int(.65*SR))/SR
    save('horse_snort',noise(.65,1700)*np.sin(np.pi*t/.65)**2*(.6+.4*np.sin(t*52)),.55)
    # Circular filtered noise, slow periodic amplitude makes the bed seamless.
    seconds=24;t=np.arange(int(seconds*SR))/SR
    left=noise(seconds,1350);right=noise(seconds,1400)
    wind=np.column_stack([left,right])*(.7+.13*np.sin(2*np.pi*t/seconds))[:,None]
    save('wind',wind,.35,True)
    seconds=16;t=np.arange(int(seconds*SR))/SR
    river=np.column_stack([noise(seconds,4800),noise(seconds,4400)])
    river*= (.8+.09*np.sin(2*np.pi*t/seconds)+.05*np.sin(2*np.pi*t*3/seconds))[:,None]
    save('river',river,.48,True)


def recording(number):
    """Decode the bundled CC0, mono 24-bit field recording without network access."""
    with wave.open(str(ROOT / 'art/audio' / f'{number}.wav'), 'rb') as stream:
        assert stream.getsampwidth() == 3 and stream.getnchannels() == 1
        rate = stream.getframerate()
        raw = np.frombuffer(stream.readframes(stream.getnframes()), dtype=np.uint8).reshape(-1, 3).astype(np.int32)
    pcm = raw[:, 0] | raw[:, 1] << 8 | raw[:, 2] << 16
    pcm = np.where(pcm & 0x800000, pcm - 0x1000000, pcm) / 8388608.0
    pcm -= np.mean(pcm)
    # Windowed sinc low-pass before resampling prevents aliasing at 32 kHz.
    taps = np.arange(-64, 65)
    cutoff = 14000 / rate
    kernel = 2 * cutoff * np.sinc(2 * cutoff * taps) * np.hamming(len(taps))
    pcm = np.convolve(pcm, kernel / kernel.sum(), mode='same')
    return np.interp(np.arange(int(len(pcm) * SR / rate)) * rate / SR, np.arange(len(pcm)), pcm)


def horse_calls():
    # Natural pitch and breath: no oscillator/formant approximation of the voice.
    save('horse_neigh', recording(1541), .55)
    breath = recording(1543)
    save('horse_sprint', breath, .46)
    save('horse_snort', breath, .40)
    for name, number in [('horse_neigh', 1541), ('horse_sprint', 1543), ('horse_snort', 1543)]:
        REPORT[name]['source'] = f'BigSoundBank #{number}, Joseph SARDIN, CC0'


if __name__=='__main__':
    score();effects();horse_calls()
    (OUT/'audio_manifest.json').write_text(json.dumps(REPORT,indent=2),encoding='utf-8')
    print('AUDIO_ASSETS_OK:',len(REPORT),'assets;',round(sum(v['seconds'] for v in REPORT.values()),1),'seconds')
