import json,pathlib,copy
from PIL import Image
r=pathlib.Path(__file__).resolve().parents[2];root=r/'assets/combat';presets={}
def layer(path,frame=None,row=0,offset=(0,0),rect=None):
 p=root/path;im=Image.open(p)
 return {'path':'res://assets/combat/'+str(path),'frame':list(frame or im.size),'row':row,'offset':list(offset),'rect':rect or []}
def lpc(part,role):
 anim={}
 for key,act in [('idle','walk'),('move','walk'),('attack','shoot' if role=='scout' else 'slash'),('spell','spellcast'),('hit','hurt'),('down','hurt')]:
  suffix='/purple.png' if part in ['torso/clothes/longsleeve/laced/male','hat/magic/wizard/base/adult'] else '.png'
  anim[key]=[layer(pathlib.Path('lpc/spritesheets')/(part+'/'+act+suffix),(64,64),0 if act=='hurt' else 2)]
 return anim
def merges(arr):return {k:sum([a[k] for a in arr],[]) for k in arr[0]}
for role in ['vanguard','scout','adept']:
 arr=[lpc(p,role) for p in ['body/bodies/male','legs/pants/male','feet/boots/basic/male','torso/armour/plate/male' if role=='vanguard' else 'torso/armour/leather/male' if role=='scout' else 'torso/clothes/longsleeve/laced/male','head/heads/human/male']]
 # Hair is selected separately, so equipment updates do not reseed appearance.
 anim=merges(arr)
 weapon='weapon/sword/longsword/walk/longsword.png' if role=='vanguard' else 'weapon/ranged/bow/normal/universal/foreground/shoot.png' if role=='scout' else 'weapon/polearm/cane/male/walk/cane.png'
 for k in anim:
  if k not in ['hit','down']:
   anim[k].append(layer(pathlib.Path('lpc/spritesheets')/weapon,(64,64),2))
 if role=='vanguard':anim['attack'][-1]=layer(pathlib.Path('lpc/spritesheets/weapon/sword/longsword/attack_slash/longsword.png'),(192,192),2,(-64,-64))
 if role=='adept':anim=merges([anim,lpc('hat/magic/wizard/base/adult',role)])
 presets[role]={'animations':anim,'native':64}
lpc_hair=[lpc('hair/'+h+'/adult','vanguard') for h in ['plain','curly_short2']]
def kenney(x,y,offset=(0,0)):
 return layer(pathlib.Path('kenney/Spritesheet/roguelikeChar_transparent.png'),(16,16),offset=offset,rect=[x*17,y*17,16,16])
kpresets={}
for role in ['vanguard','scout','adept']:
 layers=[kenney(0,0),kenney(3,2),kenney(6,5 if role=='vanguard' else 7 if role=='scout' else 3),kenney(24,8),kenney(28,0 if role=='vanguard' else 6 if role=='scout' else 7),kenney(42 if role=='vanguard' else 48 if role=='scout' else 45,9 if role=='scout' else 0,(5,0))]
 kpresets[role]={'native':16,'animations':{k:layers for k in ['idle','move','attack','spell','hit','down']}}
xpresets={}
for role,base in [('vanguard','knight'),('scout','elf'),('adept','wizzard')]:
 variants=[]
 for sex in ['m','f']:
  anim={}
  for k in ['idle','move','attack','spell','hit','down']:
   stem='run' if k=='move' else 'hit' if k=='hit' else 'idle'
   paths=sorted((root/'0x72/0x72_DungeonTilesetII_v1.7/frames').glob(base+'_'+sex+'_'+stem+'_anim_f*.png'))
   if not paths:paths=sorted((root/'0x72/0x72_DungeonTilesetII_v1.7/frames').glob(base+'_'+sex+'_idle_anim_f*.png'))
   anim[k]=[{'sequence':[str(p.relative_to(root)) for p in paths],'frame':list(Image.open(paths[0]).size),'row':0,'offset':[0,0]}]
   weapon='weapon_sword_1.png' if role=='vanguard' else 'weapon_bow.png' if role=='scout' else 'weapon_blue_magic_staff.png'
   wp=root/'0x72/0x72_DungeonTilesetII_v1.7/frames'/weapon
   if not wp.exists():
    names=[p.name for p in wp.parent.glob('weapon*') if ('staff' in p.name if role=='adept' else 'bow' in p.name if role=='scout' else 'sword' in p.name)];weapon=sorted(names)[0]
   anim[k].append(layer(pathlib.Path('0x72/0x72_DungeonTilesetII_v1.7/frames')/weapon,offset=(12,8)))
  variants.append({'native':32,'animations':anim})
 xpresets[role]=variants
npresets={}
for role in ['vanguard','scout','adept']:
 base=pathlib.Path('navinius/Modular RPG Pixel Art')
 layers=[layer(base/'Character.png'),layer(base/'Customization/blonde.png',offset=(2,0)),layer(base/'Equipment'/('steelchest.png' if role=='vanguard' else 'leatherchest.png')),layer(base/'Equipment'/('steelpants.png' if role=='vanguard' else 'leatherpants.png')),layer(base/'Equipment'/('steelgreathelm.png' if role=='vanguard' else 'leatherhood.png' if role=='scout' else 'wizardhat.png'),offset=(4,0))]
 if role=='vanguard':layers+=[layer(base/'Equipment/Sword.png',offset=(11,7)),layer(base/'Equipment/Shield.png',offset=(-3,7))]
 npresets[role]={'native':20,'animations':{k:layers for k in ['idle','move','attack','spell','hit','down']},'procedural_weapon':role!='vanguard'}
# A blade-bearing Expert uses lighter clothing, without changing identity or gear.
presets['expert']=copy.deepcopy(presets['vanguard'])
for layers in presets['expert']['animations'].values():
 for item in layers:item['path']=item['path'].replace('torso/armour/plate/male','torso/armour/leather/male')
kpresets['expert']=copy.deepcopy(kpresets['vanguard'])
for layers in kpresets['expert']['animations'].values():layers[2]=kenney(6,7);layers[4]=kenney(28,6)
xpresets['expert']=copy.deepcopy(xpresets['scout'])
for variant in xpresets['expert']:
 for layers in variant['animations'].values():layers[-1]=copy.deepcopy(xpresets['vanguard'][0]['animations']['idle'][-1])
npresets['expert']=copy.deepcopy(npresets['vanguard'])
for layers in npresets['expert']['animations'].values():
 for item in layers:
  item['path']=item['path'].replace('steelchest.png','leatherchest.png').replace('steelpants.png','leatherpants.png').replace('steelgreathelm.png','leatherhood.png')
styles=[{'id':'lpc','name':'Universal LPC','version':json.loads((r/'data/art/sources.json').read_text())['packs'][-1]['revision'],'roles':presets,'hair':lpc_hair,'note':'Layered 64px animation · neutral humanoid preview'}, {'id':'kenney','name':'Kenney Roguelike','version':'2.0','roles':kpresets,'note':'Original modular atlas · Godot motion effects'}, {'id':'0x72','name':'0x72 DungeonTileset II','version':'1.7','roles':xpresets,'note':'Original idle/run/hit frames · Godot attacks'}, {'id':'navinius','name':'Navinius Modular','version':'WIP 2026-10-09','roles':npresets,'note':'Original layers · Godot motion; bow/staff props drawn in engine'}]
(r/'data/art/styles.json').write_text(json.dumps({'schema_version':1,'styles':styles},indent=2)+'\n')
