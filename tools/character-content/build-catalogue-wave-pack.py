"""Author original v10 content; never edit or import an historical pack generator."""
from pathlib import Path
import copy, hashlib, json
ROOT = Path(__file__).resolve().parents[2]
p = json.loads((ROOT / 'data/rules/trhgd-character-v9.json').read_text())
p.update(pack_id='trhgd-character-v10', rules_version='10.0.0')
PROV = {'origin': 'Original TRHGD rules and prose; GAME-88 concepts are provenance, not copied sourcebook mechanics', 'license': 'Original project-authored content', 'revision': 'game112-wave-one'}
p['provenance'] = PROV
def c(n): return {'op': 'const', 'value': n}
def cl(id): return {'op': 'class_level', 'id': id}
def cast(id): return {'op': 'casting_level', 'id': id}
def attr(id): return {'op': 'modifier', 'id': id}
def calc(op, *args): return {'op': op, 'args': list(args)}
def add(*args): return calc('sum', *args)
def mul(a, n): return calc('multiply', a, c(n))
def div(a, n): return calc('floor_divide', a, c(n))
def req(*args): return {'op': 'all', 'args': list(args)}
def need(op, id=None, n=None): return dict(op=op, **({'id': id} if id else {}), **({'min': n} if n is not None else {}))
def mod(stat, value, typ='training'): return dict(stat=stat, type=typ, value=c(value) if isinstance(value, int) else value)
def row(category, **kw):
    kw['provenance'] = dict(PROV)
    assert not any(r['id'] == kw['id'] for r in p[category]), kw['id']
    p[category].append(kw)
    return kw['id']
def feature(id, name, abilities=None, resources=None, modifiers=None, tags=None, capabilities=None, description=''):
    kw = dict(id=id, name=name, abilities=abilities or [], resources=resources or [], modifiers=modifiers or [], tags=tags or [], senses=[], hooks=[], grants=[], description=description)
    if capabilities: kw['capabilities'] = capabilities
    return row('features', **kw)
def status(id, mods=None, caps=None, turns=3):
    kw=dict(id=id,tags=[],duration={'type':'round','amount':turns,'expiry':'global_round_start'},stacking='refresh',modifiers=mods or [],effects=[])
    if caps: kw['capabilities']=caps
    return row('statuses', **kw)
def pool(id, capacity, refresh='eligible_rest'):
    return row('resources',id=id,name=id.replace('-',' ').title(),capacity=capacity,refresh=refresh)
def apply(id, own=False): return dict(op='apply_status', id=id, **({'recipient':'actor'} if own else {}))
def heal(amount): return dict(op='heal', amount=amount)
def temp(amount, own=False): return dict(op='temporary_hp', amount=amount, **({'recipient':'actor'} if own else {}))
def damage(amount, kind='physical'): return dict(op='damage',amount=amount,damage_type=kind)
def saved(amount, kind='physical', attribute='INT', tier=1, extra=None):
    d=damage(amount,kind)
    return {'op':'save','save':'reflex' if kind!='psychic' else 'will','dc':add(c(10+tier),attr(attribute),{'op':'stat','id':'save_dc'}),'on_failure':[d]+(extra or []),'on_success':[dict(d,save_half=True)]}
def power(id,name,kind,effects,cost=None,range=1,radius=0,tags=None,requirements=None,description='',main=1,move=0):
    return row('abilities',id=id,name=name,cost={'main':main,'move':move,'reaction':0,'resources':cost or {}},effects=effects,tags=tags or [],timing={'kind':'instant'},requirements=requirements or req(),targeting={'kind':kind,'range':range,'radius':radius},description=description,**{})
def grant(cls,at,id,name,abilities=None,resources=None,mods=None,caps=None,description=''):
    f=feature(id,name,abilities,resources,mods,capabilities=caps,description=description)
    cls['features'].append({'at':at,'id':f})
    return f
classes={r['id']:r for r in p['classes']}

