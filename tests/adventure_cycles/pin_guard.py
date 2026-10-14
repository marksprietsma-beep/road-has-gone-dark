"""Freeze historical content and manifest rows while permitting verified appends."""
import hashlib,json

def verify(root,pins):
 for path,digest in pins.items():
  if path=='data/rules/packs.json':continue
  assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,'Historical source/content pin changed: '+path
 baseline_path=root/'tests/adventure_cycles/historical-pack-manifest.json'
 assert hashlib.sha256(baseline_path.read_bytes()).hexdigest()==pins['data/rules/packs.json'],'Historical manifest baseline changed'
 baseline=json.loads(baseline_path.read_text());current=json.loads((root/'data/rules/packs.json').read_text())
 assert current.keys()==baseline.keys() and current['schema_version']==baseline['schema_version'],'Manifest schema changed'
 assert len(current['packs'])>=len(baseline['packs']) and current['packs'][:len(baseline['packs'])]==baseline['packs'],'Historical pack rows removed, reordered or repinned'
 ids=[r['rules_ref']['pack_id']for r in current['packs']]
 assert len(ids)==len(set(ids)),'Duplicate installed pack'
 for row in current['packs']:
  path=row['path'];assert path.startswith('res://data/rules/') and '..'not in path,'Pack path escapes rules directory'
  pack=json.loads((root/path.removeprefix('res://')).read_text())
  expected={key:pack[key]for key in ['pack_id','schema_version','rules_version','engine_schema']}
  expected['content_hash']=hashlib.sha256(json.dumps(pack,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
  assert row['rules_ref']==expected,'Installed pack differs from its exact content pin'
