"""Make separate metallic deflection cues from the project's retained CC0 sources.
No new downloads. NumPy/SciPy and FFmpeg are required. Run from the project root.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg', required=True)
args = parser.parse_args()
root = Path('art/audio/combat')
rate = 48000
records = {}
sources = {}

def layer(name, duration, speed=1, gain=1, cutoff=200):
    path = root / 'sources' / name
    sources[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    raw = subprocess.check_output([args.ffmpeg, '-v', 'error', '-i', str(path),
                                   '-f', 'f32le', '-ac', '1', '-ar', str(rate), '-'])
    data = np.frombuffer(raw, dtype=np.float32).copy()
    energy = np.convolve(data ** 2, np.ones(240) / 240, mode='same')
    active = np.flatnonzero(energy > max(1e-7, energy.max() * .002))
    if not len(active):
        raise ValueError(f'Silent source: {name}')
    data = data[max(0, active[0] - 96):]
    data = signal.resample(data, max(2, int(len(data) / speed)))
    data = signal.sosfilt(signal.butter(2, cutoff, 'highpass', fs=rate, output='sos'), data)
    data = data[:int(duration * rate)]
    data /= max(.001, np.max(np.abs(data)))
    fade = min(1200, len(data) // 4)
    data[-fade:] *= np.linspace(1, 0, fade)
    data[:48] *= np.linspace(0, 1, 48)
    return data * gain

for character, speed, duration in [('tsukiyo', 1.08, .40), ('ren', .92, .49),
                                   ('daichi', .84, .44), ('nao', 1.28, .25), ('sayo', 1.14, .30)]:
    for variant in range(3):
        used = []
        def add(name, length, pitch=1, gain=1, cutoff=200):
            used.append(name)
            return layer(name, length, pitch, gain, cutoff)
        sword = f'starninjas-sword/sword.{variant + (6 if character in ("ren", "daichi") else 1)}.ogg'
        layers = [add(sword, duration, speed, 1, 500),
                  add('kenney-rpg/metalClick.ogg', .12, speed, .32, 1200)]
        if character == 'daichi':
            layers.append(add(f'kenney-impact/impactWood_light_{variant:03}.ogg', .18, .9, .35))
        elif character == 'sayo':
            layers.append(add(f'kenney-rpg/bookFlip{variant + 1}.ogg', .15, 1.3, .17, 1000))
        elif character == 'nao':
            layers.append(add('kenney-rpg/knifeSlice2.ogg', .10, 1.2, .18, 1800))
        mixed = np.zeros(max(map(len, layers)))
        for data in layers:
            mixed[:len(data)] += data
        mixed *= 10 ** (-9 / 20) / np.max(np.abs(mixed))
        assert np.isfinite(mixed).all() and np.max(np.abs(mixed)) < 1
        out = root / character / f'parry-{variant}.wav'
        wavfile.write(out, rate, (mixed * 32767).astype(np.int16))
        records[str(out.relative_to(root)).replace('\\', '/')] = {
            'sources': used, 'peak_dbfs': -9, 'seconds': len(mixed) / rate,
            'sha256': hashlib.sha256(out.read_bytes()).hexdigest()}
(root / 'parry-manifest.json').write_text(json.dumps({'files': records, 'source_sha256': sources}, indent=2), encoding='utf-8')
print(f'Prepared {len(records)} distinct deflection cues from retained CC0 sources.')
