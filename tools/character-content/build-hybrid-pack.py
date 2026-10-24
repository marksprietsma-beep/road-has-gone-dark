"""Append only the verified advanced-casting corrections; keep1–27 immutable."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2];p=json.loads((root/'data/rules/trhgd-character-v27.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v28',rules_version='28.0.0');p['provenance']=dict(p['provenance'],revision='duskblade-archmage-acceptance')
changed=[]
for row in p['abilities']:
 if not row['id'].startswith('high-arcana-'):continue
 row['tags'].append('supernatural')
 row['description']+=' Supernatural; unavailable while a form suppresses supernatural casting.'
 if row['id'].startswith('high-arcana-force-'):
  row['effects'][0]['dc']['args'][1]={'op':'casting_modifier','id':'archmage'}
  row['description']+=' The save DC uses the casting attribute of your permanently selected arcane progression.'
 row['provenance']=dict(row['provenance'],revision='duskblade-archmage-acceptance');changed.append(row['id'])
assert len(changed)==6
(root/'data/rules/trhgd-character-v28.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
f=root/'data/rules/packs.json';manifest=json.loads(f.read_text(encoding='utf-8'));manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']];manifest['packs'].append({'path':'res://data/rules/'+p['pack_id']+'.json','rules_ref':pin});f.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n');print(json.dumps({'rules_ref':pin,'changed_abilities':changed}))
