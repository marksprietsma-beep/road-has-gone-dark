"""Original bounded TRHGD mechanics; never edits an installed historical pack."""
from pathlib import Path
import copy,json
ROOT=Path(__file__).resolve().parents[2]
p=json.loads((ROOT/'data/rules/trhgd-character-v6.json').read_text())
p.update(pack_id='trhgd-character-v7',rules_version='7.0.0')
prov={'origin':'Original TRHGD career mechanics inspired by generic d20 archetypes; no sourcebook prose or setting text copied','license':'Original project-authored content','revision':'game119-career-1'}
def c(n):return {'op':'const','value':n}
def cl(k):return {'op':'class_level','id':k}
def total(*args):return {'op':'sum','args':list(args)}
def mult(a,b):return {'op':'multiply','args':[a,b]}
def div(a,n):return {'op':'floor_divide','args':[a,c(n)]}
def req(*args):return {'op':'all','args':list(args)}
def need(op,id,n=None):return dict(op=op,**({'id':id} if id else {}),**({'min':n} if n is not None else {}))
def mod(stat,n,typ='training'):return {'stat':stat,'type':typ,'value':c(n) if isinstance(n,int) else n}
def feature(id,name,abilities=[],resources=[],modifiers=[],tags=[],description=''):
 r=dict(id=id,name=name,abilities=abilities,resources=resources,modifiers=modifiers,tags=tags,senses=[],hooks=[],grants=[],provenance=prov,description=description);p['features'].append(r);return id

def status(id,mods,rounds=3,tags=[]):
 p['statuses'].append(dict(id=id,tags=tags,duration={'type':'round','expiry':'global_round_start','amount':rounds},stacking='refresh',modifiers=mods,effects=[],provenance=prov));return id

def resource(id,capacity):p['resources'].append(dict(id=id,name=id.replace('-',' ').title(),capacity=capacity,refresh='eligible_rest',provenance=prov));return id

def power(id,name,kind,effects,cost=None,range=1,radius=0,tags=[],requirements=None):
 if kind=='allies':kind='ally';range=0
 r=dict(id=id,name=name,cost={'main':1,'move':0,'reaction':0,'resources':cost or {}},effects=effects,tags=tags,timing={'kind':'instant'},requirements=requirements or req(),targeting={'kind':kind,'range':range,'radius':radius},provenance=prov,description=name+' · main action; '+(', '.join(k.replace('-',' ')+' × '+str(v) for k,v in (cost or {}).items()) or 'no resource cost')+'; '+effects_text(effects))
 p['abilities'].append(r);return id

def heal(n):return {'op':'heal','amount':n}
def apply(s,actor=False):return dict(op='apply_status',id=s,**({'recipient':'actor'} if actor else {}))
def formula_text(node):
 if node['op']=='const':return str(node['value'])
 if node['op'] in ['class_level','casting_level']:return node['id'].replace('-',' ').title()+(' casting level' if node['op']=='casting_level' else ' level')
 if node['op']=='multiply':return ' × '.join(formula_text(a) for a in node['args'])
 if node['op']=='sum':return ' + '.join(formula_text(a) for a in node['args'])
 return node['op'].replace('_',' ')
def effects_text(effects):
 words=[]
 for e in effects:
  if e['op']=='apply_status':words.append('apply '+e['id'].replace('-',' ')+(' to self' if e.get('recipient')=='actor' else ''))
  elif e['op']=='remove_status':words.append('remove '+e['id'].replace('-',' '))
  elif e['op'] in ['heal','temporary_hp']:words.append(('heal ' if e['op']=='heal' else 'temporary HP ')+formula_text(e['amount']))
  elif e['op']=='restore_resource':words.append('restore '+formula_text(e['amount'])+' '+e['id'].replace('-',' '))
  elif e['op']=='save':words.append(e['save'].title()+' save: '+effects_text(e['on_failure'])+'; resisted: '+effects_text(e.get('on_success',[])))
  elif e['op']=='damage':words.append(e['amount'].get('dice','')+' + '+formula_text(e['amount'].get('bonus',c(0)))+' '+e['damage_type']+' damage'+(' (half)' if e.get('save_half') else ''))
 return '; '.join(words) or 'no further effect'
