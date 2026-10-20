"""All twenty accepted pack bytes/manifest rows must survive v21 unchanged."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
baseline=json.loads((root/'tests/supernatural_signatures/historical-pins.json').read_text(encoding='utf-8'))
manifest=json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))
assert len(baseline['packs'])==20
for i,row in enumerate(baseline['packs']):
 assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
 assert manifest['packs'][i]==dict(path='res://'+row['path'],rules_ref=row['rules_ref']),row['path']
print('All twenty historical pack bytes and original manifest rows unchanged')
