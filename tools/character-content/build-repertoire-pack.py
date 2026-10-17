"""Append the bounded GAME-130 spell cohort. Never execute historical generators."""
from pathlib import Path
import json,hashlib,copy
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v16.json').read_text())
p.update(pack_id='trhgd-character-v17',rules_version='17.0.0')
p['provenance']['revision']='game130-upper-tier-repertoires'
prov=dict(origin='Original TRHGD tactical spell designs; no sourcebook prose or spell tables copied',license='Original project-authored content',revision='game130-upper-tier-repertoires')
def const(n):return dict(op='const',value=n)
def mod(stat,n,kind='insight'):return dict(stat=stat,type=kind,value=const(n))
def status(id,name,rounds=3,modifiers=None,capabilities=None,tags=None,activation=False,aura=None):
 s=dict(id=id,tags=tags or [],duration=dict(type='activation' if activation else 'round',amount=rounds,expiry='target_activation_end' if activation else 'global_round_start'),stacking='refresh',modifiers=modifiers or [],effects=[],provenance=prov)
 if capabilities:s['capabilities']=capabilities
 if aura:s['aura']=aura
 p['statuses'].append(s)
 return dict(op='apply_status',id=id)
def cleanse(ids):return [dict(op='remove_status',id=id)for id in ids]
def save(cls,tier,kind,failed,succeeded=None):return dict(op='save',save=kind,dc=dict(op='sum',args=[const(10+tier),dict(op='modifier',id='INT' if cls=='wizard'else'WIS'),dict(op='stat',id='save_dc')]),on_failure=failed,on_success=succeeded or [])
def damage(cls,kind,dice,half=False):
 d=dict(op='damage',amount=dict(dice=dice,bonus=dict(op='floor_divide',args=[dict(op='casting_level',id=cls),const(2)])),damage_type=kind)
 if half:d['save_half']=True
 return d
cohort=[]
def spell(cls,id,name,tier,effects,description,kind='ally',radius=0,extra_tags=None):
 aid=cls+'-'+id;pool=aid+'-prepared'
 a=dict(id=aid,name=name,cost=dict(main=1,move=0,reaction=0,resources={cls+'-slots-'+str(tier):1,pool:1}),effects=effects,tags=['spell','prepared','tier_'+str(tier)]+(extra_tags or []),timing=dict(kind='instant'),requirements=dict(op='attribute',id='INT'if cls=='wizard'else'WIS',min=10+tier),targeting=dict(kind=kind,range=6,radius=radius),description=description+' Main action, one tier%d slot and one prepared copy. Requires %s%d. Range6, line of sight%s.'%(tier,'INT'if cls=='wizard'else'WIS',10+tier,', radius'+str(radius)+' same-team targets'if radius else''),casting_class=cls,spell_tier=tier,provenance=prov)
 p['abilities'].append(a)
 template=copy.deepcopy(next(x for x in p['resources']if x.get('prepared_ability') and x.get('slot_class') is None))
 template.update(id=pool,name=name+' · prepared copies',prepared_ability=aid,provenance=prov)
 p['resources'].append(template)
 f=next(x for x in p['features']if x['id']==cls+'-casting-'+str(tier))
 f['abilities'].append(aid);f['resources'].append(pool)
 cohort.append(a)
