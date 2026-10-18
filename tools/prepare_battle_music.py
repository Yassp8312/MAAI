"""Prepare user-supplied combat scores using fixed gain (preserving dynamics)."""
import argparse, hashlib, json, subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg', required=True)
parser.add_argument('--inputs', nargs=2, required=True)
args = parser.parse_args()
out = Path('art/music')
out.mkdir(parents=True, exist_ok=True)
filters = 'highpass=f=35,equalizer=f=2500:t=o:w=1.5:g=-2'
report = []
for number, filename in enumerate(args.inputs, 2):
    source = Path(filename)
    measured = subprocess.run([args.ffmpeg, '-hide_banner', '-i', str(source), '-vn',
        '-af', filters + ',loudnorm=I=-21:TP=-3:LRA=20:print_format=json',
        '-f', 'null', '-'], capture_output=True, text=True, encoding='utf-8', errors='replace', check=True).stderr
    stats = json.loads(measured[measured.rfind('{'):measured.rfind('}')+1])
    gain = min(-21-float(stats['input_i']), -3-float(stats['input_tp']))
    dest = out/f'battle-{number}.ogg'
    subprocess.run([args.ffmpeg, '-v', 'error', '-y', '-i', str(source), '-map', '0:a:0',
        '-map_metadata', '-1', '-vn', '-af', filters+f',volume={gain:.4f}dB',
        '-ar', '48000', '-c:a', 'libvorbis', '-q:a', '5', str(dest)], check=True)
    report.append({'source': source.name, 'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'output':dest.name,'filter':filters,'fixed_gain_db':round(gain,4), 'filtered_source_measurement':stats})
(out/'battle-preparation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
for item in report:
    print(item['source'], 'gain',item['fixed_gain_db'], 'dB ->',item['output'])
