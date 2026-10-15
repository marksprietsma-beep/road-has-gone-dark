"""Additional original v14 cohort, executed with the existing builder's data helpers."""
def modifier_attr(id):return dict(op='modifier',id=id)
def casting(id):return dict(op='casting_level',id=id)
def normal_save(effects,attr='INT',tier=1,which='will',success=None):
 return dict(op='save',save=which,dc=add(c(10+tier),modifier_attr(attr),dict(op='stat',id='save_dc')),on_failure=effects,on_success=success or[])
def spell(cls,id,name,tier_no,kind,effects,reach=4,radius=0,at=None):
 definition=get('classes',cls);prepared=definition['spell_mode']=='prepared';aid=cls+'-'+id;slot=cls+'-slots-'+str(tier_no)
 costs={slot:1};resources=[]
 if prepared:
  reserve=cls+'-prepared-'+id
  row('resources',id=reserve,name=name+' preparations',capacity=c(0),refresh='eligible_rest',prepared_ability=aid);costs[reserve]=1;resources=[reserve]
 ability(aid,name,kind,effects,costs,['spell','prepared'if prepared else'spontaneous','tier_'+str(tier_no)],description=f'Tier{tier_no}; main action, one matching slot'+(' and prepared copy.'if prepared else'.'),reach=reach,casting_class=cls,spell_tier=tier_no)
 get('abilities',aid)['targeting']['radius']=radius
 get('abilities',aid)['requirements']=need('attribute',definition['casting_attribute'],10+tier_no)
 f=feature(aid+'-access',name,[aid],resources,tags=['casting_tier'])
 tier(cls,at if at is not None else max(1,2*tier_no-1),f)
 return aid
