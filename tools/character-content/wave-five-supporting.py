"""Supporting original content for the first v15 cohort, using the existing generic authority."""
psychics=[x['id']for x in p['classes']if 'psychic_profile'in x]
status('sovereign-clarity',caps={'immunities':['weakened','psychic-confusion']},turns=3)
status('anchoring-screen',[mod('stride',-1,'condition')],{'resistances':{'physical':3}},turns=3)
status('psychic-harmonic-aura',turns=3,aura={'radius':1,'modifiers':[mod('defence',2,'insight'),mod('reflex',2,'insight')]})
new_powers=[]
for id,name,t,discipline,mode in [
 ('kinetic-shatter','Kinetic shatter',2,'energy','shatter'),('shared-vigor','Shared vigor',2,'unity','vigor'),('sovereign-clarity','Sovereign clarity',3,'insight','clarity'),('resonant-crush','Resonant crush',3,'body','crush'),('vital-exchange','Vital exchange',4,'body','exchange'),('anchoring-screen','Anchoring screen',4,'body','anchor'),('vacuous-dread','Vacuous dread',5,'mind','dread'),('harmonic-shelter','Harmonic shelter',5,'unity','shelter'),('purifying-concord','Purifying concord',6,'unity','purify'),('severing-tempest','Severing tempest',8,'energy','tempest')]:
 variants=[];pid='power-'+id
 for aug in [0,2,4]:
  cost=2*t-1+aug;amount=3*t+2*aug;aid=pid+(''if aug==0 else'-aug'+str(aug))
  fx={
   'shatter':[damage(amount,'force'),dict(op='remove_status',id='warded')],
   'vigor':[dict(op='temporary_hp',amount=c(amount)),dict(op='heal',amount=c(2+aug))],
   'clarity':[apply('sovereign-clarity'),dict(op='temporary_hp',amount=c(aug+2))],
   'crush':[save([damage(amount,'physical'),apply('winter-brand')],'fortitude',t)],
   'exchange':[save([damage(amount,'psychic')],'will',t),dict(op='heal',amount=c(4+aug),recipient='actor')],
   'anchor':[apply('anchoring-screen'),dict(op='temporary_hp',amount=c(amount))],
   'dread':[save([apply('beguiling-pressure'),damage(amount,'psychic')],'will',t)],
   'shelter':[apply('psychic-harmonic-aura'),dict(op='temporary_hp',amount=c(4+aug))],
   'purify':[dict(op='remove_status',id='psychic-confusion'),dict(op='remove_status',id='psychic-lock'),dict(op='remove_status',id='weakened'),dict(op='heal',amount=c(amount))],
   'tempest':[save([damage(amount,'electricity'),apply('unsteady-concentration')],'reflex',t)]}[mode]
  kind='ally'if mode in ['vigor','clarity','anchor','shelter','purify']else'creature'
  radius=1 if mode in ['dread','purify','tempest']else 0
  text={'shatter':'Force damage and remove Warded.','vigor':'Temporary HP and healing.','clarity':'Immunity to weakened/confusion plus temporary HP for3 rounds.','crush':'Fortitude negates physical damage and stride/Reflex pressure.','exchange':'Will negates enemy psychic damage; the caster separately heals4 + augmentation HP.','anchor':'Physical resistance3, stride−1 for3 rounds and temporary HP.','dread':'Will negates initiative−4/saveDC−2 and psychic damage in radius1.','shelter':'Recipient maintains radius1 defence/Reflex+2 for3 rounds plus temporary HP.','purify':'Radius1 cleansing of confusion/lock/weakened plus healing.','tempest':'Reflex negates electricity damage and concentration pressure in radius1.'}[mode]
  ability(aid,name+(f' +{aug}'if aug else''),kind,fx,{'psychic-points':cost},['psychic'],description=f'Tier{t}; {cost} points and a main action. '+text+f' Magnitude{amount}; augmentation{aug}. Total expenditure cannot exceed shared manifesting level.',reach=5,psychic_power=pid,augmentation=aug)
  get('abilities',aid)['targeting']['radius']=radius;variants.append(aid)
 f=feature(pid+'-known',name+' learned',variants,tags=['known_psychic_power'],known_power=pid)
 row('psychic_powers',id=pid,name=name,description=get('abilities',variants[0])['description'],tier=t,discipline=discipline,class_ids=psychics,mantle_tags=['mantle_'+discipline],feature_id=f,variants=variants)
 new_powers.append(get('psychic_powers',pid))
for cls in p['classes']:
 for group in cls.get('career_choices',[]):
  if any(any(get('features',f).get('known_power')for f in opt['features'])for opt in group['options']):
   group['options'] += [option(power['id'],power['name'],[power['feature_id']],description=power['description'])for power in new_powers]
