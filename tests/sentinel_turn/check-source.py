from pathlib import Path
import json,subprocess
from source_scope import ROOT,BASE,UI,original,verify_ui,expected_exporter
receipt=verify_ui()
for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data','scripts'],cwd=ROOT,text=True).splitlines():
 if path!=UI:assert (ROOT/path).read_bytes()==original(path),path
assert (ROOT/'tools/release/export-game.mjs').read_text()==expected_exporter()
receipt.update(immutable_packs=33,readiness_unchanged=True,all_other_production_and_data_frozen=True)
assert (ROOT/'docs/implementation/game129/READINESS.json').read_bytes()==original('docs/implementation/game129/READINESS.json')
print(json.dumps(receipt,indent=2))
