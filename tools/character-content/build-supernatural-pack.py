"""Append GAME-148 original v21 adaptations; never rewrite accepted packs."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
p=copy.deepcopy(json.loads((root/'data/rules/trhgd-character-v20.json').read_text(encoding='utf-8')))
p.update(pack_id='trhgd-character-v21',rules_version='21.0.0');p['provenance']['revision']='game148-supernatural-signatures'
provenance=dict(origin='Original bounded TRHGD mechanics and prose; research concepts are references, not copied sourcebook rules',license='Original project-authored content',revision='game148-supernatural-signatures')
def row(cat,id):return next(x for x in p[cat]if x['id']==id)
def const(n):return dict(op='const',value=n)
def level(cls):return dict(op='class_level',id=cls)
def half(cls):return dict(op='floor_divide',args=[level(cls),const(2)])
def total(*xs):return dict(op='sum',args=list(xs))
def dc(cls,attr):return total(const(10),half(cls),dict(op='modifier',id=attr),dict(op='stat',id='save_dc'))
def status(id):return dict(op='apply_status',id=id)
def damage(amount,type,save_half=False):
 d=dict(op='damage',amount=copy.deepcopy(amount),damage_type=type)
 if save_half:d['save_half']=True
 return d
def save(kind,formula,failure,success=None):return dict(op='save',save=kind,dc=formula,on_failure=failure,on_success=success or [])
def feature(id,name,ability,description):
 f=dict(id=id,name=name,abilities=[ability],resources=[],modifiers=[],tags=[],senses=[],hooks=[],grants=[],description=description,provenance=provenance)
 p['features'].append(f);return f
# Warlock: existing selection becomes genuine action-level control versus utility.
a=row('abilities','warlock-invocation-assault');a.update(name='Binding utterance',targeting=dict(kind='creature',range=5,radius=0),effects=[save('will',dc('warlock','CHA'),[status('slowed')])],description='At will; one main action, enemy within5 and clear sight. Will save negates Slowed (-2 stride until its activation ends). No damage, spell slot or point cost. Only the selected Binding invocation is available.')
a=row('abilities','warlock-invocation-ward');a.update(name='Dusk veil',effects=[status('beguiling-veil'),dict(op='remove_status',id='weakened')],description='At will; one main action on self. Clear Weakened and gain25% weapon concealment for3 global round starts; refreshing never stacks concealment. No healing or finite pool. Only the selected Ward invocation is available.')
for id,label in [('assault','Binding invocation'),('ward','Ward invocation')]:
 f=row('features','warlock-discipline-'+id);f['name']=label;f['description']=row('abilities','warlock-invocation-'+id)['description']+' The selected persistent training bonus remains +2 '+('save DC.'if id=='assault'else'Defence.')
 o=next(x for x in row('classes','warlock')['career_choices'][0]['options']if x['id']==id);o['name']=label;o['description']=f['description']
for at in [13,16,20]:
 a=row('abilities','warlock-master-'+str(at));amount=a['effects'][0]['amount']
 a['effects']=[save('reflex',dc('warlock','CHA'),[damage(amount,'arcane'),status('weakened')],[damage(amount,'arcane',True)])]
 a['description']='At will; main action, enemy range5/clear sight. Reflex save halves arcane damage and prevents Weakened (-2 melee accuracy/weapon damage for3 global starts). Evasion and condition immunity apply. No spell slot or point pool.'
a=copy.deepcopy(row('abilities','warlock-invocation-assault'));a.update(id='warlock-career-pressure',name='Dread pressure',targeting=dict(kind='creature',range=4,radius=1),effects=[save('will',dc('warlock','CHA'),[status('mind-tether')])],description='Selected level16 Pressure invocation; at-will main action. Enemy-centred radius1 within4/clear sight; each living enemy saves Will separately or suffers -2 stride and Will for2 global starts. No damage or finite pool; area respects sight from its centre.',provenance=provenance);p['abilities'].append(a)
f=row('features','warlock-career-precision');f.update(name='Dread pressure',modifiers=[],abilities=[a['id']],description=a['description'])
for o in row('classes','warlock')['career_choices'][1]['options']:
 if o['id']=='pressure':o['name']='Dread pressure';o['description']=a['description']
row('classes','warlock')['description']='Action-limited at-will eldritch blasts and a permanent control-versus-veil invocation choice. Later choose resilient recovery or enemy-area Dread pressure. No spell slots or power points; saves and immunities provide counterplay.'
# Binder: permanent covenant is an actual offensive versus ally-protection role.
a=row('abilities','binder-embers');amount=total(const(2),level('binder'))
a.update(effects=[save('reflex',dc('binder','CHA'),[damage(amount,'fire'),status('off-balance')],[damage(amount,'fire',True)])],description='Embers covenant only; main action and1 rest-limited commitment. Enemy range5/clear sight:2 + Binder level fire damage. Reflex halves damage and prevents Off Balance (-2 Defence for2 global starts). Fire resistance/Evasion apply; other class levels do not increase damage.')
a=row('abilities','binder-sentinel');a.update(name='Covenant intercession',targeting=dict(kind='ally',range=3,radius=0),effects=[status('guarding'),dict(op='temporary_hp',amount=total(const(2),level('binder'))),dict(op='remove_status',id='weakened')],description='Sentinel covenant only; main action and1 rest-limited commitment. Ally or self within3/clear sight: clear Weakened, gain nonstacking temporary HP2 + Binder level, and Guarding until the next global start. Guarding spends the recipient\'s shared reaction to reduce an adjacent ally\'s incoming weapon hit by4; not an automatic shield for its own recipient. No forced AI target.')
for id in ['embers','sentinel']:
 f=row('features','binder-'+id+'-pact');f['description']=row('abilities','binder-'+id)['description']
 o=next(x for x in row('classes','binder')['career_choices'][0]['options']if x['id']==id);o['description']=f['description']
row('classes','binder')['description']='One durable Embers offence or Sentinel ally-protection covenant; actions spend a rest-limited commitment pool and scale with Binder level. Shared shelter, later spirit/form and master alternatives remain. No daily rebinding or external pact-world system is claimed.'
# Dragonfire: original repeatable elemental burst remains; one real shape choice.
p['statuses'].append(dict(id='breath-recovering',tags=['breath_recovering'],duration=dict(type='round',amount=2,expiry='global_round_start'),stacking='refresh',modifiers=[],effects=[],provenance=provenance))
options=[]
for element in ['fire','cold','electricity']:
 for shape in ['focused','wide']:
  a=copy.deepcopy(row('abilities','dragon-breath-'+element));a['id']='dragon-'+shape+'-'+element;a['name']=element.capitalize()+' '+('lance'if shape=='focused'else'wide breath');a['provenance']=provenance
  if shape=='focused':
   amount=dict(dice='2d6',bonus=half('dragonfire-adept'));a['targeting']=dict(kind='creature',range=6,radius=0)
   a['requirements']=dict(op='all',args=[dict(op='class_level',id='dragonfire-adept',min=6),dict(op='not',arg=dict(op='tag',id='breath_recovering'))])
   a['effects']=[save('reflex',dc('dragonfire-adept','CON'),[damage(amount,element)],[damage(amount,element,True)]),dict(status('breath-recovering'),recipient='actor')]
   a['description']=f'Selected level6 focused {element} breath; main action, single enemy range6/clear sight.2d6 + half adept level {element} damage; Reflex halves/Evasion applies. No finite pool, but starts recovery on hit or save: unavailable until2 global round starts pass. Basic breath remains available. Not a weapon attack or cone.'
  else:
   a['targeting']=dict(kind='creature',range=3,radius=2);a['cost']['resources']={'draconic-resolve':1}
   a['requirements']=dict(op='class_level',id='dragonfire-adept',min=6)
   a['description']=f'Selected level6 wide {element} breath; main action and1 rest-limited invocation resolve.1d6 + half adept level {element} damage, Reflex halves/Evasion applies, each enemy saves separately. Legal enemy centre within3/clear sight; radius2 and clear sight from centre, no friendly fire. Cost paid once for the whole burst. Not a cone.'
  p['abilities'].append(a);fid=a['id']+'-access';feature(fid,a['name'],a['id'],a['description'])
  options.append(dict(id=element+'-'+shape,name=a['name'],description=a['description'],features=[fid],requirements=dict(op='feature',id='draconic-element-'+element)))
row('classes','dragonfire-adept')['career_choices'].append(dict(id='draconic-breath-shape',name='Breath shaping',at=6,options=options))
for at in [6,11,16]:
 a=row('abilities','draconic-ward-'+str(at));a['targeting']=dict(kind='ally',range=3,radius=1 if at>=11 else 0);a['cost']['resources']['draconic-resolve']=2 if at>=11 else 1
 if at==16:a['effects']+=[dict(op='remove_status',id='slowed'),dict(op='remove_status',id='weakened')]
 a['description']=f'Main action/{a["cost"]["resources"]["draconic-resolve"]} rest-limited resolve. Ally centre range3, radius{a["targeting"]["radius"]}, clear sight: +2 insight Defence and fire/cold/electricity resistance3 for3 global starts; nonstacking temporary HP{at+3} + adept level.'+(' Also clear Slowed/Weakened.'if at==16 else'')+' Paid once for all affected allies.'
 a=row('abilities','draconic-veil-'+str(at));a['targeting']=dict(kind='ally'if at>=11 else'self',range=3 if at>=11 else 0,radius=1 if at==16 else 0);a['cost']['resources']['draconic-resolve']=2 if at==16 else 1
 a['effects']+=[dict(op='remove_status',id='slowed'),dict(op='remove_status',id='weakened')]
 a['description']=f'Main action/{a["cost"]["resources"]["draconic-resolve"]} rest-limited resolve. '+('Self'if at==6 else'Ally centre range3/clear sight')+f', radius{a["targeting"]["radius"]}: clear Slowed/Weakened, gain25% weapon concealment for3 global starts and +2 insight stride for2. Refreshes do not stack. Group costs paid once.'
 a=row('abilities','draconic-hindrance-'+str(at));a['targeting']=dict(kind='creature',range=3 if at==16 else 4,radius=2 if at==16 else 1);a['cost']['resources']['draconic-resolve']=2 if at==16 else 1
 if at>=11:a['effects'][0]['on_failure'].append(status('weakened'))
 a['description']=f'Main action/{a["cost"]["resources"]["draconic-resolve"]} rest-limited resolve. Enemy centre range{a["targeting"]["range"]}/clear sight, radius{a["targeting"]["radius"]}; each enemy saves Will or takes{at+3} fire damage and Mind Tether (-2 stride/Will for2 global starts).'+(' Also Weakened (-2 melee/weapon damage for3 starts) on failure.'if at>=11 else'')+' Successful saves negate all effects; fire resistance/condition immunity apply; cost once for the group.'
row('classes','dragonfire-adept')['description']='Repeatable chosen-element enemy-centred burst with resistance; at6 choose a focused range6 breath with2-boundary recovery or finite-resolve radius2 wide breath. Selected later invocations add ally/group wards, concealment/relief and saved enemy-area control. No cones, flight or new elemental ancestry mechanics.'
# The actual career selector reads option prose, not only feature prose.
for group in row('classes','dragonfire-adept')['career_choices']:
 if group['id'].startswith('draconic-invocation-'):
  for option in group['options']:
   owner=row('features',option['features'][0]);option['description']=row('abilities',owner['abilities'][0])['description']
for option in row('classes','warlock')['career_choices'][1]['options']:
 if option['id']=='resilience':option['name']='Resilient recovery';option['description']=row('abilities','warlock-career-recovery')['description']+' At will, no finite pool.'
for option in row('classes','binder')['career_choices'][1]['options']:
 option['description']=row('abilities','binder-master-ward')['description'] if option['id']=='recovery'else'Persistent +2 training Defence; normal strongest-of-type stacking applies. No active action or commitment cost.'
# Owning feature prose must agree with the executable action, not an old template.
changed={'warlock-invocation-assault','warlock-invocation-ward','binder-embers','binder-sentinel'}
changed.update('warlock-master-'+str(n)for n in [13,16,20]);changed.update('draconic-'+k+'-'+str(n)for k in ['ward','veil','hindrance']for n in [6,11,16])
for f in p['features']:
 owned=[row('abilities',id)for id in f.get('abilities',[])if id in changed]
 if owned:f['description']=' '.join(a['description']for a in owned)
path=root/'data/rules/trhgd-character-v21.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';m=json.loads(mp.read_text(encoding='utf-8'));m['packs']=[x for x in m['packs']if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)];mp.write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8',newline='\n');print(json.dumps(pin))
