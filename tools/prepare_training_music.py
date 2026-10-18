"""Create a dojo variation from Jorge's existing Ink Duel, preserving the source."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg', required=True)
parser.add_argument('--input', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = Path(args.input)
destination = root / 'art/music/training.ogg'
review = root / 'art/reviews/training-music'
review.mkdir(parents=True, exist_ok=True)
# Keep pitch: atempo changes duration independently of tuning. No stem separation.
filters = ('atrim=start=12:end=96,asetpts=PTS-STARTPTS,atempo=0.94,'
           'highpass=f=55,bass=g=-2.5:f=130:w=0.7,'
           'equalizer=f=2400:t=o:w=1.4:g=-2,treble=g=-2:f=5000,'
           'aecho=0.9:0.95:59|113:0.045|0.025')

def measure(path, chain):
    result = subprocess.run([args.ffmpeg, '-hide_banner', '-i', str(path), '-vn',
        '-af', chain + ',loudnorm=I=-22:TP=-3:LRA=20:print_format=json',
        '-f', 'null', '-'], capture_output=True, text=True, encoding='utf-8',
        errors='replace', check=True).stderr
    return json.loads(result[result.rfind('{'):result.rfind('}') + 1])

stats = measure(source, filters)
gain = min(-22 - float(stats['input_i']), -3 - float(stats['input_tp']))
subprocess.run([args.ffmpeg, '-v', 'error', '-y', '-i', str(source), '-map', '0:a:0',
    '-vn', '-map_metadata', '-1', '-af', filters + f',volume={gain:.4f}dB',
    '-ar', '48000', '-c:a', 'libvorbis', '-q:a', '5', str(destination)], check=True)
final_stats = measure(destination, 'anull')
# Review the transition as the game does: overlap the last/first three seconds.
subprocess.run([args.ffmpeg, '-v', 'error', '-y', '-i', str(destination),
    '-i', str(destination), '-filter_complex',
    '[0:a]atrim=start=77,asetpts=PTS-STARTPTS[a];'
    '[1:a]atrim=end=18,asetpts=PTS-STARTPTS[b];'
    '[a][b]acrossfade=d=3:c1=tri:c2=tri,afade=t=in:d=0.3[out]',
    '-map', '[out]', '-c:a', 'libmp3lame', '-q:a', '2',
    str(review / 'MAAI-entrenamiento-bucle.mp3')], check=True)
subprocess.run([args.ffmpeg, '-v', 'error', '-y', '-i', str(destination),
    '-t', '35', '-af', 'afade=t=in:d=1.4,afade=t=out:st=32:d=3',
    '-c:a', 'libmp3lame', '-q:a', '2', str(review / 'MAAI-Ink-Duel-Dojo.mp3')], check=True)
report = {
    'title': 'Ink Duel · Dojo', 'source': source.name,
    'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'source_segment_seconds': [12, 96], 'tempo_factor': 0.94, 'pitch_changed': False,
    'stem_separation': False, 'filters': filters, 'fixed_gain_db': round(gain, 4),
    'output': destination.name,
    'output_sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
    'source_after_processing_measurement': stats,
    'final_encoded_measurement': final_stats,
    'note': 'Only loudnorm input_* fields describe measured audio. Its normalized output is discarded.'
}
(destination.parent / 'training-preparation.json').write_text(
    json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps({'gain_db': gain, 'final_lufs': final_stats['input_i'],
    'final_true_peak_dbtp': final_stats['input_tp'], 'output': str(destination)}))
