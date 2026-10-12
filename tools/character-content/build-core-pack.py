import json,copy,hashlib,pathlib
root=pathlib.Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v3.json').read_text())
p.update(pack_id='trhgd-character-v4',rules_version='4.0.0',engine_schema=3)
prov={'origin':'Original TRHGD implementation of generic fantasy archetypes; no sourcebook text or proprietary setting content copied','license':'Original project-authored content','revision':'game118-core-1'}
p['provenance']=prov
c=lambda n:{'op':'const','value':n}
op=lambda name,*args:{'op':name,'args':list(args)}
lvl=lambda cls:{'op':'class_level','id':cls}
mod=lambda a:{'op':'modifier','id':a}
allreq={'op':'all','args':[]}
def m(stat,n,t='training'):return {'stat':stat,'type':t,'value':c(n) if isinstance(n,int) else n}
def featfeature(id,name,mods=[],abilities=[],resources=[],tags=[],senses=[],description=''):
 row=dict(id=id,name=name,modifiers=copy.deepcopy(mods),abilities=list(abilities),resources=list(resources),tags=list(tags),senses=list(senses),hooks=[],grants=[],provenance=prov,description=description)
 p['features'].append(row);return id
for sid,sname,attr in [('acrobatics','Acrobatics','DEX'),('spellcraft','Spellcraft','INT'),('religion','Religion','WIS'),('animal-handling','Animal handling','CHA')]:
 p['skills'].append(dict(id=sid,name=sname,attribute=attr,trained_only=False,max_rank='character_level',tags=[],modifiers=[],provenance=prov))
# Preserve old IDs used by the authority; new pack only exposes familiar core classes.
p['classes']=[]
p['feats']=[f for f in p['feats'] if f['id']!='veiled-casting']
for res in p['resources']:
 if res['id'] in ['focus','veil_uses']:res['capacity']=c(4)
for f in p['features']:f['description']=''
def resource(id,name,capacity):p['resources'].append(dict(id=id,name=name,capacity=capacity,refresh='eligible_rest',provenance=prov))
def status(id,mods,rounds=3,tags=[]):p['statuses'].append(dict(id=id,tags=tags,duration={'type':'round','amount':rounds,'expiry':'global_round_start'},stacking='refresh',modifiers=mods,effects=[],provenance=prov))
def ability(id,name,effects,kind='creature',rng=1,cost={},tags=[],description='',radius=0):
 p['abilities'].append(dict(id=id,name=name,cost={'main':1,'move':0,'reaction':0,'resources':cost},effects=effects,tags=tags,timing={'kind':'instant'},requirements=allreq,targeting={'kind':kind,'range':rng,'radius':radius},provenance=prov,description=description))
