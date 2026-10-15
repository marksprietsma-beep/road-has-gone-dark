"""Reproducible v14 original adaptations. Read-only baseline v13; no old pack rewrites."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
# Reuse construction helpers without running the v13 builder or touching its manifest.
exec((root/'tools/character-content/build-wave-three-pack.py').read_text().split('# Shared manifesting progression')[0])
p=json.loads((root/'data/rules/trhgd-character-v13.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v14',rules_version='14.0.0')
P={'origin':'Original bounded TRHGD adaptations; research names only, no sourcebook prose or settings copied','license':'Original project-authored content','revision':'game112-wave-four'}
p['provenance']=P
psychics=[x['id'] for x in p['classes'] if 'psychic_profile'in x]
for id,name,template,hp,skills,attr,text in [
 ('erudite','Erudite','psion',4,4,'INT','A broad learned psychic repertoire constrained by distinct powers per eligible rest: 1 + class level/4. Repeated casts and augmentation share the same power identity. Saved across encounters and reloads; only an eligible rest resets the list.'),
 ('divine-mind','Divine Mind','ardent',8,4,'WIS','Armoured psychic support: select a mantle, learn restricted powers and maintain one local aura. Switching auras costs an action and resolve; nearby living allies receive effects only while in range and line of sight.'),
 ('marshal','Marshal','fighter',8,6,'CHA','Martial leadership: select command doctrines, maintain an area aura and spend finite command uses on rally or manoeuvre support. No spell or psychic progression.')]:
 career(id,name,template,hp,skills,attr,text)
 get('classes',id)['class_skills']=['perception','persuasion','insight','arcana'] if id!='erudite'else ['arcana','craft','perception']
 get('classes',id)['proficiencies']=['simple','martial','light','medium','shield']if id!='erudite'else['simple']
 if id=='erudite':get('classes',id)['recommended_equipment']=['staff']
 if id=='marshal':
  get('classes',id)['bab']=cl(id);get('classes',id)['recommended_equipment']=['shortblade','mail','shield']
 if id!='marshal':
  get('classes',id)['psychic_profile']=dict(max_tier=6 if id=='divine-mind'else 9,attribute=attr,points_per_level=1 if id=='divine-mind'else 2,mantle_restricted=id=='divine-mind')
  tier(id,1,'shared-psychic-access');psychics.append(id)
get('classes','erudite')['distinct_power_limit']=add(c(1),div(cl('erudite'),4))
get('resources','psychic-points')['capacity']=add(c(2),*(mul(cl(x),get('classes',x)['psychic_profile']['points_per_level'])for x in psychics))
# Psychic progression groups reuse the same permanent selection validator.
for cls in ['erudite','divine-mind']:
 if cls=='divine-mind':
  group=copy.deepcopy(get('classes','ardent')['career_choices'][0]);group['id']='divine-mind-mantle';get('classes',cls)['career_choices'].append(group)
  for at in [4,8,12]:
   extra=copy.deepcopy(group);extra.update(id='divine-mind-mantle-'+str(at),at=at,name='Additional mantle')
   for opt in extra['options']:opt['requirements']={'op':'not','arg':need('feature',opt['features'][0])}
   get('classes',cls)['career_choices'].append(extra)
 for at in range(1,21):
  opts=[option(x['id'],x['name'],[x['feature_id']],description=x['description'])for x in p['psychic_powers']]
  choice(cls,cls+'-power-'+str(at),'Learn a psychic power',at,opts)
 # Erudite starts with two known powers but can use only one distinct identity per rest.
 if cls=='erudite':choice(cls,'erudite-second-power','Second learned power',1,copy.deepcopy(opts[1:]+opts[:1]))
# Shared maintained auras: one per owner, toggled by ordinary costed statuses.
aura_ids=[]
for cls in ['divine-mind','marshal']:
 pool(cls+'-resolve',add(c(2),div(cl(cls),3)))
 scale=add(c(1),div(cl(cls),5))
 for mode,mods in [('assault',[mod('melee_attack',scale,'insight'),mod('ranged_attack',scale,'insight')]),('bulwark',[mod('defence',scale,'insight'),mod('fortitude',scale,'insight')]),('stride',[mod('stride',1,'insight'),mod('will',scale,'insight')])]:
  id=cls+'-aura-'+mode;aura_ids.append(id)
  status(id,turns=1,aura={'radius':3,'modifiers':mods})
  get('statuses',id)['duration']=dict(type='rest',amount=1,expiry='eligible_rest')
# Switching clears all own auras, including the other support class in a multiclass build.
for cls in ['divine-mind','marshal']:
 options=[]
 for mode in ['assault','bulwark','stride']:
  id=cls+'-aura-'+mode
  effects=[dict(op='remove_status',id=x)for x in aura_ids]+[apply(id)]
  a=ability(id,'Maintain '+mode+' aura','self',effects,{cls+'-resolve':1},['psychic']if cls=='divine-mind'else[],description='Main action and one resolve; replaces your previous aura. Living allies within3 orthogonal tiles and clear line of sight gain '+mode+' support. Scales at5/10/15/20. Ends at rest; downed or transformed source grants nothing. Typed bonuses do not stack with stronger insight effects.')
  options.append(option(mode,mode.title(),[feature(id+'-access',mode.title()+' doctrine',[a])]))
 choice(cls,cls+'-doctrine','Starting aura doctrine',1,options)
 for at in [5,10]:
  choice(cls,cls+'-doctrine-'+str(at),'Additional aura doctrine',at,[dict(x,requirements={'op':'not','arg':need('feature',x['features'][0])})for x in copy.deepcopy(options)])
 tier(cls,1,feature(cls+'-resolve-feature','Resolve reserve',resources=[cls+'-resolve']))
 for at in [2,6,12,16,20]:
  a=ability(cls+'-rally-'+str(at),'Rally '+str(at),'ally',[dict(op='temporary_hp',amount=add(c(at),cl(cls))),dict(op='remove_status',id='off-balance')],{cls+'-resolve':1},description='Main action, one resolve: temporary HP equals class level + milestone; remove off-balance, ally within3.',reach=3)
  tier(cls,at,feature(a+'-feature','Experienced leadership',[a],mods=[mod('will',1+at//8,'insight')]))
# Eight additional learned identities, each with actual point costs/augmentation.
newpowers=[('crystal-shard',1,'energy','damage'),('iron-vigor',1,'body','hp'),('mental-dampening',2,'mind','weaken'),('rallying-thought',2,'unity','support'),('adrenal-response',3,'body','speed'),('synaptic-javelin',4,'energy','damage'),('renewing-concord',5,'unity','heal'),('crystalline-prison',6,'mind','lock')]
for id,t,discipline,mode in newpowers:
 variants=[]
 for aug in [0,2,4,6]:
  cost=2*t-1+aug
  if cost>20:continue
  pid='power-'+id;aid=pid+(''if not aug else'-aug'+str(aug));amount=4*t+2*aug
  fx=[damage(amount,'physical'if id=='crystal-shard'else'psychic')]if mode=='damage'else[dict(op='temporary_hp',amount=c(amount))]if mode=='hp'else[dict(op='heal',amount=c(amount))]if mode=='heal'else[save([apply('weakened'),damage(aug)],'will',t)]if mode=='weaken'else[apply('psychic-unity'),dict(op='temporary_hp',amount=c(amount))]if mode=='support'else[apply('psychic-haste'),dict(op='temporary_hp',amount=c(amount))]if mode=='speed'else[save([apply('psychic-lock'),damage(amount)],'will',t)]
  kind='creature'if mode in ['damage','weaken','lock']else'self'if mode=='speed'else'ally'
  ability(aid,id.replace('-',' ').title()+(f' +{aug}'if aug else''),kind,fx,{'psychic-points':cost},['psychic'],description=f'Tier{t} {discipline}; main action, {cost} points, magnitude{amount}. '+{'damage':'Direct damage.','hp':'Temporary HP.','heal':'Actual healing bounded by maximum HP.','weaken':'Will negates weakened; augmentation adds damage.','support':'Melee/Will+2 for three rounds, plus temporary HP.','speed':'Stride+2 for two rounds plus temporary HP.','lock':'Will negates immobility and damage.'}[mode],reach=5 if kind!='self'else 0,psychic_power=pid,augmentation=aug);variants.append(aid)
 f=feature(pid+'-known',id.replace('-',' ').title(),variants,known_power=pid)
 row('psychic_powers',id=pid,name=id.replace('-',' ').title(),description=get('abilities',variants[0])['description'],tier=t,discipline=discipline,class_ids=psychics,mantle_tags=['mantle_'+discipline],feature_id=f,variants=variants)
# Existing and new learned choices see the same expanded catalogue; old pins untouched.
for power in p['psychic_powers']:power['class_ids']=list(psychics)
for cls in p['classes']:
 for group in cls.get('career_choices',[]):
  if group['options'] and all(any(o['id']==x['id']for x in p['psychic_powers'])for o in group['options']):
   for x in p['psychic_powers']:
    if not any(o['id']==x['id']for o in group['options']):group['options'].append(option(x['id'],x['name'],[x['feature_id']],description=x['description']))
# One earned psychic prestige with deliberate choice and hybrid level progression.
career('cognition-adept','Cognition Adept','erudite',4,4,'INT','Original adaptation of the researched Slayer concept: earned psychic/martial hunter with precise strikes, mental wards and learned powers. Five playable levels.',kind='prestige',cap=5,requirements=req(need('level',n=6),need('attribute','INT',13),need('bab',n=4),need('skill','perception',4),need('feat','psychic-discipline'),need('tag','psychic_manifester')))
get('classes','cognition-adept')['psychic_profile']=dict(max_tier=9,attribute='INT',points_per_level=2,mantle_restricted=False)
get('classes','cognition-adept')['bab']=cl('cognition-adept');tier('cognition-adept',1,'shared-psychic-access');psychics.append('cognition-adept')
for at in range(1,6):
 a=ability('cognition-strike-'+str(at),'Cognition strike '+str(at),'creature',[damage(at*2)],{'psychic-points':at},['psychic','weapon_strike'],description='Main action, '+str(at)+' points: adjacent psychic damage followed by a separately rolled equipped melee attack.',reach=1)
 get('abilities',a)['requirements']=need('tag','melee')
 tier('cognition-adept',at,feature(a+'-feature','Hunter cognition',[a],mods=[mod('will',at,'insight')]))
 choice('cognition-adept','cognition-power-'+str(at),'Learn a psychic power',at,[option(x['id'],x['name'],[x['feature_id']],description=x['description'])for x in p['psychic_powers']])
for power in p['psychic_powers']:power['class_ids']=list(psychics)
get('resources','psychic-points')['capacity']=add(c(2),*(mul(cl(x),get('classes',x)['psychic_profile']['points_per_level'])for x in psychics))
# Mechanical ancestry/body variants, culture remains independent.
for id,name,adjust,size,body,mods,caps,weapon in [
 ('bugbear','Bugbear',{'DEX':2,'STR':2,'CHA':-2},'medium','humanoid',[mod('initiative',2)],{},None),
 ('ogre','Ogre',{'STR':4,'INT':-2,'CHA':-2},'large','heavy-humanoid',[mod('fortitude',1),mod('reach',1)],{},None),
 ('half-giant','Half-giant',{'STR':2,'DEX':-2},'large','heavy-humanoid',[mod('defence',1)],{'resistances':{'fire':2}},None),
 ('troglodyte','Troglodyte',{'STR':2,'CON':2,'INT':-2},'medium','reptilian-humanoid',[mod('defence',2)],{},'boar-tusks')]:
 fs=[]
 if id=='half-giant':
  a=ability('half-giant-stomp','Inherited stomp','creature',[apply('off-balance')],{'inherited-psychic':1},['psychic'],description='Main action, one inherited point: off-balance on one adjacent enemy. Two shared inherited points per home rest; does not qualify as a manifesting class.',reach=1)
  fs=[feature('half-giant-stomp-feature','Giant psychic inheritance',[a],['inherited-psychic'])]
 if weapon:
  a=ability(id+'-natural-bite','Inherited bite','creature',[],tags=['weapon_strike'],attack_weapon=weapon,description='Natural 1d8 physical bite; ordinary melee attack roll, one main action. No aquatic travel claimed.')
  fs=[feature(id+'-bite','Natural bite',[a])]
 descriptions={'bugbear':'A strong, quick humanoid. Strength +2, Dexterity +2, Charisma −2; initiative +2. Medium size.', 'ogre':'A large, powerful humanoid. Strength +4, Intelligence −2, Charisma −2; Fortitude +1 and melee reach +1. Occupies one tactical tile.', 'half-giant':'A massive humanoid with psychic inheritance. Strength +2, Dexterity −2; defence +1 and fire resistance2. Inherited stomp costs one of two points per home rest and leaves one adjacent enemy off balance.', 'troglodyte':'A resilient reptilian humanoid. Strength +2, Constitution +2, Intelligence −2; natural defence +2. An inherited bite makes an ordinary melee attack for1d8 physical damage.'}
 ancestry=copy.deepcopy(get('ancestries','heritage-human'));ancestry.update(id='heritage-'+id,people_id=id,name=name,description=descriptions[id],attribute_adjustments=adjust,size=size,body_plan=body,tags=[id,'humanoid'],features=fs,modifiers=mods,skill_bonuses={},capabilities=caps,visual_profile=dict(body_plan=body,size=size,head=body,torso='standard',arms=2,legs=2,optional_features=['tail']if body!='humanoid'else[],art_status='neutral_humanoid_fallback'),provenance=dict(P));p['ancestries'].append(ancestry)
# Eight real feat choices with permanent prerequisites and supported effects.
for id,name,requirements,mods,caps in [
 ('iron-discipline','Iron discipline',need('feat','psychic-discipline'),[mod('will',2,'insight')],{}),
 ('deep-reserve','Deep reserve',need('feat','expanded-psychic-reserve'),[],{'resource_bonuses':{'psychic-points':c(4)}}),
 ('commanding-presence','Commanding presence',need('class_level','marshal',1),[],{'resource_bonuses':{'marshal-resolve':c(2)}}),
 ('steadfast-mantle','Steadfast mantle',need('class_level','divine-mind',1),[],{'resource_bonuses':{'divine-mind-resolve':c(2)}}),
 ('bugbear-skirmisher','Bugbear skirmisher',need('ancestry','bugbear'),[mod('stride',1),mod('reflex',1)],{}),
 ('ogre-endurance','Ogre endurance',need('ancestry','ogre'),[mod('HP',4)],{}),
 ('natural-ferocity','Natural ferocity',need('feature','troglodyte-bite'),[],{'weapon_damage':{'boar-tusks':'1d10'}}),
 ('bond-veteran','Bond veteran',need('feat','beast-stewardship'),[mod('fortitude',2)],{})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
# Two genuinely different owned actors and a new form using existing entity authority.
for id,name,template,mods,caps in [('thorn-guardian','Thorn guardian','stone-guardian',[mod('defence',2),mod('reach',1)],{'resistances':{'physical':2}}),('ember-spirit','Ember spirit','renewal-spirit',[mod('stride',2)],{'resistances':{'fire':5}})]:
 creature=copy.deepcopy(get('creatures',template));creature.update(id=id,name=name,provenance=dict(P))
 fx=[damage(5,'fire')]if id=='ember-spirit'else[apply('psychic-lock')]
 a=ability(id+'-special',name+' '+('flare'if id=='ember-spirit'else'root'),'creature',fx,{'creature-effort':1},description='Main action, one creature effort: '+('five fire damage within4.'if id=='ember-spirit'else'immobile for one global round within2.'),reach=4 if id=='ember-spirit'else 2)
 f=feature(id+'-body',name+' anatomy',[a],['creature-effort'],mods=mods,caps=caps);creature['feature_id']=f;p['creatures'].append(creature)
 a=ability('call-'+id,'Call '+name,'self',[dict(op='summon',id=id,rounds=3)],{'bonded-summoner-bond':1},description='One bond use and main action; one temporary summon, three rounds.')
 get('abilities',a)['cost']['resources']=copy.deepcopy(get('abilities','bonded-summoner-technique-1')['cost']['resources'])
 tier('bonded-summoner',3 if id=='ember-spirit'else 5,feature(a+'-feature',name+' calling',[a]))
body=copy.deepcopy(get('statuses','leopard-form'));body.update(id='scaled-guardian-form',provenance=dict(P));body['body_form'].update(id='scaled-guardian-form',body_plan='reptilian-quadruped',attributes={'STR':4,'DEX':0},feature_id='scaled-guardian-anatomy',weapon_id='boar-tusks');p['statuses'].append(body)
feature('scaled-guardian-anatomy','Scaled guardian anatomy',mods=[mod('defence',3)],caps={'resistances':{'fire':3}})
a=ability('wild-shape-scaled-guardian','Wild shape: Scaled guardian','self',[apply('scaled-guardian-form')],{'wildshape':1},description='One Wild Shape use, three rounds; STR+4, defence+3, fire resistance3, 1d8 natural bite. Ordinary form suppression/reversion. No swimming claimed.')
tier('druid',8,feature(a+'-feature','Scaled guardian form',[a]));get('abilities','revert-form')['effects'].append(dict(op='remove_status',id='scaled-guardian-form'))
# Two new shared spell identities, with genuine prepared/spontaneous class references.
status('unsteady-concentration',[mod('save_dc',-2,'condition'),mod('will',-2,'condition')],turns=2)
for cls in ['wizard','sorcerer','bard','cleric']:
 for id,name,t,kind,fx in [('fracture-concentration','Fracture concentration',2,'creature',[dict(op='save',save='will',dc=add(c(12),dict(op='modifier',id=get('classes',cls)['casting_attribute']),dict(op='stat',id='save_dc')),on_failure=[apply('unsteady-concentration')],on_success=[])]),('cleansing-ward','Cleansing ward',2,'ally',[dict(op='remove_status',id='off-balance'),dict(op='remove_status',id='weakened'),dict(op='temporary_hp',amount=c(6))])]:
  costs={cls+'-slots-2':1};prepared=get('classes',cls)['spell_mode']=='prepared'
  if prepared:
   reserve=cls+'-prepared-'+id;row('resources',id=reserve,name=name+' copies',capacity=c(0),refresh='eligible_rest',prepared_ability=cls+'-'+id);costs[reserve]=1
  a=ability(cls+'-'+id,name,kind,fx,costs,['spell','prepared'if prepared else'spontaneous','tier_2'],description='Main action, one tier2 slot'+(' and prepared copy'if prepared else'')+'. '+('Will negates saveDC/Will−2 for two rounds.'if kind=='creature'else'Remove weakened/off-balance and grant six temporary HP.'),reach=4,casting_class=cls,spell_tier=2)
  tier(cls,3 if cls!='bard'else 4,feature(a+'-access',name,[a],list(costs.keys())[1:]if prepared else[]))
exec((root/'tools/character-content/wave-four-cohort.py').read_text(encoding='utf-8'))
path=root/'data/rules/trhgd-character-v14.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
manifest_path=root/'data/rules/packs.json';manifest=json.loads(manifest_path.read_text())
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!='trhgd-character-v14']+[dict(path='res://data/rules/trhgd-character-v14.json',rules_ref=pin)];manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(pin))
