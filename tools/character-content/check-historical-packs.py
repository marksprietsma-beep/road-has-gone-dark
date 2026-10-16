"""Byte-for-byte and exact manifest-pin guard for every accepted v1-v15 pack."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]
baseline=json.loads((root/'tests/character_completeness/fixtures/historical-packs.json').read_text())
installed={r['rules_ref']['pack_id']:r for r in json.loads((root/'data/rules/packs.json').read_text())['packs']}
for row in baseline['packs']:
 assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']+' mutated'
 current=installed[row['rules_ref']['pack_id']]
 assert current['rules_ref']==row['rules_ref'] and current['path']=='res://'+row['path'],'Historical pin/path changed'
print(json.dumps(dict(historical_packs=len(baseline['packs']),baseline=baseline['baseline_commit'],bytes_and_pins_unchanged=True)))
