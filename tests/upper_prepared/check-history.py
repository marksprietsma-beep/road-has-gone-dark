"""Host source inspection only: all22 historical bytes and rows remain immutable."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
rows=json.loads((root/'tests/upper_prepared/historical-pins.json').read_text());manifest=json.loads((root/'data/rules/packs.json').read_text())['packs'];assert len(rows)==22
for i,r in enumerate(rows):
 assert hashlib.sha256((root/r['path']).read_bytes()).hexdigest()==r['sha256']
 assert manifest[i]==dict(path='res://'+r['path'],rules_ref=r['rules_ref'])
print('22 exact historical pack bytes and manifest rows unchanged')
