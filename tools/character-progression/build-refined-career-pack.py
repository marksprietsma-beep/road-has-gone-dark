"""Retain published v7; refine an inferior high-level power in a new immutable pin."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v7.json').read_text())
p.update(pack_id='trhgd-character-v8',rules_version='8.0.0')
r=next(r for r in p['abilities'] if r['id']=='barbarian-career-11')
r.update(name='Renewed fury',description='Main action and two Rage uses: remove Slowed and Off Balance, enter Rage for three rounds, and gain temporary HP equal to twice Barbarian level.')
r['effects']=[{'op':'remove_status','id':'slowed'},{'op':'remove_status','id':'off-balance'},{'op':'apply_status','id':'raging'},{'op':'temporary_hp','amount':{'op':'multiply','args':[{'op':'class_level','id':'barbarian'},{'op':'const','value':2}]}}]
f=next(f for f in p['features'] if f['id']=='barbarian-career-11-feature');f.update(name='Renewed fury',description=r['description'])
(root/'data/rules/trhgd-character-v8.json').write_text(json.dumps(p,indent=2)+'\n')
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text());manifest['packs']=[r for r in manifest['packs'] if r['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs'].append({'path':'res://data/rules/trhgd-character-v8.json','rules_ref':pin});mp.write_text(json.dumps(manifest,indent=2)+'\n')
print(pin)
