"""Append v29 after pinned Windows reproduction; never rewrite v1–v28."""
from pathlib import Path
import copy
import hashlib
import json

ROOT=Path(__file__).resolve().parents[2]
p=json.loads((ROOT/'data/rules/trhgd-character-v28.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v29',rules_version='29.0.0')
prov=dict(origin='Original bounded TRHGD dual-caster prestige adaptations; no sourcebook prose copied',license='Original project-authored content',revision='game123-dual-prestige')
p['provenance']=dict(p['provenance'],revision=prov['revision'])
classes={r['id']:r for r in p['classes']}

def const(n):return dict(op='const',value=n)
def total(*args):return dict(op='sum',args=list(args))
def existing_parents(group,tradition,path,minimum):
    # Keep existing ordering/defaults and add genuine supported casters only.
    previous={r['id']:r for r in group['options']}
    ids=list(previous)+[r['id']for r in p['classes']if r.get('class_kind')=='base'and r.get('casting_tradition')==tradition and r.get('spell_mode')and r['id']not in previous]
    options=[]
    for identity in ids:
        option=copy.deepcopy(previous.get(identity,dict(id=identity,name=classes[identity]['name'],features=[],requirements=dict(op='class_level',id=identity,min=minimum),advance_casting=identity,progression_class=path)))
        option['description']=f"Advance only {classes[identity]['name']}'s existing casting tiers, repertoire and slots once per prestige level. Its {classes[identity]['casting_attribute']} requirement, known/prepared/retrieved choices and pools remain independent; no unrelated class powers or borrowed slots. A junior parent advances from its own level."
        options.append(option)
    group['options']=options

theurge=classes['mystic-theurge']
theurge['max_level']=10
theurge['description']='Ten optional dual-caster prestige levels. Advance one existing arcane and one divine track independently; neither inherits another caster\'s spell tiers, resources or class powers. Choose large restoration, bounded cleansing or preventive protection as the path develops.'
theurge['requirements']['args'] += [dict(op='spell_tier',id=tradition,min=2)for tradition in ['arcane','divine']]
for group,tradition in zip(theurge['career_choices'],['arcane','divine'],strict=True):existing_parents(group,tradition,'mystic-theurge',1)
for level in [7,9]:theurge['features'].append(dict(at=level,id=f'mystic-theurge-power-{level}-feature'))
theurge['provenance']=prov

champion=classes['abjurant-champion']
champion['requirements']['args'].append(dict(op='spell_tier',id='arcane',min=1))
casting=next(g for g in champion['career_choices']if g['id']=='abjurant-casting')
existing_parents(casting,'arcane','abjurant-champion',2)
# The class must have a legal parent choice as well as aggregate entry scores.
champion['requirements']['args'].append(dict(op='any',args=[dict(op='class_level',id=o['id'],min=2)for o in casting['options']]))
champion['provenance']=prov
for group in champion['career_choices']:
    if not group['id'].startswith('abjurant-doctrine-'):continue
    level=group['at']
    for option in group['options']:
        if option['id']=='aegis':option['description']=f'Main action and one resolve: protect one living ally at range3 with Runic shell, Spirit shelter and {6+3*level} nonstacking temporary HP. No healing, free casting or extra reaction.'
        else:option['description']=f'Main action and one resolve: gain {4+2*level} nonstacking temporary HP, then make one ordinary adjacent melee weapon attack. Buffer is retained on a miss; normal accuracy, armour, interception and shared reactions apply. No ranged weapon, free spell or second attack.'

for ability in p['abilities']:
    if ability['id'].startswith('mystic-theurge-power-')or ability['id'].startswith('abjurant-retaliation-'):
        assert 'supernatural'not in ability['tags']
        ability['tags'].append('supernatural')
        ability['description']+=' Supernatural: unavailable in a body that suppresses supernatural casting; ordinary attacks and original reversion remain available.'
        ability['provenance']=prov

for level,name,effects,description in [
    (7,'Concordant release',[dict(op='remove_status',id=s)for s in ['weakened','arcane-tether']]+[dict(op='heal',amount=total(const(4),dict(op='class_level',id='mystic-theurge')))],'Clear only Weakened and Arcane tether, then heal4 + Theurge level. Smaller healing than Restoration5; no universal dispel, resurrection, actions or resource recovery.'),
    (9,'Concordant refuge',[dict(op='temporary_hp',amount=total(const(4),dict(op='class_level',id='mystic-theurge'))),dict(op='apply_status',id='warded')],'Grant a separate nonstacking buffer4 + Theurge level and the existing finite Warded defence boon. No healing or restored spell slots; protective status expiry and the separate temporary-HP buffer retain their original policies.')]:
    aid=f'mystic-theurge-power-{level}'
    text=description+' Main action and one Mystic Theurge use; self-centred allied radius2. Supernatural; incompatible forms suppress this action.'
    p['abilities'].append(dict(id=aid,name=name,cost=dict(main=1,move=0,reaction=0,resources={'mystic-theurge-uses':1}),effects=effects,tags=['supernatural'],timing=dict(kind='instant'),requirements=dict(op='all',args=[]),targeting=dict(kind='ally',range=0,radius=2),description=text,provenance=prov))
    p['features'].append(dict(id=aid+'-feature',name=name,abilities=[aid],resources=['mystic-theurge-uses'],modifiers=[],tags=[],senses=[],hooks=[],grants=[],description=text,provenance=prov))

out=ROOT/'data/rules/trhgd-character-v29.json'
out.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
path=ROOT/'data/rules/packs.json';manifest=json.loads(path.read_text(encoding='utf-8'))
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']]
manifest['packs'].append(dict(path='res://data/rules/'+out.name,rules_ref=pin))
path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(pin))
