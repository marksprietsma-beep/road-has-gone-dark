"""GAME-149 bounded original class identity cohort; never rewrites historical packs."""
from pathlib import Path
import json,copy,hashlib
root=Path(__file__).resolve().parents[2];p=json.loads((root/'data/rules/trhgd-character-v21.json').read_text());p['pack_id']='trhgd-character-v22';p['rules_version']='22.0.0'
provenance=dict(origin='Original bounded TRHGD performance, illusion and spirit adaptations; no sourcebook prose copied',license='Original project-authored content',revision='game149-performance-spirit')
def row(kind,id):return next(x for x in p[kind]if x['id']==id)
def const(n):return dict(op='const',value=n)
def status(id):return dict(op='apply_status',id=id)
def remove(id):return dict(op='remove_status',id=id)
def save(attr,tier,effects):return dict(op='save',save='will',dc=dict(op='sum',args=[const(10+tier),dict(op='modifier',id=attr),dict(op='stat',id='save_dc')]),on_failure=effects,on_success=[])
def feature(id,name,ability):
 p['features'].append(dict(id=id,name=name,modifiers=[],abilities=[ability],resources=[],tags=[],senses=[],hooks=[],grants=[],provenance=provenance,description=row('abilities',ability)['description']))
def grant(cls,at,id):row('classes',cls)['features'].append(dict(at=at,id=id))
def spell(id,name,cls,tier,effects,target,description):
 a=copy.deepcopy(row('abilities', 'bard-lightning'if cls=='bard'else'beguiler-beguiling-control-2'));a.update(id=id,name=name,casting_class=cls,spell_tier=tier,effects=effects,targeting=target,description=description,provenance=provenance)
 a['tags']=['spell','spontaneous','tier_'+str(tier)];a['cost']['resources']={cls+'-slots-'+str(tier):1};a['requirements']=dict(op='attribute',id='CHA'if cls=='bard'else'INT',min=10+tier)
 p['abilities'].append(a)
 # Existing tier access, including multiclass and prestige casting, remains authority.
 owner=next(f for f in p['features']if any(row('abilities',x).get('casting_class')==cls and row('abilities',x).get('spell_tier')==tier for x in f['abilities']if any(a['id']==x for a in p['abilities'])))
 owner['abilities'].append(id)
# Rally becomes an existing party-aura projection, with one shared performance group.
for at in [1,6]:
 a=row('abilities',f'bard-rally-{at}');a['tags']=['maintained_performance'];a['targeting']=dict(kind='self',range=0,radius=0);a['effects']=[status(f'bard-rally-{at}-status')]
 a['description']=f'Start a maintained rally: main action and1 performance. Allies within{2 if at==1 else 3} tiles/clear sight gain +{2 if at==1 else 3} training Defence/Will. One rally per bard; strongest typed bonuses do not stack. Each later own activation spends1 performance automatically, leaving its main action for a spell or weapon. Ends on exhaustion, stop, defeat, form or battle end. Switching/restarting costs a new main action and use.'
 s=row('statuses',f'bard-rally-{at}-status');s.update(modifiers=[],duration=dict(type='round',amount=1,expiry='eligible_rest'),stance_group='maintained-performance',upkeep=dict(resource='performance',amount=1),aura=dict(radius=2 if at==1 else 3,modifiers=[dict(stat=stat,type='training',value=const(2 if at==1 else 3))for stat in ['defence','will']]))
 a=row('abilities',f'bard-dirge-{at}');a['effects']=[save('CHA',1 if at==1 else 3,[status(f'bard-dirge-{at}-status')])];a['targeting']['radius']=0 if at==1 else 1
 a['description']='Main action and1 performance. Enemy centre range4/clear sight; '+('single enemy'if at==1 else'radius1 enemies, each saves separately')+'. Will negates -2 melee attack/Will for3 global starts. No damage or automatic hit. This short dirge is not a maintained ally rally.'
stop=copy.deepcopy(row('abilities','bard-rally-1'));stop.update(id='bard-stop-performance',name='Stop performance (free)',effects=[remove('bard-rally-1-status'),remove('bard-rally-6-status')],description='On your activation, end your maintained rally without spending an action or performance. No resource recovery.',provenance=provenance);stop['tags']=[];stop['cost']=dict(main=0,move=0,reaction=0,resources={});p['abilities'].append(stop);feature('bard-stop-performance-access',stop['name'],stop['id']);grant('bard',1,'bard-stop-performance-access')
spell('bard-unbinding-refrain','Unbinding refrain','bard',3,[remove(x)for x in ['slowed','weakened','off-balance','mind-tether']],dict(kind='ally',range=4,radius=1),'Known tier3/CHA13; main action and one tier3 slot. Ally centre range4/clear sight, radius1 allies clear Slowed, Weakened, Off Balance and Mind Tether. No healing, damage or resource recovery. Distinct from Lightning. A maintained rally may continue on later turns, but starting one competes for this main action.')
# Counter concealment through a real saved spell, not a fictional reveal/world system.
illusions=[s['id']for s in p['statuses']if s.get('capabilities',{}).get('concealment',0)>0]
spell('beguiler-unmasking-chime','Unmasking chime','beguiler',2,[save('INT',2,[remove(x)for x in illusions])],dict(kind='creature',range=4,radius=0),'Known tier2/INT12; main action and one tier2 slot. Enemy range4/clear sight; Will negates removal of the supported status-based concealment veils. No damage and no weapon concealment roll. Does not remove permanent ancestry concealment or unrelated buffs. Subsequent weapon attacks still use normal accuracy.')
a=row('abilities','beguiler-beguiling-control-7');a['effects'][0]['on_failure']=[e for e in a['effects'][0]['on_failure']if e.get('id')!='warded']+[remove(x)for x in illusions];a['description']='Known tier7/INT17; main action and one tier7 slot. Enemy centre range6/clear sight, radius1; each enemy saves Will independently. Failure applies Prismatic Fracture and removes supported status concealment. Success negates. Never grants the enemy Warded; no damage or general anti-magic.'
# Choices must explain actual mechanics instead of an internal feature ID.
for c in ['bard','spirit-shaman']:
 for group in row('classes',c)['career_choices']:
  for option in group['options']:
   acts=[row('abilities',aid)for fid in option['features']for aid in row('features',fid)['abilities']]
   if acts:option['description']=' '.join(x['description']for x in acts)
for f in p['features']:
 if any(x.startswith('bard-rally-') or x.startswith('bard-dirge-')for x in f['abilities']):f['description']=' '.join(row('abilities',x).get('description','')for x in f['abilities'])
row('classes','bard')['description']='Spontaneous Charisma caster and finite performer. Start a maintained ally rally or use a saved short enemy dirge; an ongoing rally spends performance each own activation while later main actions remain available. Tier3 offers condition relief as well as lightning. No musical AI or sourcebook-wide performance system.'
row('classes','beguiler')['description']='Intelligence-based spontaneous illusion/control caster. Known spells are permanent; saved hostile control and status-concealment removal differ from allied veils. Late Prismatic Doubt never wards an enemy. Actual saves, condition immunity and finite slots apply; no world illusion simulation.'
path=root/'data/rules/trhgd-character-v22.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest();mp=root/'data/rules/packs.json';m=json.loads(mp.read_text());m['packs']=[x for x in m['packs']if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)];mp.write_text(json.dumps(m,indent=2)+'\n');print(json.dumps(pin))