# Ancestry is separate from culture/class. Body descriptors are honest art hooks.
ancestries=[
 ('aasimar','Aasimar',{'WIS':2,'CHA':2},'medium',{'radiant':5},['weakened'],{'insight':2},'celestial-humanoid','Radiant lineage; radiant resistance5 and immunity to Weakened.',[]),
 ('tiefling','Tiefling',{'DEX':2,'INT':2,'CHA':-2},'medium',{'fire':5},[],{'stealth':2},'horned-humanoid','Fire resistance5; inherited horns/tail are descriptors, culture is independent.',[]),
 ('kobold','Kobold',{'DEX':2,'STR':-2,'CON':-2},'small',{},[],{'craft':2},'small-reptilian','Small reptilian body; +1 defence, fast evasive movement, claw action.',[mod('defence',1),mod('stride',1)]),
 ('lizardfolk','Lizardfolk',{'STR':2,'CON':2,'INT':-2},'medium',{'physical':2},[],{'athletics':2},'reptilian','Scaled hide reduces physical damage2; natural claw action.',[]),
 ('gnoll','Gnoll',{'STR':2,'CON':2,'CHA':-2},'medium',{},[],{'perception':2},'furred-humanoid','Furred muzzle and claw attack; one extra movement tile.',[mod('stride',1)]),
 ('hobgoblin','Hobgoblin',{'DEX':2,'CON':2},'medium',{},['off-balance'],{'athletics':2},'humanoid','Stable footing prevents Off Balance; disciplined body, independent upbringing.',[]),
 ('goliath','Goliath',{'STR':2,'CON':2,'DEX':-2},'large',{},[],{'athletics':2},'large-humanoid','Large silhouette: reach2, stride3, defence−1. Occupies one tactical cell in this adaptation.',[mod('reach',1),mod('stride',-1),mod('defence',-1)]),
 ('steelbound','Steelbound',{'CON':2,'CHA':-2},'medium',{'physical':3},['weakened'],{'craft':2},'constructed-humanoid','Original constructed ancestry inspired by the Warforged research concept. Integrated plating blocks armour; healing remains available.',[mod('defence',2)]),
]
for id,name,adjust,size,resist,immune,skills,body,description,mods in ancestries:
    feats=[]
    if id in ['kobold','lizardfolk','gnoll']:
        attack=power(id+'-claws','Natural claws','creature',[],tags=['weapon_strike'],description='Main action; reach1; unarmed physical attack roll/damage, independent of the held weapon. Strength and actual combat modifiers apply.')
        p['abilities'][-1]['attack_weapon']='unarmed'
        feats=[feature(id+'-natural-weapons','Natural claws',[attack],description='A real unarmed natural attack, independent of class equipment.')]
    caps={'resistances':resist,'immunities':immune}
    if id=='steelbound':caps['blocked_equipment']=['armor']
    row('ancestries',id='heritage-'+id,people_id=id,name=name+' Standard',description=description,attribute_adjustments=adjust,size=size,skill_bonuses=skills,body_plan=body,tags=[id,'humanoid' if id!='steelbound' else 'constructed'],features=feats,modifiers=mods,capabilities=caps,visual_profile={'body_plan':body,'size':size,'head': 'muzzle' if id in ['gnoll','kobold','lizardfolk'] else 'humanoid','torso':'plated' if id=='steelbound' else 'standard','arms':2,'legs':2,'optional_features':['horns','tail'] if id=='tiefling' else ['tail'] if id in ['kobold','lizardfolk'] else [],'art_status':'neutral_humanoid_fallback'})
    p['ancestries'][-1]['provenance']['source_concept']='Warforged' if id=='steelbound' else name
