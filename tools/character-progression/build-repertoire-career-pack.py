"""Keep v1-v8 exact; a full prior repertoire can learn each newly unlocked tier."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v8.json').read_text());p.update(pack_id='trhgd-character-v9',rules_version='9.0.0')
for r in p['classes']:
 if r['id']=='bard':r['known_spell_limits']=[0,2,2,3,4,4,5,6,6,6,7,7,8]
 if r['id']=='sorcerer':r['known_spell_limits']=[0,2,2,3,4,4,5,6,7,8,9,10,11]
(root/'data/rules/trhgd-character-v9.json').write_text(json.dumps(p,indent=2)+'\n')
mp=root/'data/rules/packs.json';m=json.loads(mp.read_text());m['packs']=[r for r in m['packs'] if r['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest();m['packs'].append({'path':'res://data/rules/trhgd-character-v9.json','rules_ref':pin});mp.write_text(json.dumps(m,indent=2)+'\n');print(pin)
