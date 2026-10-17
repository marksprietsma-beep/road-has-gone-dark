"""GAME-133: append ten original spells to accepted v17; never run old generators."""
from pathlib import Path
import copy, hashlib, json
root=Path(__file__).resolve().parents[2]
before=json.loads((root/'data/rules/trhgd-character-v17.json').read_text())
p=copy.deepcopy(before);p.update(pack_id='trhgd-character-v18',rules_version='18.0.0')
p['provenance']['revision']='game133-sorcerer-druid-repertoires'
prov=dict(origin='Original TRHGD tactical spell designs; no sourcebook text or spell tables copied',license='Original project-authored content',revision='game133-sorcerer-druid-repertoires')
def c(n):return dict(op='const',value=n)
def level(cls):return dict(op='casting_level',id=cls)
def total(*args):return dict(op='sum',args=list(args))
def half(cls):return dict(op='floor_divide',args=[level(cls),c(2)])
def mod(stat,n,kind='insight'):return dict(stat=stat,type=kind,value=c(n))
def status(id,modifiers=None,capabilities=None,rounds=3,activation=False):
 row=dict(id=id,tags=[],duration=dict(type='activation'if activation else'round',amount=rounds,expiry='target_activation_end'if activation else'global_round_start'),stacking='refresh',modifiers=modifiers or [],effects=[],provenance=prov)
 if capabilities:row['capabilities']=capabilities
 p['statuses'].append(row)
 return dict(op='apply_status',id=id)
def remove(ids):return [dict(op='remove_status',id=id)for id in ids]
def save(cls,tier,kind,failed,success=None):return dict(op='save',save=kind,dc=total(c(10+tier),dict(op='modifier',id='CHA'if cls=='sorcerer'else'WIS'),dict(op='stat',id='save_dc')),on_failure=failed,on_success=success or [])
def damage(cls,kind,dice,halved=False):
 row=dict(op='damage',amount=dict(dice=dice,bonus=half(cls)),damage_type=kind)
 if halved:row['save_half']=True
 return row
cohort=[]
def spell(cls,id,name,tier,effects,description,kind='ally',radius=0):
 aid=cls+'-'+id;attr='CHA'if cls=='sorcerer'else'WIS';prepared=cls=='druid'
 pools={cls+'-slots-'+str(tier):1}
 if prepared:
  pool=aid+'-prepared';pools[pool]=1
  template=copy.deepcopy(next(x for x in p['resources']if x.get('prepared_ability') and x.get('slot_class')is None))
  template.update(id=pool,name=name+' · prepared copies',prepared_ability=aid,provenance=prov);p['resources'].append(template)
 row=dict(id=aid,name=name,cost=dict(main=1,move=0,reaction=0,resources=pools),effects=effects,tags=['spell','prepared'if prepared else'spontaneous','tier_'+str(tier)],timing=dict(kind='instant'),requirements=dict(op='attribute',id=attr,min=10+tier),targeting=dict(kind=kind,range=6,radius=radius),description=description+' Main action; one tier%d slot%s; %s%d. Range6, line of sight%s.'%(tier,' and prepared copy'if prepared else'; must be permanently known',attr,10+tier,', radius%d same-team targets'%radius if radius else''),casting_class=cls,spell_tier=tier,provenance=prov)
 p['abilities'].append(row);cohort.append(row)
 f=next(x for x in p['features']if x['id']==cls+'-casting-'+str(tier));f['abilities'].append(aid)
 if prepared:f['resources'].append(pool)