# A learned-power feat chain changes real reserves/defences and requires actual permanent knowledge.
for id,name,requirements,mods,caps in [
 ('resonant-discipline','Resonant discipline',req(need('feat','psychic-discipline'),need('feature','power-kinetic-shatter-known')),[],{'resource_bonuses':{'psychic-points':c(2)},'resistances':{'force':3}}),
 ('harmonic-focus','Harmonic focus',req(need('feat','resonant-discipline'),need('feature','power-harmonic-shelter-known')),[mod('reflex',1,'insight')],{'resource_bonuses':{'psychic-points':c(2)}})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
# Two new actors have their own natural attacks, effort, real actions and growth.
for id,name,template,mods,caps,weapon_damage,kind in [
 ('ancestor-sentinel','Ancestor sentinel','sentinel-spirit',[mod('will',3),mod('defence',2),mod('stride',-1)],{'resistances':{'psychic':4}},'1d4','force'),
 ('briar-beast','Briar beast','boar',[mod('reach',1),mod('fortitude',2)],{'resistances':{'physical':2}},'1d8','physical')]:
 creature=copy.deepcopy(get('creatures',template));weapon=id+'-natural'
 row('equipment',id=weapon,name=name+' natural attack',kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=2 if id=='briar-beast'else 1,range=2 if id=='briar-beast'else 1,damage=weapon_damage,damage_type=kind,proficiency='')
 attack=ability(id+'-strike',name+' strike','creature',[],tags=['weapon_strike'],description='One ordinary main-action natural attack.',attack_weapon=weapon)
 fx=[dict(op='temporary_hp',amount=add(c(6),div(cl('bond-creature'),2))),dict(op='remove_status',id='weakened')]if id=='ancestor-sentinel'else[dict(op='save',save='reflex',dc=add(c(10),div(cl('bond-creature'),2),attr('WIS')),on_failure=[apply('briar-rooted')],on_success=[])]
 special=ability(id+'-special',name+(' intercession'if id=='ancestor-sentinel'else' grasping tangle'),'ally'if id=='ancestor-sentinel'else'creature',fx,{'creature-effort':1},description='Main action/one creature effort: '+('grant6 + half creature level temporary HP and cleanse weakened.'if id=='ancestor-sentinel'else'Reflex negates immobility for1 global round.'),reach=3)
 fid=feature(id+'-body',name+' anatomy',[attack,special],['creature-effort'],mods=mods,caps=caps)
 creature.update(id=id,name=name,weapon_id=weapon,feature_id=fid,provenance=dict(P));p['creatures'].append(creature)
 for cls in ['druid','ranger']:
  for group in get('classes',cls)['career_choices']:
   prior=next((get('features',f)for opt in group['options']for f in opt['features']if get('features',f).get('companion')),None)
   if not prior:continue
   companion=copy.deepcopy(prior['companion']);companion['creature_id']=id
   bf=feature(cls+'-'+group['id']+'-'+id+'-bond',name+' bond',companion=companion,tags=['permanent_nature_bond'])
   group['options'].append(option(id,name,[bf],description='One persistent owned '+name+'; normal bond growth and one-companion limit. Neutral humanoid visual fallback.'))
 for cls,t,at in [('spirit-shaman',3,5),('druid',3,5),('wizard',4,7)]:
  # Spirit retrieval and spontaneous slots use the new helper; prepared casters retain copies.
  if cls=='spirit-shaman':spell(cls,'call-'+id,'Call '+name,t,'self',[dict(op='summon',id=id,rounds=3)],at,reach=0,description='One temporary owned creature, legal adjacent placement, actual turns and3-round expiry; one active summon per owner.')
  else:
   aid=cls+'-call-'+id;slot=cls+'-slots-'+str(t);reserve=aid+'-prepared';row('resources',id=reserve,name=name+' prepared copies',capacity=c(0),refresh='eligible_rest',prepared_ability=aid)
   ability(aid,'Call '+name,'self',[dict(op='summon',id=id,rounds=3)],{slot:1,reserve:1},['spell','prepared','tier_'+str(t)],description=f'Tier{t}, one main action, slot and prepared copy; one owned temporary creature for3 rounds.',reach=0,casting_class=cls,spell_tier=t)
   get('abilities',aid)['requirements']=need('attribute',get('classes',cls)['casting_attribute'],10+t)
   tier(cls,at,feature(aid+'-access',name+' calling',[aid],[reserve],tags=['casting_tier']))
# Three functional wild forms, with existing equipment suppression and authoritative original HP.
for id,name,at,strength,dexterity,weapon,mods,caps in [
 ('moon-stag','Moon stag',6,2,4,'stag-antlers',[mod('stride',2)],{'resistances':{'cold':3}}),
 ('iron-tortoise','Iron tortoise',10,4,-4,'boar-tusks',[mod('stride',-2),mod('defence',4),mod('fortitude',2)],{'resistances':{'physical':3}}),
 ('briar-cat','Briar cat',14,2,4,'leopard-claws',[mod('stride',1)],{'moving_damage':c(2)})]:
 anatomy=feature(id+'-anatomy',name+' anatomy',mods=mods,caps=caps)
 body=copy.deepcopy(get('statuses','leopard-form'));body.update(id=id+'-form',provenance=dict(P),modifiers=[]);body['body_form'].update(id=id+'-form',body_plan='quadruped',attributes={'STR':strength,'DEX':dexterity},feature_id=anatomy,weapon_id=weapon);p['statuses'].append(body)
 aid=ability('wild-shape-'+id,'Wild shape: '+name,'self',[apply(id+'-form')],{'wildshape':1},['supernatural'],description=f'Main action/one Wild Shape use; STR{strength:+}, DEX{dexterity:+}, distinct movement/defence/resistance or moving damage,3 rounds. Original HP and identity remain; equipment and magic are suppressed. Revert before another new form. Neutral humanoid art, no unsupported exploration.',reach=0)
 tier('druid',at,feature(aid+'-access',name+' form',[aid]));get('abilities','revert-form')['effects'].append(dict(op='remove_status',id=id+'-form'))
for id,name,requirements,mods,caps,extra in [
 ('ancestral-bond','Ancestral bond',req(need('tag','permanent_nature_bond'),need('class_level','spirit-shaman',1)),[],{'resource_bonuses':{'spirit-favour':c(1)}},dict(companion_growth=c(1))),
 ('briar-form-training','Briar form training',need('feature','druid-shape'),[],{'weapon_damage':{'leopard-claws':'1d8'}},{})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps,**extra);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
