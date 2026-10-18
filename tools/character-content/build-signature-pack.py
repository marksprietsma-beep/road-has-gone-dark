"""GAME-129 original bounded signatures; append v19, never rewrite accepted packs."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2];old=json.loads((root/'data/rules/trhgd-character-v18.json').read_text());p=copy.deepcopy(old)
p.update(pack_id='trhgd-character-v19',rules_version='19.0.0');p['provenance']['revision']='game129-class-signatures'
prov=dict(origin='Original TRHGD tactical class adaptations; no sourcebook prose or tables copied',license='Original project-authored content',revision='game129-class-signatures')
def c(n):return dict(op='const',value=n)
def cl(id):return dict(op='class_level',id=id)
def add(*args):return dict(op='sum',args=list(args))
def div(a,n):return dict(op='floor_divide',args=[a,c(n)])
def mod(stat,n):return dict(stat=stat,type='insight',value=n if isinstance(n,dict)else c(n))
def table(k,id):return next(x for x in p[k]if x['id']==id)
def own(e):return dict(e,recipient='actor')
def apply(id):return dict(op='apply_status',id=id)
def status(id,mods=None,**kw):
 row=dict(id=id,tags=[],duration=dict(type='round',amount=3,expiry='global_round_start'),stacking='refresh',modifiers=mods or [],effects=[],provenance=prov);row.update(kw);p['statuses'].append(row);return id

def ability(id,name,kind,effects,description,cls,at=1,costs=None,main=1,move=0,**kw):
 row=dict(id=id,name=name,cost=dict(main=main,move=move,reaction=0,resources=costs or{}),effects=effects,tags=[],timing=dict(kind='instant'),requirements=dict(op='class_level',id=cls,min=at),targeting=dict(kind=kind,range=0 if kind=='self'else 1,radius=0),description=description,provenance=prov);row.update(kw);p['abilities'].append(row);return id

def feature(id,name,abilities=None,**kw):
 row=dict(id=id,name=name,modifiers=[],abilities=abilities or[],resources=[],tags=[],senses=[],hooks=[],grants=[],description=name,provenance=prov);row.update(kw);p['features'].append(row);return id

def grant(cls,at,id):table('classes',cls)['features'].append(dict(at=at,id=id))
# Manifestation actually selects a weapon independently of held equipment. Forms win.
weapon=copy.deepcopy(table('equipment','unarmed'));weapon.update(id='mind-blade',name='Manifested mind blade',damage='1d8',range=1,tags=['melee'],proficiency='simple',provenance=prov);p['equipment'].append(weapon)
thrown=copy.deepcopy(weapon);thrown.update(id='mind-blade-thrown',name='Hurled mind blade',range=4,tags=['ranged']);p['equipment'].append(thrown)
manifest=table('statuses','soulknife-manifested');manifest.update(weapon_override='mind-blade',modifiers=[mod('damage',add(c(1),div(cl('soulknife'),5))),mod('melee_attack',div(cl('soulknife'),5)),mod('ranged_attack',div(cl('soulknife'),5))],capabilities={'weapon_damage':{'mind-blade':'1d8','mind-blade-thrown':'1d8'}})
table('abilities','soulknife-manifest')['description']='Main action; manifest a real mind blade for three global round boundaries. Overrides the held weapon, never a transformed natural weapon. Enhancement scales every five Soulknife levels; damage dice grow at8/16. Original equipment stays saved.'
for at,dice in [(8,'2d6'),(16,'2d8')]:grant('soulknife',at,feature('mind-blade-growth-'+str(at).zfill(2),'Mind blade growth '+str(at),capabilities={'weapon_damage':{'mind-blade':dice,'mind-blade-thrown':dice}}))
# Highest body/class override wins: status must not reset late dice. Runtime blade
# status only chooses the weapon; permanent growth lives on class features.
manifest.pop('capabilities')
for at in [1,4,8,12]:
 a=table('abilities','soulknife-technique-'+str(at));a.update(effects=[],requires_status='soulknife-manifested',requires_weapon='mind-blade',requires_melee=True,strike_effects=[dict(op='damage',amount=c(2+at//2),damage_type='psychic')],description='Main action; focus cost shown. Requires manifested mind blade and melee. A confirmed hit adds psychic damage; miss/concealment spends the action/focus but produces no charge effect. No lingering weapon-damage bonus.')
for at in [13,16,20]:
 a=table('abilities','soulknife-master-'+str(at));a.update(effects=[],requires_status='soulknife-manifested',requires_weapon='mind-blade',requires_melee=True,strike_effects=[dict(op='damage',amount=div(cl('soulknife'),2),damage_type='psychic'),dict(op='save',save='will',dc=add(c(10),div(cl('soulknife'),2),dict(op='modifier',id='WIS')),on_failure=[apply('weakened'if at==13 else'off-balance')],on_success=[])],description='Main action/two focus. Manifested melee hit deals half Soulknife level psychic damage, then Will negates disruption. No rider or rider save on a missed/concealed strike; ordinary psychic resistance applies.')
aid=ability('soulknife-hurl','Hurl mind blade','creature',[],'Main action/one focus; manifested blade only. One genuine ranged attack within4 and line of sight; threatened ranged penalty and concealment apply. Blade persists; no second melee strike. Psychic rider only on hit.','soulknife',4,{'soulknife-focus':1},tags=['weapon_strike'],attack_weapon='mind-blade-thrown',requires_status='soulknife-manifested',requires_weapon='mind-blade',strike_effects=[dict(op='damage',amount=div(cl('soulknife'),2),damage_type='psychic')]);grant('soulknife',4,feature('soulknife-hurl-feature','Projected mind blade',[aid]))
# A shared stance slot stops multiclass stacking and is actual tactical choice.
for cls,variants in [('warblade',[('pressure',[mod('damage',2),mod('defence',-1)]),('shelter',[mod('defence',2),mod('damage',-1)])]),('swordsage',[('flow',[mod('stride',1)]),('cinder',[mod('damage',1)])])]:
 for name,mods in variants:
  sid=status(cls+'-'+name,mods,stance_group='martial-stance',**({'capabilities':{'concealment':20}}if name=='flow'else{}))
  aid=ability(cls+'-stance-'+name,name.capitalize()+' stance','self',[apply(sid)],'Spend movement, retain main action. Three global round boundaries; replaces every other martial stance, including another class stance. '+('20% weapon concealment/stride+1.'if name=='flow'else'Listed derived modifiers apply to actual weapon combat.'),cls,1,main=0,move=1)
  grant(cls,1,feature(aid+'-feature',name.capitalize()+' stance',[aid]))
# Strikes no longer apply hostile riders before hit resolution.
for cls in ['warblade','crusader','swordsage']:
 for a in p['abilities']:
  if not a['id'].startswith(cls+'-')or 'weapon_strike'not in a['tags']:continue
  a['requires_melee']=True
  if cls=='warblade':
   a['effects']=[own(dict(op='remove_status',id='off-balance'))]if 'master'in a['id']else[]
   a['strike_effects']=[dict(op='remove_status',id='guarding'),dict(op='remove_status',id='warded'),apply('off-balance')]
   a['description']='Main action/readiness shown. Melee hit removes Guarding/Warded and disrupts footing. Miss/concealment cannot strip a ward or apply disruption. Master versions also clear own off-balance before attacking.'
  else:
   a['strike_effects']=a['effects'];a['effects']=[]
   a['description']='Main action/readiness shown; melee only. Listed restoration, protection or disruption occurs only after a confirmed weapon hit, never before accuracy or on concealment/miss. '+('Self restoration/protection does not revive a downed character.'if cls=='crusader'else'Fire riders are separate resistance-tested packets.')
# Explicitly armed, nonrecursive miss counter. Uses the same reaction as guarding
# and leaving-threat attacks. There is no second reaction pool or extra turn.
status('warblade-riposte-ready',duration=dict(type='activation',amount=2,expiry='target_activation_end'))
aid=ability('warblade-arm-riposte','Arm riposte','self',[apply('warblade-riposte-ready')],'Spend movement and one readiness. Until the end of your next activation, your next ordinary incoming melee miss can spend the shared reaction for one melee counterattack. Requires living attacker in reach/LOS. Concealment misses and reaction attacks never trigger; no counter chains.','warblade',4,{'warblade-readiness':1},main=0,move=1)
trigger=ability('warblade-riposte','Riposte reaction','creature',[own(dict(op='remove_status',id='warblade-riposte-ready'))],'Automatically resolves only when explicitly armed and an ordinary incoming melee attack misses. One shared reaction; arm is consumed even if counter misses.','warblade',4,main=0,trigger='melee_miss',requires_status='warblade-riposte-ready',counterattack=True);table('abilities',trigger)['cost']['reaction']=1
grant('warblade',4,feature('warblade-riposte-feature','Armed riposte',[aid,trigger]))
# Crusader regains one bounded readiness on own turn; no random granted manoeuvres.
aid=ability('crusader-renewal','Resolute renewal','self',[dict(op='restore_resource',id='crusader-readiness',amount=c(1))],'Once at the start of your actual activation, recover one readiness up to capacity. No XP or off-turn recovery; this original bounded adaptation has no random grant deck.','crusader',1,main=0,trigger='activation_start');grant('crusader',1,feature('crusader-renewal-feature','Resolute renewal',[aid]))
table('abilities','swordsage-recover')['cost']['move']=1;table('abilities','swordsage-recover')['description']='Meditate: spend main AND movement to restore two readiness, bounded by capacity. No attack or movement this activation. Distinct from Warblade main-only recovery and Crusader automatic renewal.'
# Swordsage exchanges offence for an armed defensive concealment burst on a hit.
status('swordsage-evasion-ready',duration=dict(type='activation',amount=2,expiry='target_activation_end'))
status('swordsage-afterimage',capabilities={'concealment':50},duration=dict(type='round',amount=1,expiry='global_round_start'))
aid=ability('swordsage-arm-afterimage','Arm afterimage','self',[apply('swordsage-evasion-ready')],'Movement/one readiness. A surviving ordinary incoming melee hit may spend your shared reaction to gain50% weapon concealment until next global round. It does not undo the triggering damage. Misses/ranged/reaction hits never trigger.','swordsage',4,{'swordsage-readiness':1},main=0,move=1)
tr=ability('swordsage-afterimage','Afterimage reaction','self',[apply('swordsage-afterimage'),dict(op='remove_status',id='swordsage-evasion-ready')],'Only after a surviving ordinary melee hit while armed. Shared reaction; protects against later weapon attacks, not the triggering hit or spells.','swordsage',4,main=0,trigger='melee_hit',requires_status='swordsage-evasion-ready');table('abilities',tr)['cost']['reaction']=1
grant('swordsage',4,feature('swordsage-afterimage-feature','Armed afterimage',[aid,tr]))
# Existing feats gain conditional consumers; original passive benefits retained.
f=table('features','adamant-stance-feature')
aid=ability('adamant-answer','Adamant answer','self',[dict(op='temporary_hp',amount=c(4))],'While Shelter stance is active, survive an ordinary melee hit to spend your shared reaction for4 nonstacking temporary HP. This does not reduce the triggering hit. Competes with riposte/guard/opportunity.','warblade',4,main=0,trigger='melee_hit',requires_status='warblade-shelter');table('abilities',aid)['cost']['reaction']=1;f['abilities'].append(aid);f['description']='Fortitude+2 training; Shelter stance enables Adamant answer after a surviving melee hit, using the shared reaction.'
f=table('features','martial-recovery-feature');f['description']='Fortitude+1 training. On your own activation, regain one owned focus/readiness per relevant martial class, bounded by capacity. No new resource pools.'
for cls in ['soulknife','warblade','crusader','swordsage']:
 pool=cls+('-focus'if cls=='soulknife'else'-readiness')
 aid=ability('martial-recovery-'+cls,'Trained '+cls+' recovery','self',[dict(op='restore_resource',id=pool,amount=c(1))],'Martial recovery feat: one owned point at actual activation start, bounded by capacity; no manual invocation.',cls,1,main=0,trigger='activation_start');f['abilities'].append(aid)
# Precise conditional feat chain for a manifested hit, not a passive always-on bonus.
aid=ability('mindblade-echo','Mindblade echo','self',[dict(op='temporary_hp',amount=div(cl('soulknife'),2))],'After your ordinary manifested melee hit, spend the shared reaction for half Soulknife level nonstacking temporary HP. Not on ranged, miss, concealment, natural form or reaction attacks. Competes with protection/opportunity.', 'soulknife',8,main=0,trigger='weapon_hit',requires_status='soulknife-manifested');table('abilities',aid)['cost']['reaction']=1
fid=feature('mindblade-echo-feature','Mindblade echo',[aid]);p['feats'].append(dict(id='mindblade-echo',name='Mindblade echo',requirements=dict(op='all',args=[dict(op='class_level',id='soulknife',min=8),dict(op='feat',id='iron-soul')]),features=[fid],repeatable=False,choice_parameters=[],provenance=prov))
for cls in ['soulknife','warblade','crusader','swordsage']:
 table('classes',cls)['description']='Original v19 tactical adaptation: '+{'soulknife':'Actual manifested weapon, scaling dice, hit-confirmed psychic strikes and ranged projection.','warblade':'Exclusive stances, hit-confirmed ward disruption, armed shared-reaction riposte and main-action recovery.','crusader':'Hit-confirmed restorative strikes and bounded automatic readiness at own activation.','swordsage':'Exclusive flow/cinder stances, hit-confirmed disruption/fire, armed afterimage and full-activation meditation.'}[cls]
path=root/'data/rules/trhgd-character-v19.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';m=json.loads(mp.read_text());m['packs']=[r for r in m['packs']if r['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)];mp.write_text(json.dumps(m,indent=2)+'\n')
delta={}
for key in old:
 if old[key]==p[key]:continue
 if isinstance(old[key],list):
  a={x['id']:x for x in old[key]};b={x['id']:x for x in p[key]};delta[key]=dict(added=sorted(b.keys()-a.keys()),removed=sorted(a.keys()-b.keys()),modified=[id for id in a if a[id]!=b[id]])
 else:delta[key]=dict(before=old[key],after=p[key])
(root/'docs/implementation/game129/PACK-DELTA.json').write_text(json.dumps(dict(rules_ref=pin,delta=delta),indent=2)+'\n')
print(json.dumps(pin))