spell('sorcerer','crystal-reservoir','Crystal reservoir',4,[dict(op='temporary_hp',amount=total(c(8),half('sorcerer')))],'Grant8+half effective Sorcerer level temporary HP. Replaces only a smaller temporary-HP buffer; never stacks, heals wounds or restores resources. Persists until consumed; no timed ward.')
doubt=status('crushing-doubt',[mod('melee_attack',-3,'condition'),mod('ranged_attack',-3,'condition'),mod('will',-3,'condition')],rounds=2,activation=True)
spell('sorcerer','crushing-doubt','Crushing doubt',5,[save('sorcerer',5,'will',[doubt])],'Will negates weapon attack and Will penalties of3 for two target activations. No damage, immobility or casting suppression.',kind='creature')
veil=status('slipstream-veil',[mod('stride',2)],dict(concealment=50),rounds=2)
spell('sorcerer','slipstream-veil','Slipstream veil',6,[veil],'One ally gains50% weapon concealment and stride+2 insight for two global round boundaries. Does not evade targeted spells or grant teleportation.')
boons=['warded','haste','wizard-greater-ward-status','sorcerer-greater-ward-status','cleric-faith-ward-status','druid-oak-ward-status','perfect-shadow','beguiling-veil','runic-shell','spirit-shelter','spirit-lattice','lucid-poise','sovereign-clarity','elemental-covenant','company-veil','freedom-path','slipstream-veil','packward-canopy','predators-rhythm']
spell('sorcerer','sundering-chord','Sundering chord',7,[save('sorcerer',7,'fortitude',remove(boons))],'Each enemy in radius1 makes its own Fortitude save; failure strips the nineteen listed temporary wards and enhancements. No damage. Cannot remove ancestry, feats, maintained auras, temporary HP or body forms.',kind='creature',radius=1)
fracture=status('starfall-fracture',[mod('fortitude',-2,'condition')],rounds=2,activation=True)
spell('sorcerer','starfall-rupture','Starfall rupture',7,[save('sorcerer',7,'reflex',[damage('sorcerer','force','4d6'),fracture],[damage('sorcerer','force','4d6',True)])],'Enemies in radius1 take4d6+half caster level force damage and Fortitude−2 for two activations. Reflex halves damage and prevents fracture. Existing evasion and force resistance apply separately per target.',kind='creature',radius=1)
rooted=status('bramble-tether',capabilities=dict(immobile=True),rounds=2,activation=True)
spell('druid','bramble-tether','Bramble tether',4,[save('druid',4,'reflex',[rooted])],'Reflex negates rooting one enemy for two target activations. Prevents movement, not attacks or spells. No damage or impassable terrain.',kind='creature')
spell('druid','sap-renewal','Sap renewal',5,[dict(op='heal',amount=total(c(10),level('druid'))),dict(op='temporary_hp',amount=half('druid')),*remove(['weakened','off-balance'])],'Heal10+effective Druid level, clear Weakened/off-balance and grant half caster level temporary HP. The buffer never stacks; no resources, downed recovery or permanent injury removal.')
canopy=status('packward-canopy',[mod('fortitude',2)],dict(resistances=dict(physical=5)))
spell('druid','packward-canopy','Packward canopy',6,[canopy],'Allies in radius1, including active companions and summons, gain physical resistance5 per packet and Fortitude+2 insight for three global round boundaries. Does not grant elemental resistance or revive defeated creatures.',radius=1)
rhythm=status('predators-rhythm',[mod('reach',1),mod('stride',1),mod('damage',3)])
spell('druid','predators-rhythm',"Predator's rhythm",6,[rhythm],'One living ally gains melee reach+1, stride+1 and weapon damage+3 insight for three global round boundaries, including natural attacks. Does not change anatomy, restore actions or grant extra attacks.')
winter=status('winter-lock',capabilities=dict(immobile=True),rounds=2,activation=True)
spell('druid','winters-verdict',"Winter's verdict",7,[save('druid',7,'fortitude',[damage('druid','cold','3d6'),winter],[damage('druid','cold','3d6',True)])],'Enemies in radius1 take3d6+half caster level cold damage and become immobile for two activations. Fortitude halves damage and prevents rooting; cold resistance and existing evasion apply. No terrain or weather simulation.',kind='creature',radius=1)
assert set(boons)<=set(x['id']for x in p['statuses'])
assert len(cohort)==10
path=root/'data/rules/trhgd-character-v18.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
manifest_path=root/'data/rules/packs.json';manifest=json.loads(manifest_path.read_text())
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[x for x in manifest['packs']if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
(root/'docs/implementation/game133/COHORT.json').write_text(json.dumps(dict(rules_ref=pin,spells=cohort,dispel_statuses=boons,scope='Ten executable original choices using existing effect primitives; not ten new engine mechanics.'),indent=2)+'\n')
# Exact logical audit. No historical class/equipment/ancestry/feat/spell mutation.
delta={}
for key in before:
 if before[key]==p[key]:continue
 if isinstance(before[key],list):
  old={x['id']:x for x in before[key]};new={x['id']:x for x in p[key]}
  delta[key]=dict(added=sorted(set(new)-set(old)),removed=sorted(set(old)-set(new)),modified=[id for id in old if old[id]!=new[id]])
 else:delta[key]=dict(before=before[key],after=p[key])
assert set(delta)=={'pack_id','rules_version','provenance','abilities','features','resources','statuses'}
assert not delta['abilities']['modified'] and not delta['resources']['modified'] and not delta['statuses']['modified']
assert len(delta['features']['modified'])==8
(root/'docs/implementation/game133/PACK-DELTA.json').write_text(json.dumps(delta,indent=2)+'\n')
print(json.dumps(pin))