def dmg(n,typ='physical'):return {'op':'damage','amount':n if isinstance(n,dict) else c(n),'damage_type':typ}
def heal(n):return {'op':'heal','amount':n if isinstance(n,dict) else c(n)}
def die(s,b=0):return {'dice':s,'bonus':c(b) if isinstance(b,int) else b}
def apply(id):return {'op':'apply_status','id':id}
def save(stat,dc,effects):return {'op':'save','save':stat,'dc':dc,'on_failure':effects}
# Martial identity: activatable rage, trained weapon techniques, flurry, smite, quarry and sneak attack.
resource('rage-uses','Rage uses',op('sum',c(1),op('floor_divide',lvl('barbarian'),c(3))))
status('raging',[m('melee_attack',2,'condition'),m('damage',2,'condition'),m('fortitude',2,'condition'),m('defence',-2,'condition')],3,['rage'])
ability('rage','Rage',[apply('raging')],'self',0,{'rage-uses':1},description='Three rounds: melee +2, damage +2, Fortitude +2, Defence −2. Costs a main action and one rest-limited use.')
featfeature('barbarian-rage','Rage',abilities=['rage'],resources=['rage-uses'],description='Trade defence for ferocious attacks. Uses increase at levels 3 and 6.')
featfeature('barbarian-speed','Fast movement',[m('stride',1)],description='One additional battlefield tile of movement.')
featfeature('barbarian-toughness','Damage endurance',[m('HP',4)],description='Four additional maximum HP.')
status('reckless',[m('melee_attack',2,'condition'),m('defence',-2,'condition')],2)
ability('reckless-assault','Reckless assault',[{'op':'apply_status','id':'reckless','recipient':'actor'}],rng=1,tags=['weapon_strike'],description='Gain +2 melee and −2 defence for two rounds, then make a weapon attack.')
featfeature('barbarian-reckless','Reckless assault',abilities=['reckless-assault'])
resource('fighter-resolve','Second wind uses',op('sum',c(1),op('floor_divide',lvl('fighter'),c(3))))
ability('second-wind','Second wind',[heal(op('sum',c(4),lvl('fighter')))],'self',0,{'fighter-resolve':1},description='Restore 4 + Fighter level HP; main action, one rest-limited use.')
ability('power-strike','Power strike',[],tags=['weapon_strike','power_strike'],description='Weapon attack at −2 to hit and +4 damage. Requires a melee weapon.')
featfeature('fighter-training','Weapon training',[m('melee_attack',1),m('ranged_attack',1)],abilities=['power-strike','second-wind','guard'],resources=['fighter-resolve'],description='All martial weapons, all armour and shields; +1 attack. Guard protects an adjacent ally using the shared reaction.')
featfeature('fighter-specialization','Weapon specialization',[m('damage',2)],description='Weapon attacks deal two additional damage.')
featfeature('fighter-veteran','Veteran training',[m('melee_attack',1),m('ranged_attack',1)])
resource('ki','Ki',op('max',c(1),op('sum',op('floor_divide',lvl('monk'),c(2)),mod('WIS'))))
ability('flurry','Flurry of blows',[],tags=['weapon_strike','flurry'],description='Two unarmed strikes, each at −2 attack; uses one main action. Unarmoured only.')
ability('ki-step','Ki step',[apply('ki-swiftness')],'self',0,{'ki':1},description='One Ki: +2 movement and +2 Defence for two rounds.')
status('ki-swiftness',[m('stride',2,'condition'),m('defence',2,'condition')],2)
featfeature('monk-training','Unarmed discipline',abilities=['flurry','ki-step'],resources=['ki'],tags=['monk_unarmoured'],description='Unarmed weapon improves at level 4; Wisdom adds to Defence while unarmoured. Flurry has no armour compatibility.')
featfeature('monk-evasion','Evasion',[m('reflex',2)],description='Reflex +2 in this tactical adaptation; full half-damage evasion remains continuation work.')
featfeature('monk-speed','Unarmoured speed',[m('stride',1)])
resource('smite-uses','Smite uses',op('sum',c(1),op('floor_divide',lvl('paladin'),c(3))))
resource('lay-hands','Lay on hands',op('max',c(1),op('sum',lvl('paladin'),mod('CHA'))))
ability('smite','Smite raider',[],rng=1,cost={'smite-uses':1},tags=['weapon_strike','smite'],description='Melee strike against a hostile raider: Charisma adds to attack, Paladin level adds to damage. Rest-limited uses.')
ability('lay-on-hands','Lay on hands',[heal(op('sum',c(3),lvl('paladin'),op('max',c(0),mod('CHA'))))],'ally',1,{'lay-hands':1},description='Touch healing for 3 + Paladin level + positive Charisma modifier.')
featfeature('paladin-oath','Oath and smite',abilities=['smite','lay-on-hands'],resources=['smite-uses','lay-hands'])
featfeature('paladin-grace','Divine grace',tags=['divine_grace'],description='Positive Charisma modifier adds to all three saves.')
featfeature('paladin-courage','Aura of courage',[m('will',2)],description='Will +2; broader fear immunity is not present in this batch.')
ability('aimed-shot','Aimed shot',[],rng=7,tags=['weapon_strike','aimed_shot'],description='Bow attack with +2 attack; costs both movement and main action.')
p['abilities'][-1]['cost']['move']=1
featfeature('ranger-quarry','Favoured enemy: raiders',tags=['favoured_raider'],abilities=['aimed-shot'],description='+2 weapon attack and damage against the authored humanoid raiders. Other favoured-enemy choices are not implemented yet.')
featfeature('ranger-tracker','Track and awareness',[m('initiative',1)],description='Survival and Perception are class skills; +1 initiative.')
featfeature('ranger-style','Archery style',[m('ranged_attack',1)])
featfeature('rogue-sneak','Sneak attack',abilities=['precision'],tags=['sneak_scaling'],description='Once per round, allied melee threat enables extra damage: +2 at Rogue 1, +4 at 3, +6 at 5. Orthogonal attacks only.')
featfeature('rogue-evasion','Nimble avoidance',[m('reflex',2)])
ability('rogue-feint','Feint',[apply('off-balance')],rng=1,description='Make an adjacent opponent off balance (Defence −2) for two rounds; costs a main action.')
status('off-balance',[m('defence',-2,'condition')],2)
featfeature('rogue-feint-feature','Combat feint',abilities=['rogue-feint'])
# Shared real spell system: typed traditions, per-tier slots, prepared versus spontaneous selections.
status('blessed',[m('melee_attack',1,'condition'),m('ranged_attack',1,'condition'),m('will',1,'condition')],3)
status('inspired',[m('melee_attack',1,'condition'),m('ranged_attack',1,'condition'),m('damage',1,'condition')],3)
status('warded',[m('defence',3,'armor')],3)
status('barkskin',[m('defence',2,'condition')],3)
status('entangled',[m('stride',-2,'condition'),m('ranged_attack',-2,'condition')],3)
status('bear-form',[m('melee_attack',2,'condition'),m('damage',3,'condition'),m('defence',1,'condition')],3,['shape_bear'])
status('haste',[m('stride',2,'condition'),m('melee_attack',1,'condition'),m('ranged_attack',1,'condition')],3)
status('weakened',[m('melee_attack',-2,'condition'),m('damage',-2,'condition')],3)
resource('performance','Performance uses',op('max',c(1),op('sum',c(2),lvl('bard'),mod('CHA'))))
ability('inspire-courage','Inspire courage',[apply('inspired')],'ally',0,{'performance':1},description='All allies within three tiles gain +1 attack and damage for three rounds.',radius=3)
featfeature('bard-performance','Bardic performance',abilities=['inspire-courage'],resources=['performance'])
featfeature('bard-lore','Bardic knowledge',[m('will',1)],description='Arcana, Craft and social skills receive class-skill training bonuses.')
resource('channel','Channel uses',op('max',c(1),op('sum',c(2),mod('CHA'))))
ability('channel-healing','Channel healing',[heal(op('sum',c(2),op('multiply',c(2),lvl('cleric'))))],'ally',0,{'channel':1},description='All allies within three tiles regain 2 + twice Cleric level HP. One main action and one channel use.',radius=3)
featfeature('cleric-channel','Channel positive energy',abilities=['channel-healing'],resources=['channel'])
featfeature('cleric-domain','Protection domain',[m('will',1)],description='Protection domain grants +1 Will and defensive divine spells. Domain selection is not yet implemented.')
resource('wildshape','Wild shape uses',c(1))
ability('wild-shape','Wild shape: bear',[apply('bear-form')],'self',0,{'wildshape':1},description='For three rounds: +2 melee, +3 damage, +1 Defence. Class 5+. Visual transformation uses a labelled neutral fallback; dedicated bear art is future work.')
featfeature('druid-shape','Wild shape',abilities=['wild-shape'],resources=['wildshape'])
featfeature('druid-bond','Nature bond: woodland domain',[m('will',1)],description='Domain bond grants barkskin and nature spells. An autonomous animal companion is not offered in this batch.')
featfeature('sorcerer-blood','Arcane bloodline',[m('save_dc',1)],description='Inherited arcane affinity grants +1 spell DC; culture and ancestry remain independent. Bloodline choice is continuation work.')
featfeature('wizard-study','Arcane study',description='Intelligence-based prepared casting. Select spells from your learned spell list; unselected spells cannot be cast. Cloth and simple weapons only.')
class_specs={
'barbarian':(12,4,1,['fortitude'],['athletics','survival','perception'],['simple','martial','light','medium','shield'],None,[(1,'barbarian-rage'),(1,'barbarian-speed'),(3,'barbarian-toughness'),(5,'barbarian-reckless')],'A fierce martial warrior whose limited rage trades defence for attack and damage.'),
'bard':(8,6,.75,['reflex','will'],['arcana','persuasion','insight','craft','stealth','perception'],['simple','light'],('arcane','spontaneous','CHA'),[(1,'bard-performance'),(1,'bard-lore')],'A charismatic performer: bolster nearby allies and cast a limited known repertoire.'),
'cleric':(8,2,.75,['fortitude','will'],['insight','arcana','persuasion'],['simple','light','medium','shield'],('divine','prepared','WIS'),[(1,'cleric-channel'),(1,'cleric-domain')],'A divine prepared caster with party healing, protective prayers and channel energy.'),
'druid':(8,4,.75,['fortitude','will'],['survival','perception','insight'],['simple','light'],('divine','prepared','WIS'),[(1,'druid-bond'),(5,'druid-shape')],'A prepared nature caster with a woodland domain bond and bear form at level five.'),
'fighter':(10,2,1,['fortitude'],['athletics','craft'],['simple','martial','light','medium','heavy','shield'],None,[(1,'fighter-training'),(3,'fighter-specialization'),(5,'fighter-veteran')],'A trained weapons specialist: guard, power strikes, second wind and weapon specialization.'),
'monk':(8,4,.75,['fortitude','reflex','will'],['athletics','stealth','perception','insight'],['simple'],None,[(1,'monk-training'),(2,'monk-evasion'),(3,'monk-speed')],'An unarmoured Wisdom-based martial artist using unarmed flurries and limited Ki.'),
'paladin':(10,2,1,['fortitude'],['persuasion','insight'],['simple','martial','light','medium','heavy','shield'],('divine','prepared','CHA'),[(1,'paladin-oath'),(2,'paladin-grace'),(3,'paladin-courage')],'An oath-bound warrior with smite, touch healing and Charisma-based divine grace.'),
'ranger':(10,6,1,['fortitude','reflex'],['survival','perception','stealth','athletics'],['simple','martial','light','medium','shield'],('divine','prepared','WIS'),[(1,'ranger-quarry'),(1,'ranger-tracker'),(2,'ranger-style')],'A skilled tracker and archer with a raider quarry, aimed shots and later nature casting.'),
'rogue':(8,8,.75,['reflex'],['stealth','perception','persuasion','craft','athletics','insight'],['simple','light'],None,[(1,'rogue-sneak'),(2,'rogue-evasion'),(3,'rogue-feint-feature')],'A versatile skill expert whose ally-assisted sneak attacks improve at levels three and five.'),
'sorcerer':(6,2,.5,['will'],['arcana','persuasion'],['simple'],('arcane','spontaneous','CHA'),[(1,'sorcerer-blood')],'A Charisma-based spontaneous caster. Choose a smaller known repertoire and spend shared tier slots freely.'),
'wizard':(6,2,.5,['will'],['arcana','craft','insight'],['simple'],('arcane','prepared','INT'),[(1,'wizard-study')],'An Intelligence-based scholar. Prepare a daily selection from a larger learned list; each tier has limited slots.')}
spell_lists={
'arcane':[(1,'arcane-bolt','Arcane bolt',[dmg(die('1d6',2),'arcane')],'creature',6,'Reliable arcane damage; one tier-one slot.'),(1,'mage-armour','Mage armour',[apply('warded')],'ally',3,'Armour +3 for three rounds; does not stack with better armour.'),(1,'enfeeble','Enfeebling ray',[save('fortitude',op('sum',c(11),mod('INT')),[apply('weakened')])],'creature',5,'Fortitude resists attack and damage −2 for three rounds.'),(2,'scorching-ray','Scorching ray',[dmg(die('2d6',2),'fire')],'creature',6,'Two dice of fire damage; a tier-two slot.'),(2,'haste-spell','Haste',[apply('haste')],'ally',4,'Movement +2 and attack +1 for three rounds.'),(3,'lightning','Lightning',[dmg(die('3d6',3),'lightning')],'creature',7,'Three dice of lightning damage; a tier-three slot.')],
'divine':[(1,'cure-wounds','Cure wounds',[heal(die('1d6',3))],'ally',1,'Touch healing, bounded by maximum HP.'),(1,'bless','Bless',[apply('blessed')],'ally',4,'Attack and Will +1 for three rounds.'),(1,'radiance','Radiant strike',[dmg(die('1d6',2),'radiant')],'creature',5,'Divine ranged damage.'),(2,'greater-cure','Greater cure',[heal(die('2d6',4))],'ally',2,'Two-dice healing at short range.'),(2,'prayer','Protective prayer',[apply('barkskin')],'ally',4,'Defence +2 for three rounds.'),(3,'sunburst','Sun lance',[dmg(die('3d6',2),'radiant')],'creature',6,'A powerful divine strike.')],
'nature':[(1,'vine-snare','Vine snare',[save('reflex',op('sum',c(11),mod('WIS')),[apply('entangled')])],'creature',5,'Reflex resists movement and ranged attack −2 for three rounds.'),(1,'nature-cure','Nature cure',[heal(die('1d6',2))],'ally',1,'Touch healing from nature.'),(1,'thorn-dart','Thorn dart',[dmg(die('1d6',1),'physical')],'creature',6,'Ranged physical damage.'),(2,'barkskin-spell','Barkskin',[apply('barkskin')],'ally',3,'Defence +2 for three rounds.'),(2,'storm-bolt','Storm bolt',[dmg(die('2d6',1),'lightning')],'creature',6,'Two-dice lightning damage.'),(3,'roots','Grasping roots',[dmg(die('2d6',2),'physical'),apply('entangled')],'creature',5,'Damage and three-round entanglement.')]
}
for cls,(hd,sp,bab,good,skills,profs,casting,features,desc) in class_specs.items():
 features=list(features)
 cl=lvl(cls)
 ratio=cl if bab==1 else op('floor_divide',op('multiply',cl,c(3 if bab==.75 else 1)),c(4 if bab==.75 else 2))
 saves={s:op('sum',c(2),op('floor_divide',cl,c(2))) if s in good else op('floor_divide',cl,c(3)) for s in ['fortitude','reflex','will']}
 loadout=['unarmed'] if cls=='monk' else ['bow','leathers'] if cls=='ranger' else ['shortblade','leathers'] if cls in ['rogue','bard','barbarian'] else ['staff'] if cls in ['wizard','sorcerer','druid'] else ['shortblade','mail','shield'] if cls in ['fighter','paladin'] else ['staff','mail','shield']
 abilities=[]
 if casting:
  tradition,mode,attr=casting
  family='nature' if cls in ['druid','ranger'] else 'arcane' if tradition=='arcane' else 'divine'
  for tier in [1,2,3]:
   start=1 if tier==1 else 3 if tier==2 else 5
   if cls in ['sorcerer','bard']:start=1 if tier==1 else 4 if tier==2 else 6
   if cls in ['paladin','ranger']:start=4 if tier==1 else 6 if tier==2 else 99
   if start>6:continue
   pool=f'{cls}-slots-{tier}'
   resource(pool,f'{cls.title()} tier {tier} slots',op('max',c(1),op('sum',c(2 if cls=='sorcerer' else 1),op('floor_divide',op('sum',cl,c(-start)),c(2)),op('max',c(0),mod(attr)))))
   p['resources'][-1]['slot_class']=cls;p['resources'][-1]['spell_tier']=tier
   prepared_pools=[]
   for t,id,name,effects,kind,rng,text in spell_lists[family]:
    if t!=tier:continue
    sid=f'{cls}-{id}';fx=copy.deepcopy(effects)
    # Spell DC keys use this class's casting attribute, not a shared generic mage attribute.
    def rewrite(x):
     if isinstance(x,dict):
      if x.get('op')=='save':x['dc']=op('sum',c(10+tier),mod(attr),{'op':'stat','id':'save_dc'})
      if x.get('op')=='modifier' and x.get('id') in ['INT','WIS']:x['id']=attr
      for v in x.values():rewrite(v)
     elif isinstance(x,list):
      for v in x:rewrite(v)
    rewrite(fx)
    if id in ['scorching-ray','storm-bolt','lightning','sunburst']:
     half=copy.deepcopy(fx[0]);half['save_half']=True
     fx=[dict(op='save',save='reflex',dc=op('sum',c(10+tier),mod(attr),{'op':'stat','id':'save_dc'}),on_failure=fx,on_success=[half])]
    ability(sid,name,fx,kind,rng,{pool:1},['spell',mode,f'tier_{tier}'],text)
    p['abilities'][-1]['casting_class']=cls;p['abilities'][-1]['spell_tier']=tier
    if mode=='prepared':
     prepared_pool=f'{cls}-prepared-{id}';resource(prepared_pool,name+' prepared copies',c(0));p['resources'][-1]['prepared_ability']=sid;prepared_pools.append(prepared_pool);p['abilities'][-1]['cost']['resources'][prepared_pool]=1
    p['abilities'][-1]['requirements']={'op':'attribute','id':attr,'min':10+tier}
    abilities.append(sid)
   fid=f'{cls}-casting-{tier}'
   featfeature(fid,f'{mode.title()} {tradition} spells · tier {tier}',abilities=[a for a in abilities if f'tier_{tier}' in next(x for x in p['abilities'] if x['id']==a)['tags']],resources=[pool]+prepared_pools,description=f'{attr} casting; shared tier-{tier} slots. {mode.title()} spell selections are enforced by combat authority.')
   features.append((start,fid))
 p['classes'].append(dict(id=cls,name=cls.title(),max_level=6,requirements=allreq,hp_per_level=max(3,hd//2),skill_points=sp,bab=ratio,saves=saves,casting=cl if casting else c(0),casting_tradition=casting[0] if casting else '',features=[{'at':n,'id':f} for n,f in features],provenance=prov,description=desc,bonus_feat_levels=[2,4,6] if cls=='fighter' else [2,6] if cls=='monk' else [],hit_die=hd,class_skills=skills,proficiencies=profs,spell_mode=casting[1] if casting else '',casting_attribute=casting[2] if casting else '',recommended_equipment=loadout))
# New weapons and actual class-dependent equipment legality.
p['equipment'].append(dict(id='unarmed',name='Unarmed strike',kind='weapon',requirements=allreq,modifiers=[],tags=['melee','unarmed'],reach=1,range=1,damage='1d6',damage_type='physical',provenance=prov))
for e in p['equipment']:
 e['proficiency']='martial' if e['id']=='bow' else 'medium' if e['id']=='mail' else 'light' if e['id']=='leathers' else 'shield' if e['id']=='shield' else 'simple' if e['kind']=='weapon' else ''
# More selectable passive feats with genuine numeric tradeoffs.
for id,name,mods,req in [('toughness','Toughness',[m('HP',3)],allreq),('improved-initiative','Improved initiative',[m('initiative',4)],allreq),('iron-will','Iron will',[m('will',2)],allreq),('great-fortitude','Great fortitude',[m('fortitude',2)],allreq),('lightning-reflexes','Lightning reflexes',[m('reflex',2)],allreq),('weapon-focus','Weapon focus',[m('melee_attack',1)],{'op':'bab','min':1}),('point-blank-shot','Archery training',[m('ranged_attack',1)],allreq)]:
 fid=featfeature(id+'-feature',name,mods)
 p['feats'].append(dict(id=id,name=name,requirements=req,features=[fid],repeatable=False,choice_parameters=[],provenance=prov))
# Familiar ancestry descriptors. Culture remains public world context, never a racial bonus.
p['ancestries']=[]
ancestries=[('human','Human',{},'medium',4,[],{'persuasion':1,'craft':1},'Versatile training: Craft and Persuasion +1. No inherited ability adjustment.'),('dwarf','Dwarf',{'CON':2,'CHA':-2},'medium',3,['darkvision'],{'craft':2},'Constitution +2, Charisma −2. Darkvision; Fortitude +2; movement 3.'),('elf','Elf',{'DEX':2,'CON':-2},'medium',4,['low_light'],{'perception':2},'Dexterity +2, Constitution −2. Low-light vision; Perception +2.'),('halfling','Halfling',{'DEX':2,'STR':-2},'small',3,[],{'stealth':2},'Dexterity +2, Strength −2. Small: attack and Defence +1, Stealth +2, movement 3.'),('gnome','Gnome',{'CON':2,'STR':-2},'small',3,['low_light'],{'craft':2},'Constitution +2, Strength −2. Small: attack and Defence +1, Craft +2; movement 3.'),('half-elf','Half-elf',{'CHA':2},'medium',4,['low_light'],{'persuasion':2},'Charisma +2; low-light vision and Persuasion +2.'),('half-orc','Half-orc',{'STR':2,'INT':-2,'CHA':-2},'medium',4,['darkvision'],{'athletics':2},'Strength +2, Intelligence −2, Charisma −2. Darkvision and Athletics +2.')]
for id,name,attrs,size,stride,senses,skills,desc in ancestries:
 modifiers=[m('stride',stride-4,'untyped')] if stride!=4 else []
 if size=='small':modifiers += [m('defence',1,'untyped'),m('melee_attack',1,'untyped'),m('ranged_attack',1,'untyped')]
 if id=='dwarf':modifiers += [m('fortitude',2,'untyped')]
 for variant in ['', '-hill' if id=='dwarf' else '-woodland' if id=='elf' else '-stout' if id=='halfling' else None]:
  if variant is None:continue
  fid=featfeature('ancestry-'+id+(variant or '-base'),name+' inherited traits',senses=senses,description=desc)
  vm=copy.deepcopy(modifiers)
  if variant:vm.append(m('HP',2,'untyped') if id in ['dwarf','halfling'] else m('initiative',1,'untyped'))
  p['ancestries'].append(dict(id='heritage-'+id+variant,people_id=id,tags=[id,size],features=[fid],modifiers=vm,provenance=prov,name=name+(variant.replace('-',' ').title() if variant else ' Standard'),description=desc+(' Heritage adds '+('HP +2.' if id in ['dwarf','halfling'] else 'Initiative +1.') if variant else ''),attribute_adjustments=attrs,size=size,skill_bonuses=skills,body_plan='humanoid'))
# Role guidance remains internal only; creator class choice has its own recommendations.
for role,cls in [('vanguard','fighter'),('scout','ranger'),('adept','wizard'),('expert','rogue')]:
 r=p['role_recommendations'][role];r['class']=cls;r['feat']='toughness';r['equipment']=next(x for x in p['classes'] if x['id']==cls)['recommended_equipment']
for feature in p['features']:
 if feature['id'] in ['monk-evasion','rogue-evasion']:
  feature['tags'].append('evasion');feature['name']='Evasion';feature['description']='A successful Reflex save against a spell offering half damage prevents all damage. Reflex +2.'
 if feature['id']=='sorcerer-blood':
  for modifier in feature['modifiers']:modifier['type']='untyped'
 if feature['id']=='weapon-focus-feature':
  for modifier in feature['modifiers']:modifier['type']='untyped'
for cls in p['classes']:
 for sid in {'wizard':['spellcraft'],'sorcerer':['spellcraft'],'bard':['spellcraft','acrobatics'],'cleric':['religion'],'druid':['animal-handling'],'ranger':['animal-handling'],'rogue':['acrobatics'],'monk':['acrobatics']}.get(cls['id'],[]):
  if sid not in cls['class_skills']:cls['class_skills'].append(sid)
p['rules']['base_abilities']=['attack','move','departure-attack']
(root/'data/rules/trhgd-character-v4.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
manifest=json.loads((root/'data/rules/packs.json').read_text());manifest['packs']=[r for r in manifest['packs'] if r['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k] for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs'].append({'path':'res://data/rules/trhgd-character-v4.json','rules_ref':pin});(root/'data/rules/packs.json').write_text(json.dumps(manifest,indent=2)+'\n')
