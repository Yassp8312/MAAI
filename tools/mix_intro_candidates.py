"""Prepare reproducible audition mixes. Requires numpy/scipy and a supplied FFmpeg.

Run from the project root with --ffmpeg PATH. Never modifies the source recordings.
"""
import argparse
import json
import subprocess
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg', required=True)
args = parser.parse_args()
RATE, DURATION, LEAD = 48000, 47.2, 0.8
N = int(RATE * DURATION)
OUT = Path('art/reviews/ink-resolve')
OUT.mkdir(parents=True, exist_ok=True)
TMP = Path('tmp/ink-resolve')
TMP.mkdir(parents=True, exist_ok=True)

def decode(path, mono=False):
    raw = subprocess.check_output([args.ffmpeg, '-v', 'error', '-i', str(path),
        '-vn', '-f', 'f32le', '-ac', '1' if mono else '2', '-ar', str(RATE), '-'])
    data = np.frombuffer(raw, dtype=np.float32).reshape(-1, 1 if mono else 2).copy()
    return np.repeat(data, 2, axis=1) if mono else data

def db(value):
    return float(20 * np.log10(max(float(value), 1e-10)))

def rms(data):
    return np.sqrt(np.mean(data.astype(np.float64)**2))

def bands(data):
    frequencies, power = signal.welch(data, fs=RATE, nperseg=4096, axis=0)
    power = power.mean(axis=1)
    total = power.sum()
    return {f'{lo}-{hi} Hz': round(float(power[(frequencies >= lo) & (frequencies < hi)].sum()/total*100), 2)
        for lo, hi in [(20,120),(120,300),(300,900),(900,1800),(1800,4500),(4500,10000),(10000,24000)]}

voice = np.zeros((N, 2), dtype=np.float32)
spoken = decode('art/intro/prologo-es.mp3', mono=True) * 10**(-1/20)
offset = int(LEAD * RATE)
voice[offset:offset+len(spoken)] = spoken

# A speech-controlled envelope: anticipation on each phrase, slow recovery in pauses.
# Spectral carving is confined to the music. Voice timbre is left intact.
hop = int(0.01 * RATE)
blocks = voice.reshape(-1, hop, 2)
voice_rms = np.sqrt(np.mean(blocks**2, axis=(1,2)))
speech_strength = np.clip((20*np.log10(np.maximum(voice_rms,1e-9)) + 43)/19, 0, 1)
speech_strength = np.maximum(speech_strength, np.roll(speech_strength, -1))
smoothed = np.zeros_like(speech_strength)
for i in range(len(smoothed)):
    previous = smoothed[i-1] if i else 0
    tau = 0.035 if speech_strength[i] > previous else 0.42
    coefficient = np.exp(-0.01/tau)
    smoothed[i] = coefficient*previous + (1-coefficient)*speech_strength[i]
t = np.arange(N)/RATE
envelope = np.interp(t, (np.arange(len(smoothed))+.5)*.01, smoothed).astype(np.float32)
voiced = envelope > .65
mid_filter = signal.butter(3, [900,4500], btype='bandpass', fs=RATE, output='sos')
body_filter = signal.butter(2, [80,300], btype='bandpass', fs=RATE, output='sos')
sub_filter = signal.butter(2, 32, btype='highpass', fs=RATE, output='sos')
results = {'voice_bands_percent': bands(spoken), 'duration_seconds': DURATION, 'tracks': []}

for label, filename in [('A','Ink Resolve.mp3'), ('B','Ink Resolve (1).mp3')]:
    source = decode(Path('..')/filename)
    music = source[:N].astype(np.float64)
    if len(music) < N:
        music = np.pad(music, ((0,N-len(music)),(0,0)))
    source_bands = bands(music)
    # Keep the natural opening. Both candidates receive the same reference level.
    gain_db = -26.5 - db(rms(music[:int(43.8*RATE)]))
    music = signal.sosfiltfilt(sub_filter, music, axis=0) * 10**(gain_db/20)
    before = music.copy()
    presence = signal.sosfiltfilt(mid_filter, music, axis=0)
    body = signal.sosfiltfilt(body_filter, music, axis=0)
    music -= presence * (1-10**(-5*envelope[:,None]/20))
    music -= body * (1-10**(-2*envelope[:,None]/20))
    music *= 10**(-1.5*envelope[:,None]/20)
    # Keep the score audible; the final title gets a short lift and a smooth exit.
    music *= (10**(3*np.clip((t-43.5)/1.2,0,1)/20))[:,None]
    music *= np.minimum(1,t/1.0)[:,None]
    end = np.clip((DURATION-t)/2.5,0,1)
    music *= (np.sin(end*np.pi/2)**2)[:,None]
    mixed = voice + music
    assert len(mixed) == N and np.all(np.isfinite(mixed))
    assert np.max(np.abs(music[-100:])) < .0001, 'End fade must reach silence'
    assert np.allclose(mixed-music, voice, atol=1e-7), 'Narration must remain unchanged'
    peak = float(np.max(np.abs(mixed)))
    if peak > .97:
        raise RuntimeError(f'{label}: clipping risk ({db(peak):.2f} dBFS); lower music gain before rendering')
    wavfile.write(TMP/f'mix-{label}.wav', RATE, mixed.astype(np.float32))
    wavfile.write(TMP/f'music-{label}.wav', RATE, music.astype(np.float32))
    post_mid = signal.sosfiltfilt(mid_filter, music, axis=0)
    entry = {'label':label, 'source':filename, 'source_seconds':round(len(source)/RATE,3),
        'excerpt_seconds':[0,DURATION], 'source_bands_percent':source_bands,
        'gain_db':round(gain_db,2), 'mix_peak_dbfs':round(db(peak),2),
        'voice_rms_during_speech_dbfs':round(db(rms(voice[voiced])),2),
        'music_rms_during_speech_dbfs':round(db(rms(music[voiced])),2),
        'presence_reduction_during_speech_db':round(db(rms(post_mid[voiced]))-db(rms(presence[voiced])),2),
        'music_blocks_dbfs':{f'{a}-{b}':round(db(rms(music[int(a*RATE):int(b*RATE)])),2) for a,b in [(0,13),(13,27),(27,36),(36,43.5),(43.5,45)]}}
    results['tracks'].append(entry)
    print(json.dumps(entry, ensure_ascii=False), flush=True)
    # Isolated processed music is saved too, so selecting a candidate doesn't bake in the voice.
    subprocess.run([args.ffmpeg,'-v','error','-y','-i',str(TMP/f'music-{label}.wav'),
        '-c:a','libvorbis','-q:a','6',str(OUT/f'music-{label}.ogg')],check=True)

(OUT/'mix-analysis.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
