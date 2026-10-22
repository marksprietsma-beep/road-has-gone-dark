"""Append GAME-152 semantics; accepted v1-v23 bytes and pins stay frozen."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v23.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v24',rules_version='24.0.0')
revision='game152-psychic-resource-parity'
p['provenance']=dict(p['provenance'],revision=revision)
def row(category,identity):return next(x for x in p[category]if x['id']==identity)
assault=row('features','psion-discipline-assault')
assault['capabilities']=dict(ability_damage=dict(psychic=2))
assault['description']='Persistent weapon damage +2 and psychic ability damage +2; mutually exclusive with Ward. Does not increase healing, barriers or arcane spell damage.'
assault['provenance']=dict(assault['provenance'],revision=revision)
row('statuses','weakened')['capabilities']=dict(ability_damage=dict(psychic=-2))
row('statuses','weakened')['provenance']=dict(row('statuses','weakened')['provenance'],revision=revision)
surge=row('abilities','wilder-surge')
surge['description']='Main action and four power points: 6 + twice Wilder class level psychic damage. The existing Weakened status lasts three global round starts: melee attack, weapon damage and psychic ability damage -2. Subsequent psychic strikes, including another surge, pay that price; no extra penalty, random surge refund or resource conversion.'
surge['provenance']=dict(surge['provenance'],revision=revision)
row('classes','cerebremancer')['provenance']=dict(row('classes','cerebremancer')['provenance'],revision=revision)
row('classes','cerebremancer')['requirements']['args'].append(dict(op='spell_tier',id='arcane',min=1))
row('classes','cerebremancer')['description']+=' Entry also requires a permanently usable arcane spell: sufficient casting attribute, owned slot capacity and a known spell for spontaneous casters. Spent slots and temporary combat suppression do not change permanent eligibility.'
for cls in p['classes']:
 for group in cls.get('career_choices',[]):
  for option in group['options']:
   if option['features']==['psion-discipline-assault']:option['description']=assault['description']
   if 'psychic_profile'in cls and any(row('features',fid).get('known_power')for fid in option['features']):
    option['description']+=' Permanent known-power attribute: '+cls['psychic_profile']['attribute']+'. Uses the class that learned this power, not another psychic class or arcane casting attribute.'
path=root/'data/rules/trhgd-character-v24.json'
path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text())
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(pin))
