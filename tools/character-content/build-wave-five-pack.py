"""Reproducible original v15 adaptations; historical v1–v14 bytes are never written."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
exec((root/'tools/character-content/build-wave-three-pack.py').read_text(encoding='utf-8').split('# Shared manifesting progression')[0])
p=json.loads((root/'data/rules/trhgd-character-v14.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v15',rules_version='15.0.0')
P={'origin':'Original bounded TRHGD character adaptations; research names identify concepts, no sourcebook prose, setting lore or tables copied','license':'Original project-authored content','revision':'game112-wave-five'}
p['provenance']=dict(P)
def casting(id):return dict(op='casting_level',id=id)
def attr(id):return dict(op='modifier',id=id)
def good(id):return add(c(2),div(cl(id),2))
def spell(cls,id,name,t,kind,fx,at,reach=4,radius=0,description=''):
 aid=cls+'-'+id;slot=cls+'-slots-'+str(t)
 ability(aid,name,kind,fx,{slot:1},['spell','spontaneous','tier_'+str(t)],description=description+f' Main action and one tier{t} slot. Requires '+get('classes',cls)['casting_attribute']+f'{10+t}.',reach=reach,casting_class=cls,spell_tier=t)
 a=get('abilities',aid);a['targeting']['radius']=radius;a['requirements']=need('attribute',get('classes',cls)['casting_attribute'],10+t)
 tier(cls,at,feature(aid+'-access',name,[aid],tags=['casting_tier']))
 return aid
def save_for(cls,t,fx,which='will',success=None):
 return dict(op='save',save=which,dc=add(c(10+t),attr(get('classes',cls)['casting_attribute']),dict(op='stat',id='save_dc')),on_failure=fx,on_success=success or[])
def dice(n,s=6,bonus=None):return dict(dice=f'{n}d{s}',bonus=bonus or c(0))
def slots(cls,max_tier,unlock):
 for t in range(1,max_tier+1):
  at=unlock(t);id=cls+'-slots-'+str(t)
  row('resources',id=id,name=get('classes',cls)['name']+f' tier{t} slots',capacity=add(c(1),div(add(casting(cls),c(-at)),4),calc('max',c(0),attr(get('classes',cls)['casting_attribute']))),refresh='eligible_rest',slot_class=cls,spell_tier=t)
  tier(cls,at,feature(id+'-access',f'Casting tier{t}',resources=[id],tags=['casting_tier']))
# A full-BAB martial caster; spell delivery is handled by the existing cost/attack/effect authority.
dusk=career('duskblade','Duskblade','fighter',6,4,'INT','An Intelligence-based martial caster. At class3, channel a selected eligible known spell through the one equipped melee weapon. A main action and the spell slot are spent on hit, miss or concealment; only an actual authoritative hit delivers the spell once. Five spell tiers, full BAB, deliberate runic training and feats through20.')
dusk.update(bab=cl('duskblade'),casting=cl('duskblade'),casting_tradition='arcane',spell_mode='spontaneous',casting_attribute='INT',class_skills=['arcana','spellcraft','athletics','craft'],proficiencies=['simple','martial','light','medium','shield'],recommended_equipment=['shortblade','mail'],known_spell_limits=[0]+[2+n//2 for n in range(1,21)],bonus_feat_levels=[4,8,12,16,20],attribute_priority=['INT','STR','CON','DEX','WIS','CHA'])
dusk['saves']={'fortitude':good('duskblade'),'will':good('duskblade'),'reflex':div(cl('duskblade'),3)}
slots('duskblade',5,lambda t:1+4*(t-1))
status('briar-rooted',caps={'immobile':True},turns=1)
status('arcane-tether',caps={'immobile':True},turns=1)
status('runic-shell',[mod('defence',2,'insight')],turns=3)
status('winter-brand',[mod('stride',-2,'condition'),mod('reflex',-1,'condition')],turns=2)
status('spirit-shelter',[mod('will',2,'insight')],{'resistances':{'psychic':3,'force':3}},turns=3)
status('ancestor-guard',[mod('fortitude',3,'insight'),mod('will',3,'insight')],turns=3)
status('spirit-lattice',caps={'resistances':{'physical':2,'fire':3,'cold':3}},turns=3)
status('ancestral-sanctuary',turns=3,aura={'radius':2,'modifiers':[mod('defence',3,'insight'),mod('will',3,'insight')]})
for t in range(1,6):
 at=1+4*(t-1)
 names={1:('Searing grasp','Frost brand'),2:('Thunderbrand','Binding edge'),3:('Force rend','Sapping touch'),4:('Dimensional scar','Winter grasp'),5:('Ruinous touch','Storm brand')}
 for mode in [0,1]:
  id=['searing-grasp','frost-brand','thunderbrand','binding-edge','force-rend','sapping-touch','dimensional-scar','winter-grasp','ruinous-touch','storm-brand'][(t-1)*2+mode]
  kind=['fire','cold','electricity','physical','force','physical','force','cold','force','electricity'][(t-1)*2+mode]
  harm=damage(dice(t,4 if t==1 else 6,div(casting('duskblade'),3)),kind)
  condition={1:'winter-brand',2:('off-balance'if mode==0 else'arcane-tether'),3:('off-balance'if mode==0 else'weakened'),4:('unsteady-concentration'if mode==0 else'winter-brand'),5:('beguiling-pressure'if mode==0 else'off-balance')}[t]
  if t==1:fx=[harm]+([apply(condition)]if mode else[]);desc=f'{t}d4 + effective caster level/3 {kind} damage'+('; stride−2/Reflex−1 for2 rounds.'if mode else'.')
  else:
   save_type='reflex'if mode==0 else'fortitude'
   failure=[harm,apply(condition)];success=[dict(**copy.deepcopy(harm),save_half=True)]if mode==0 else[]
   fx=[save_for('duskblade',t,failure,save_type,success)];desc=f'{t}d6 + effective caster level/3 {kind} damage and {condition}; '+('Reflex halves damage and avoids condition.'if mode==0 else'Fortitude negates both.')
  spell('duskblade',id,names[t][mode],t,'creature',fx,at,reach=3,description=desc)
spell('duskblade','runic-ward','Runic ward',1,'self',[apply('runic-shell')],1,reach=0,description='Defence+2 for3 rounds. This self ward cannot be channelled.')
for at in [1,5,9,13,17,20]:
 opts=[]
 for mode,mods,caps in [('sentinel',[mod('fortitude',1+at//6,'insight')],{'resistances':{'physical':1+at//8}}),('pursuer',[mod('initiative',1+at//5,'insight'),mod('stride',1,'insight')],{})]:
  f=feature('duskblade-rune-'+mode+'-'+str(at),mode.title()+' rune',mods=mods,caps=caps)
  opts.append(option(mode,mode.title(),[f],description='Fortitude and physical resistance.'if mode=='sentinel'else'Initiative and stride. Normal same-type stacking rules apply.'))
 choice('duskblade','duskblade-rune-'+str(at),'Runic training',at,opts)
# Spirit retrieval uses the same saved known-spell list and a one-change rest resource.
shaman=career('spirit-shaman','Spirit Shaman','druid',6,4,'WIS','A Wisdom-based spirit/nature caster. Retrieve a bounded spell repertoire at creation, then change it once after a genuine home-return rest. Retrieval never restores spell slots. Chosen guides and finite spirit favour grant real support and protection; no spirit dialogue, incorporeal AI or exploration vision is claimed.')
shaman.update(casting=cl('spirit-shaman'),casting_tradition='divine',spell_mode='spontaneous',casting_attribute='WIS',class_skills=['nature','insight','perception','animal-handling','spellcraft'],proficiencies=['simple','light','medium','shield'],recommended_equipment=['staff','leathers'],known_spell_limits=[0]+[2+n//2 for n in range(1,21)],rest_retrieval=True,retrieval_resource='spirit-retrieval')
shaman['saves']={'fortitude':good('spirit-shaman'),'will':good('spirit-shaman'),'reflex':div(cl('spirit-shaman'),3)}
pool('spirit-retrieval',c(1));pool('spirit-favour',add(c(2),div(cl('spirit-shaman'),4)))
tier('spirit-shaman',1,feature('spirit-retrieval-access','Rest-selected spirit repertoire',resources=['spirit-retrieval','spirit-favour']))
slots('spirit-shaman',9,lambda t:2*t-1)
for t in range(1,10):
 at=2*t-1
 element='physical'if t in [5,7]else'force'if t==9 else'psychic'if t%2 else'cold'
 harm=damage(dice(t,6,div(casting('spirit-shaman'),3)),element)
 hostile_names=['Spirit needle','Binding roots','Ashen rebuke','Severing chant','Briar reproach','Winter reproach','Hungry grove','Ancestral reckoning','Judgment of the ancestors']
 support_names=['Ancestors shelter','Whispered mend','Communal mending','Ancestors guard','Guided renewal','Echo ward','Ancestral sanctuary','Choir of renewal','Refuge of the living']
 condition={1:'off-balance',2:'entangled',3:'weakened',4:'unsteady-concentration',5:'briar-rooted',6:'winter-brand',7:'briar-rooted',8:'beguiling-pressure',9:'weakened'}[t]
 hostile=[save_for('spirit-shaman',t,[harm,apply(condition)],'will'if t%2 else'fortitude')]
 support={1:[dict(op='temporary_hp',amount=add(c(3),div(casting('spirit-shaman'),2)))],2:[dict(op='heal',amount=dice(2,4,calc('max',c(0),attr('WIS'))))],3:[dict(op='heal',amount=c(10))],4:[apply('ancestor-guard')],5:[dict(op='heal',amount=c(16)),dict(op='remove_status',id='weakened'),dict(op='remove_status',id='off-balance')],6:[apply('spirit-shelter'),dict(op='temporary_hp',amount=c(14))],7:[apply('ancestral-sanctuary')],8:[dict(op='heal',amount=c(24)),dict(op='temporary_hp',amount=c(10)),dict(op='remove_status',id='psychic-lock')],9:[dict(op='heal',amount=c(32)),apply('spirit-lattice'),dict(op='temporary_hp',amount=c(20)),dict(op='remove_status',id='weakened'),dict(op='remove_status',id='slowed')]}[t]
 for mode,fx in [('rebuke',hostile),('refuge',support)]:
  radius=1 if (t>=5 and mode=='rebuke')or(t in[3,5]and mode=='refuge')else 2 if t>=8 and mode=='refuge'else 0
  name=hostile_names[t-1]if mode=='rebuke'else support_names[t-1]
  descriptions={1:'Temporary HP3 + effective caster level/2.',2:'Heal2d4 + nonnegative Wisdom modifier.',3:'Heal10 to the selected ally and adjacent allies.',4:'Fortitude/Will+3 for3 rounds.',5:'Heal16 and remove weakened/off-balance in radius1.',6:'Will+2, psychic/force resistance3 and14 temporary HP for3 rounds.',7:'The selected ally maintains a radius2 sanctuary: defence/Will+3 for3 rounds.',8:'Heal24, grant10 temporary HP and remove psychic lock in radius2.',9:'Heal32, physical resistance2, fire/cold resistance3,20 temporary HP and remove weakened/slowed in radius2.'}
  desc=f'{t}d6 + effective caster level/3 {element} damage and {condition}; '+('Will'if t%2 else'Fortitude')+' negates.'if mode=='rebuke'else descriptions[t]+' No slot restoration.'
  spell('spirit-shaman','spirit-'+mode+'-'+str(t),name,t,'creature'if mode=='rebuke'else'ally',fx,at,reach=4+t//3,radius=radius,description=desc)
# A third initial choice makes retrieval a real build decision, rather than choosing the entire initial pool.
spell('spirit-shaman','listening-ward','Listening ward',1,'ally',[apply('spirit-shelter')],1,description='Will+2, psychic/force resistance3 for3 rounds.')
for at in [1,5,10,15,20]:
 opts=[]
 for mode in ['hearth','watcher','storm']:
  fx=[dict(op='heal',amount=add(c(4+at),div(cl('spirit-shaman'),2))),dict(op='remove_status',id='weakened')]if mode=='hearth'else[apply('ancestor-guard'),dict(op='temporary_hp',amount=c(4+at))]if mode=='watcher'else[save_for('spirit-shaman',min(9,1+at//3),[damage(4+at,'electricity'),apply('off-balance')],'reflex')]
  aid=ability('spirit-guide-'+mode+'-'+str(at),'Spirit guide: '+mode+' '+str(at),'creature'if mode=='storm'else'ally',fx,{'spirit-favour':1 if at<15 else 2},['supernatural'],description='Main action and finite spirit favour: '+('heal and cleanse weakened.'if mode=='hearth'else'Fortitude/Will+3 and temporary HP.'if mode=='watcher'else'Reflex negates electricity damage and off-balance.'),reach=4)
  opts.append(option(mode,mode.title(),[feature(aid+'-access',mode.title()+' spirit',[aid],mods=[mod('will',1+at//5,'insight')]if mode=='watcher'else[])]))
 choice('spirit-shaman','spirit-guide-'+str(at),'Spirit guide',at,opts)
# Earned martial-caster warding path; exact entry is deliberate and XP-funded by the existing authority.
career('abjurant-champion','Abjurant Champion','duskblade',8,4,'INT','Five earned martial/arcane ward levels. Advance an existing arcane caster and choose a finite protective aegis or retaliatory melee technique. No extra main actions or automatic prestige entry.',kind='prestige',cap=5,requirements=req(need('level',n=6),need('bab',n=5),need('skill','spellcraft',4),need('feat','arcane-strike'),need('casting','arcane',2)))
champ=get('classes','abjurant-champion');champ.update(bab=cl('abjurant-champion'),class_skills=['arcana','spellcraft','athletics','craft']);champ.pop('rest_retrieval',None);champ.pop('retrieval_resource',None)
choice('abjurant-champion','abjurant-casting','Existing arcane progression',1,[dict(**option(x,get('classes',x)['name'],[],need('class_level',x,2),'Advance the chosen existing arcane caster once per prestige level.'),advance_casting=x,progression_class='abjurant-champion')for x in ['duskblade','wizard','sorcerer','beguiler']])
pool('abjurant-resolve',add(c(2),cl('abjurant-champion')));tier('abjurant-champion',1,feature('abjurant-reserve','Abjurant resolve',resources=['abjurant-resolve']))
for at in [1,3,5]:
 opts=[]
 for mode in ['aegis','retaliation']:
  fx=[apply('runic-shell'),apply('spirit-shelter'),dict(op='temporary_hp',amount=c(6+at*3))]if mode=='aegis'else[dict(op='temporary_hp',amount=c(4+at*2),recipient='actor')]
  aid=ability('abjurant-'+mode+'-'+str(at),'Abjurant '+mode+' '+str(at),'ally'if mode=='aegis'else'creature',fx,{'abjurant-resolve':1},['weapon_strike','power_strike']if mode=='retaliation'else['supernatural'],description='Main action and one resolve: '+('defence/mental protection and temporary HP.'if mode=='aegis'else f'grant the caster{4+at*2} temporary HP before one ordinary melee strike; ward is retained on a miss. No ranged weapon, free spell or second attack.'),reach=3 if mode=='aegis'else 1)
  opts.append(option(mode,mode.title(),[feature(aid+'-access',mode.title()+' mastery',[aid],mods=[mod('melee_attack',1+at//2,'insight')]if mode=='retaliation'else[mod('will',1+at//2,'insight')])]))
 choice('abjurant-champion','abjurant-doctrine-'+str(at),'Abjurant doctrine',at,opts)
# A researched three-level grove-warden concept adapted without copying source text.
career('grove-warden','Grove Warden','spirit-shaman',6,4,'WIS','Three earned levels of grove protection: advance an existing nature caster, maintain a local sanctuary and spend finite grove favour on ally renewal. Bounded original Holt Warden adaptation; no unimplemented forest travel or spirit dialogue.',kind='prestige',cap=3,requirements=req(need('level',n=6),need('skill','nature',6),need('skill','insight',4),need('feat','spirit-reserve'),need('casting','divine',3)))
grove=get('classes','grove-warden');grove.pop('rest_retrieval',None);grove.pop('retrieval_resource',None)
choice('grove-warden','grove-casting','Existing nature progression',1,[dict(**option(x,get('classes',x)['name'],[],need('class_level',x,3),'Advance this existing nature caster once per prestige level.'),advance_casting=x,progression_class='grove-warden')for x in ['spirit-shaman','druid','ranger']])
pool('grove-favour',add(c(1),cl('grove-warden')));tier('grove-warden',1,feature('grove-reserve','Grove favour',resources=['grove-favour']))
for at in [1,2,3]:
 fx=[apply('ancestral-sanctuary')]if at==1 else[dict(op='heal',amount=c(12)),dict(op='remove_status',id='weakened')]if at==2 else[dict(op='heal',amount=c(20)),apply('spirit-lattice'),dict(op='temporary_hp',amount=c(12))]
 aid=ability('grove-protection-'+str(at),'Grove protection '+str(at),'self'if at==1 else'ally',fx,{'grove-favour':1},['supernatural'],description='Main action and one grove favour: '+('maintain radius2 defensive sanctuary for3 rounds.'if at==1 else'heal and cleanse an ally.'if at==2 else'heal, protect and grant temporary HP to nearby allies.'),reach=0 if at==1 else 4)
 if at==3:get('abilities',aid)['targeting']['radius']=1
 tier('grove-warden',at,feature(aid+'-access','Grove protection',[aid]))
# Actual prerequisite/effect feats, not catalogue-only rows.
for id,name,requirements,mods,caps in [
 ('channel-training','Channel training',need('class_level','duskblade',3),[mod('save_dc',2,'training')],{}),
 ('arcane-endurance','Arcane endurance',need('feat','arcane-strike'),[mod('HP',4),mod('fortitude',1)],{}),
 ('spirit-reserve','Spirit reserve',need('class_level','spirit-shaman',1),[],{'resource_bonuses':{'spirit-favour':c(2)}}),
 ('ancestral-listener','Ancestral listener',need('class_level','spirit-shaman',3),[mod('will',2,'training')],{}),
 ('retrieved-capacity','Retrieved capacity',need('class_level','spirit-shaman',1),[],{'resource_bonuses':{'spirit-shaman-slots-1':c(1)}}),
 ('runic-veteran','Runic veteran',need('class_level','duskblade',5),[],{'resistances':{'force':3}}),
 ('watchful-channel','Watchful channel',need('feat','channel-training'),[mod('initiative',2,'training')],{}),
 ('spirit-temper','Spirit temper',need('feat','spirit-reserve'),[],{'resistances':{'psychic':3}})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
# New inherited concepts are original adaptations with explicit neutral LPC fallbacks.
for id,name,attrs,mods,skills,body,size,extra in [
 ('catfolk','Catfolk',{'DEX':2,'CHA':2,'STR':-2},[mod('stride',1)],{'acrobatics':2},'feline-humanoid','medium',['tail','cat-ears']),
 ('riverborn','Riverborn',{'STR':2,'CON':2,'DEX':-2},[mod('fortitude',1)],{},'aquatic-humanoid','medium',[]),
 ('wildborn','Wildborn',{'WIS':2,'CON':2,'STR':-2},[mod('will',1)],{'nature':2},'fey-humanoid','medium',['antlers']),
 ('ratfolk','Ratfolk',{'DEX':2,'CON':2,'CHA':-2},[mod('reflex',1),mod('defence',1)],{'stealth':2},'rodent-humanoid','small',['tail','rounded-ears'])]:
 a=copy.deepcopy(get('ancestries','heritage-human'));a.update(id='heritage-'+id,people_id=id,name=name,tags=[id,'humanoid'],features=[],modifiers=mods,attribute_adjustments=attrs,skill_bonuses=skills,body_plan=body,size=size,capabilities={},description=name+' inherited statistics, skills and anatomy are shown numerically. Culture and background remain separate. Neutral humanoid LPC art; no swimming, flight, climbing or environmental vision mechanics claimed.',provenance=dict(P))
 a['visual_profile']=dict(body_plan=body,size=size,head=body,torso='standard',arms=2,legs=2,optional_features=extra,art_status='neutral_humanoid_fallback')
 if id=='riverborn':a['capabilities']={'resistances':{'cold':3}}
 if id in ['catfolk','riverborn']:
  weapon=id+'-natural';row('equipment',id=weapon,name=name+' natural attack',kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=1,range=1,damage='1d4'if id=='catfolk'else'1d6',damage_type='physical',proficiency='')
  aid=ability(id+'-natural-strike',name+' '+('claws'if id=='catfolk'else'bite'),'creature',[],tags=['weapon_strike'],description='One main action and ordinary melee attack with the inherited natural weapon; equipment choice is not replaced.',attack_weapon=weapon)
  get('abilities',aid)['effects']=[]
  a['features']=[feature(id+'-anatomy',name+' natural anatomy',[aid])]
 if id=='wildborn':
  pool('wildborn-gift',c(2));aid=ability('wildborn-shelter','Inherited bark shelter','self',[apply('spirit-lattice')],{'wildborn-gift':1},['supernatural'],description='One main action/one of two uses per eligible home rest: physical resistance2 and fire/cold resistance3 for3 rounds.')
  a['features']=[feature('wildborn-inheritance','Wildborn shelter',[aid],['wildborn-gift'])]
 p['ancestries'].append(a)
for id,base,name,attrs,mods,skills in [
 ('catfolk-swiftstrider','catfolk','Swiftstrider Catfolk',{'DEX':2,'CON':2,'STR':-2},[mod('stride',2),mod('will',-1)],{'acrobatics':1}),
 ('riverborn-rime','riverborn','Rime Riverborn',{'CON':2,'WIS':2,'DEX':-2},[mod('fortitude',2),mod('stride',-1)],{})]:
 a=copy.deepcopy(get('ancestries','heritage-'+base));a.update(id='heritage-'+id,name=name,attribute_adjustments=attrs,modifiers=mods,skill_bonuses=skills,provenance=dict(P));a['description']='An inherited '+name+' variation with explicit attribute and movement/save tradeoffs. Culture remains independent; the same honest neutral LPC fallback applies.';p['ancestries'].append(a)
for id,name,requirements,mods,caps in [
 ('catfolk-ambush','Catfolk ambush',need('ancestry','catfolk'),[],{'moving_damage':c(1)}),
 ('riverborn-fangs','Riverborn fangs',need('ancestry','riverborn'),[],{'weapon_damage':{'riverborn-natural':'1d8'}}),
 ('wildborn-resilience','Wildborn resilience',need('ancestry','wildborn'),[],{'resistances':{'physical':2}}),
 ('ratfolk-footwork','Ratfolk footwork',need('ancestry','ratfolk'),[mod('reflex',2),mod('stride',1,'circumstance')],{})]:
 f=feature(id+'-feature',name,mods=mods,caps=caps);row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
exec((root/'tools/character-content/wave-five-supporting.py').read_text(encoding='utf-8'))
# Each new aura replaces the recipient's other maintained auras, including multiclass sources.
all_auras=[x['id']for x in p['statuses']if x.get('aura')]
for a in p['abilities']:
 if any(e.get('op')=='apply_status'and e.get('id')in all_auras for e in a['effects']):
  a['effects']=[dict(op='remove_status',id=x)for x in all_auras]+[e for e in a['effects']if not(e.get('op')=='remove_status'and e.get('id')in all_auras)]
# Channel wrappers are delivery modes of existing spell identities, never additional spells.
channel_ids=[]
for original in list(p['abilities']):
 if original.get('casting_class')!='duskblade' or original['targeting']['kind']!='creature':continue
 aid='channel-'+original['id'];a=copy.deepcopy(original);a.update(id=aid,name='Channel: '+original['name'],channel_spell=original['id'],effects=[],provenance=dict(P));a['tags'].append('weapon_strike');a['targeting'].update(range=1,radius=0);a['description']='Use the one selected equipped melee weapon and a legal enemy target. '+original['description']+' On miss/concealment the action and slot are spent with no spell effect. On a hit the original spell resolves once, after ordinary weapon damage.'
 p['abilities'].append(a);channel_ids.append(aid)
tier('duskblade',3,feature('duskblade-channel-access','Arcane channeling',channel_ids,tags=['martial_channeling']))
path=root/'data/rules/trhgd-character-v15.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text(encoding='utf-8'))
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!='trhgd-character-v15']+[dict(path='res://data/rules/trhgd-character-v15.json',rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print(json.dumps(pin))