def saved(dice,bonus,attr='INT',tier=1,extra=[]):
 amount={'dice':dice,'bonus':c(bonus)};damage={'op':'damage','amount':amount,'damage_type':'arcane'}
 return {'op':'save','save':'reflex','dc':total(c(10+tier),{'op':'modifier','id':attr},{'op':'stat','id':'save_dc'}),'on_failure':[damage]+extra,'on_success':[dict(damage,save_half=True)]}
classes={r['id']:r for r in p['classes']}
for r in classes.values():
 r['max_level']=12;r['career_choices']=[];r['class_kind']='base'
 if r['id']=='fighter':r['bonus_feat_levels']=[2,4,6,8,10,12]
 if r['id']=='monk':r['bonus_feat_levels']=[2,6,10]
 if r['id']=='sorcerer':r['known_spell_limits']=[0,2,2,3,3,4,4,5,6,6,7,7,8]
# Casting tier features are the only base features advanced by hybrid careers.
for r in p['features']:
 if '-casting-' in r['id']:r['tags'].append('casting_tier')
def effective(node):
 if isinstance(node,dict):
  if node.get('op')=='class_level':node['op']='casting_level'
  for v in node.values():effective(v)
 elif isinstance(node,list):
  for v in node:effective(v)
for r in p['resources']:
 if r.get('slot_class'):effective(r['capacity'])
# Spell expansions include control/healing as well as saved damage.
for cls,tiers in [('wizard',[(5,9),(6,11)]),('sorcerer',[(5,10),(6,12)]),('cleric',[(5,9),(6,11)]),('druid',[(5,9),(6,11)]),('bard',[(4,10)]),('paladin',[(4,11)]),('ranger',[(4,11)])]:
 base=classes[cls];attr=base['casting_attribute'];prepared=base['spell_mode']=='prepared'
 for tier,at in tiers:
  slot=resource(f'{cls}-slots-{tier}',{'op':'max','args':[c(1),total(c(1),div(total({'op':'casting_level','id':cls},c(-at)),2),{'op':'max','args':[c(0),{'op':'modifier','id':attr}]})]})
  p['resources'][-1].update(slot_class=cls,spell_tier=tier)
  ids=[];pools=[slot]
  for variant in ['control','restoration']:
   id=f'{cls}-tier{tier}-{variant}';cost={slot:1}
   if prepared:
    pool=resource(f'{id}-copies',c(0));p['resources'][-1]['prepared_ability']=id;cost[pool]=1;pools.append(pool)
   if variant=='control':
    st=status(id+'-status',[mod('stride',-2,'condition'),mod('defence',-2,'condition')],2)
    effect=[saved(f'{tier}d6',tier,attr,tier,[apply(st)])];kind='creature';name=f'{base["name"]}: binding tempest {tier}'
   else:
    kind='ally';name=f'{base["name"]}: restorative aegis {tier}'
    st=status(id+'-status',[mod('defence',tier,'training'),mod('will',tier,'training')],3)
    effect=[heal(total(c(2*tier),{'op':'casting_level','id':cls})),apply(st),{'op':'remove_status','id':'slowed'}]
   power(id,name,kind,effect,cost,6,tags=['spell','prepared' if prepared else 'spontaneous',f'tier_{tier}'],requirements=need('attribute',attr,10+tier))
   p['abilities'][-1].update(casting_class=cls,spell_tier=tier);ids.append(id)
  f=feature(f'{cls}-casting-{tier}',f'{base["name"]} tier {tier}',ids,pools,tags=['casting_tier'],description=f'Class {at}: real tier slots and prepared copies / known selections; save/control and restorative ward spells.')
  base['features'].append({'at':at,'id':f})