# Real inherited variations; no claim of aquatic/flight/darkness mechanics.
for id,name,base,changes in [
 ('tiefling-ash','Tiefling Ash','tiefling',{'capabilities':{'resistances':{'fire':8}},'attribute_adjustments':{'CON':2,'INT':2,'CHA':-2}}),
 ('aasimar-dawn','Aasimar Dawn','aasimar',{'capabilities':{'resistances':{'radiant':3},'immunities':['off-balance']},'attribute_adjustments':{'STR':2,'CHA':2}}),
 ('kobold-stone','Kobold Stone','kobold',{'modifiers':[mod('defence',2),mod('stride',-1)],'attribute_adjustments':{'DEX':2,'CON':2,'STR':-2}}),
 ('steelbound-scout','Steelbound Scout','steelbound',{'size':'small','attribute_adjustments':{'DEX':2,'CON':2,'STR':-2},'modifiers':[mod('defence',1),mod('stride',1)]}),
]:
    base_row=copy.deepcopy(next(r for r in p['ancestries'] if r['id']=='heritage-'+base))
    base_row.update(id='heritage-'+id,name=name,description='Original TRHGD inherited variant: '+name+'. Numerical adjustments/capabilities are shown on the sheet.',**changes)
    p['ancestries'].append(base_row)

