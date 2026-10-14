"""Append v13. Original bounded psychic/creature adaptations; never alter v1–v12."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v12.json').read_text())
p.update(pack_id='trhgd-character-v13',rules_version='13.0.0')
P={'origin':'Original TRHGD mechanics and prose; research names identify bounded adaptations, not sourcebook conversions','license':'Original project-authored content','revision':'game112-wave-three'}
p['provenance']=P;p['psychic_powers']=[]
def c(n):return dict(op='const',value=n)
def cl(id):return dict(op='class_level',id=id)
def calc(op,*args):return dict(op=op,args=list(args))
def add(*args):return calc('sum',*args)
def mul(a,n):return calc('multiply',a,c(n))
def div(a,n):return calc('floor_divide',a,c(n))
def req(*args):return dict(op='all',args=list(args))
def need(op,id=None,n=None):return dict(op=op,**({'id':id}if id else{}),**({'min':n}if n is not None else{}))
def mod(stat,n,typ='training'):return dict(stat=stat,type=typ,value=c(n)if isinstance(n,int)else n)
def get(cat,id):return next(r for r in p[cat]if r['id']==id)
def row(cat,**kw):
 assert not any(r['id']==kw['id']for r in p[cat]),kw['id']
 kw['provenance']=dict(P);p[cat].append(kw);return kw['id']
def feature(id,name,abilities=None,resources=None,mods=None,tags=None,caps=None,**kw):
 fields=dict(id=id,name=name,modifiers=mods or[],abilities=abilities or[],resources=resources or[],tags=tags or[],senses=[],hooks=[],grants=[],description=name,**kw)
 if caps:fields['capabilities']=caps
 return row('features',**fields)
def pool(id,capacity):return row('resources',id=id,name=id.replace('-',' ').title(),capacity=capacity,refresh='eligible_rest')
def ability(id,name,kind,effects,cost=None,tags=None,description='',reach=1,**kw):return row('abilities',id=id,name=name,cost=dict(main=1,move=0,reaction=0,resources=cost or{}),effects=effects,tags=tags or[],timing=dict(kind='instant'),requirements=req(),targeting=dict(kind=kind,range=reach,radius=0),description=description or name,**kw)
def status(id,mods=None,caps=None,turns=3,**kw):
 fields=dict(id=id,tags=[],duration=dict(type='round',amount=turns,expiry='global_round_start'),stacking='refresh',modifiers=mods or[],effects=[],**kw)
 if caps:fields['capabilities']=caps
 return row('statuses',**fields)
def apply(id,own=False):return dict(op='apply_status',id=id,**({'recipient':'actor'}if own else{}))
def damage(n,kind='psychic'):return dict(op='damage',amount=c(n)if isinstance(n,int)else n,damage_type=kind)
def save(effects,which='will',bonus=0):return dict(op='save',save=which,dc=add(c(10+bonus),dict(op='manifesting_modifier'),dict(op='stat',id='save_dc')),on_failure=effects,on_success=[])
def option(id,name,features,requirements=None,description=''):return dict(id=id,name=name,description=description or name,features=features,requirements=requirements or req())
def choice(cls,id,name,at,options):get('classes',cls)['career_choices'].append(dict(id=id,name=name,at=at,options=options))
def tier(cls,at,id):get('classes',cls)['features'].append(dict(at=at,id=id))
def career(id,name,template,hp,skills,attr,description,kind='base',cap=20,requirements=None):
 base=copy.deepcopy(get('classes',template))
 base.update(id=id,name=name,max_level=cap,hp_per_level=hp,hit_die=hp+2,skill_points=skills,features=[],career_choices=[],class_kind=kind,bonus_feat_levels=[],class_skills=['arcana','perception','stealth','nature','animal-handling']if id=='lurk'else['arcana','perception','nature','animal-handling'],proficiencies=['simple','light'],recommended_equipment=['shortblade','leathers'],description=description,requirements=requirements or req(),spell_mode='',casting_attribute='',casting=c(0),casting_tradition='',attribute_priority=[attr]+[a for a in ['DEX','CON','INT','WIS','STR','CHA']if a!=attr],provenance=dict(P))
 base.pop('known_spell_limits',None);base['bab']=div(mul(cl(id),3),4);base['saves']={s:div(cl(id),3)for s in ['fortitude','reflex','will']};base['saves']['will']=add(c(2),div(cl(id),2))
 p['classes'].append(base);return base
# Shared manifesting progression and pool. Existing v12 remains immutable.
psychic_classes=['psion','psychic-warrior','wilder','ardent','lurk','cerebremancer']
career('ardent','Ardent','psion',6,4,'WIS','Chosen philosophical mantles restrict learned powers and confer defensive, restorative or perceptive capabilities. Wisdom-based manifesting; deliberate power choices through level20.')
career('lurk','Lurk','rogue',6,6,'INT','A psychic infiltrator with a smaller point reserve and limited ambush focus. Concealment, debilitation and a risky melee precision strike distinguish it from a full manifester.')
career('cerebremancer','Cerebremancer','wizard',4,4,'INT','Earned arcane/psychic hybrid; advances the chosen arcane caster and shared manifesting level. Five original playable levels.',kind='prestige',cap=5,requirements=req(need('level',n=6),need('casting','arcane',3),need('resource','psychic-points',6),need('skill','arcana',4),need('feat','psychic-discipline')))
for cls in psychic_classes:
 r=get('classes',cls);r['psychic_profile']=dict(max_tier=6 if cls in ['psychic-warrior','lurk']else 9,attribute='WIS'if cls in ['ardent','psychic-warrior']else'CHA'if cls=='wilder'else'INT',points_per_level=1 if cls in ['psychic-warrior','lurk']else 2,mantle_restricted=cls=='ardent')
ml=calc('min',c(20),add(*(cl(x)for x in psychic_classes)))
pp=add(c(2),*(mul(cl(x),get('classes',x)['psychic_profile']['points_per_level'])for x in psychic_classes))
pool('psychic-points',pp)
access=feature('shared-psychic-access','Shared manifesting reserve',resources=['psychic-points'],tags=['psychic_manifester'])
for cls in psychic_classes:tier(cls,1,access)
for r in p['features']:
 r['resources']=[x for x in r['resources']if x not in ['psion-points','psychic-warrior-points','wilder-points']]
for a in p['abilities']:
 costs=a['cost']['resources']
 for old in ['psion-points','psychic-warrior-points','wilder-points']:
  if old in costs:costs['psychic-points']=costs.pop(old);a['provenance']=dict(P)
# Psion v13 starts with learned powers, not a fixed offence spell hidden in generic techniques.
get('classes','psion')['features']=[t for t in get('classes','psion')['features']if t['id']=='shared-psychic-access']
# Feats with executable reserve, resistance, creature and form consequences.
for id,name,requirements,mods,caps in [
 ('expanded-psychic-reserve','Expanded psychic reserve',need('tag','psychic_manifester'),[],{'resource_bonuses':{'psychic-points':c(4)}}),
 ('psychic-ward-training','Psychic ward training',need('feat','psychic-discipline'),[],{'resistances':{'psychic':2}}),
 ('beast-stewardship','Beast stewardship',need('tag','permanent_nature_bond'),[mod('fortitude',1)],{}),
 ('form-footwork','Form footwork',need('feature','druid-shape'),[dict(**mod('stride',1,'circumstance'),when=need('tag','body_transformed'))],{}),
 ('summoning-reserve','Summoning reserve',need('class_level','wizard',1),[],{'resource_bonuses':{'wizard-slots-1':c(1)}})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
get('feats','psychic-discipline')['requirements']=need('tag','psychic_manifester')
# Mantles grant real capabilities; power choices are constrained by these durable tags.
options=[]
for id,name,mods,caps in [('energy','Energy',[mod('save_dc',1,'insight')],{'resistances':{'fire':2,'electricity':2}}),('body','Body',[mod('fortitude',2,'insight')],{}),('mind','Mind',[mod('will',2,'insight')],{'resistances':{'psychic':2}}),('insight','Insight',[mod('initiative',2,'insight')],{}),('unity','Unity',[mod('defence',1,'insight')],{})]:
 f=feature('ardent-mantle-'+id,name+' mantle',mods=mods,caps=caps,tags=['mantle_'+id],unique_selection=True);options.append(option(id,name,[f],description='Unlocks '+id+' powers. '+{'energy':'Fire/electricity resistance2 and save DC+1.','body':'Fortitude+2.','mind':'Will+2 and psychic resistance2.','insight':'Initiative+2.','unity':'Defence+1.'}[id]))
choice('ardent','ardent-mantle','Philosophical mantle',1,options)
choice('ardent','ardent-second-mantle','Second starting mantle',1,options[1:]+options[:1])
for at in [4,8,12]:
 opts=copy.deepcopy(options)
 for option_row in opts:option_row['requirements']={'op':'not','arg':need('feature',option_row['features'][0])}
 choice('ardent','ardent-mantle-'+str(at),'Additional mantle',at,opts)
# Executable psychic catalogue. Every augmentation is an ordinary ability with actual extra cost/effects.
status('psychic-screen',[mod('defence',3,'insight')]);status('psychic-haste',[mod('stride',2,'insight')],turns=2)
status('psychic-confusion',[mod('melee_attack',-2,'condition'),mod('ranged_attack',-2,'condition')],turns=2)
status('psychic-clarity',[mod('initiative',3,'insight'),mod('will',2,'insight')]);status('psychic-unity',[mod('melee_attack',2,'insight'),mod('will',2,'insight')])
status('psychic-lock',caps={'immobile':True},turns=1)
status('psychic-resistance',caps={'resistances':{'fire':4,'electricity':4,'psychic':4}})
# kind, tier, discipline, damage/support effect family, range
specs=[('kinetic-bolt','Kinetic bolt',1,'energy','bolt',5),('thought-thrust','Thought thrust',1,'mind','mental',4),('force-screen','Force screen',1,'body','barrier',4),('body-renewal','Body renewal',1,'body','heal',3),('burst-step','Burst step',1,'insight','speed',0),('thought-fog','Thought fog',1,'mind','fog',4),('keen-mind','Keen mind',1,'insight','clarity',0),('fellowship','Fellowship',1,'unity','support',3),('electric-lance','Electric lance',2,'energy','electricity',5),('shared-barrier','Shared barrier',2,'unity','barrier',4),('mind-lock','Mind lock',2,'mind','lock',4),('energy-surge','Energy surge',3,'energy','electricity',6),('phase-guard','Phase guard',3,'body','resistance',0),('mind-crush','Mind crush',4,'mind','mental',5),('restorative-weave','Restorative weave',4,'body','heal',4),('concord','Concord',5,'unity','support',5),('astral-guardian','Astral guardian',5,'unity','summon',0),('synaptic-collapse','Synaptic collapse',6,'mind','lock_damage',5),('radiant-cascade','Radiant cascade',7,'energy','electricity',6),('renewal-nexus','Renewal nexus',8,'body','heal',5),('perfect-unity','Perfect unity',9,'unity','support',5)]
for id,name,t,discipline,mode,reach in specs:
 variants=[]
 for aug in [0,2,4,6]:
  cost=2*t-1+aug
  if cost>20:continue
  power_id='power-'+id;aid=power_id+(''if aug==0 else'-aug'+str(aug));amount=3*t+aug*2
  kind='self'if mode in ['speed','clarity','resistance','summon']else'ally'if mode in ['barrier','heal','support']else'creature'
  if mode=='bolt':fx=[damage(amount,'force')]
  elif mode=='electricity':fx=[save([damage(amount,'electricity')],'reflex',t)]
  elif mode=='mental':fx=[save([damage(amount)],'will',t)]
  elif mode=='barrier':fx=[dict(op='temporary_hp',amount=c(amount)),apply('psychic-screen')]
  elif mode=='heal':fx=[dict(op='heal',amount=c(amount))]
  elif mode=='speed':fx=[apply('psychic-haste'),dict(op='temporary_hp',amount=c(aug))]
  elif mode=='fog':fx=[save([apply('psychic-confusion'),damage(aug)],'will',t)]
  elif mode=='clarity':fx=[apply('psychic-clarity'),dict(op='temporary_hp',amount=c(aug))]
  elif mode=='support':fx=[apply('psychic-unity'),dict(op='temporary_hp',amount=c(amount))]
  elif mode=='lock':fx=[save([apply('psychic-lock'),damage(aug)],'will',t)]
  elif mode=='resistance':fx=[apply('psychic-resistance'),dict(op='temporary_hp',amount=c(aug*2))]
  elif mode=='summon':fx=[dict(op='summon',id='sentinel-spirit',rounds=3+aug//2)]
  else:fx=[save([apply('psychic-lock'),damage(amount)],'will',t)]
  descriptions={'speed':'Stride +2 for two rounds; ordinary movement and opportunity attacks remain authoritative.','clarity':'Initiative +3 and Will +2 for three rounds; no unsupported sight/darkness claims.','summon':'One sentinel, first legal adjacent tile; owns a turn, expires after 3 + augmentation/2 global rounds.','barrier':'Temporary HP and defence +3 for three rounds.','support':'Melee attack +2 and Will +2 for three rounds plus temporary HP.','fog':'Will save or attacks −2 for two rounds.','lock':'Will save or immobile for one global round.','resistance':'Fire/electric/psychic resistance4 for three rounds.'}
  text=f'Tier{t} {discipline}; {cost} points, main action. '+descriptions.get(mode,f'{amount} '+('healing.'if mode=='heal'else'damage; save negates where listed.'))+f' Augmentation +{aug}: '+('longer summon duration.'if mode=='summon'else f'effect magnitude {amount}; secondary damage or temporary HP scales with extra points.')+' Total expenditure cannot exceed shared manifesting level.'
  ability(aid,name+(f' +{aug}'if aug else''),kind,fx,{'psychic-points':cost},['psychic'],text,reach=reach,psychic_power=power_id,augmentation=aug);variants.append(aid)
 f=feature(power_id+'-known',name+' learned',variants,tags=['known_psychic_power'],known_power=power_id)
 row('psychic_powers',id=power_id,name=name,description=get('abilities',variants[0])['description'],tier=t,discipline=discipline,class_ids=psychic_classes,mantle_tags=['mantle_'+discipline],feature_id=f,variants=variants)
# Learn two distinct Psion/Ardent powers initially, others one. Subsequent options use shared progression.
for cls in psychic_classes:
 levels=[1,2,4,6,8,10,12,14,16,18,20]if cls not in ['cerebremancer']else[1,3,5]
 for at in levels:
  opts=[option(power['id'],f"{power['name']} · tier{power['tier']} · {2*power['tier']-1} PP",[power['feature_id']],description=power['description'])for power in p['psychic_powers']]
  choice(cls,cls+'-power-'+str(at),'Learn psychic power',at,opts)
 if cls in ['psion','ardent']:
  opts=copy.deepcopy(get('classes',cls)['career_choices'][-len(levels)]['options']);opts=opts[2:]+opts[:2]
  choice(cls,cls+'-second-power','Second starting power',1,opts)
# Lurk's smaller PP reserve plus a separate finite ambush focus. Melee exposure is its risk.
pool('lurk-focus',add(c(2),div(cl('lurk'),4)))
status('lurk-veiled',caps={'concealment':25},turns=2);get('statuses','lurk-veiled')['tags']=['psychic_ambush_ready']
ambush=ability('lurk-psychic-ambush','Psychic ambush','creature',[damage(add(c(2),div(cl('lurk'),2))),apply('off-balance')],{'psychic-points':1,'lurk-focus':1},['weapon_strike','psychic'],description='Main action and one PP/focus: melee weapon attack plus psychic damage 2 + half Lurk level and off-balance. Requires adjacency; leaving engagement still provokes.',reach=1)
get('abilities',ambush)['requirements']=req(need('tag','psychic_ambush_ready'),need('tag','melee'))
get('abilities',ambush)['effects'].append(dict(op='remove_status',id='lurk-veiled',recipient='actor'))
get('abilities',ambush)['description']='Requires an active Psychic veil; consumes the veil, one focus/PP and main action. Adjacent target takes psychic damage2 + half Lurk level and off-balance, then a separate rolled attack with your equipped melee weapon. Veiling requires a prior action; engagement remains dangerous.'
veil=ability('lurk-veil','Psychic veil','self',[apply('lurk-veiled')],{'lurk-focus':1},['psychic'],description='Main action, one focus; 25% weapon concealment for two global rounds. No invisibility or automatic sneak attack.')
tier('lurk',1,feature('lurk-infiltration','Psychic infiltration',[ambush,veil],['lurk-focus']))
for cls in ['psion','ardent','lurk','cerebremancer']:
 for at in ([4,8,12,16,20]if cls!='cerebremancer'else[3,5]):
  a=ability(cls+'-focus-'+str(at),'Centre '+cls+' '+str(at),'self',[dict(op='temporary_hp',amount=add(c(at),cl(cls))),dict(op='remove_status',id='off-balance')],{'psychic-points':min(5,1+at//4)},['psychic'],description='Main action, costed survival: temporary HP equals technique tier plus class level; remove off-balance. No resource-refund loop.')
  tier(cls,at,feature(cls+'-focus-'+str(at)+'-feature','Experienced '+cls+' focus',[a],mods=[mod('will',at//4,'insight')]))
opts=[]
for target in ['wizard','sorcerer']:
 opts.append(dict(**option(target,get('classes',target)['name'],[],need('class_level',target,3),'Advance the existing arcane class once per prestige level; learned psychic choices and shared manifesting progression also advance.'),advance_casting=target,progression_class='cerebremancer'))
choice('cerebremancer','cerebremancer-casting','Arcane progression',1,opts)
# Distinct owned actors use the existing single-companion/summon authority.
for f in p['features']:
 if f.get('companion') and 'permanent_nature_bond'not in f['tags']:f['tags'].append('permanent_nature_bond')
for id,name,dice,reach in [('leopard-claws','Leopard claws','1d6',1),('boar-tusks','Boar tusks','1d8',1),('stag-antlers','Stag antlers','1d6',2),('stone-slam','Stone slam','1d12',2),('spirit-touch','Spirit touch','1d4',1)]:row('equipment',id=id,name=name,kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=reach,range=reach,damage=dice,damage_type='physical',proficiency='')
pool('creature-effort',add(c(2),div(cl('bond-creature'),4)))
creatures=[('leopard','Leopard',dict(STR=13,DEX=15,CON=14,INT=8,WIS=12,CHA=10),'leopard-claws',[mod('stride',2),mod('reflex',2)],'medium','predator'),('boar','Boar',dict(STR=15,DEX=10,CON=14,INT=8,WIS=13,CHA=12),'boar-tusks',[mod('fortitude',2),mod('defence',2)],'medium','guardian'),('stag','Stag',dict(STR=13,DEX=14,CON=12,INT=8,WIS=15,CHA=10),'stag-antlers',[mod('stride',1),mod('reach',1)],'large','support'),('stone-guardian','Stone guardian',dict(STR=15,DEX=8,CON=14,INT=10,WIS=13,CHA=12),'stone-slam',[mod('stride',-1),mod('defence',3),mod('reach',1)],'large','heavy'),('renewal-spirit','Renewal spirit',dict(STR=10,DEX=12,CON=13,INT=8,WIS=15,CHA=14),'spirit-touch',[mod('will',2)],'small','healer')]
for id,name,attrs,weapon,mods,size,mode in creatures:
 strike=ability(id+'-natural-strike',name+' strike','creature',[],tags=['weapon_strike'],attack_weapon=weapon,reach=2 if size=='large'else 1,description='Natural weapon attack through the ordinary attack/RNG engine.')
 if mode=='predator':fx=[apply('slowed')];kind='creature';reach=1;tags=['weapon_strike']
 elif mode=='guardian':fx=[apply('guarding'),dict(op='temporary_hp',amount=cl('bond-creature'))];kind='self';reach=0;tags=[]
 elif mode=='support':fx=[dict(op='temporary_hp',amount=add(c(3),div(cl('bond-creature'),2))),apply('psychic-unity')];kind='ally';reach=2;tags=[]
 elif mode=='heavy':fx=[apply('off-balance')];kind='creature';reach=2;tags=['weapon_strike']
 else:fx=[dict(op='heal',amount=add(c(3),div(cl('bond-creature'),2)))];kind='ally';reach=3;tags=[]
 action=ability(id+'-special',name+' '+mode,kind,fx,{'creature-effort':1},tags,description='Main action, one creature effort (2 + level/4 per rest): '+mode+' action. '+('Natural weapon strike plus condition.'if tags else'Uses actual support/defensive effect.'),reach=reach,**({'attack_weapon':weapon}if tags else{}))
 f=feature(id+'-creature-body',name+' body',[strike,action],['creature-effort'],mods,caps={'blocked_equipment':['weapon','armor','shield']})
 row('creatures',id=id,name=name,attributes=attrs,feature_id=f,weapon_id=weapon,body_plan='quadruped'if mode in ['predator','guardian','support']else'spirit-biped',size=size)
for cls,at,offset in [('druid',1,0),('ranger',4,-3)]:
 group=next(x for x in get('classes',cls)['career_choices']if x['id']==cls+'-companion')
 for creature in ['leopard','boar','stag']:
  f=feature(cls+'-'+creature+'-bond',creature.title()+' companion',tags=['permanent_nature_bond'],companion=dict(creature_id=creature,level_class=cls,offset=offset,divisor=1))
  group['options'].append(option(creature,creature.title(),[f],description='Persistent '+creature+'; distinct natural special action costs creature effort. Class-scaled owner record; one permanent companion.'))
# Additional prepared summons with costs/copies/duration; no parallel summon controller.
for cls in ['wizard','cleric','druid']:
 for creature in ['leopard','boar','renewal-spirit','stone-guardian']:
  id=cls+'-summon-'+creature;prepared=cls+'-prepared-summon-'+creature;pool(prepared,c(0));get('resources',prepared)['prepared_ability']=id
  t=2 if creature in ['leopard','boar']else 3
  ability(id,'Summon '+get('creatures',creature)['name'],'self',[dict(op='summon',id=creature,rounds=3)],{cls+'-slots-'+str(t):1,prepared:1},['spell','prepared','tier_'+str(t)],description=f'Main action, tier{t} slot and prepared copy; one actual {creature}, legal adjacent placement, expires after three global rounds. Uses its own effort-costed action.',reach=0,casting_class=cls,spell_tier=t)
  casting=get('features',cls+'-casting-'+str(t));casting['abilities'].append(id);casting['resources'].append(prepared)
for at,creature in [(1,'leopard'),(3,'renewal-spirit'),(5,'stone-guardian')]:
 id='bonded-summoner-call-'+creature
 a=ability(id,'Call '+get('creatures',creature)['name'],'self',[dict(op='summon',id=creature,rounds=3)],{'bonded-summoner-bond':1},description='Spend one existing bond use and main action; one selected creature, three rounds, no second summon slot.',reach=0)
 # Discover the existing resource ID instead of manufacturing a second reserve.
 old=get('abilities','bonded-summoner-technique-1');get('abilities',a)['cost']['resources']=copy.deepcopy(old['cost']['resources'])
 tier('bonded-summoner',at,feature(id+'-feature','Expanded summoning repertoire',[a]))
# Three new body forms, distinct weapon/speed/defence tradeoffs. Current HP remains original.
for id,name,attrs,weapon,mods,size,caps in [
 ('leopard-form','Leopard',{'STR':2,'DEX':6},'leopard-claws',[mod('stride',3),mod('defence',1)],'medium',{}),
 ('boar-form','Boar',{'STR':4,'DEX':-2},'boar-tusks',[mod('fortitude',3),mod('defence',3)],'medium',{'resistances':{'physical':2}}),
 ('stone-form','Stone guardian',{'STR':6,'DEX':-4},'stone-slam',[mod('stride',-1),mod('reach',1),mod('defence',2)],'large',{'resistances':{'physical':3}})]:
 f=feature(id+'-body',name+' anatomy',mods=mods,caps=caps)
 body=dict(id=id,body_plan='quadruped'if id!='stone-form'else'heavy-biped',size=size,attributes=attrs,feature_id=f,weapon_id=weapon,suppressed_equipment=['weapon','armor','shield'],art_status='neutral_humanoid_fallback')
 status(id,turns=3,body_form=body);get('statuses',id)['tags']=['body_transformed']
 a=ability('wild-shape-'+id.replace('-form',''),'Wild shape: '+name,'self',[apply(id)],{'wildshape':1},description='One Wild Shape use, main action: three rounds. '+str(attrs)+'; '+str(mods)+'. Original HP/ancestry/history persist; held gear and spells/powers suppressed. Labelled humanoid art fallback.')
 tier('druid',8 if id=='stone-form'else 5,feature(id+'-access',name+' form',[a]))
 get('abilities','revert-form')['effects'].append(dict(op='remove_status',id=id))
# Beast Heart concept uses an original production identity, permanent prerequisite, growth and support.
career('beast-steward','Beast Steward','ranger',8,4,'WIS','Original Beast Heart Adept concept: earned permanent companion mastery. One existing bond grows with prestige levels; costed ally commands and a chosen training path.',kind='prestige',cap=5,requirements=req(need('level',n=5),need('tag','permanent_nature_bond'),need('skill','animal-handling',4),need('skill','nature',3),need('feat','beast-stewardship')))
tier('beast-steward',1,feature('beast-steward-growth','Steward bond growth',companion_growth=cl('beast-steward')))
pool('beast-steward-commands',add(c(2),div(cl('beast-steward'),2)))
a=ability('steward-rally','Rally bonded ally','ally',[dict(op='heal',amount=add(c(3),cl('beast-steward'))),apply('guarding')],{'beast-steward-commands':1},description='Main action, one command: heal3 + prestige level and guard an ally within3. The permanent bond prerequisite cannot be met by a summon.',reach=3)
tier('beast-steward',1,feature('beast-steward-rally','Steward rally',[a],['beast-steward-commands']))
for at in [3,5]:
 a=ability('steward-drive-'+str(at),'Pack drive '+str(at),'ally',[apply('psychic-unity'),dict(op='temporary_hp',amount=add(c(at*2),cl('beast-steward')))],{'beast-steward-commands':1},description='Main action, one command; ally melee attack/Will +2 for three rounds and temporary HP scaling with prestige progression.',reach=4)
 tier('beast-steward',at,feature('steward-drive-'+str(at)+'-feature','Pack coordination',[a]))
choice('beast-steward','beast-steward-training','Steward training',1,[option('swift','Swift bond',[feature('steward-swift','Swift bonded growth',companion_growth=c(1),mods=[mod('initiative',2)])],description='One extra companion level (cap20) and initiative+2.'),option('enduring','Enduring steward',[feature('steward-enduring','Enduring steward',mods=[mod('fortitude',2)],caps={'resistances':{'physical':2}})],description='Fortitude+2 and physical resistance2; standard companion progression.')])
# Coherent psychic ancestries, separate inherited reserve from class manifesting qualification.
pool('inherited-psychic',c(2))
status('inherited-burst',[mod('stride',2,'insight')],turns=2)
status('maenad-outburst',[mod('damage',2,'insight'),mod('defence',-1,'condition')],turns=2)
for id,name,adjust,size,body,mode in [('elan','Elan',{'CHA':-2},'medium','humanoid','barrier'),('xeph','Xeph',{'DEX':2,'STR':-2},'medium','humanoid','speed'),('maenad','Maenad',{},'medium','humanoid','outburst'),('dromite','Dromite',{'CHA':2,'STR':-2},'small','insectoid-humanoid','energy')]:
 fx=[dict(op='temporary_hp',amount=c(5))]if mode=='barrier'else[apply('inherited-burst')]if mode=='speed'else[apply('maenad-outburst')]if mode=='outburst'else[damage(4,'electricity')]
 a=ability(id+'-inheritance-action',name+' '+mode,'creature'if mode=='energy'else'self',fx,{'inherited-psychic':1},description='Inherited main action, one of two uses per eligible rest. '+{'barrier':'Five temporary HP.','speed':'Stride+2 for two rounds; ordinary movement rules.','outburst':'Damage+2, defence−1 for two rounds.','energy':'Four electric damage within range4.'}[mode],reach=4 if mode=='energy'else 0)
 f=feature(id+'-inheritance',name+' inheritance',[a],['inherited-psychic'])
 ancestry=copy.deepcopy(get('ancestries','heritage-human'))
 ancestry.update(id='heritage-'+id,people_id=id,name=name,description='Inherited traits: '+get('abilities',a)['description']+' Culture stays separate. Dedicated ancestry artwork unavailable: neutral humanoid fallback.',attribute_adjustments=adjust,size=size,body_plan=body,tags=[id,'humanoid'],features=[f],modifiers=[],skill_bonuses={},capabilities={'resistances':{'electricity':2}}if id=='dromite'else{},visual_profile=dict(body_plan=body,size=size,head='insectoid'if id=='dromite'else'humanoid',torso='standard',arms=2,legs=2,optional_features=['antennae']if id=='dromite'else[],art_status='neutral_humanoid_fallback'),provenance=dict(P));p['ancestries'].append(ancestry)
# Remap inherited psychic-resource references only in the new pack, including feats/rest actions.
remap={'psion-points':'psychic-points','psychic-warrior-points':'psychic-points','wilder-points':'psychic-points'}
def remap_node(value):
 if isinstance(value,dict):return {remap.get(k,k):remap_node(v)for k,v in value.items()}
 if isinstance(value,list):return [remap_node(v)for v in value]
 if isinstance(value,str):return remap.get(value,value)
 return value
for category in ['features','feats','abilities','classes','statuses','ancestries']:
 p[category]=remap_node(p[category])
# Canonical psychic classification also covers inherited and retained legacy techniques.
for ability_row in p['abilities']:
 if any(key in ability_row['cost']['resources']for key in ['psychic-points','inherited-psychic']) or ability_row['id'].startswith(('psion-','psychic-warrior-','wilder-')):
  if 'psychic'not in ability_row['tags']:ability_row['tags'].append('psychic')
# High-level learned tiers require deliberate attribute advancement, never silently relax scores.
(root/'data/rules/trhgd-character-v13.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
manifest_path=root/'data/rules/packs.json';manifest=json.loads(manifest_path.read_text())
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!='trhgd-character-v13']+[{ 'path':'res://data/rules/trhgd-character-v13.json','rules_ref':pin}]
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(dict(pin=pin,classes=len(p['classes']),powers=len(p['psychic_powers']),creatures=len(p['creatures']))))