# Deliberate specialisations, two different actionable options for each class.
choices={
'barbarian':('Rage power',[('reckless','Reckless assault','self',[mod('melee_attack',3),mod('damage',3),mod('defence',-2,'condition')]),('resilient','Resilient rage','self',[mod('fortitude',4),mod('defence',2)])],'rage-uses'),
'bard':('Performance tradition',[('dirge','Disheartening dirge','creature',[mod('melee_attack',-2,'condition'),mod('will',-2,'condition')]),('rally','Rallying song','allies',[mod('initiative',2),mod('defence',2)])],'performance'),
'cleric':('Domain',[('healing','Healing domain','ally',[]),('war','War domain','ally',[mod('melee_attack',2),mod('damage',2)])],'channel'),
'druid':('Nature bond',[('growth','Growth bond','ally',[mod('defence',2),mod('fortitude',2)]),('storm','Storm bond','creature',[mod('stride',-2,'condition')])],'nature-bond-uses'),
'fighter':('Weapon discipline',[('blade','Blade discipline','self',[mod('melee_attack',2),mod('defence',1)]),('bow','Bow discipline','self',[mod('ranged_attack',2),mod('damage',1)])],'fighter-resolve'),
'monk':('Ki discipline',[('iron','Iron body','self',[mod('defence',3),mod('fortitude',2)]),('wind','Wind step','self',[mod('stride',2),mod('reflex',2)])],'ki'),
'paladin':('Sacred oath',[('mercy','Merciful oath','ally',[]),('justice','Oath of justice','self',[mod('melee_attack',2),mod('damage',3)])],'lay-hands'),
'ranger':('Combat style',[('archery','Archery style','self',[mod('ranged_attack',2),mod('damage',2)]),('blade','Blade style','self',[mod('melee_attack',2),mod('defence',2)])],'tracker-resolve'),
'rogue':('Rogue talent',[('debilitating','Debilitating trick','creature',[mod('defence',-3,'condition'),mod('melee_attack',-2,'condition')]),('escape','Escape artist','self',[mod('stride',2),mod('defence',2)])],'rogue-talent-uses'),
'sorcerer':('Bloodline',[('draconic','Draconic bloodline','creature',[]),('fey','Fey bloodline','creature',[mod('stride',-2,'condition'),mod('will',-2,'condition')])],'bloodline-uses'),
'wizard':('Arcane school',[('evocation','Evocation school','creature',[]),('abjuration','Abjuration school','ally',[mod('defence',2),mod('will',2)])],'school-uses')}
for cls,(label,options,pool) in choices.items():
 if pool not in [r['id'] for r in p['resources']]:resource(pool,total(c(1),div(cl(cls),3)))
 for at in [1,6]:
  group=dict(id=f'{cls}-choice-{at}',name=label if at==1 else label+' advanced technique',at=at,options=[])
  for key,name,kind,mods in options:
   id=f'{cls}-{key}-{at}';st=status(id+'-status',mods,3) if mods else None
   effects=[apply(st)] if st else []
   if key in ['healing','mercy']:effects=[heal(total(c(4 if at==1 else 8),mult(cl(cls),c(1 if at==1 else 2)))),{'op':'remove_status','id':'slowed'}]
   if key in ['evocation','draconic']:effects=[saved('1d6' if at==1 else '3d6',2,'INT' if cls=='wizard' else 'CHA',at)]
   if cls=='druid' and key=='storm':effects=[saved('1d6' if at==1 else '3d6',0,'WIS',at,[apply(st)])]
   if at==6 and st:effects.append({'op':'temporary_hp','amount':cl(cls),'recipient':'actor'})
   power(id,name+(' mastery' if at==6 else ''),kind,effects,{pool:1},4 if kind!='self' else 0,2 if kind=='allies' else 0)
   f=feature(id+'-feature',name,[id],[pool],description=p['abilities'][-1]['description']+'; '+(' / '.join(m['stat']+' '+formula_text(m['value']) for m in mods) if mods else 'bounded heal or saved spell damage'))
   group['options'].append(dict(id=key,name=name,description=p['features'][-1]['description'],features=[f],requirements=need('feature',f'{cls}-{key}-1-feature') if at==6 and cls in ['wizard','sorcerer'] else req()))
  classes[cls]['career_choices'].append(group)
# Ranger's inherited quarry is now an explicit durable choice, preserving old packs.
classes['ranger']['features']=[x for x in classes['ranger']['features'] if x['id']!='ranger-quarry']
q=[]
for key,name,tag in [('raiders','Humanoid raiders','favoured_raider'),('archers','Hostile archers','quarry_archer')]:
 f=feature('ranger-quarry-'+key,'Favoured enemy: '+name,['aimed-shot'],tags=[tag],description='+2 attack and damage against '+name.lower()+'. Archer choice only applies to hostile bow wielders.')
 q.append(dict(id=key,name=name,description=p['features'][-1]['description'],features=[f],requirements=req()))
