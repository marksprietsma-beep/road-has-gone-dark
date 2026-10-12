"""Release gates for exact installed pins and honest catalogue status; stdlib only."""
import hashlib,json,pathlib,re
root=pathlib.Path(__file__).resolve().parents[2]
manifest=json.loads((root/'data/rules/packs.json').read_text());assert manifest['schema_version']==1
seen=set()
for row in manifest['packs']:
 path=row['path'];assert path.startswith('res://data/rules/') and '..'not in path
 pack=json.loads((root/path.removeprefix('res://')).read_text())
 pin={k:pack[k] for k in ['pack_id','schema_version','rules_version','engine_schema']}
 pin['content_hash']=hashlib.sha256(json.dumps(pack,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 assert row['rules_ref']==pin,'Exact manifest pin differs: '+path
 assert pin['pack_id']not in seen;seen.add(pin['pack_id'])
 for category in ['classes','feats','features','abilities','ancestries','equipment']:
  for item in pack[category]:assert item['provenance'].get('license'),'Missing licence provenance'
coverage=json.loads((root/'docs/implementation/game104/COVERAGE.json').read_text());ids=set()
for row in coverage['entries']:
 assert row['id']not in ids;ids.add(row['id'])
 assert row['status']in ['researched','designed','implemented','mechanically_validated','playable']
 assert row['playable']==(row['status']=='playable')
 assert row['licensing']['strategy'] and row['intended_implementation']['kind']
 if row['playable']:assert row.get('evidence') and row['intended_implementation']['production_id']
 if row['intended_implementation']['kind']=='exception':assert row.get('exception_reason')
assert len(ids)==720
print(json.dumps({'installed_packs':len(seen),'accounted_research_entries':len(ids),'playable_catalogue_entries':sum(r['playable']for r in coverage['entries'])}))
