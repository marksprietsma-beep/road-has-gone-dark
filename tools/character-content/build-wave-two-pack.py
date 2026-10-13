"""Append v12 from immutable v11. Original bounded mechanics, no supplement prose."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v11.json').read_text())
p.update(pack_id='trhgd-character-v12',rules_version='12.0.0')
P={'origin':'Original TRHGD mechanics and prose; research concepts are indexing references only','license':'Original project-authored content','revision':'game112-wave-two'}
p['provenance']=P;p['creatures']=[]
def c(n):return {'op':'const','value':n}
def cl(id):return {'op':'class_level','id':id}
def calc(op,*args):return {'op':op,'args':list(args)}
def add(*args):return calc('sum',*args)
def mul(a,n):return calc('multiply',a,c(n))
def div(a,n):return calc('floor_divide',a,c(n))
def req(*args):return {'op':'all','args':list(args)}
def need(op,id=None,n=None):return dict(op=op,**({'id':id}if id else{}),**({'min':n}if n is not None else{}))
def mod(stat,n,typ='training'):return dict(stat=stat,type=typ,value=c(n)if isinstance(n,int)else n)
def row(category,**kw):
 assert not any(r['id']==kw['id']for r in p[category]),kw['id']
 kw['provenance']=dict(P);p[category].append(kw);return kw['id']
def get(cat,id):return next(r for r in p[cat]if r['id']==id)
def feat(id,name,abilities=None,resources=None,mods=None,tags=None,caps=None,**kw):
 fields=dict(id=id,name=name,modifiers=mods or [],abilities=abilities or [],resources=resources or [],tags=tags or [],senses=[],hooks=[],grants=[],description=name,**kw)
 if caps:fields['capabilities']=caps
 return row('features',**fields)
def pool(id,capacity,refresh='eligible_rest'):return row('resources',id=id,name=id.replace('-',' ').title(),capacity=capacity,refresh=refresh)
def ability(id,name,kind,effects,cost=None,tags=None,description='',reach=1,**kw):return row('abilities',id=id,name=name,cost=dict(main=1,move=0,reaction=0,resources=cost or{}),effects=effects,tags=tags or[],timing={'kind':'instant'},requirements=req(),targeting=dict(kind=kind,range=reach,radius=0),description=description or name,**kw)
def status(id,mods=None,caps=None,turns=3,**kw):
 fields=dict(id=id,tags=[],duration=dict(type='round',amount=turns,expiry='global_round_start'),stacking='refresh',modifiers=mods or[],effects=[],**kw)
 if caps:fields['capabilities']=caps
 return row('statuses',**fields)
def apply(id,own=False):return dict(op='apply_status',id=id,**({'recipient':'actor'}if own else{}))
def damage(n,kind='physical'):return dict(op='damage',amount=c(n)if isinstance(n,int)else n,damage_type=kind)
def tier(cls,at,feature):get('classes',cls)['features'].append(dict(at=at,id=feature))
def choice(cls,id,name,at,options):get('classes',cls)['career_choices'].append(dict(id=id,name=name,at=at,options=options))
def option(id,name,features,requirements=None,description=''):return dict(id=id,name=name,description=description or name,features=features,requirements=requirements or req())
# Non-player creature advancement track. Hidden from creator; no research-class count.
base=copy.deepcopy(get('classes','fighter'))
base.update(id='bond-creature',name='Owned creature',max_level=20,hp_per_level=4,skill_points=1,features=[],career_choices=[],class_kind='companion',bonus_feat_levels=[],class_skills=['athletics','perception'],proficiencies=[],recommended_equipment=[],description='Internal owned actor progression; creature definitions supply anatomy and natural weapons.',provenance=dict(P))
base['bab']=cl('bond-creature');base['saves']={s:div(cl('bond-creature'),2 if s=='fortitude'else 3)for s in ['fortitude','reflex','will']}
p['classes'].append(base)
for id,name,dice,reach in [('nature-bite','Natural bite','1d6',1),('bear-claws','Bear claws','1d10',2),('spirit-slam','Spirit slam','1d8',1),('bull-gore','Horn gore','1d8',2)]:
 row('equipment',id=id,name=name,kind='weapon',requirements=req(),modifiers=[],tags=['natural'],reach=reach,range=reach,damage=dice,damage_type='physical',proficiency='')
for id,name,attrs,weapon,mods,size in [
 ('wolf','Wolf',dict(STR=14,DEX=15,CON=13,INT=8,WIS=12,CHA=10),'nature-bite',[mod('stride',1),mod('defence',1)],'medium'),
 ('bear','Bear',dict(STR=15,DEX=10,CON=14,INT=8,WIS=13,CHA=12),'bear-claws',[mod('defence',2),mod('reach',1)],'large'),
 ('sentinel-spirit','Sentinel spirit',dict(STR=14,DEX=12,CON=15,INT=8,WIS=13,CHA=10),'spirit-slam',[mod('defence',2)],'medium')]:
 aid=ability(id+'-natural-strike',name+' strike','creature',[],tags=['weapon_strike'],attack_weapon=weapon,reach=2 if size=='large'else 1,description='Natural main-action weapon attack, rolled by GAME-32. No held equipment required.')
 f=feat(id+'-creature-body',name+' body',[aid],mods=mods,caps={'blocked_equipment':['weapon','armor','shield']})
 row('creatures',id=id,name=name,attributes=attrs,feature_id=f,weapon_id=weapon,body_plan='quadruped'if id!='sentinel-spirit'else'spirit-biped',size=size)
# Persistent, selected companion: Druid full class level; Ranger class level minus3.
for cls,at,offset in [('druid',1,0),('ranger',4,-3)]:
 options=[]
 for creature in ['wolf','bear']:
  f=feat(cls+'-'+creature+'-bond',creature.title()+' companion',companion=dict(creature_id=creature,level_class=cls,offset=offset,divisor=1))
  options.append(option(creature,creature.title(),[f],description='Persistent '+creature+'; owns movement/main/reaction, damage and conditions; level '+cls+(' minus3'if offset else'')+'. One nature companion per character.'))
 choice(cls,cls+'-companion', 'Animal companion',at,options)
# Body forms suppress equipment, retain identity, HP/conditions, resources and histories.
for id,name,attrs,weapon,mods,size in [
 ('bear-form','Bear',{'STR':4,'DEX':-2},'bear-claws',[mod('defence',2),mod('reach',1),mod('stride',-1)],'large'),
 ('wolf-form','Wolf',{'STR':2,'DEX':4},'nature-bite',[mod('stride',2),mod('defence',1)],'medium')]:
 f=feat(id+'-body',name+' anatomy',mods=mods)
 body=dict(id=id,body_plan='quadruped',size=size,attributes=attrs,feature_id=f,weapon_id=weapon,suppressed_equipment=['weapon','armor','shield'],art_status='neutral_humanoid_fallback')
 if id=='bear-form':get('statuses',id).update(modifiers=[],body_form=body,provenance=dict(P))
 else:status(id,body_form=body)
get('abilities','wild-shape').update(description='Main action, one Wild Shape use: three global rounds as a large bear. Strength+4, Dexterity−2, reach2, stride−1, claws1d10. Equipment melds; spells suppressed; HP and conditions persist. Humanoid art fallback is labelled.',provenance=dict(P))
wolf=ability('wild-shape-wolf','Wild shape: wolf','self',[apply('wolf-form')],{'wildshape':1},description='Three rounds: Strength+2, Dexterity+4, stride+2; bite1d6. Equipment melds and spells are suppressed; health remains the character’s. Fallback appearance labelled.')
revert=ability('revert-form','Return to original form','self',[{'op':'remove_status','id':'bear-form'},{'op':'remove_status','id':'wolf-form'}],description='Main action, no resource cost; removes body form without healing or removing other conditions.')
get('features','druid-shape')['abilities'] += [wolf,revert]
# Higher Druid defensive techniques also use real body descriptors and can revert.
for at in [13,16,20]:
 st=get('statuses',f'druid-master-{at}-form');st['body_form']=copy.deepcopy(get('statuses','bear-form')['body_form']);st['body_form']['id']=st['id']
 get('abilities','revert-form')['effects'].append(dict(op='remove_status',id=st['id']))
# Prepared temporary summons: actual tier slot + prepared copy, three global rounds.
for cls,attr in [('wizard','INT'),('cleric','WIS'),('druid','WIS')]:
 id=cls+'-summon-sentinel';prepared=cls+'-prepared-summon-sentinel';slot=cls+'-slots-1'
 pool(prepared,c(0));get('resources',prepared)['prepared_ability']=id
 ability(id,'Summon sentinel','self',[dict(op='summon',id='sentinel-spirit',rounds=3)],{slot:1,prepared:1},['spell','prepared','tier_1'],description='Main action, tier-one slot and prepared copy. One sentinel per caster, placed on the first clear adjacent tile; acts after caster, expires after three global round boundaries. Dismissal costs a main action.',reach=0,casting_class=cls,spell_tier=1)
 get('abilities',id)['requirements']=need('attribute',attr,11)
 cast=get('features',cls+'-casting-1');cast['abilities'].append(id);cast['resources'].append(prepared)
# Supporting feats amplify real creature strikes/form statistics through the owned caster.
f=feat('natural-form-training','Natural form training',mods=[mod('melee_attack',1,'circumstance')]);get('features',f)['modifiers'][0]['when']=need('tag','body_transformed')
row('feats',id='natural-form-training',name='Natural form training',requirements=need('feature','druid-shape'),features=[f],repeatable=False,choice_parameters=[])
for st in p['statuses']:
 if st.get('body_form'):st['tags'].append('body_transformed')
# Write only appended pack/manifest. Historical JSON bytes are never rewritten.
(root/'data/rules/trhgd-character-v12.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
manifest=json.loads((root/'data/rules/packs.json').read_text());manifest['packs']=[x for x in manifest['packs']if x['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs'].append(dict(path='res://data/rules/trhgd-character-v12.json',rules_ref=pin))
(root/'data/rules/packs.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(pin))
