"""Build MAAI's character-specific mono SFX from downloaded CC0 recordings.
Requires numpy, scipy and FFmpeg; sources are retained with per-file provenance.
"""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path
import numpy as np
from scipy import signal
from scipy.io import wavfile

parser = argparse.ArgumentParser()
parser.add_argument('--ffmpeg', required=True)
args = parser.parse_args()
ROOT = Path('tmp/sfx-sources')
OUT = Path('art/audio/combat')
OUT.mkdir(parents=True, exist_ok=True)
RATE = 48000
cache, used, manifest = {}, {}, {}

def source(pack, name):
    paths = [p for p in (ROOT/pack).rglob(name) if not p.name.startswith('._')]
    if len(paths) != 1: raise ValueError((pack, name, paths))
    path = paths[0]
    key = f'{pack}/{name}'
    if key not in cache:
        raw = subprocess.check_output([args.ffmpeg, '-v','error','-i',str(path),'-vn','-f','f32le','-ac','1','-ar',str(RATE),'-'])
        data = np.frombuffer(raw,dtype=np.float32).copy()
        data -= data.mean()
        # Trim quiet margins before any layering; preserve a short attack lead-in.
        energy = np.convolve(data**2,np.ones(240)/240,mode='same')
        active = np.flatnonzero(energy > max(1e-7,float(energy.max())*.0015))
        if not len(active): raise ValueError(f'Silent source: {key}')
        data = data[max(0,active[0]-144):min(len(data),active[-1]+480)]
        data /= max(.001,np.max(np.abs(data)))
        cache[key] = data
        target = OUT/'sources'/pack/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(path,target)
        used[key] = {'file':str(target.relative_to(OUT)).replace('\\','/'), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    return key,cache[key].copy()

K='kenney-impact'; R='kenney-rpg'; V='vehicle-apparel'; W='artisticdude-swishes'; S='starninjas-sword'
current_sources=[]
def layer(pack,name,length,level=1,speed=1,hp=70,lp=10000):
    key,data=source(pack,name)
    current_sources.append(key)
    if speed != 1:
        data=signal.resample(data, max(2,int(len(data)/speed)))
    data=signal.sosfilt(signal.butter(2,hp,btype='highpass',fs=RATE,output='sos'),data)
    data=signal.sosfilt(signal.butter(2,lp,btype='lowpass',fs=RATE,output='sos'),data)
    data=data[:int(length*RATE)]
    if len(data)>100:
        fade=min(len(data)//3,960)
        data[-fade:]*=np.linspace(1,0,fade)
        data[:96]*=np.linspace(0,1,96)
    return data*level

def combine(*layers):
    result=np.zeros(max(len(x) for x in layers))
    for x in layers: result[:len(x)] += x
    return result

def delayed(data,seconds):
    return np.pad(data,(int(seconds*RATE),0))

def save(character,kind,index,data,peak):
    path=OUT/character/f'{kind}-{index}.wav'
    path.parent.mkdir(exist_ok=True)
    data=data/max(.001,np.max(np.abs(data)))*10**(peak/20)
    assert np.all(np.isfinite(data)) and np.max(np.abs(data))<1
    wavfile.write(path,RATE,(data*32767).astype(np.int16))
    manifest[str(path.relative_to(OUT)).replace('\\','/')]= {'sources':sorted(set(current_sources)), 'peak_dbfs':peak, 'seconds':round(len(data)/RATE,4)}
    current_sources.clear()

profiles={
 'tsukiyo':{'foot':-18,'weapon':-13,'weight':.9,'cloth':'cloth1.ogg','stone':0,'speed':1.08},
 'ren':{'foot':-15,'weapon':-12,'weight':1.1,'cloth':'clothBelt.ogg','stone':2,'speed':.94},
 'daichi':{'foot':-12,'weapon':-11,'weight':1.35,'cloth':'beltHandle1.ogg','stone':4,'speed':.83},
 'nao':{'foot':-22,'weapon':-16,'weight':.7,'cloth':'cloth2.ogg','stone':1,'speed':1.22},
 'sayo':{'foot':-19,'weapon':-15,'weight':.85,'cloth':'cloth4.ogg','stone':3,'speed':1.03},
}
for character,p in profiles.items():
    for i in range(3):
        step=layer(K,f"footstep_concrete_{(p['stone']+i)%5:03}.ogg",.24*p['weight'],speed=p['speed'],lp=3800 if character in ['tsukiyo','nao','sayo'] else 6500)
        fabric=layer(R,p['cloth'],.22,.13)
        extras=np.zeros(1)
        if character=='ren': extras=layer(V,f'boots-leather-step-{i+1:02}.wav',.25,.35)
        if character=='daichi': extras=layer(K,f'impactSoft_heavy_{i:03}.ogg',.2,.4,speed=.9,lp=1300)
        if character=='nao': extras=layer(K,f'footstep_carpet_{i:03}.ogg',.13,.45,lp=2300)
        if character=='sayo': extras=layer(V,f'arrow-feathers-{i+1:02}.wav',.17,.15,lp=4200)
        step_mix=combine(step,fabric,extras)
        step_sources=list(current_sources)
        save(character,'step',i,step_mix,p['foot'])
        current_sources.extend(step_sources)
        landing=combine(step_mix,layer(K,f'impactSoft_medium_{i:03}.ogg',.25,.32*p['weight'],lp=2300))
        save(character,'land',i,landing,p['foot']+3)
        # Weapon bodies come from different recordings and layers, not just pitch shifts.
        if character=='tsukiyo':
            weapon=combine(layer(W,f'swish-{i+1}.wav',.24,1,speed=1.1,hp=300),layer(S,f'sword.{i+1}.ogg',.14,.14,hp=1700))
        elif character=='ren':
            weapon=combine(layer(W,f'swish-{i+5}.wav',.38,1,speed=.9,hp=120,lp=6500),layer(S,f'sword.{i+6}.ogg',.22,.22,hp=600))
        elif character=='daichi':
            weapon=combine(layer(W,f'swish-{i+8}.wav',.42,1,speed=.8,hp=90,lp=4700),layer(K,f'impactWood_light_{i:03}.ogg',.13,.2,lp=2500))
        elif character=='nao':
            weapon=combine(layer(W,f'swish-{i+11}.wav',.15,1,speed=1.4,hp=800),delayed(layer(R,'knifeSlice.ogg' if i%2==0 else 'knifeSlice2.ogg',.10,.4,speed=1.25,hp=1300),.045))
        else:
            weapon=combine(layer(V,f'arrow-feathers-{i+1:02}.wav',.3,.9),layer(R,f'bookFlip{i+1}.ogg',.23,.65,speed=1.25),layer(R,'metalClick.ogg',.085,.25,hp=1800),layer(W,'swish-4.wav',.24,.24))
        weapon_sources=list(current_sources)
        save(character,'weapon',i,weapon,p['weapon'])
        current_sources.extend(weapon_sources)
        impact=combine(weapon*.22,layer(K,f"impactPunch_{'heavy' if character in ['ren','daichi'] else 'medium'}_{i:03}.ogg",.28,.85,speed=1/p['weight'],lp=5000),layer(R,'chop.ogg',.16,.3 if character!='sayo' else .08))
        save(character,'impact',i,impact,-8 if character in ['ren','daichi'] else -10)
        cloth=layer(R,p['cloth'],.30,1,speed=p['speed'])
        dodge=combine(cloth,layer(W,f'swish-{i+1}.wav',.18,.16,speed=1.25,lp=4000))
        save(character,'dodge',i,dodge,p['foot']-1)
        collapse=combine(layer(K,f'impactSoft_heavy_{i:03}.ogg',.45,1,speed=1/p['weight'],lp=3500),layer(R,'dropLeather.ogg',.32,.3),layer(R,p['cloth'],.4,.4))
        save(character,'collapse',i,collapse,-12 if character in ['ren','daichi'] else -15)

# Keep source license notices and an exact recipe index with the deliverable.
(OUT/'licenses').mkdir(exist_ok=True)
(OUT/'sources'/'.gdignore').touch()
(OUT/'licenses'/'.gdignore').touch()
for pack,filename in [(K,'License.txt'),(R,'License.txt'),(V,'readme.txt')]:
    shutil.copyfile(ROOT/pack/filename,OUT/'licenses'/f'{pack}.txt')
shutil.copyfile(ROOT/'downloads.json',OUT/'licenses'/'downloads.json')
(OUT/'manifest.json').write_text(json.dumps({'files':manifest,'sources':used,'profiles':profiles},indent=2),encoding='utf-8')
print(f'{len(manifest)} edited sounds; {len(used)} original sources preserved')