rooted=status('gravitic-snare','Gravitic snare',rounds=2,activation=True,capabilities=dict(immobile=True))
spell('wizard','gravitic-snare','Gravitic snare',4,[save('wizard',4,'reflex',[rooted])],'Reflex negates immobilisation for two target activations; attacks and casting remain legal. Pure area control, no damage.',kind='creature',radius=1)
boons=['warded','haste','wizard-greater-ward-status','cleric-faith-ward-status','perfect-shadow','beguiling-veil','runic-shell','spirit-shelter','spirit-lattice','lucid-poise','sovereign-clarity','elemental-covenant','company-veil','freedom-path']
spell('wizard','unravel-enchantment','Unravel enchantment',5,[save('wizard',5,'will',cleanse(boons))],'Will negates removal of listed temporary wards, haste, concealment and protective immunities. No damage. Does not dispel forms, maintained auras, ancestry, feats or equipment.',kind='creature')
veil=status('company-veil','Veil of the company',rounds=2,capabilities=dict(concealment=50))
spell('wizard','company-veil','Veil of the company',6,[veil],'Allies in radius1 gain50% weapon concealment for two global round boundaries. Does not prevent targeted spells or grant invisibility.',radius=1)
seal=status('dissonant-seal','Dissonant seal',rounds=2,activation=True,tags=['spell_suppressed'])
spell('wizard','dissonant-seal','Dissonant seal',7,[save('wizard',7,'will',[seal])],'Will negates suppression of spell-tagged abilities for two target activations. Psychic, supernatural and weapon actions remain legal. No damage.',kind='creature')
spell('wizard','prismatic-volley','Prismatic volley',7,[save('wizard',7,'reflex',[damage('wizard','fire','3d6')],[damage('wizard','fire','3d6',True)]),save('wizard',7,'fortitude',[damage('wizard','electricity','3d6')],[damage('wizard','electricity','3d6',True)])],'Separate fire/Reflex and electricity/Fortitude saves, each halves its own3d6+casterlevel/2 packet. Resistances and evasion apply independently. No condition riders.',kind='creature')
movement=['slowed','entangled','briar-rooted','arcane-tether','winter-brand','mind-tether','gravitic-snare']
freedom=status('freedom-path','Path of freedom',capabilities=dict(immunities=movement))
spell('cleric','freedom-path','Path of freedom',4,cleanse(movement)+[freedom],'Remove the seven listed movement conditions and prevent their reapplication for three global round boundaries. No general terrain, flight or universal movement immunity.')
litany=status('battle-litany','Litany of resolve',aura=dict(radius=2,modifiers=[mod('melee_attack',2),mod('ranged_attack',2),mod('damage',2)]))
spell('cleric','battle-litany','Litany of resolve',5,[litany],'The selected ally maintains a radius2 aura: melee/ranged attack and weapon damage+2 insight for three global round boundaries. Dynamic range, living allies only; typed bonuses do not stack.')
afflictions=movement+['weakened','off-balance','unsteady-concentration','beguiling-doubt','beguiling-pressure','prismatic-fracture','psychic-lock','psychic-confusion','dissonant-seal']
spell('cleric','purifying-renewal','Purifying renewal',6,[dict(op='heal',amount=dict(op='sum',args=[const(8),dict(op='casting_level',id='cleric')]))]+cleanse(afflictions),'Heal8+effective Cleric caster level and remove the sixteen listed tactical afflictions, including spell suppression. No resurrection, permanent curse removal, resource or slot restoration.')
covenant=status('elemental-covenant','Elemental covenant',capabilities=dict(resistances=dict(fire=8,cold=8,electricity=8)))
spell('cleric','elemental-covenant','Elemental covenant',6,[covenant],'Allies in radius1 gain fire/cold/electricity resistance8 per packet for three global round boundaries. No physical or force resistance, healing or defence bonus.',radius=1)
spell('cleric','return-to-breath','Return to breath',7,[dict(op='heal',amount=dict(op='sum',args=[const(12),dict(op='casting_level',id='cleric')])),*cleanse(['weakened','off-balance'])],'Heal12+effective Cleric caster level and remove weakened/off-balance. May target a downed persistent ally while battle is active; no extra turn, XP, resource restoration or permanently dead/summoned creature recovery.',extra_tags=['recover_downed'])
# Assert every bounded removal/immunity resolves to an actual status.
ids={s['id']for s in p['statuses']}
assert set(boons+afflictions)<=ids,set(boons+afflictions)-ids
path=root/'data/rules/trhgd-character-v17.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text())
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[x for x in manifest['packs']if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n')
(root/'docs/implementation/game130/COHORT.json').write_text(json.dumps(dict(rules_ref=pin,spells=cohort,dispel_statuses=boons,cleansed_statuses=afflictions,scope='Ten executable spell identities, not ten new effect opcodes. Original bounded adaptations.'),indent=2)+'\n')
print(json.dumps(pin))