classes['ranger']['career_choices'].append(dict(id='ranger-quarry-choice',name='Favoured enemy',at=1,options=q))
# Every core class receives distinct higher-level actions at 9 and 11.
high={
'barbarian':('rage-uses','self',[{'op':'remove_status','id':'slowed'},{'op':'temporary_hp','amount':mult(cl('barbarian'),c(2))}], 'Unstoppable rage'),
'bard':('performance','allies',[{'op':'remove_status','id':'off-balance'},heal(cl('bard'))],'Song of recovery'),
'cleric':('channel','allies',[heal(mult(cl('cleric'),c(2))),{'op':'remove_status','id':'weakened'}],'Mass restoration'),
'druid':('wildshape','creature',[saved('4d6',3,'WIS',5,[apply('entangled')])],'Grasping storm'),
'fighter':('fighter-resolve','self',[apply('guarding'),heal(cl('fighter'))],'Recovering guard'),
'monk':('ki','creature',[{'op':'save','save':'fortitude','dc':total(c(15),{'op':'modifier','id':'WIS'}),'on_failure':[apply('slowed'),apply('off-balance')],'on_success':[]}],'Disrupting palm'),
'paladin':('smite-uses','allies',[heal(cl('paladin')),{'op':'remove_status','id':'weakened'},apply('oath-shelter')],'Purifying oath'),
'ranger':('tracker-resolve','self',[apply('ranger-steady'),{'op':'remove_status','id':'slowed'}],'Unhindered pursuit'),
'rogue':('rogue-talent-uses','creature',[apply('expert-feint'),apply('weakened')],'Crippling trick'),
'sorcerer':('bloodline-uses','creature',[saved('5d6',4,'CHA',5,[apply('slowed')])],'Bloodline tempest'),
'wizard':('school-uses','ally',[apply('scholar-ward'),{'op':'restore_resource','id':'wizard-slots-1','amount':c(1)}],'Arcane restoration')}
for cls,(pool,kind,effects,name) in high.items():
 for at in [9,11]:
  id=f'{cls}-career-{at}';fx=copy.deepcopy(effects)
  if at==11:
   # Advance the technique into a more costly, distinct recovery/control package.
   if kind in ['self','ally','allies']:fx.append({'op':'temporary_hp','amount':cl(cls)})
   else:fx.append({'op':'remove_status','id':'slowed','recipient':'actor'})
  power(id,name+(' perfected' if at==11 else ''),kind,fx,{pool:2 if at==11 else 1},5 if kind!='self' else 0,2 if kind=='allies' else 0)
  f=feature(id+'-feature',name,[id],[pool],description=p['abilities'][-1]['description'])
  classes[cls]['features'].append({'at':at,'id':f})
# Prestige paths: original five-level playable adaptations, not catalogue completion.
def prestige(id,name,requirements,bab,hp,skills,features):
 base=copy.deepcopy(classes['fighter']);base.update(id=id,name=name,max_level=5,requirements=requirements,bab=bab,hp_per_level=hp,skill_points=4,features=features,bonus_feat_levels=[],career_choices=[],class_kind='prestige',class_skills=skills,spell_mode='',casting_attribute='',casting_tradition='',casting=c(0),description='Prestige path · five playable class levels; durable entry prerequisites; original tactical adaptation.',provenance=prov)
 for save in base['saves']:base['saves'][save]=div(cl(id),3)
 base['proficiencies']=['simple','martial','light'] if id=='duelist' else ['simple','martial','medium','shield'] if id=='eldritch-knight' else ['simple','light'] if id=='arcane-trickster' else ['simple']
 base['saves']['will']=total(c(2),div(cl(id),2))
 p['classes'].append(base);classes[id]=base;return base
