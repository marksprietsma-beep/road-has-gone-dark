"""Append v12 from immutable v11. Original bounded mechanics, no supplement prose."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v11.json').read_text())
p.update(pack_id='trhgd-character-v12',rules_version='12.0.0')
P={'origin':'Original TRHGD mechanics and prose; research concepts are indexing references only','license':'Original project-authored content','revision':'game112-wave-two'}
p['provenance']=P;p['creatures']=[]
def c(n):return {'op':'const','value':n}
def cl(id):return {'op':'class_level','id':id}
def calc(op,*args):return {'op':op,'args':list(args)}
def add(*args):return calc('sum',*args)
def mul(a,n):return calc('multiply',a,c(n))
def div(a,n):return calc('floor_divide',a,c(n))
def req(*args):return {'op':'all','args':list(args)}
def need(op,id=None,n=None):return dict(op=op,**({'id':id}if id else{}),**({'min':n}if n is not None else{}))
def mod(stat,n,typ='training'):return dict(stat=stat,type=typ,value=c(n)if isinstance(n,int)else n)
def row(category,**kw):
 assert not any(r['id']==kw['id']for r in p[category]),kw['id']
 kw['provenance']=dict(P);p[category].append(kw);return kw['id']
def get(cat,id):return next(r for r in p[cat]if r['id']==id)
def feat(id,name,abilities=None,resources=None,mods=None,tags=None,caps=None,**kw):
 fields=dict(id=id,name=name,modifiers=mods or [],abilities=abilities or [],resources=resources or [],tags=tags or [],senses=[],hooks=[],grants=[],description=name,**kw)
 if caps:fields['capabilities']=caps
 return row('features',**fields)
def pool(id,capacity,refresh='eligible_rest'):return row('resources',id=id,name=id.replace('-',' ').title(),capacity=capacity,refresh=refresh)
def ability(id,name,kind,effects,cost=None,tags=None,description='',reach=1,**kw):return row('abilities',id=id,name=name,cost=dict(main=1,move=0,reaction=0,resources=cost or{}),effects=effects,tags=tags or[],timing={'kind':'instant'},requirements=req(),targeting=dict(kind=kind,range=reach,radius=0),description=description or name,**kw)
def status(id,mods=None,caps=None,turns=3,**kw):
 fields=dict(id=id,tags=[],duration=dict(type='round',amount=turns,expiry='global_round_start'),stacking='refresh',modifiers=mods or[],effects=[],**kw)
 if caps:fields['capabilities']=caps
 return row('statuses',**fields)
def apply(id,own=False):return dict(op='apply_status',id=id,**({'recipient':'actor'}if own else{}))
def damage(n,kind='physical'):return dict(op='damage',amount=c(n)if isinstance(n,int)else n,damage_type=kind)
def tier(cls,at,feature):get('classes',cls)['features'].append(dict(at=at,id=feature))
def choice(cls,id,name,at,options):get('classes',cls)['career_choices'].append(dict(id=id,name=name,at=at,options=options))
def option(id,name,features,requirements=None,description=''):return dict(id=id,name=name,description=description or name,features=features,requirements=requirements or req())
# Non-player creature advancement track. Hidden from creator; no research-class count.
base=copy.deepcopy(get('classes','fighter'))
base.update(id='bond-creature',name='Owned creature',max_level=20,hp_per_level=4,skill_points=1,features=[],career_choices=[],class_kind='companion',bonus_feat_levels=[],class_skills=['athletics','perception'],proficiencies=[],recommended_equipment=[],description='Internal owned actor progression; creature definitions supply anatomy and natural weapons.',provenance=dict(P))
base['bab']=cl('bond-creature');base['saves']={s:div(cl('bond-creature'),2 if s=='fortitude'else 3)for s in ['fortitude','reflex','will']}
p['classes'].append(base)
for id,name,dice,reach in [('nature-bite','Natural bite','1d6',1),('bear-claws','Bear claws','1d10',2),('spirit-slam','Spirit slam','1d8',1),('bull-gore','Horn gore','1d8',2)]:
 row('equipment',id=id,name=name,kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=reach,range=reach,damage=dice,damage_type='physical',proficiency='')
for id,name,attrs,weapon,mods,size in [
 ('wolf','Wolf',dict(STR=14,DEX=15,CON=13,INT=8,WIS=12,CHA=10),'nature-bite',[mod('stride',1),mod('defence',1)],'medium'),
 ('bear','Bear',dict(STR=15,DEX=10,CON=14,INT=8,WIS=13,CHA=12),'bear-claws',[mod('defence',2),mod('reach',1)],'large'),
 ('sentinel-spirit','Sentinel spirit',dict(STR=14,DEX=12,CON=15,INT=8,WIS=13,CHA=10),'spirit-slam',[mod('defence',2)],'medium')]:
 aid=ability(id+'-natural-strike',name+' strike','creature',[],tags=['weapon_strike'],attack_weapon=weapon,reach=2 if size=='large'else 1,description='Natural main-action weapon attack, rolled by GAME-32. No held equipment required.')
 f=feat(id+'-creature-body',name+' body',[aid],mods=mods,caps={'blocked_equipment':['weapon','armor','shield']})
 row('creatures',id=id,name=name,attributes=attrs,feature_id=f,weapon_id=weapon,body_plan='quadruped'if id!='sentinel-spirit'else'spirit-biped',size=size)
# Persistent, selected companion: Druid full class level; Ranger class level minus3.
for cls,at,offset in [('druid',1,0),('ranger',4,-3)]:
 options=[]
 for creature in ['wolf','bear']:
  f=feat(cls+'-'+creature+'-bond',creature.title()+' companion',companion=dict(creature_id=creature,level_class=cls,offset=offset,divisor=1))
  options.append(option(creature,creature.title(),[f],description='Persistent '+creature+'; owns movement/main/reaction, damage and conditions; level '+cls+(' minus3'if offset else'')+'. One nature companion per character.'))
 choice(cls,cls+'-companion', 'Animal companion',at,options)
# Body forms suppress equipment, retain identity, HP/conditions, resources and histories.
for id,name,attrs,weapon,mods,size in [
 ('bear-form','Bear',{'STR':4,'DEX':-2},'bear-claws',[mod('defence',2),mod('reach',1),mod('stride',-1)],'large'),
 ('wolf-form','Wolf',{'STR':2,'DEX':4},'nature-bite',[mod('stride',2),mod('defence',1)],'medium')]:
 f=feat(id+'-body',name+' anatomy',mods=mods)
 body=dict(id=id,body_plan='quadruped',size=size,attributes=attrs,feature_id=f,weapon_id=weapon,suppressed_equipment=['weapon','armor','shield'],art_status='neutral_humanoid_fallback')
 if id=='bear-form':get('statuses',id).update(modifiers=[],body_form=body,provenance=dict(P))
 else:status(id,body_form=body)
get('abilities','wild-shape').update(description='Main action, one Wild Shape use: three global rounds as a large bear. Strength+4, Dexterity−2, reach2, stride−1, claws1d10. Equipment melds; spells suppressed; HP and conditions persist. Humanoid art fallback is labelled.',provenance=dict(P))
wolf=ability('wild-shape-wolf','Wild shape: wolf','self',[apply('wolf-form')],{'wildshape':1},description='Three rounds: Strength+2, Dexterity+4, stride+2; bite1d6. Equipment melds and spells are suppressed; health remains the character’s. Fallback appearance labelled.')
revert=ability('revert-form','Return to original form','self',[{'op':'remove_status','id':'bear-form'},{'op':'remove_status','id':'wolf-form'}],description='Main action, no resource cost; removes body form without healing or removing other conditions.')
get('features','druid-shape')['abilities'] += [wolf,revert]
# Higher Druid defensive techniques also use real body descriptors and can revert.
for at in [13,16,20]:
 st=get('statuses',f'druid-master-{at}-form');st['body_form']=copy.deepcopy(get('statuses','bear-form')['body_form']);st['body_form']['id']=st['id']
 if st.get('capabilities',{}).get('weapon_damage',{}).get('unarmed'):
  st['capabilities']['weapon_damage']['bear-claws']=st['capabilities']['weapon_damage'].pop('unarmed')
 get('abilities','revert-form')['effects'].append(dict(op='remove_status',id=st['id']))
# Prepared temporary summons: actual tier slot + prepared copy, three global rounds.
for cls,attr in [('wizard','INT'),('cleric','WIS'),('druid','WIS')]:
 id=cls+'-summon-sentinel';prepared=cls+'-prepared-summon-sentinel';slot=cls+'-slots-1'
 pool(prepared,c(0));get('resources',prepared)['prepared_ability']=id
 ability(id,'Summon sentinel','self',[dict(op='summon',id='sentinel-spirit',rounds=3)],{slot:1,prepared:1},['spell','prepared','tier_1'],description='Main action, tier-one slot and prepared copy. One sentinel per caster, placed on the first clear adjacent tile; acts after caster, expires after three global round boundaries. Dismissal costs a main action.',reach=0,casting_class=cls,spell_tier=1)
 get('abilities',id)['requirements']=need('attribute',attr,11)
 cast=get('features',cls+'-casting-1');cast['abilities'].append(id);cast['resources'].append(prepared)
# Supporting feats amplify real creature strikes/form statistics through the owned caster.
f=feat('natural-form-training','Natural form training',mods=[mod('melee_attack',1,'circumstance')]);get('features',f)['modifiers'][0]['when']=need('tag','body_transformed')
row('feats',id='natural-form-training',name='Natural form training',requirements=need('feature','druid-shape'),features=[f],repeatable=False,choice_parameters=[])
for st in p['statuses']:
 if st.get('body_form'):st['tags'].append('body_transformed')

# Advance all eight alternative tracks with control/recovery choices at13/16/20.
for cls in ['psion','psychic-warrior','soulknife','warlock','scout','swashbuckler','knight','warblade']:
 get('classes',cls)['max_level']=20
 for at in [13,16,20]:
  id=cls+'-master-'+str(at)
  if cls=='psion':
   fx=[damage(add(c(at),cl(cls)),'psychic'),apply('off-balance')]
   ability(id,'Synaptic disruption '+str(at),'creature',fx,{'psion-points':6},reach=5,description='Spend six psychic points; direct psychic damage plus disrupted footing. Higher level adds a real main-action restoration choice below.')
  elif cls=='warlock':
   fx=[damage(add(c(at//2),cl(cls)),'arcane'),apply('weakened')]
   ability(id,'Sapping invocation '+str(at),'creature',fx,reach=5,description='At-will main action: eldritch damage and weakened attacks; no spell slot or psychic point pool.')
  elif cls in ['knight','scout','swashbuckler']:
   pool_id=cls+'-resolve'
   fx=[apply('weakened'),dict(op='temporary_hp',amount=cl(cls),recipient='actor')]
   if cls=='scout':fx.append(dict(op='remove_status',id='slowed',recipient='actor'))
   if cls=='knight':fx.append(apply('guarding',True))
   ability(id,'Master '+cls+' technique '+str(at),'creature',fx,{pool_id:2},['weapon_strike']if cls!='knight'else[],reach=6 if cls=='scout'else 3 if cls=='knight'else 1,description='Two resolve and main action; attack/control, temporary survival and class-specific movement or adjacent guard consequences.')
  else:
   pool_id={'psychic-warrior':'psychic-warrior-points','soulknife':'soulknife-focus','warblade':'warblade-readiness'}[cls]
   st=status(id+'-stance',[mod('damage',at//3),mod('defence',1 if cls!='warblade'else -1)],turns=1,caps={'resistances':{'physical':2}}if cls=='psychic-warrior'else None)
   ability(id,'Master '+cls+' strike '+str(at),'creature',[apply(st,True),dict(op='remove_status',id='off-balance',recipient='actor')],{pool_id:2},['weapon_strike'],description='Two class resource points: clear disrupted footing, adopt a one-round strike stance and attack. Martial readiness/focus can recover; psychic points require home rest.')
  tier(cls,at,feat(id+'-feature','Class '+str(at)+' '+cls,[id]))
 # Deliberate high-level alternative: escape condition vs restore/ward, not BAB-only.
 recovery=cls+'-career-recovery'
 fx=[dict(op='remove_status',id='slowed'),dict(op='remove_status',id='weakened')]
 fx.append(dict(op='temporary_hp',amount=cl(cls)))
 ability(recovery,'Regain composure','self',fx,description='Main action: shed Slowed/Weakened and gain temporary HP equal to class level; cannot stack temporary HP.')
 f=feat(recovery+'-feature','Resilient career',[recovery])
 offence=feat(cls+'-career-precision','Disciplined pressure',mods=[mod('melee_attack',1),mod('ranged_attack',1)])
 choice(cls,cls+'-career-16','Master career approach',16,[option('resilience','Resilience',[f]),option('pressure','Pressure',[offence])])
# Four coherent original adapters: ready manoeuvres, surge risk and persistent pacts.
for cls,name,hp,skills,attribute,profs in [
 ('crusader','Crusader',5,4,'STR',['simple','martial','light','medium','heavy','shield']),
 ('swordsage','Swordsage',4,6,'DEX',['simple','martial','light']),
 ('wilder','Wilder',3,4,'CHA',['simple','light']),
 ('binder','Binder',4,4,'CHA',['simple','light'])]:
 base=copy.deepcopy(get('classes','fighter'))
 base.update(id=cls,name=name,max_level=20,hp_per_level=hp,skill_points=skills,features=[],career_choices=[],bonus_feat_levels=[],class_skills=['athletics','perception','insight','arcana']if cls!='swordsage'else['acrobatics','stealth','perception','athletics'],proficiencies=profs,recommended_equipment=['shortblade']if 'martial'in profs else['staff'],description=name+' is an original bounded adaptation: '+('selected manoeuvres, two ready charges and a main-action recovery cycle'if cls in ['crusader','swordsage']else 'psychic augmentation with self-weakening surge risk'if cls=='wilder'else 'one persistent covenant, distinct pact powers and limited daily commitments')+'. Levels1–20; not a full sourcebook conversion.',attribute_priority=[attribute]+[x for x in ['CON','DEX','STR','CHA','WIS','INT']if x!=attribute],provenance=dict(P))
 base['bab']=cl(cls)if cls=='crusader'else div(mul(cl(cls),3),4)
 base['saves']={s:add(c(2),div(cl(cls),2))if s==('reflex'if cls=='swordsage'else'will')else div(cl(cls),3)for s in ['fortitude','reflex','will']}
 p['classes'].append(base)
 resource=cls+'-readiness'if cls in ['crusader','swordsage']else cls+'-points'if cls=='wilder'else cls+'-commitments'
 pool(resource,c(2)if cls in ['crusader','swordsage']else add(c(2),mul(cl(cls),2))if cls=='wilder'else add(c(1),div(cl(cls),3)),refresh='encounter'if cls in ['crusader','swordsage']else'eligible_rest')
 if cls in ['crusader','swordsage']:
  recover=ability(cls+'-recover','Recover manoeuvres','self',[dict(op='restore_resource',id=resource,amount=c(2))],description='Main action to restore two readiness; no attack this action. Previously selected manoeuvres remain persistent.')
  tier(cls,1,feat(cls+'-recovery','Manoeuvre readiness',[recover],[resource]))
  stance_options=[]
  for mode in ['guard','pressure']:
   st=feat(cls+'-'+mode+'-stance',mode.title()+' stance',mods=[mod('defence',2)]if mode=='guard'else[mod('damage',2)])
   stance_options.append(option(mode,mode.title(),[st],description='Persistent chosen stance: '+('Defence+2'if mode=='guard'else'Damage+2')+'.'))
  choice(cls,cls+'-stance','Martial stance',1,stance_options)
 for at in [1,4,8,12,16,20]:
  id=cls+'-technique-'+str(at)
  if cls=='crusader':
   fx=[dict(op='heal',amount=calc('max',c(1),div(cl(cls),3)),recipient='actor'),apply('guarding',True)]
   ability(id,'Rallying strike '+str(at),'creature',fx,{resource:1},['weapon_strike'],description='One readiness: restore own health, protect an adjacent ally with shared reaction, then strike; restoration occurs before the attack, even on a miss.')
  elif cls=='swordsage':
   fx=[apply('off-balance')]
   ability(id,'Disrupting cut '+str(at),'creature',fx,{resource:1},['weapon_strike'],description='One readiness: disrupt the target’s footing before a weapon attack. Distinct from Crusader restoration/protection; recover instead of attacking when charges run out.')
  elif cls=='wilder':
   fx=[damage(add(c(at//2+2),cl(cls)),'psychic')]
   ability(id,'Focused psychic impulse '+str(at),'creature',fx,{resource:2},reach=5,description='Spend two psychic points, direct psychic damage. Deliberate surged augmentation below costs more points and weakens the caster; no spell slots.')
  else:
   fx=[dict(op='temporary_hp',amount=add(c(at),cl(cls))),dict(op='remove_status',id='weakened')]
   ability(id,'Covenant shelter '+str(at),'self',fx,{resource:1},description='Spend one daily commitment and a main action: recover from Weakened and gain nonstacking temporary health. Selected pact powers create distinct offence/control.')
  tier(cls,at,feat(id+'-feature',name+' level '+str(at),[id],[resource]))
 if cls=='wilder':
  id=ability('wilder-surge','Volatile psychic surge','creature',[damage(add(c(6),mul(cl(cls),2)),'psychic'),apply('weakened',True)],{resource:4},reach=5,description='Four points: doubled class-level psychic damage+6, but the caster becomes Weakened for the pinned duration. Deterministic risk, no random-free resource gain.')
  tier(cls,1,feat('wilder-surge-feature','Volatile augmentation',[id]))
 if cls=='binder':
  options=[]
  for pact in ['embers','sentinel']:
   effects=[damage(add(c(2),cl(cls)),'fire')]if pact=='embers'else[apply('slowed')]
   id=ability('binder-'+pact,'Pact of '+pact,'creature',effects,{resource:1},reach=5,description='Persistent covenant, one daily commitment and main action; '+('fire damage'if pact=='embers'else'restrict target movement')+'. One covenant may be chosen at class1; original identity survives multiclassing.')
   f=feat('binder-'+pact+'-pact','Covenant: '+pact,[id],tags=['pact_'+pact])
   options.append(option(pact,pact.title(),[f]))
  choice(cls,'binder-pact','Binding covenant',1,options)
 # Master choice supplies a real alternative active technique.
 ward=ability(cls+'-master-ward','Master recovery','self',[dict(op='heal',amount=cl(cls)),dict(op='remove_status',id='slowed')],{resource:1},description='Class16 choice; one owned resource and main action to restore real HP and clear Slowed.')
 choice(cls,cls+'-master-choice','Master technique',16,[option('recovery','Recovery',[feat(cls+'-master-recovery','Master recovery',[ward])]),option('focus','Focused defence',[feat(cls+'-master-defence','Focused defence',mods=[mod('defence',2)])])])
# Real inherited bodies and limited acquired form actions; culture remains unchanged.
for id,name,attrs,size,body,mods,caps in [
 ('centaur','Centaur',{'STR':2,'CON':2,'DEX':-2},'large','centaur',[mod('stride',2),mod('reach',1),mod('defence',-1)],{'blocked_equipment':['armor']}),
 ('minotaur','Minotaur',{'STR':2,'CON':2,'INT':-2},'large','horned-humanoid',[mod('reach',1),mod('defence',-1)],{'resistances':{'physical':2}}),
 ('changeling','Changeling',{'CHA':2,'CON':-2},'medium','humanoid',[],{}),
 ('shifter','Shifter',{'DEX':2,'INT':-2},'medium','furred-humanoid',[mod('stride',1)],{})]:
 features=[]
 if id=='minotaur':
  a=ability('minotaur-gore','Horn gore','creature',[],tags=['weapon_strike'],attack_weapon='bull-gore',reach=2,description='Inherited natural weapon: main-action roll,1d8, reach2; independent of equipped weapon.')
  features=[feat('minotaur-gore-feature','Inherited horns',[a])]
 if id=='shifter':
  pool('shifter-shifts',c(1));a=ability('shifter-shift','Predatory shift','self',[apply('wolf-form')],{'shifter-shifts':1},description='One eligible-rest use; real wolf form for three rounds, melded equipment, no spells; original ancestry preserved.')
  features=[feat('shifter-inheritance','Predatory inheritance',[a,'revert-form'],['shifter-shifts'])]
 if id=='changeling':
  st=status('changeling-adapted',[mod('reflex',2)],turns=3)
  pool('changeling-adaptations',c(1));a=ability('changeling-adapt','Adaptive reflexes','self',[apply(st)],{'changeling-adaptations':1},description='Once per eligible rest; three rounds of Reflex+2. No disguise/social-rule claims; ancestry remains independent of origin/culture.')
  features=[feat('changeling-adaptation','Inherited adaptation',[a],['changeling-adaptations'])]
 row('ancestries',id='heritage-'+id,people_id=id,name=name+' Standard',description=name+' original bounded inherited adaptation. '+('Large body, one tactical cell; special movement is terrestrial only.'if size=='large'else'Inherited ability is shown on sheet; unusual art uses labelled neutral humanoid fallback.'),attribute_adjustments=attrs,size=size,skill_bonuses={'athletics':2}if size=='large'else{},body_plan=body,tags=[id,'humanoid'],features=features,modifiers=mods,capabilities=caps,visual_profile=dict(body_plan=body,size=size,head='horned'if id=='minotaur'else'humanoid',torso='equine'if id=='centaur'else'standard',arms=2,legs=4 if id=='centaur'else 2,optional_features=['horns']if id=='minotaur'else['tail']if id=='centaur'else[],art_status='neutral_humanoid_fallback'))
# New-track tiers add executable mechanics, rather than six renamed tier-one buttons.
for cls in ['crusader','swordsage','wilder','binder']:
 for at in [4,8,12,16,20]:
  a=get('abilities',cls+'-technique-'+str(at))
  if cls=='crusader':
   if at==4:a['effects'].append(dict(op='remove_status',id='weakened',recipient='actor'))
   if at==8:
    st=status('crusader-stone-shelter',caps={'resistances':{'physical':3}},turns=2);a['effects'].append(apply(st,True))
   if at==12:
    a.update(tags=[],targeting=dict(kind='ally',range=3,radius=1),effects=[dict(op='heal',amount=cl(cls)),dict(op='remove_status',id='weakened')]);a['cost']['resources']={cls+'-readiness':2};a['name']='Rally the company'
   if at==16:a['effects'].append(apply('warded',True))
   if at==20:
    a.update(tags=['weapon_strike'],targeting=dict(kind='creature',range=1,radius=1),effects=[damage(cl(cls),'radiant')]);a['cost']['resources']={cls+'-readiness':2};a['name']='Devoted radiance strike'
  elif cls=='swordsage':
   if at==4:a['effects'].append(apply('warded',True))
   if at==8:a['effects'].append(apply('slowed'))
   if at==12:a['effects'].append(damage(div(cl(cls),2),'fire'))
   if at==16:a['effects'] += [dict(op='remove_status',id='slowed',recipient='actor'),dict(op='remove_status',id='weakened',recipient='actor')]
   if at==20:
    st=status('swordsage-shadow-step',caps={'concealment':20},turns=2);a['effects'].append(apply(st,True));a['cost']['resources']={cls+'-readiness':2}
  elif cls=='wilder':
   if at==4:a['effects'].append(dict(op='remove_status',id='weakened',recipient='actor'))
   if at==8:a['effects'].append(dict(op='temporary_hp',amount=cl(cls),recipient='actor'))
   if at==12:a['effects'].append(apply('slowed'))
   if at==16:a['effects'].append(apply('off-balance'))
   if at==20:a['targeting']['radius']=1;a['cost']['resources']={cls+'-points':6}
  else:
   if at==4:a['effects'].append(dict(op='remove_status',id='slowed'))
   if at==8:a['effects'].append(apply('warded'))
   if at==12:a['effects'].append(dict(op='heal',amount=div(cl(cls),2)))
   if at==16:a['effects']=[dict(op='summon',id='sentinel-spirit',rounds=4)];a['cost']['resources']={cls+'-commitments':2};a['name']='Covenant sentinel'
   if at==20:a['effects']=[apply('wolf-form')];a['cost']['resources']={cls+'-commitments':2};a['name']='Covenant metamorphosis';get('features',cls+'-technique-20-feature')['abilities'].append('revert-form')
  a['description']=a['name']+'; main action, '+str(a['cost']['resources'])+'. Actual effects: '+', '.join(e['op']+(' '+e['id']if 'id'in e else'')for e in a['effects'])+'.'
# A selected ready manoeuvre supplements the permanent martial stance.
for cls in ['crusader','swordsage']:
 default=cls+'-technique-8-feature'
 get('classes',cls)['features']=[x for x in get('classes',cls)['features']if x['id']!=default]
 aid=ability(cls+'-measured-renewal','Measured renewal','ally',[dict(op='heal',amount=div(cl(cls),2)),dict(op='remove_status',id='off-balance')],{cls+'-readiness':1},reach=3,description='Chosen class8 manoeuvre. One readiness and main action: heal an ally and restore footing; competes with the offensive manoeuvre choice. Recover readiness instead of striking.')
 f=feat(cls+'-measured-renewal-feature','Measured renewal',[aid])
 choice(cls,cls+'-manoeuvre-8','Ready manoeuvre',8,[option('strike','Offensive technique',[default]),option('renewal','Measured renewal',[f])])

# Two additional source-indexed prestige adapters using the new body/summon authority.
for cls,name,requirements in [
 ('warshaper','Warshaper',req(need('level',n=5),need('bab',n=4),need('feature','druid-shape'))),
 ('bonded-summoner','Bonded Summoner',req(need('level',n=5),need('casting','arcane',3),need('skill','arcana',4)))]:
 base=copy.deepcopy(get('classes','druid'if cls=='warshaper'else'wizard'))
 base.update(id=cls,name=name,max_level=5,requirements=requirements,features=[],career_choices=[],bonus_feat_levels=[],known_spell_limits=[] if False else base.get('known_spell_limits',None),class_kind='prestige',spell_mode='',casting_attribute='',casting_tradition='',casting=c(0),recommended_equipment=['staff'],description='Original five-level '+name+' path: real permanent entry requirements and active creature/form techniques.',provenance=dict(P))
 base.pop('known_spell_limits',None)
 base['bab']=div(mul(cl(cls),3),4);base['saves']={s:div(cl(cls),2)for s in ['fortitude','reflex','will']}
 p['classes'].append(base)
 resource=cls+'-uses';pool(resource,add(c(1),div(cl(cls),2)))
 for at in [1,3,5]:
  id=cls+'-technique-'+str(at)
  if cls=='warshaper':
   st=copy.deepcopy(get('statuses','bear-form'));st.update(id=id+'-form',provenance=dict(P));st['body_form']=copy.deepcopy(st['body_form']);st['body_form']['id']=st['id'];st['body_form']['attributes']['STR']=4+at//2;st['modifiers']=[mod('defence',at//2)];p['statuses'].append(st)
   fx=[apply(st['id'])];get('abilities','revert-form')['effects'].append(dict(op='remove_status',id=st['id']))
  else:fx=[dict(op='summon',id='sentinel-spirit',rounds=3+at)]
  ability(id,name+' technique '+str(at),'self',fx,{resource:1},description='Prestige'+str(at)+': main action, one limited career use; '+('actual strengthened bear body form; may revert without healing.'if cls=='warshaper'else'real owned sentinel, one active per caster, bounded '+str(3+at)+' global rounds.'))
  tier(cls,at,feat(id+'-feature',name+' tier '+str(at),[id,'revert-form']if cls=='warshaper'else[id],[resource]))
# Supporting chains have prerequisites and tangible numerical consequences.
for id,name,requirements,mods in [
 ('martial-recovery','Martial recovery',need('bab',n=4),[mod('fortitude',1)]),
 ('psychic-discipline','Psychic discipline',need('class_level','wilder',3),[mod('will',2)]),
 ('pact-endurance','Pact endurance',need('class_level','binder',3),[mod('HP',4)]),
 ('shape-endurance','Shape endurance',need('feat','natural-form-training'),[mod('fortitude',2)])]:
 f=feat(id+'-feature',name,mods=mods);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])

# Write only appended pack/manifest. Historical JSON bytes are never rewritten.
(root/'data/rules/trhgd-character-v12.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
manifest=json.loads((root/'data/rules/packs.json').read_text());manifest['packs']=[x for x in manifest['packs']if x['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs'].append(dict(path='res://data/rules/trhgd-character-v12.json',rules_ref=pin))
(root/'data/rules/packs.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(pin))
