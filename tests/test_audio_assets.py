"""Validate original WAV sources; Python standard library only."""
from array import array
from pathlib import Path
import json
import math
import sys
import wave

folder = Path(__file__).resolve().parents[1] / 'assets/audio'
manifest = json.loads((folder / 'audio_manifest.json').read_text())
assert len(manifest) == 24
for name, metadata in manifest.items():
    with wave.open(str(folder / f'{name}.wav')) as stream:
        assert stream.getsampwidth() == 2 and stream.getframerate() == 32000
        channels = stream.getnchannels()
        assert channels == (2 if metadata['loop'] else 1)
        samples = array('h', stream.readframes(stream.getnframes()))
        if sys.byteorder != 'little': samples.byteswap()
    peak = max(abs(value) for value in samples) / 32768
    rms = math.sqrt(sum(value * value for value in samples) / len(samples)) / 32768
    assert 0.002 < rms < 0.3 and peak < 0.8, name
    if not metadata['loop']: assert samples[0] == samples[-1] == 0, name
    if name == 'manha_no_vale':
        assert len(samples) == 96 * 32000 * 2
        assert samples[:2] == samples[-2:], 'Musical loop must meet continuously'
print('AUDIO_SIGNAL_OK: 24 original files, bounded peaks/RMS, faded effects and seamless musical loop')
