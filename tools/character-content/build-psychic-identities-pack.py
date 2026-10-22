"""Append GAME-127's bounded adjacency contract; never rewrite historical packs."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v24.json').read_text())
p.update(pack_id='trhgd-character-v25',rules_version='25.0.0')
p['provenance']=dict(p['provenance'],revision='game127-psychic-identities')
a=next(a for a in p['abilities']if a['id']=='lurk-psychic-ambush')
a['requires_melee']=True
a['requires_adjacent']=True
a['description']='Requires an active Psychic veil, an equipped melee weapon and a living enemy exactly one orthogonal tile away. Extra weapon or ancestry reach does not extend this ambush. Costs main action, one focus and one power point; consumes veil. The original direct psychic damage (2 + half Lurk level) and off-balance occur before a separate weapon attack roll; the weapon can still miss or be concealed. This is not invisibility or a guaranteed weapon hit.'
a['provenance']=dict(a['provenance'],revision='game127-psychic-identities')
path=root/'data/rules/trhgd-character-v25.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text())
manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(pin))
