"""Append only confirmed Cognition targeting contracts; never mutate pinned packs."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v25.json').read_text())
p.update(pack_id='trhgd-character-v26',rules_version='26.0.0')
p['provenance']=dict(p['provenance'],revision='game127-psychic-support')
for ability in p['abilities']:
 if ability['id'].startswith('cognition-strike-'):
  ability['requires_adjacent']=True
  ability['requires_melee']=True
  ability['description']='Main action and '+str(ability['cost']['resources']['psychic-points'])+' shared power points. Requires an equipped melee weapon and a living enemy exactly one orthogonal tile away. Extra ancestry or weapon reach does not extend this strike. Original direct psychic damage precedes a separately rolled weapon attack, which can miss or be concealed. Psychic resistance still applies.'
  ability['provenance']=dict(ability['provenance'],revision='game127-psychic-support')
path=root/'data/rules/trhgd-character-v26.json'
path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text())
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(pin))
