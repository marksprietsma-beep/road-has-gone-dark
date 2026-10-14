"""Negative gates for append-only historical pins, using isolated copied fixtures."""
from pathlib import Path
import json,tempfile,shutil
from pin_guard import verify
root=Path(__file__).resolve().parents[2];pins=json.loads((root/'tests/adventure_cycles/source-pins.json').read_text());checks=0
with tempfile.TemporaryDirectory()as work:
 base=Path(work)
 paths=set(pins)|{'tests/adventure_cycles/historical-pack-manifest.json'}
 manifest=json.loads((root/'data/rules/packs.json').read_text())
 paths.update(r['path'].removeprefix('res://')for r in manifest['packs'])
 for path in paths:
  target=base/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/path,target)
 def rejected(change):
  global checks
  candidate=json.loads(json.dumps(manifest));change(candidate)
  (base/'data/rules/packs.json').write_text(json.dumps(candidate))
  try:verify(base,pins)
  except (AssertionError,KeyError,FileNotFoundError):checks+=1
  else:raise AssertionError('Illegal manifest accepted')
 verify(base,pins);checks+=1
 rejected(lambda m:m['packs'][0]['rules_ref'].update(content_hash='0'*64))
 rejected(lambda m:m['packs'].pop(0))
 rejected(lambda m:m['packs'].reverse())
 rejected(lambda m:m['packs'].append(m['packs'][0]))
 rejected(lambda m:m.update(schema_version=2))
 rejected(lambda m:m['packs'][-1]['rules_ref'].update(content_hash='0'*64))
 (base/'data/rules/packs.json').write_text(json.dumps(manifest))
 (base/'data/rules/trhgd-rules-v1.json').write_text('{}')
 try:verify(base,pins)
 except AssertionError:checks+=1
 else:raise AssertionError('Historical rules mutation accepted')
print(f'Historical append-only pin gates: {checks} checks, 0 failures')