for id,name,entry,hp in [
('duelist','Duelist',req(need('bab','',6),need('skill','acrobatics',4),need('feat','dodge'),need('feat','mobility')),5),
('eldritch-knight','Eldritch Knight',req(need('bab','',4),need('casting','arcane',3),need('skill','spellcraft',4),need('feat','weapon-focus')),5),
('arcane-trickster','Arcane Trickster',req(need('casting','arcane',3),need('skill','arcana',4),need('skill','stealth',4),need('feature','rogue-sneak')),3),
('mystic-theurge','Mystic Theurge',req(need('casting','arcane',3),need('casting','divine',3),need('skill','arcana',3),need('skill','insight',3)),3)]:
 pool=resource(id+'-uses',total(c(1),div(cl(id),2)))
 tiers=[]
 for at in [1,3,5]:
  aid=f'{id}-power-{at}'
  if id=='duelist':
   st=status(aid+'-stance',[mod('defence',at+1),mod('melee_attack',2)],2)
   power(aid,'Parrying precision '+str(at),'creature',[apply(st,True)],{pool:1},1,tags=['weapon_strike'],requirements=need('tag','melee'))
  elif id=='eldritch-knight':
   st=status(aid+'-stance',[mod('damage',at+2),mod('defence',2)],2)
   power(aid,'Spellblade surge '+str(at),'creature',[apply(st,True)],{pool:1,'focus':1},1,tags=['weapon_strike'],requirements=need('tag','melee'))
  elif id=='arcane-trickster':power(aid,'Ranged legerdemain '+str(at),'creature',[saved(f'{at+1}d6',at,'INT',at,[apply('off-balance')])],{pool:1},6)
  else:power(aid,'Concordant restoration '+str(at),'allies',[heal(total(c(4*at),cl(id))),apply('warded')],{pool:1},4,2)
  f=feature(aid+'-feature',name+' technique '+str(at),[aid],[pool]+(['focus'] if id=='eldritch-knight' else []),description=p['abilities'][-1]['description'])
  tiers.append({'at':at,'id':f})
 base=prestige(id,name,entry,cl(id) if id in ['duelist','eldritch-knight'] else div(cl(id),2),hp,['acrobatics','stealth'] if id=='duelist' else ['arcana','spellcraft','insight'],tiers)
 if id!='duelist':
  for tradition in (['arcane','divine'] if id=='mystic-theurge' else ['arcane']):
   opts=[]
   for target in ['wizard','sorcerer','bard'] if tradition=='arcane' else ['cleric','druid','paladin','ranger']:
    opts.append(dict(id=target,name=classes[target]['name'],description='Each prestige level advances '+classes[target]['name']+' casting tiers, slots and repertoire; it does not grant unrelated base-class powers.',features=[],requirements=need('class_level',target,1),advance_casting=target,progression_class=id))
   base['career_choices'].append(dict(id=id+'-'+tradition,name='Advance '+tradition+' casting',at=1,options=opts))
# Additional gated feat chains: passive bonuses and an active finite tactical choice.
for id,name,requirements,mods in [
('greater-weapon-focus','Greater weapon focus',req(need('feat','weapon-focus'),need('bab','',8)),[mod('melee_attack',2),mod('ranged_attack',2)]),
('greater-spell-focus','Greater spell focus',req(need('feat','spell-focus'),need('casting','arcane',5)),[mod('save_dc',1,'untyped')]),
('spring-attack','Spring attack',req(need('feat','mobility'),need('bab','',4)),[mod('stride',1),mod('reflex',1)]),
('iron-will','Iron will',req(),[mod('will',2,'untyped')]),
('great-fortitude','Great fortitude',req(),[mod('fortitude',2,'untyped')]),
('lightning-reflexes','Lightning reflexes',req(),[mod('reflex',2,'untyped')]),
('greater-weapon-specialisation','Greater weapon specialisation',req(need('feat','veteran-weapon-training'),need('class_level','fighter',10)),[mod('damage',2,'untyped')])]:
 if any(row['id']==id for row in p['feats']):continue
 f=feature(id+'-feature',name,modifiers=mods,description=' / '.join(m['stat']+' '+str(m['value']['value']) for m in mods))
 p['feats'].append(dict(id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[],provenance=prov))
# Remove obsolete hardcoded descriptions in the newly authored pin only.
classes['ranger']['description']='A skilled tracker with deliberately selected quarry and combat style, later prepared nature magic.'
classes['druid']['description']='A prepared nature caster with a selected bond, bear form and higher control/restoration spells.'
classes['wizard']['description']='An Intelligence-based prepared scholar with a deliberately selected school and limited school powers.'
classes['sorcerer']['description']='A Charisma-based spontaneous caster with permanent known repertoire and a deliberately selected bloodline.'
for cls in classes.values():cls['features'].sort(key=lambda x:(x['at'],x['id']))
(ROOT/'data/rules/trhgd-character-v7.json').write_text(json.dumps(p,indent=2)+'\n')
print('Wrote v7:',len(p['classes']),'classes;',sum(len(c['career_choices']) for c in p['classes']),'choice groups;',len(p['feats']),'feats')