# Full spontaneous illusion/control adaptation, not a renamed Sorcerer repertoire.
beguiler=career('beguiler','Beguiler','sorcerer',4,6,'INT','An Intelligence-based spontaneous illusion and control caster with broad infiltration skills. Choose a subtle discipline; conceal allies, undermine attacks and restrain enemies with actual saving throws. No mind-controlled AI or trap subsystem is claimed.')
beguiler.update(bab=div(cl('beguiler'),2),casting=cl('beguiler'),casting_tradition='arcane',spell_mode='spontaneous',casting_attribute='INT',class_skills=['stealth','perception','persuasion','acrobatics','arcana','spellcraft'],proficiencies=['simple','light'],recommended_equipment=['staff','leathers'],known_spell_limits=[0]+[2+(n//2)for n in range(1,21)])
status('beguiling-veil',caps={'concealment':25},turns=3)
status('beguiling-doubt',[mod('melee_attack',-2,'condition'),mod('ranged_attack',-2,'condition')],turns=3)
status('draconic-ward',[mod('defence',2,'insight')],{'resistances':{'fire':3,'cold':3,'electricity':3}},turns=3)
status('mind-tether',[mod('stride',-2,'condition'),mod('will',-2,'condition')],turns=2)
status('iron-carapace',[mod('stride',-1,'condition')],{'resistances':{'physical':4}},turns=3)
status('beguiling-pressure',[mod('initiative',-4,'condition'),mod('save_dc',-2,'condition')],turns=2)
status('lucid-poise',[mod('will',2,'insight')],{'immunities':['weakened','psychic-confusion']},turns=3)
status('prismatic-fracture',[mod('reflex',-3,'condition'),mod('ranged_attack',-3,'condition')],turns=2)
status('perfect-shadow',caps={'concealment':50},turns=2)
for t in range(1,10):
 at=1 if t==1 else 2*t
 slot='beguiler-slots-'+str(t)
 row('resources',id=slot,name='Beguiler tier '+str(t)+' slots',capacity=add(c(1),div(add(casting('beguiler'),c(-at)),4),calc('max',c(0),modifier_attr('INT'))),refresh='eligible_rest',slot_class='beguiler',spell_tier=t)
 tier('beguiler',at,feature('beguiler-slots-'+str(t)+'-access','Beguiler casting tier '+str(t),resources=[slot],tags=['casting_tier']))
 names={1:('Veil of doubt','False openings'),2:('Compelling stillness','Veiled step'),3:('Phantasmal assault','Mass veil'),4:('Mind tether','Sheltering fiction'),5:('Dread convergence','Lucid refuge'),6:('Crushing apprehension','Unerring poise'),7:('Prismatic doubt','Collective refuge'),8:('Nightmare pressure','Perfect concealment'),9:('Dominion of dread','Sanctuary of shadows')}
 for mode in [0,1]:
  id='beguiling-'+('control-'if mode==0 else'ward-')+str(t)
  hostile={1:[apply('beguiling-doubt')],2:[apply('psychic-lock')],3:[damage(9),apply('off-balance')],4:[apply('mind-tether')],5:[damage(15),apply('weakened')],6:[apply('beguiling-pressure')],7:[apply('prismatic-fracture'),dict(op='remove_status',id='warded')],8:[apply('psychic-lock'),apply('beguiling-pressure'),damage(12)],9:[damage(30),apply('weakened'),apply('psychic-lock')]}
  support={1:[apply('beguiling-veil')],2:[apply('beguiling-veil'),apply('psychic-haste')],3:[apply('beguiling-veil')],4:[apply('psychic-screen'),dict(op='temporary_hp',amount=c(12))],5:[apply('psychic-resistance'),dict(op='remove_status',id='weakened'),dict(op='remove_status',id='off-balance')],6:[apply('lucid-poise'),dict(op='remove_status',id='psychic-confusion'),dict(op='remove_status',id='psychic-lock'),dict(op='remove_status',id='weakened')],7:[apply('beguiling-veil'),dict(op='temporary_hp',amount=c(14))],8:[apply('perfect-shadow')],9:[apply('beguiling-veil'),apply('iron-carapace'),dict(op='temporary_hp',amount=c(18)),dict(op='remove_status',id='psychic-lock')]}
  kind='creature'if mode==0 else'self'if t in [2,5]else'ally'
  radius=(2 if t>=8 else 1 if t in [5,7]else 0)if mode==0 else(2 if t>=9 else 1 if t in [3,7]else 0)
  effects=[normal_save(hostile[t],'INT',t)]if mode==0 else support[t]
  aid=spell('beguiler',id,names[t][mode],t,kind,effects,reach=0 if kind=='self'else 4+t//3,radius=radius,at=at)
  descriptions={1:('Will negates attacks−2 for3 rounds.','25% weapon concealment for3 rounds.'),2:('Will negates immobility for1 global round.','Self:25% weapon concealment and stride+2.'),3:('Will negates9 psychic damage and off-balance.','Selected ally and adjacent allies gain25% weapon concealment.'),4:('Will negates stride−2/Will−2 for2 rounds.','Selected ally gains defence+3 and12 temporary HP.'),5:('Will negates15 psychic damage and weakened in radius1.','Self: fire/electric/psychic resistance4; remove weakened/off-balance.'),6:('Will negates initiative−4 and saveDC−2 for2 rounds.','Cleanse psychic confusion/lock/weakened and grant Will+2 and immunity to weakened/confusion.'),7:('Will negates Reflex/ranged attack−3 and removal of warded in radius1.','Radius1 ally concealment25% and14 temporary HP.'),8:('Will negates immobility, initiative/saveDC pressure and12 psychic damage in radius2.','Selected ally gains50% weapon concealment for2 rounds.'),9:('Will negates30 psychic damage, weakened and immobility in radius2.','Radius2 allies:25% concealment, physical resistance4/stride−1,18 temporary HP and remove psychic lock.')}
  get('abilities',aid)['description']+=' '+descriptions[t][mode]

for at in [1,5,10,15,20]:
 opts=[]
 for mode,mods,caps in [('subtle',[mod('initiative',1+at//5,'insight')],{'concealment':10}),('compelling',[mod('save_dc',1,'insight')],{'resistances':{'psychic':1+at//5}})]:
  f=feature('beguiler-discipline-'+mode+'-'+str(at),mode.title()+' discipline',mods=mods,caps=caps)
  opts.append(option(mode,mode.title(),[f],description='Initiative and personal concealment.'if mode=='subtle'else'Save DC+1 and scaling psychic resistance. Same-type bonuses use their normal stacking rules.'))
 choice('beguiler','beguiler-discipline-'+str(at),'Subtle discipline',at,opts)
# Repeatable area breath with Reflex half damage; selected, finite invocations add other roles.
dragon=career('dragonfire-adept','Dragonfire Adept','warlock',6,4,'CON','A repeatable elemental breath specialist. Breath spends a main action, uses a Reflex save and affects enemies in a radius-one burst around a legal target. Selected invocations spend finite resolve. No cone, flight or friendly-fire mechanics are claimed.')
dragon.update(bab=div(cl('dragonfire-adept'),2),class_skills=['arcana','persuasion','insight','perception'],proficiencies=['simple','light'],recommended_equipment=['staff','leathers'])
pool('draconic-resolve',add(c(2),div(cl('dragonfire-adept'),4)))
tier('dragonfire-adept',1,feature('draconic-reserve','Invocation resolve',resources=['draconic-resolve']))
opts=[]
for element in ['fire','cold','electricity']:
 amount=dict(dice='1d6',bonus=div(cl('dragonfire-adept'),2))
 dc=add(c(10),div(cl('dragonfire-adept'),2),modifier_attr('CON'),dict(op='stat',id='save_dc'))
 fx=[dict(op='save',save='reflex',dc=dc,on_failure=[dict(op='damage',amount=amount,damage_type=element)],on_success=[dict(op='damage',amount=amount,damage_type=element,save_half=True)])]
 aid=ability('dragon-breath-'+element,element.title()+' breath','creature',fx,tags=['breath'],description='Repeatable main action; 1d6 + half adept level '+element+' damage; Reflex halves. Enemy-centred radius1, range4, clear line of sight. No point or spell cost.',reach=4)
 get('abilities',aid)['targeting']['radius']=1
 f=feature('draconic-element-'+element,element.title()+' draconic inheritance',[aid],caps={'resistances':{element:3}},tags=['draconic_breath'])
 opts.append(option(element,element.title(),[f],description='Repeatable '+element+' burst and resistance3.'))
choice('dragonfire-adept','draconic-element','Breath element',1,opts)
for at in [1,6,11,16]:
 opts=[]
 for mode in ['ward','veil','hindrance']:
  kind='self'if mode in ['ward','veil']else'creature'
  fx=[apply('draconic-ward'),dict(op='temporary_hp',amount=add(c(at+3),cl('dragonfire-adept')))]if mode=='ward'else[apply('beguiling-veil'),apply('psychic-haste')]if mode=='veil'else[normal_save([apply('mind-tether'),damage(at+3,'fire')],'CON',at//3+1)]
  aid=ability('draconic-'+mode+'-'+str(at),'Draconic '+mode+' '+str(at),kind,fx,{'draconic-resolve':1 if at<11 else 2},description='Main action and '+('one'if at<11 else'two')+' invocation resolve. '+('Elemental ward and scaling temporary HP.'if mode=='ward'else'Weapon concealment25% and stride+2.'if mode=='veil'else'Will negates tether and fire damage.'),reach=4 if kind=='creature'else 0)
  opts.append(option(mode,mode.title(),[feature(aid+'-access',mode.title()+' invocation',[aid])]))
 choice('dragonfire-adept','draconic-invocation-'+str(at),'Invocation selection',at,opts)
# Three prestige paths: durable prerequisites and actual chosen progression/features.
career('war-chanter','War Chanter','marshal',8,6,'CHA','Earned battlefield chorus: a wider area doctrine and finite rally, with five deliberate prestige levels.',kind='prestige',cap=5,requirements=req(need('level',n=6),need('bab',n=4),need('skill','performance',4),dict(op='any',args=[need('feat','commanding-presence'),need('feat','inspiring-performance')])))
get('classes','war-chanter')['class_skills']=['performance','persuasion','insight','perception']
get('classes','war-chanter')['bab']=cl('war-chanter')
pool('chorus-resolve',add(c(2),div(cl('war-chanter'),2)))
tier('war-chanter',1,feature('chorus-reserve','Chorus reserve',resources=['chorus-resolve']))
opts=[]
for mode,mods in [('courage',[mod('melee_attack',add(c(1),div(cl('war-chanter'),2)),'insight'),mod('will',2,'insight')]),('shelter',[mod('defence',add(c(1),div(cl('war-chanter'),2)),'insight'),mod('fortitude',2,'insight')])]:
 sid='chorus-'+mode
 status(sid,turns=1,aura=dict(radius=4,modifiers=mods));get('statuses',sid)['duration']=dict(type='rest',amount=1,expiry='eligible_rest')
 aid=ability(sid,'Maintain chorus: '+mode,'self',[apply(sid)],{'chorus-resolve':1},description='One main action/chorus resolve; replaces your maintained aura. Living allies within4 with clear sight gain the selected chorus until rest or encounter cleanup.')
 opts.append(option(mode,mode.title(),[feature(aid+'-access',mode.title()+' chorus',[aid])]))
choice('war-chanter','chorus-doctrine','Chorus doctrine',1,opts)
for at in [2,4,5]:
 aid=ability('chorus-rally-'+str(at),'Chorus rally '+str(at),'ally',[dict(op='temporary_hp',amount=add(c(at*2),cl('war-chanter'))),dict(op='remove_status',id='weakened'),dict(op='remove_status',id='off-balance')],{'chorus-resolve':1},description='Main action/one chorus resolve: cleanse weakened/off-balance and grant temporary HP to nearby allies.',reach=3)
 get('abilities',aid)['targeting']['radius']=1
 tier('war-chanter',at,feature(aid+'-access','Experienced chorus',[aid]))
career('archmage','Archmage','wizard',4,4,'INT','Earned high arcana. Deliberately advance an existing arcane class, then select real warding or force mastery. Five prestige levels; no automatic assignment.',kind='prestige',cap=5,requirements=req(need('level',n=13),need('skill','arcana',10),need('skill','spellcraft',10),need('feat','greater-spell-focus'),dict(op='any',args=[need('resource',x+'-slots-7',1)for x in ['wizard','sorcerer','beguiler']])))
choice('archmage','archmage-casting','Existing arcane progression',1,[dict(**option(x,get('classes',x)['name'],[],need('class_level',x,10),'Advance the chosen existing caster once per prestige level.'),advance_casting=x,progression_class='archmage')for x in ['wizard','sorcerer','beguiler']])
get('classes','archmage')['class_skills']=['arcana','spellcraft','craft','perception']
pool('high-arcana',add(c(1),div(cl('archmage'),2)))
tier('archmage',1,feature('high-arcana-reserve','High arcana',resources=['high-arcana']))
for at in [1,3,5]:
 opts=[]
 for mode in ['force','ward']:
  fx=[normal_save([damage(8+at*3,'force'),apply('off-balance')],'INT',5,'reflex')]if mode=='force'else[apply('draconic-ward'),dict(op='temporary_hp',amount=add(c(10),mul(cl('archmage'),2)))]
  aid=ability('high-arcana-'+mode+'-'+str(at),'High arcana: '+mode+' '+str(at),'creature'if mode=='force'else'ally',fx,{'high-arcana':1},description='Main action and one high-arcana use: '+('Reflex negates force damage and off-balance on enemies near the selected target.'if mode=='force'else'Nearby allies gain elemental wards and temporary HP.'),reach=5)
  get('abilities',aid)['targeting']['radius']=1
  opts.append(option(mode,mode.title(),[feature(aid+'-access','High '+mode+' mastery',[aid],mods=[mod('save_dc',1,'insight')]if mode=='force'else[mod('will',2,'insight')])]))
 choice('archmage','high-arcana-'+str(at),'High arcana mastery',at,opts)
career('metamind','Metamind','psion',4,4,'INT','Earned psychic resource mastery. A finite reserve reclaims power points through a main action; learn additional powers and choose disciplined reserve or psychic resilience. Ten prestige levels.',kind='prestige',cap=10,requirements=req(need('level',n=8),need('attribute','INT',13),need('skill','arcana',8),need('feat','deep-reserve'),need('tag','psychic_manifester')))
get('classes','metamind')['class_skills']=['arcana','spellcraft','insight','perception']
get('classes','metamind')['psychic_profile']=dict(max_tier=9,attribute='INT',points_per_level=1,mantle_restricted=False)
tier('metamind',1,'shared-psychic-access');pool('metamind-reserve',add(c(1),div(cl('metamind'),4)))
aid=ability('metamind-reclaim','Reclaim psychic reserve','self',[dict(op='restore_resource',id='psychic-points',amount=add(c(4),cl('metamind')))],{'metamind-reserve':1},description='Main action and one finite reserve use: restore4 + Metamind level power points, bounded by capacity. Eligible home rest restores reserve; no free-action or self-refund loop.')
tier('metamind',1,feature('metamind-reserve-access','Psychic reserve mastery',[aid],['metamind-reserve']))
for at in [1,5,10]:
 choice('metamind','metamind-discipline-'+str(at),'Reserve discipline',at,[option('reserve','Expanded reserve',[feature('metamind-reserve-'+str(at),'Expanded reserve',caps={'resource_bonuses':{'psychic-points':c(2)}})],description='Power-point capacity+2.'),option('resilience','Psychic resilience',[feature('metamind-resilience-'+str(at),'Psychic resilience',mods=[mod('will',2,'insight')],caps={'resistances':{'psychic':2+at//5}})],description='Will+2 and scaling psychic resistance.')])
# Six more real psychic identities, retaining typed known-power/cost and class eligibility.
new_psychics=[x['id']for x in p['classes']if x.get('psychic_profile')]
for id,t,discipline,mode in [('frost-lance',2,'energy','cold'),('vigilant-link',2,'insight','vigilance'),('severing-thought',3,'mind','sever'),('communal-renewal',4,'unity','heal'),('iron-carapace',5,'body','armor'),('void-detonation',7,'energy','force')]:
 variants=[]
 for aug in [0,2,4,6]:
  cost=2*t-1+aug
  if cost>20:continue
  pid='power-'+id;aid=pid+(''if aug==0 else'-aug'+str(aug));amount=t*4+aug*2
  kind='ally'if mode in ['vigilance','heal']else'self'if mode=='armor'else'creature'
  fx=[save([damage(amount,'cold'),apply('slowed')],'reflex',t)]if mode=='cold'else[apply('psychic-clarity'),dict(op='temporary_hp',amount=c(amount))]if mode=='vigilance'else[dict(op='remove_status',id='guarding'),dict(op='remove_status',id='psychic-screen'),damage(amount)]if mode=='sever'else[dict(op='heal',amount=c(amount))]if mode=='heal'else[apply('iron-carapace'),dict(op='temporary_hp',amount=c(amount))]if mode=='armor'else[damage(amount,'force')]
  ability(aid,id.replace('-',' ').title()+(f' +{aug}'if aug else''),kind,fx,{'psychic-points':cost},['psychic'],description=f'Tier{t}; main action/{cost} points, magnitude{amount}. '+{'cold':'Reflex negates cold damage and slowed.','vigilance':'Initiative+3/Will+2 and temporary HP.','sever':'Remove guarding/psychic screen and apply psychic damage.','heal':'Heal selected ally and adjacent allies; bounded by maximum HP.','armor':'Physical resistance4, stride−1 for3 rounds, plus temporary HP.','force':'Force burst on the selected enemy and adjacent enemies.'}[mode],reach=5 if kind!='self'else 0,psychic_power=pid,augmentation=aug)
  if mode in ['heal','force']:get('abilities',aid)['targeting']['radius']=1
  variants.append(aid)
 fid=feature(pid+'-known',id.replace('-',' ').title(),variants,known_power=pid)
 row('psychic_powers',id=pid,name=id.replace('-',' ').title(),description=get('abilities',variants[0])['description'],tier=t,discipline=discipline,class_ids=new_psychics,mantle_tags=['mantle_'+discipline],feature_id=fid,variants=variants)
for power in p['psychic_powers']:power['class_ids']=list(new_psychics)
for cls in p['classes']:
 for group in cls.get('career_choices',[]):
  if group['options'] and all(any(o['id']==x['id']for x in p['psychic_powers'])for o in group['options']):
   for power in p['psychic_powers']:
    if not any(o['id']==power['id']for o in group['options']):group['options'].append(option(power['id'],power['name'],[power['feature_id']],description=power['description']))
for at in [1,3,5,7,9]:choice('metamind','metamind-power-'+str(at),'Learn psychic power',at,[option(x['id'],x['name'],[x['feature_id']],description=x['description'])for x in p['psychic_powers']])
get('resources','psychic-points')['capacity']=add(c(2),*(mul(cl(x),get('classes',x)['psychic_profile']['points_per_level'])for x in new_psychics))
# Four inherited families and two actual heritage tradeoffs; culture is never inferred.
for element,adjust,caps,mods,fx,kind in [
 ('air',{'DEX':2,'INT':2,'WIS':-2},{'resistances':{'electricity':3}},[],[apply('psychic-haste')],'self'),
 ('earth',{'STR':2,'CON':2,'CHA':-2},{'resistances':{'physical':2}},[mod('stride',-1)],[dict(op='temporary_hp',amount=c(5))],'self'),
 ('fire',{'INT':2,'DEX':2,'CHA':-2},{'resistances':{'fire':3}},[],[damage(5,'fire')],'creature'),
 ('water',{'CON':2,'WIS':2,'CHA':-2},{'resistances':{'cold':3}},[],[dict(op='heal',amount=c(5))],'ally')]:
 id=element+'-genasi';pool(id+'-inheritance',c(2))
 aid=ability(id+'-gift',element.title()+' inherited gift',kind,fx,{id+'-inheritance':1},description='Main action, one of two inherited uses per home rest. '+{'air':'Stride+2 for two rounds.','earth':'Five temporary HP.','fire':'Five fire damage within3.','water':'Heal5 HP within2; no swimming mechanics.'}[element],reach=3 if kind=='creature'else 2 if kind=='ally'else 0)
 fid=feature(id+'-gift-access',element.title()+' inheritance',[aid],[id+'-inheritance'])
 a=copy.deepcopy(get('ancestries','heritage-human'))
 desc={'air':'Dexterity+2, Intelligence+2, Wisdom−2; electricity resistance3 and a costed burst of speed.','earth':'Strength+2, Constitution+2, Charisma−2; physical resistance2, stride−1 and a costed stone ward.','fire':'Intelligence+2, Dexterity+2, Charisma−2; fire resistance3 and a costed flame attack.','water':'Constitution+2, Wisdom+2, Charisma−2; cold resistance3 and a costed healing gift. No aquatic exploration ability.'}[element]
 a.update(id='heritage-'+id,people_id=id,name=element.title()+' Genasi',description=desc,attribute_adjustments=adjust,size='medium',body_plan='humanoid',tags=[id,'humanoid'],features=[fid],modifiers=mods,skill_bonuses={},capabilities=caps,visual_profile=dict(body_plan='humanoid',size='medium',head='humanoid',torso='standard',arms=2,legs=2,optional_features=[],art_status='neutral_humanoid_fallback'),provenance=dict(P));p['ancestries'].append(a)
for id,name,base,changes in [('air-genasi-highwind','Highwind Genasi','air-genasi',dict(attribute_adjustments={'DEX':2,'CHA':2,'CON':-2},modifiers=[mod('stride',1)])),('earth-genasi-granite','Granite Genasi','earth-genasi',dict(attribute_adjustments={'STR':2,'CON':2,'DEX':-2},capabilities={'resistances':{'physical':3}}))]:
 a=copy.deepcopy(get('ancestries','heritage-'+base));a.update(id='heritage-'+id,name=name,description='An inherited '+name+' variation with its own attribute and defensive/movement tradeoffs. Culture remains independent.',**changes);p['ancestries'].append(a)
# Eight feats with observable, supported consequences.
for id,name,requirements,mods,caps,extra in [
 ('draconic-vigor','Draconic vigor',need('class_level','dragonfire-adept',1),[mod('HP',4)],{'resource_bonuses':{'draconic-resolve':c(1)}},{}),
 ('beguiling-discipline','Beguiling discipline',need('class_level','beguiler',3),[mod('save_dc',1,'training')],{},{}),
 ('elemental-endurance','Elemental endurance',need('ancestry','earth-genasi'),[mod('fortitude',2,'insight')],{},{}),
 ('highwind-footwork','Highwind footwork',need('ancestry','air-genasi'),[mod('reflex',2,'insight'),mod('initiative',1)],{},{}),
 ('ember-ward','Ember ward',need('ancestry','fire-genasi'),[],{'resistances':{'fire':5}},{}),
 ('tidal-reserve','Tidal reserve',need('ancestry','water-genasi'),[],{'resource_bonuses':{'water-genasi-inheritance':c(1)}},{}),
 ('devoted-bond','Devoted bond',need('feat','beast-stewardship'),[],{},dict(companion_growth=c(1))),
 ('form-reach-training','Form reach training',need('feature','druid-shape'),[dict(**mod('reach',1,'circumstance'),when=need('tag','body_transformed'))],{},{}),
]:
 fid=feature(id+'-feature',name,mods=mods,caps=caps,**extra);row('feats',id=id,name=name,requirements=requirements,features=[fid],repeatable=False,choice_parameters=[])
# Distinct creatures reuse normal ownership, effort, turns, duration and dismissal.
for id,name,attrs,weapon,dice,damage_type,mods,fx,kind,reach in [
 ('frost-hound','Frost hound',dict(STR=14,DEX=15,CON=13,INT=8,WIS=12,CHA=10),'frost-fangs','1d6','cold',[mod('stride',2),mod('reflex',1)],[normal_save([apply('slowed')],'WIS',2,'fortitude')],'creature',3),
 ('bulwark-construct','Bulwark construct',dict(STR=14,DEX=8,CON=15,INT=10,WIS=13,CHA=12),'bulwark-slam','1d8','physical',[mod('defence',3),mod('stride',-1)],[apply('guarding',True),dict(op='temporary_hp',amount=add(c(4),div(cl('bond-creature'),2)))],'ally',2),
]:
 row('equipment',id=weapon,name=name+' natural attack',kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=1,range=1,damage=dice,damage_type=damage_type,proficiency='')
 aid=ability(id+'-special',name+' '+('chilling howl'if id=='frost-hound'else'shield lattice'),kind,fx,{'creature-effort':1},description='Main action/one creature effort. '+('Fortitude negates slowed within3.'if id=='frost-hound'else'The construct guards adjacent allies through its shared reaction and grants temporary HP to an ally within2.'),reach=reach)
 fid=feature(id+'-anatomy',name+' anatomy',[aid],['creature-effort'],mods=mods,caps={'resistances':{'cold':3}}if id=='frost-hound'else{'blocked_equipment':['weapon','armor','shield']})
 row('creatures',id=id,name=name,attributes=attrs,feature_id=fid,weapon_id=weapon,body_plan='quadruped'if id=='frost-hound'else'heavy-biped',size='medium',provenance=dict(P))
 aid=ability('call-'+id,'Call '+name,'self',[dict(op='summon',id=id,rounds=3)],copy.deepcopy(get('abilities','bonded-summoner-technique-1')['cost']['resources']),description='Main action/one existing bond use; one temporary owned actor for3 rounds. Normal summon limits apply.')
 tier('bonded-summoner',3 if id=='frost-hound'else 5,feature(aid+'-access',name+' calling',[aid]))
# Four shared divine/arcane spell identities and genuine prepared summons.
for cls in ['wizard','cleric','druid']:
 for id,name,kind,fx in [('restorative-circle','Restorative circle','ally',[dict(op='heal',amount=c(9)),dict(op='remove_status',id='weakened')]),('anchoring-ward','Anchoring ward','ally',[apply('psychic-screen'),dict(op='temporary_hp',amount=c(8))])]:
  # Arcane receives ward, divine receives both; no arbitrary arcane cure repertoire.
  if cls=='wizard'and id=='restorative-circle':continue
  aid=spell(cls,id,name,3,kind,fx,radius=1)
  get('abilities',aid)['description']+=' '+('Heal9 HP and remove weakened.'if id=='restorative-circle'else'Defence+3 for3 rounds and8 temporary HP.')
 for creature in ['frost-hound','bulwark-construct']:
  aid=spell(cls,'summon-'+creature,'Summon '+get('creatures',creature)['name'],3,'self',[dict(op='summon',id=creature,rounds=3)],reach=0)
  get('abilities',aid)['description']+=' One temporary creature, legal adjacent placement, normal action order and3-round expiry; one active summon per owner.'
# Every aura activation replaces any other maintained aura, including multiclass paths.
all_auras=[x['id']for x in p['statuses']if x.get('aura')]
for a in p['abilities']:
 if any(e.get('op')=='apply_status'and e.get('id')in all_auras for e in a['effects']):
  a['effects']=[dict(op='remove_status',id=x)for x in all_auras]+[e for e in a['effects']if not(e.get('op')=='remove_status'and e.get('id')in all_auras)]
