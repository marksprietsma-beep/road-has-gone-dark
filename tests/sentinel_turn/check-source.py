from pathlib import Path
import json,subprocess,importlib.util
from source_scope import ROOT,BASE,UI,original,verify_ui,expected_exporter
receipt=verify_ui()
scope34=None
if (ROOT/'data/rules/trhgd-character-v34.json').exists():
 spec=importlib.util.spec_from_file_location('dragon_sentinel_scope',ROOT/'tests/dragon_warshaper/source_scope.py');scope34=importlib.util.module_from_spec(spec);spec.loader.exec_module(scope34);scope34.verify_production()

for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data','scripts'],cwd=ROOT,text=True).splitlines():
 if path==UI:continue
 if scope34 and (path.startswith('scripts/')or path=='data/rules/packs.json'):
  # Current34 bytes were checked against the exact recipe above. Retain every
  # original33 historical assertion against the preserved source projection.
  assert scope34.original(path)==original(path),path
 else:assert (ROOT/path).read_bytes()==original(path),path
assert (ROOT/'tools/release/export-game.mjs').read_text()==expected_exporter()
receipt.update(immutable_packs=33,readiness_unchanged=(ROOT/'docs/implementation/game129/READINESS.json').read_bytes()==original('docs/implementation/game129/READINESS.json'),all_other_production_and_data_frozen=scope34 is None,current34_extension_strict=scope34 is not None,fixed_footer_preserved=True)
if scope34:scope34.verify_readiness()
else:assert (ROOT/'docs/implementation/game129/READINESS.json').read_bytes()==original('docs/implementation/game129/READINESS.json')
print(json.dumps(receipt,indent=2))
