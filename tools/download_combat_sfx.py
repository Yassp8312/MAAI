import urllib.request, zipfile, json, hashlib
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
root = Path('tmp/sfx-sources').resolve()
root.mkdir(parents=True,exist_ok=True)
packs = {
 'kenney-impact': 'https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip',
 'starninjas-sword': 'https://opengameart.org/sites/default/files/sword_-_starninjas_1.zip',
 'vehicle-apparel': 'https://opengameart.org/sites/default/files/weapons-apparel.zip',
 'kenney-rpg': 'https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip',
 'artisticdude-swishes': 'https://opengameart.org/sites/default/files/swishes.zip',
}
def fetch(item):
    name,url=item
    target=root/(name+'.zip')
    if not target.exists():
        urllib.request.urlretrieve(url,target)
    folder=root/name
    with zipfile.ZipFile(target) as archive:
        for entry in archive.infolist():
            destination=(folder/entry.filename).resolve()
            if not destination.is_relative_to(folder.resolve()):
                raise RuntimeError('Archive path escapes source folder')
        archive.extractall(folder)
    return {'pack':name,'url':url,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size}
with ThreadPoolExecutor(max_workers=3) as pool:
    result=list(pool.map(fetch,packs.items()))
(root/'downloads.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
for entry in result: print(entry)
