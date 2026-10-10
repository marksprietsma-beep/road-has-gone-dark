#!/usr/bin/env python3
"""Acquire original GAME-93 artwork; retain unchanged source bytes and provenance.
The three itch/Kenney archives must be fetched from the published provider pages.
--sources points at the locally acquired originals; the LPC revision is immutable.
"""
import argparse,csv,hashlib,json,pathlib,shutil,urllib.request,concurrent.futures
ROOT=pathlib.Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--sources',type=pathlib.Path,required=True);a=p.parse_args();src=a.sources
out=ROOT/'assets/combat';out.mkdir(parents=True,exist_ok=True)
pin=json.loads((src/'lpc/download-manifest.json').read_text())['revision']
files=[]
def copy(provider,path,source_url,version,credit=None):
 dest=out/provider/path;dest.parent.mkdir(parents=True,exist_ok=True);original=src/provider/path
 shutil.copyfile(original,dest)
 row={'provider':provider,'path':str(dest.relative_to(ROOT)),'source_url':source_url,'version':version,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
 if credit:row['attribution']=credit
 files.append(row)
for provider,folder,version,url in [('kenney','kenney','2.0','https://kenney.nl/assets/roguelike-characters'),('0x72','0x72','1.7','https://0x72.itch.io/dungeontileset-ii'),('navinius','navinius','WIP downloaded 2026-10-09','https://navinius.itch.io/pixel-rpg-modular-kit-wip')]:
 for f in sorted((src/folder).rglob('*')):
  if f.is_file() and '__MACOSX' not in f.parts and f.name!='.DS_Store' and f.suffix.lower() in ['.png','.txt','.md'] or f.is_file() and f.name in ['README','tile_list_v1.7']:
   copy(provider,f.relative_to(src/folder),url,version)
credits=list(csv.DictReader((src/'lpc/CREDITS.csv').open()))
actions=['walk','slash','shoot','spellcast','hurt']
parts=['body/bodies/male','head/heads/human/male','hair/plain/adult','hair/curly_short2/adult','legs/pants/male','feet/boots/basic/male','torso/armour/plate/male','torso/armour/leather/male','torso/clothes/longsleeve/laced/male','hat/magic/wizard/base/adult']
paths=[part+'/'+action+('/purple.png' if part in parts[-2:] else '.png') for part in parts for action in actions]
paths+=['weapon/sword/longsword/walk/longsword.png','weapon/sword/longsword/attack_slash/longsword.png','weapon/ranged/bow/normal/universal/foreground/shoot.png','weapon/ranged/bow/normal/universal/background/shoot.png','weapon/polearm/cane/male/walk/cane.png']
def fetch(path):
 full='spritesheets/'+path;dest=src/'lpc'/full;dest.parent.mkdir(parents=True,exist_ok=True)
 url='https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/'+pin+'/'+full
 if not dest.exists():dest.write_bytes(urllib.request.urlopen(url,timeout=45).read())
 # The upstream CSV records original animation paths before palette/weapon splits.
 alias=path
 if path.endswith('/purple.png'):alias=path.removesuffix('/purple.png')+'.png'
 if path.startswith('weapon/sword/longsword/'):
  matches=[x for x in credits if x['filename'].startswith('weapon/sword/longsword/')]
 elif path.startswith('weapon/polearm/cane/'):
  matches=[x for x in credits if x['filename']=='weapon/polearm/cane/male/walk.png']
 else:matches=[x for x in credits if x['filename']==alias]
 if not matches:raise RuntimeError('Missing credits for '+path)
 copy('lpc',pathlib.Path(full),url,pin,matches)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:list(pool.map(fetch,paths))
for name in ['CREDITS.csv','README.md']:
 shutil.copyfile(src/'lpc'/name,out/'lpc'/name)
# Record original archive hashes alongside individual embedded resources.
manifest={'schema_version':1,'purpose':'Four real GAME-93 art providers; selected original LPC layers, complete CC0 PNG libraries. No final ancestry roster.','packs':json.loads((src/'source-audit.json').read_text())['packs'],'files':sorted(files,key=lambda x:x['path'])}
manifest['packs'][-1]['acquisition']='55 selected original animation layers, full upstream credits and generator README; not the exhaustive upstream corpus'
manifest['packs'][-1]['license']='Per-asset OGA-BY 3.0 / CC-BY-SA 3.0 alternatives; exact selected contributors retained on every file'
(ROOT/'data/art/sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Retained',len(files),'original resources')
