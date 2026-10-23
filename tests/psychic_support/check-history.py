"""Static bytes/pins only: this does not execute a game on the host."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
baseline=json.loads((root/'tests/psychic_support/historical-pins.json').read_text())
installed={r['rules_ref']['pack_id']:r for r in json.loads((root/'data/rules/packs.json').read_text())['packs']}
for row in baseline['packs']:
 assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
 assert installed[row['rules_ref']['pack_id']]==dict(path='res://'+row['path'],rules_ref=row['rules_ref'])
before=json.loads((root/'data/rules/trhgd-character-v24.json').read_text());after=json.loads((root/'data/rules/trhgd-character-v25.json').read_text())
for category in before:
 if not isinstance(before[category],list)or not before[category]or not isinstance(before[category][0],dict)or'id'not in before[category][0]:continue
 assert [r['id']for r in before[category]]==[r['id']for r in after[category]],category+' roster changed'
print(json.dumps(dict(historical_packs=len(baseline['packs']),bytes_and_pins_unchanged=True,no_roster_expansion=True)))

# Exact semantic candidate guard: only the five Cognition targeting contracts.
import copy
path=root/'data/rules/trhgd-character-v26.json'
if path.exists():
 old=json.loads((root/'data/rules/trhgd-character-v25.json').read_text());new=json.loads(path.read_text());expected=copy.deepcopy(old)
 for key in ['pack_id','rules_version','provenance']:expected[key]=new[key]
 changed=[]
 for before in expected['abilities']:
  if before['id'].startswith('cognition-strike-'):
   after=next(r for r in new['abilities']if r['id']==before['id'])
   for key in ['requires_melee','requires_adjacent','description','provenance']:before[key]=after[key]
   assert after['requires_melee']is True and after['requires_adjacent']is True
   changed.append(before['id'])
 assert len(changed)==5 and expected==new,'Unrelated candidate mechanics or roster change'