# Core13–20: genuine actions/control/survival, additional tier slots/spells and choices.
high={
 'barbarian':('rage-uses','self','Titan fury',[apply('raging'),temp(mul(cl('barbarian'),2)),{'op':'remove_status','id':'slowed'}],0,0),
 'bard':('performance','ally','Resonant renewal',[heal(cl('bard')),{'op':'remove_status','id':'weakened'},{'op':'remove_status','id':'off-balance'}],5,2),
 'cleric':('channel','ally','Sanctuary of restoration',[heal(mul(cl('cleric'),2)),{'op':'remove_status','id':'slowed'},apply('warded')],5,2),
 'druid':('wildshape','self','Primal ironhide',[],0,0),
 'fighter':('fighter-resolve','creature','Whirlwind discipline',[saved(add(c(6),cl('fighter')),'physical','STR',6)],1,1),
 'monk':('ki','creature','Resonating palm',[saved(add(c(4),cl('monk')),'force','WIS',6,[apply('off-balance')])],2,0),
 'paladin':('lay-hands','ally','Unbroken covenant',[heal(mul(cl('paladin'),2)),{'op':'remove_status','id':'weakened'},apply('oath-shelter')],4,2),
 'ranger':('tracker-resolve','creature','Pinpoint quarry',[],6,0),
 'rogue':('rogue-talent-uses','creature','Expose the opening',[apply('expert-feint'),apply('weakened'),temp(cl('rogue'),True)],4,0),
 'sorcerer':('bloodline-uses','creature','Bloodline cataclysm',[saved({'dice':'6d6','bonus':cl('sorcerer')},'arcane','CHA',6,[apply('slowed')])],6,1),
 'wizard':('school-uses','ally','Master abjuration',[apply('scholar-ward'),{'op':'remove_status','id':'slowed'}],6,1),
}
for id in high:
    cls=classes[id];cls['max_level']=20
    if id=='fighter':cls['bonus_feat_levels']=list(range(2,21,2))
    if id=='monk':cls['bonus_feat_levels'] += [14,18]
    if cls.get('known_spell_limits'):cls['known_spell_limits'] += list(range(cls['known_spell_limits'][-1]+1,cls['known_spell_limits'][-1]+9))
    resource,kind,name,effects,reach,radius=high[id]
    resource_row=next(r for r in p['resources'] if r['id']==resource)
    resource_row['capacity']=add(resource_row['capacity'],calc('max',c(0),div(add(cl(id),c(-12)),4)))
    for at in [13,16,20]:
        aid=f'{id}-master-{at}';fx=copy.deepcopy(effects);caps=None
        if id=='druid':
            st=status(aid+'-form',[mod('damage',at//4),mod('defence',2)],{'resistances':{'physical':at//4},'immunities':['slowed'],'weapon_damage':{'unarmed':'2d6' if at<20 else '2d10'}})
            fx=[apply(st),temp(cl(id))]
        elif id=='ranger':
            st=status(aid+'-aim',[mod('damage',at//3),mod('ranged_attack',2)],turns=1)
            fx=[apply(st,True)];kind='creature'
        elif id=='barbarian':
            st=status(aid+'-hardiness',[],{'resistances':{'physical':at//4}})
            fx.append(apply(st))
        elif id=='monk':
            caps={'weapon_damage':{'unarmed':{13:'2d6',16:'2d8',20:'2d10'}[at]}}
        elif id=='wizard':
            st=status(aid+'-ward',[mod('defence',at//4)],{'resistances':{'arcane':at//3}},turns=3)
            fx.append(apply(st))
        if at>=16 and id not in ['druid','ranger']:fx.append(temp(cl(id),kind=='creature'))
        if at==20:
            if kind in ['self','ally']:fx.append({'op':'remove_status','id':'off-balance'})
            else:fx.append({'op':'remove_status','id':'weakened','recipient':'actor'})
        power(aid,name+f' {at}',kind,fx,{resource:2 if at<20 else 3},reach,radius,tags=['weapon_strike'] if id=='ranger' else [],description=f'Class{at}: '+name+'; main action, '+str(2 if at<20 else 3)+' '+resource+'; bounded recovery/control or damage with actual status effects.')
        grant(cls,at,aid+'-feature',name,[aid],[resource],caps=caps,description=p['abilities'][-1]['description'])
    # High-career choices retain the original identity choice and add an actual action.
    first=cls['career_choices'][0]
    group=copy.deepcopy(first);group.update(id=id+'-choice-15',name=first['name']+' master technique',at=15)
    for option in group['options']:
        inherited=option['features'][0]
        option['requirements']=need('feature',inherited)
        option['features'] += [id+'-master-13-feature']
        option['description'] += ' Master career preserves your original choice and grants its higher technique.'
    # It selects a distinct enduring modifier rather than a duplicate grant.
    for option,stat in zip(group['options'],['defence','save_dc']):
        fid=feature(id+'-master-choice-'+option['id'],option['name']+' mastery',modifiers=[mod(stat,2)],description='Persistent '+stat+' +2; original specialisation required.')
        option['features']=[fid];option['description']=p['features'][-1]['description']
    cls['career_choices'].append(group)

# Higher core spell tiers, complete existing bounded casting repertoire through20.
for id in ['wizard','sorcerer','cleric','druid','bard','paladin','ranger']:
    cls=classes[id];attrid=cls['casting_attribute'];prepared=cls['spell_mode']=='prepared'
    tiers=[(7,13),(8,15),(9,17)] if id not in ['bard','paladin','ranger'] else [(5,13),(6,16)]
    for tier,at in tiers:
        slot=pool(f'{id}-slots-{tier}',calc('max',c(1),add(c(1),div(add(cast(id),c(-at)),2),calc('max',c(0),attr(attrid)))))
        p['resources'][-1].update(slot_class=id,spell_tier=tier)
        ids=[];resources=[slot]
        for variant in ['tempest','sanctuary']:
            aid=f'{id}-tier{tier}-{variant}';cost={slot:1}
            if prepared:
                copies=pool(aid+'-copies',c(0));p['resources'][-1]['prepared_ability']=aid;resources.append(copies);cost[copies]=1
            if variant=='tempest':fx=[saved({'dice':f'{tier}d6','bonus':cast(id)},'arcane' if cls['casting_tradition']=='arcane' else 'radiant',attrid,tier,[apply('slowed')])];kind='creature';radius=1
            else:
                st=status(aid+'-status',[mod('defence',tier//2),mod('will',tier//2)],{'resistances':{'physical':tier//2},'immunities':['weakened']})
                fx=[heal(add(c(tier*2),cast(id))),apply(st),{'op':'remove_status','id':'off-balance'}];kind='ally';radius=1
            power(aid,cls['name']+': '+variant.title()+f' {tier}',kind,fx,cost,6,radius,tags=['spell','prepared' if prepared else 'spontaneous',f'tier_{tier}'],requirements=need('attribute',attrid,10+tier),description=f'Tier{tier}: '+('saved area damage and Slowed; resisted damage is halved.' if variant=='tempest' else 'area healing, physical resistance, Weakened immunity and recovery.'))
            p['abilities'][-1].update(casting_class=id,spell_tier=tier);ids.append(aid)
        grant(cls,at,f'{id}-casting-{tier}',cls['name']+f' tier{tier}',ids,resources,description='Actual slots, preparation/known selection and two executable spells.')
        p['features'][-1]['tags']=['casting_tier']

# Eight distinct alternative classes. All newly implemented tracks initially1–12.
def newclass(id,name,hp,skills,bab,save,profs,gear,description):
    cls=copy.deepcopy(classes['fighter'])
    cls.update(id=id,name=name,max_level=12,hp_per_level=hp,skill_points=skills,bab=bab,casting=c(0),casting_tradition='',spell_mode='',casting_attribute='',bonus_feat_levels=[],features=[],career_choices=[],class_kind='base',class_skills=save[1],proficiencies=profs,recommended_equipment=gear,description=description,provenance=dict(PROV))
    cls['saves']={s:add(c(2),div(cl(id),2)) if s in save[0] else div(cl(id),3) for s in ['fortitude','reflex','will']}
    p['classes'].append(cls);classes[id]=cls;return cls
def choice(cls,id,label,options,at=1):
    cls['career_choices'].append(dict(id=id,name=label,at=at,options=[dict(id=key,name=name,description=description,features=[f],requirements=req()) for key,name,f,description in options]))
for id,name,hp,points,bab,save,profs,gear,description in [
 ('psion','Psion',3,4,div(cl('psion'),2),(['will'],['arcana','insight','spellcraft']),['simple'],['staff'],'Psychic specialist: shared power points; choose telepathy or kinetic focus. Augmented actions cost more points; no spell slots.'),
 ('psychic-warrior','Psychic Warrior',5,2,div(mul(cl('psychic-warrior'),3),4),(['fortitude'],['athletics','arcana']),['simple','martial','medium','shield'],['shortblade','mail','shield'],'Armoured psychic martialist: power points buy physical augmentation and manifested strikes. Lower point capacity than Psion.'),
 ('soulknife','Soulknife',5,4,div(mul(cl('soulknife'),3),4),(['reflex','will'],['acrobatics','stealth']),['simple','martial','light'],['unarmed','leathers'],'Manifest a mind blade; replenish psychic focus with a full main action and spend it on a charged strike.'),
 ('warlock','Warlock',4,4,div(mul(cl('warlock'),3),4),(['will'],['arcana','persuasion']),['simple','light'],['staff','leathers'],'Repeatable eldritch blast and durable invocation choices. No spell slots/points: sustained damage trades against main-action wards/control.'),
 ('scout','Scout',4,6,div(mul(cl('scout'),3),4),(['reflex'],['stealth','perception','athletics']),['simple','martial','light'],['bow','leathers'],'Movement creates an actual once-per-activation skirmish damage opening; precise mobile ranged fighting with survey/travel training.'),
 ('swashbuckler','Swashbuckler',5,4,cl('swashbuckler'),(['reflex'],['acrobatics','persuasion']),['simple','martial','light'],['shortblade','leathers'],'Dexterous blade fighting: finesse accuracy, limited panache for attack-and-ward or disarming control. Not a Fighter feat progression.'),
 ('knight','Knight',6,2,cl('knight'),(['fortitude','will'],['athletics','insight']),['simple','martial','heavy','medium','light','shield'],['shortblade','mail','shield'],'Shared-reaction ally protection; limited challenges weaken targets while anchoring a defensive line. No promised AI taunt.'),
 ('warblade','Warblade',6,4,cl('warblade'),(['fortitude'],['athletics','acrobatics']),['simple','martial','medium','light'],['shortblade','mail'],'Martial manoeuvres spend encounter readiness. Recover readiness with a main action; choose durable aggressive or defensive stance.'),
]:
    cls=newclass(id,name,hp,points,bab,save,profs,gear,description)
    cls['provenance']['source_concept']=name
    resource=pool(id+'-points' if id in ['psion','psychic-warrior'] else id+'-readiness' if id=='warblade' else id+'-focus' if id=='soulknife' else id+'-resolve',add(c(2),mul(cl(id),2 if id=='psion' else 1)), 'encounter' if id in ['warblade','soulknife'] else 'eligible_rest') if id!='warlock' else None
    if id in ['warblade','soulknife']:
        # Capacities remain bounded regardless of multiclass history; no repeated free action.
        next(r for r in p['resources'] if r['id']==resource)['capacity']=c(2)
        recovery=power(id+'-recover','Recover '+('manoeuvres' if id=='warblade' else 'psychic focus'),'self',[{'op':'restore_resource','id':resource,'amount':c(2)}],description='Main action restores2 readiness/focus; cannot also attack this activation.')
        grant(cls,1,id+'-recovery','Recover readiness',[recovery],[resource])
    if id=='scout':grant(cls,1,'scout-skirmish','Skirmish',mods=[mod('stride',1)],caps={'moving_damage':add(c(1),div(cl(id),3))},description='After actual movement, first weapon hit gains1 + class level/3 damage. Shares the once-only precision opening.')
    if id=='swashbuckler':grant(cls,1,'swashbuckler-finesse','Blade finesse',mods=[mod('melee_attack',calc('max',c(0),add(attr('DEX'),mul(attr('STR'),-1))))],description='Melee accuracy uses the better of Dexterity/Strength, without changing damage attribute.')
    if id=='knight':grant(cls,1,'knight-protection','Shielding guard',['guard'],[resource],description='Guarding uses the existing shared reaction to protect an adjacent ally.')
    if id=='soulknife':
        st=status('soulknife-manifested',[mod('damage',2)],{'weapon_damage':{'unarmed':'1d8'}},turns=3)
        aid=power('soulknife-manifest','Manifest mind blade','self',[apply(st)],range=0,description='Main action;3 rounds: +2 damage, unarmed weapon becomes1d8. Original equipment history is retained.')
        grant(cls,1,'soulknife-blade','Mind blade',[aid],description=p['abilities'][-1]['description'])
    for at in [1,4,8,12]:
        aid=f'{id}-technique-{at}';cost={resource:1 if at<8 else 2} if resource else {};kind='creature';tags=[];reach=5;fx=[]
        if id=='psion':
            cost={resource:1 if at==1 else at//2}
            fx=[saved(add(c(at+2),cl(id)),'psychic','INT',at//2+1,[apply('weakened')])]
            name='Mind thrust' if at==1 else 'Augmented mind thrust '+str(at)
        elif id=='psychic-warrior':
            st=status(aid+'-augmentation',[mod('damage',at//3+1),mod('defence',1)],turns=2)
            fx=[apply(st,True),temp(cl(id),True)];tags=['weapon_strike'];reach=1;name='Augmented strike '+str(at)
        elif id=='soulknife':
            st=status(aid+'-charged',[mod('damage',at//2+2)],turns=1)
            fx=[apply(st,True)];tags=['weapon_strike'];reach=1;name='Psychic strike '+str(at)
        elif id=='warlock':
            fx=[saved(add(c(2),div(cl(id),2),c(at)),'arcane','CHA',at//3+1,[apply('off-balance')] if at>=8 else [])]
            name='Eldritch blast' if at==1 else 'Shaping blast '+str(at)
        elif id=='scout':
            fx=[apply('off-balance')];tags=['weapon_strike'];reach=6;name='Mark the opening '+str(at)
            if at>=8:fx.append({'op':'remove_status','id':'slowed','recipient':'actor'})
        elif id=='swashbuckler':
            st=status(aid+'-fencing',[mod('defence',1+at//4)],turns=2)
            fx=[apply(st,True),apply('weakened')];tags=['weapon_strike'];reach=1;name='Disarming flourish '+str(at)
        elif id=='knight':
            fx=[apply('weakened'),apply('guarding',True),temp(add(c(at),cl(id)),True)];reach=3;name='Resolute challenge '+str(at)
        else:
            st=status(aid+'-edge',[mod('damage',2+at//3),mod('defence',-1,'condition')],turns=1)
            fx=[apply(st,True)];tags=['weapon_strike'];reach=1;name='Iron-edge manoeuvre '+str(at)
        power(aid,name,kind,fx,cost,reach,tags=tags,description=name+'; main action; '+(', '.join(str(v)+' '+k.replace('-',' ') for k,v in cost.items()) if cost else 'at will')+'; '+{'psion':'Will save; psychic damage and Weakened on failure, half damage on success.','psychic-warrior':'Augment damage and defence for2 rounds, gain temporary HP, then make a normal weapon strike.','soulknife':'Charge weapon damage for1 round, then strike. Recover psychic focus with a main action.','warlock':'Reflex save against eldritch damage; half on success. Higher blasts also disrupt footing.','scout':'Weapon strike creates Off Balance; actual movement enables the first-hit skirmish bonus.','swashbuckler':'Weapon strike weakens the target and guards the fencer for2 rounds.','knight':'Weaken the target, gain temporary HP and Guarding; protect an adjacent ally with the shared reaction.','warblade':'Weapon strike with a1-round damage surge and defence trade-off; consumes readiness.'}[id])
        grant(cls,at,aid+'-feature',name,[aid],[resource] if resource else [],description=p['abilities'][-1]['description'])
    options=[]
    for key,stat in [('assault','save_dc' if id=='warlock' else 'damage'),('ward','defence')]:
        fid=feature(id+'-discipline-'+key,key.title()+' discipline',modifiers=[mod(stat,2)],description='Persistent '+stat+' +2; mutually exclusive discipline.')
        if id=='warlock':
            st=status(id+'-invocation-'+key,[mod(stat,3)],turns=2)
            aid=power(id+'-invocation-'+key,key.title()+' invocation','self',[apply(st)],range=0,description='At-will main action;2-round '+stat+' +3 invocation. Choosing it replaces the other invocation.')
            next(r for r in p['features'] if r['id']==fid)['abilities']=[aid]
        options.append((key,key.title(),fid,p['features'][-1]['description']))
    choice(cls,id+'-discipline','Invocation' if id=='warlock' else 'Discipline / stance',options)

# Four further prestige tracks, actual progression lengths and honest entry facts.
prestiges=[
 ('shadowdancer','Shadowdancer',req(need('level',n=5),need('skill','stealth',5),need('feat','dodge')),10,'Shadow shroud; physical weapon concealment and mobile control, no teleportation promise.'),
 ('dragon-disciple','Dragon Disciple',req(need('level',n=5),need('casting','arcane',3),need('skill','arcana',4)),10,'Inherited draconic manifestation, fiery breath, natural protection; ancestry history is never overwritten.'),
 ('dwarven-defender','Dwarven Defender',req(need('bab',n=5),need('ancestry','dwarf'),need('feat','toughness')),10,'Defensive stance trades all movement for physical resistance and defensive modifiers.'),
 ('pyrokineticist','Pyrokineticist',req(need('level',n=5),need('resource','psion-points',6),need('skill','arcana',4)),10,'Psychic ignition spends existing power points; fire effects differ from mind attacks.'),
]
for id,name,entry,cap,description in prestiges:
    cls=newclass(id,name,4,4,div(mul(cl(id),3),4),(['will'],['stealth','arcana','athletics']),['simple','martial','light'],['shortblade','leathers'],description)
    cls.update(class_kind='prestige',max_level=cap,requirements=entry);cls['provenance']['source_concept']=name
    if id=='dragon-disciple':
        options=[]
        for caster in ['wizard','sorcerer','bard']:
            options.append(dict(id=caster,name=classes[caster]['name'],description='Every two prestige levels advance the selected existing arcane casting track once; no unrelated class powers.',features=[],requirements=need('class_level',caster,1),advance_casting=caster,progression_class=id,advance_ratio=2))
        cls['career_choices'].append(dict(id=id+'-casting',name='Arcane lineage track',at=1,options=options))
        grant(cls,1,id+'-scales','Draconic scales',mods=[mod('defence',2)],caps={'weapon_damage':{'unarmed':'1d6'}})
    if id=='pyrokineticist':grant(cls,1,id+'-power-growth','Psychic fire reservoir',caps={'resource_bonuses':{'psion-points':cl(id)}})
    resource='psion-points' if id=='pyrokineticist' else pool(id+'-uses',add(c(1),div(cl(id),3)))
    for at in [1,4,7,10]:
        aid=f'{id}-technique-{at}';kind='self';reach=0;fx=[]
        if id=='shadowdancer':
            st=status(aid+'-shroud',[mod('stride',1)],{'concealment':20+at*2},turns=2)
            fx=[apply(st),{'op':'remove_status','id':'slowed'}]
        elif id=='dragon-disciple':
            kind='creature';reach=4;fx=[saved(add(c(4+at),cl(id)),'fire','CHA',at//2+1)]
        elif id=='dwarven-defender':
            st=status(aid+'-stance',[mod('defence',2+at//3)],{'immobile':True,'resistances':{'physical':3+at//2}},turns=2)
            fx=[apply(st),temp(cl(id))]
        else:
            kind='creature';reach=5;fx=[saved({'dice':f'{1+at//3}d6','bonus':cl(id)},'fire','INT',at//2+1,[apply('weakened')])]
        power(aid,name+' technique '+str(at),kind,fx,{resource:2 if id=='pyrokineticist' else 1},reach,description=description+f' Class{at}; real limited action.')
        grant(cls,at,aid+'-feature',name+' technique '+str(at),[aid],[resource],caps={'resistances':{'fire':at}} if id in ['dragon-disciple','pyrokineticist'] else None,description=p['abilities'][-1]['description'])

# Supporting feats with genuine requirements and effects.
for id,name,requirements,mods,caps in [
 ('psychic-reservoir','Psychic reservoir',need('class_level','psion',3),[],{'resource_bonuses':{'psion-points':c(2)}}),
 ('iron-soul','Iron soul',need('class_level','soulknife',4),[mod('defence',2)],{'immunities':['weakened']}),
 ('mobile-skirmisher','Mobile skirmisher',req(need('class_level','scout',4),need('feat','mobility')),[mod('stride',1)],None),
 ('invocation-ward','Invocation ward',need('class_level','warlock',4),[],{'resistances':{'arcane':3}}),
 ('adamant-stance','Adamant stance',need('class_level','warblade',4),[mod('fortitude',2)],None),
 ('natural-armour','Natural armour',need('ancestry','lizardfolk'),[mod('defence',2)],None),
 ('greater-resilience','Greater resilience',req(need('feat','toughness'),need('level',n=13)),[],{'resistances':{'physical':3}}),
 ('master-arcane-focus','Master arcane focus',req(need('feat','greater-spell-focus'),need('level',n=13)),[mod('save_dc',2)],None),
]:
    f=feature(id+'-feature',name,modifiers=mods,capabilities=caps,description='Original mechanical feat; displayed modifiers/capabilities apply to actual rules.')
    row('feats',id=id,name=name,requirements=requirements,features=[f],repeatable=False,choice_parameters=[])
    p['feats'][-1]['provenance']['source_concept']=name

# Data-driven recommended arrays for new tracks, no competing class switches.
for id,priority in {
 'psion':['INT','DEX','CON','WIS','CHA','STR'],
 'psychic-warrior':['WIS','STR','CON','DEX','INT','CHA'],
 'soulknife':['DEX','STR','CON','WIS','INT','CHA'],
 'warlock':['CHA','DEX','CON','INT','WIS','STR'],
 'scout':['DEX','INT','CON','WIS','STR','CHA'],
 'swashbuckler':['DEX','CHA','CON','STR','WIS','INT'],
 'knight':['STR','CON','CHA','WIS','DEX','INT'],
 'warblade':['STR','CON','INT','DEX','WIS','CHA'],
}.items():classes[id]['attribute_priority']=priority
# Variant anatomy must remain internally consistent.
for row in p['ancestries']:
 if row.get('visual_profile'):
  row['visual_profile']['size']=row['size'];row['visual_profile']['body_plan']=row['body_plan']

# Publication pin is computed from canonical JSON, matching the existing Godot resolver.
path=ROOT/'data/rules/trhgd-character-v10.json'
path.write_text(json.dumps(p,indent=2)+'\n')
manifest_path=ROOT/'data/rules/packs.json';manifest=json.loads(manifest_path.read_text())
manifest['packs']=[r for r in manifest['packs'] if r['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k] for k in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs'].append({'path':'res://data/rules/trhgd-character-v10.json','rules_ref':pin})
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'pin':pin,'base_classes':19,'prestige_classes':8,'race_families':17,'heritages':26,'feats':38}))
