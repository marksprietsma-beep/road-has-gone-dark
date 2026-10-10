#!/usr/bin/env python3
"""Pinned original LPC subset; per-item licences, compatible wardrobe catalog.
Requires Pillow for image inspection only. Originals are never altered.
"""
import pathlib,json,hashlib,urllib.request,urllib.error,concurrent.futures
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[2]
PIN='58ce1aa479e4df32845a73a5d0afc221c3a893c2'
BASE='https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/'+PIN+'/'
OUT=ROOT/'assets/combat/lpc';OUT.mkdir(parents=True,exist_ok=True)
ACTIONS=['idle','walk','slash','shoot','thrust','spellcast','hurt']
definitions={}
parts={}
rows={}
def original(path,credits,optional=False):
 dest=OUT/path;url=BASE+path
 if not dest.exists():
  try:b=urllib.request.urlopen(url,timeout=60).read()
  except urllib.error.HTTPError as e:
   if e.code==404 and optional:return None
   raise
  dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(b)
 chosen=[]
 for c in credits:
  choices=c['licenses']
  licence=next((v for v in ['OGA-BY 3.0','OGA-BY 3.0+','CC-BY-SA 3.0','CC-BY 4.0'] if v in choices),None)
  if licence is None:raise RuntimeError('Unreviewed licence: '+path+' '+str(choices))
  chosen.append({'authors':c['authors'],'license':licence,'source_urls':c['urls'],'notes':c.get('notes','')})
 rows[path]={'provider':'lpc','path':str(dest.relative_to(ROOT)),'source_url':url,'version':PIN,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attribution':chosen}
 return dest
def definition(path):
 if path not in definitions:
  # Item metadata is redistributed with the exact artwork it describes.
  cached=OUT/path
  data=cached.read_bytes() if cached.exists() else urllib.request.urlopen(BASE+path,timeout=60).read()
  o=json.loads(data);definitions[path]=o
  original(path,o['credits'])
 return definitions[path]
def part(key,definition_path,body='male',variant=None,layer=1):
 o=definition(definition_path);meta=o['layer_'+str(layer)];stem=meta[body];credit=o['credits']
 result={'z':meta['zPos'],'source_definition':'res://assets/combat/lpc/'+definition_path,'actions':{}}
 def f(act):
  p='spritesheets/'+stem+act+('/'+variant+'.png' if variant else '.png')
  if key in ['bow-front','bow-back'] and act=='walk':
   p='spritesheets/weapon/ranged/bow/normal/walk/'+('foreground' if key=='bow-front' else 'background')+'/medium.png'
  dest=original(p,credit,optional=True)
  if not dest:return act,None
  im=Image.open(dest);frame=im.height if act=='hurt' else im.height//4
  assert frame in [64,128,192],(p,im.size)
  return act,{'path':'res://assets/combat/lpc/'+p,'frame':[frame,frame],'offset':[-(frame-64)//2,-(frame-64)//2],'source_animation':act,'columns':im.width//frame,'directions':1 if act=='hurt' else 4}
 with concurrent.futures.ThreadPoolExecutor(max_workers=7) as pool:
  for act,item in pool.map(f,ACTIONS):
   if item:result['actions'][act]=item
 assert 'walk' in result['actions'],key
 parts[key]=result
 return key
def d(s):return 'sheet_definitions/'+s+'.json'
for body,pants,boots in [('male','male','male'),('female','female','female')]:
 part('body-'+body,d('body/body'),body)
 part('pants-'+body,d('legs/pants/legs_pants'),body)
 part('boots-'+body,d('feet/boots/feet_boots_basic'),body)
 part('mail-'+body,d('torso/torso_chainmail'),body)
 part('leather-'+body,d('torso/armour/torso_armour_leather'),body)
 part('skirt-'+body,d('legs/skirts/legs_skirts_plain'),body)
 for color in ['brown','forest','navy']:
  part('shirt-'+body+'-'+color,d('torso/shirts/longsleeve/torso_clothes_longsleeve_laced') if body=='male' else d('torso/shirts/torso_clothes_tunic'),body,color)
 for color in ['purple','blue']:
  # Tunic + native skirt supports staff thrust in both families; the full robe does not.
  part('mage-'+body+'-'+color,d('torso/shirts/longsleeve/torso_clothes_longsleeve_laced') if body=='male' else d('torso/shirts/torso_clothes_tunic'),body,color)
 part('cane-'+body,d('weapons/polearm/weapon_polearm_cane'),body,'cane')
for key,file in [('male','male'),('female','female'),('gaunt','male_gaunt')]:
 part('head-'+key,d('head/heads/human/heads_human_'+file))
for key,file,layer in [('plain','short/hair_plain',1),('curly','curly/hair_curly_short2',1),('ponytail-front','braids/hair_ponytail',1),('ponytail-back','braids/hair_ponytail',2),('beard','beards/beards_trimmed',1)]:
 part(key,d('hair/'+file),layer=layer)
for key,file,layer in [('cape-front','torso/cape/cape_tattered',1),('cape-back','torso/cape/cape_tattered',2),('hood','headwear/coverings/hoods/hat_hood_sack_cloth',1),('helmet','headwear/helmets/helmets/hat_helmet_bascinet_round',1)]:
 part(key,d(file),layer=layer)
for color in ['purple','blue']:part('hat-'+color,d('headwear/hats/magic/hat_magic_wizard'),variant=color)
for key,file,variant,layer in [('blade-front','weapons/sword/weapon_sword_dagger','dagger',1),('blade-back','weapons/sword/weapon_sword_dagger','dagger',2),('bow-front','weapons/ranged/bow/weapon_ranged_bow_normal',None,2),('bow-back','weapons/ranged/bow/weapon_ranged_bow_normal',None,1),('shield','weapons/shields/shield_round','brown',1)]:
 part(key,d(file),variant=variant,layer=layer)
# These colours are authored project presentation, not copied generator code.
# Original body/hair shade values are identified from the retained source images.
palettes={
 'skin':{'source':['271920','99423c','cc8665','e4a47c','f9d5ba','faece7'],'sets':[
 ['271920','854d46','b67d61','d9a47e','f0c5a2','f9deca'],
 ['211923','523835','815845','a97858','c6976e','dfb990'],
 ['1d1820','342a2b','514037','735342','986f54','ba9273'],
 ['231c25','604b43','96735b','b9906c','d8b084','ebcda5']]},
 'hair':{'source':['260d14','6a1108','a42600','bf4000','e55600','ff8a00'],'sets':[
 ['171820','24232b','35313b','4d414a','645354','816b61'],
 ['251820','4f302a','754636','976449','bd875f','d5a476'],
 ['2c2025','66513d','91714b','b99861','debc7e','f1d8a0'],
 ['20202a','454652','767680','a4a3aa','cfccd1','f1e9e1'],
 ['2c1520','67322c','93462f','b9693b','d79050','eeb577']]}}
timelines={'idle':{'frames':[0,0,1],'fps':2,'loop':True},'move':{'frames':list(range(1,9)),'fps':12,'loop':True},'slash':{'frames':list(range(6)),'fps':9,'impact':0.34},'shoot':{'frames':list(range(13)),'fps':16,'impact':0.58},'thrust':{'frames':list(range(8)),'fps':11,'impact':0.38},'spell':{'frames':list(range(7)),'fps':9,'impact':0.46},'down':{'frames':list(range(6)),'fps':9},'hit':{'frames':[0,1,0],'fps':12}}
catalog={'schema_version':2,'styles':[{'id':'lpc','name':'Universal LPC','version':PIN,'note':'LPC V1 · native directional character animation','native':64,'parts':parts,'palettes':palettes,'timelines':timelines}]}
(ROOT/'data/art/styles.json').write_text(json.dumps(catalog,indent=2)+'\n')
# Include prior selected LPC originals too; historical four-provider manifest stays intact.
prior=json.loads((ROOT/'data/art/sources.json').read_text())
for row in prior['files']:
 if row['provider']=='lpc' and row['path'].removeprefix('assets/combat/lpc/') not in rows:
  legacy=json.loads(json.dumps(row))
  legacy['attribution']=[{'authors':[a.strip() for a in c['authors'].split(',')],
   'license':'OGA-BY 3.0' if 'OGA-BY 3.0' in c['licenses'] else 'CC-BY-SA 3.0',
   'source_urls':[u.strip() for u in c['urls'].split(',')],'notes':c.get('notes','').strip()}
   for c in row['attribution']]
  rows[row['path'].removeprefix('assets/combat/lpc/')]=legacy
manifest={'schema_version':1,'purpose':'GAME-94 LPC-only original resources and per-item selected licences; no final ancestry roster','packs':[{'id':'lpc','revision':PIN,'source_url':'https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator','acquisition':'Selected original body-compatible layers and metadata. Project-authored palette adjustments and compositions are CC-BY-SA 3.0 artwork.'}],'files':sorted(rows.values(),key=lambda x:x['path'])}
(ROOT/'data/art/lpc-sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
authors=sorted({a for r in manifest['files'] for c in r['attribution'] for a in c['authors']})
(ROOT/'assets/combat/LPC-CREDITS.txt').write_text('THE ROAD HAS GONE DARK — UNIVERSAL LPC CHARACTER PRESENTATION V1\n\n'
 'Original artwork: Universal LPC Character Generator\n'+manifest['packs'][0]['source_url']+'\nRevision '+PIN+'\n\nSprites by: '+', '.join(authors)+'\n\n'
 'Per-layer selected licences, authors, original URLs and SHA-256 values: artwork/sources.json (distribution), data/art/lpc-sources.json (repository). Full original credits: artwork/lpc/CREDITS.csv. Original item metadata and unchanged PNGs are supplied beside the executable.\n\n'
 'Select OGA-BY 3.0 where offered; otherwise CC-BY-SA 3.0. Exact choices are recorded on each file. Licence URLs: https://static.opengameart.org/OGA-BY-3.0.txt ; https://creativecommons.org/licenses/by-sa/3.0/ . Legal texts are included in artwork/licenses/. Upstream GPL-3.0 repository notice is retained in artwork/lpc/LICENSE; no generator implementation code is used.\n\n'
 'TRHGD modifications: project-authored skin/hair palette adjustments, layered combinations and scale/animation presentation. These derivative artwork arrangements are available under CC-BY-SA 3.0. Original assets retain their selected licences. This notice concerns artwork, not the gameplay source code. No endorsement by the artists is implied.\n\n'
 'Native idle/walk/slash/shoot/thrust/spellcast/hurt frames are used where supported. Held poses for missing item animations, projectile traces, lunge, flash, floating text and interpolation are Godot presentation effects. No final ancestry roster or complete body-plan coverage is claimed.\n')
print('LPC parts:',len(parts),'original resources:',len(rows),'native coverage:',{k:list(v['actions']) for k,v in parts.items()})
