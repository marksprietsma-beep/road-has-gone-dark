"""Strict new33 source/data scope and all released1–32 byte/pin preservation."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE='09c48ba785bbca020168cc9b7e37c09f5f9370f2'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
 manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'));old=json.loads(original('data/rules/packs.json'))
 scope34=None
 if (ROOT/'data/rules/trhgd-character-v34.json').exists():
  spec34=importlib.util.spec_from_file_location('dragon_warshaper_scope',ROOT/'tests/dragon_warshaper/source_scope.py');scope34=importlib.util.module_from_spec(spec34);spec34.loader.exec_module(scope34);scope34.verify_production()
  manifest=dict(manifest,packs=manifest['packs'][:33]) # Exact old prefix after independent append-only34 validation.
 assert len(old['packs'])==32 and len(manifest['packs'])==33 and manifest['packs'][:32]==old['packs']
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 a=json.loads(original('data/rules/trhgd-character-v32.json'));b=json.loads((ROOT/'data/rules/trhgd-character-v33.json').read_text(encoding='utf-8'))
 spec=importlib.util.spec_from_file_location('grove_summoner_recipe',ROOT/'tools/character-content/build-grove-summoner-pack.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen);assert b==gen.content()
 assert {k for k in a if a[k]!=b[k]}=={'pack_id','rules_version','provenance','classes','abilities'}
 calls={'bonded-summoner-technique-'+str(n)for n in [1,3,5]}|{'bonded-summoner-call-'+n for n in ['leopard','renewal-spirit','stone-guardian']}|{'call-'+n for n in ['thorn-guardian','ember-spirit','frost-hound','bulwark-construct']}
 expected={'classes':{'grove-warden','bonded-summoner'},'abilities':calls};deltas={}
 for category in ['classes','features','feats','skills','resources','statuses','abilities','equipment','ancestries','backgrounds','creatures','psychic_powers']:
  x={r['id']:r for r in a[category]};y={r['id']:r for r in b[category]};assert set(x)==set(y),category
  changed={k for k in x if x[k]!=y[k]};assert changed==expected.get(category,set()),(category,changed);deltas[category]=sorted(changed)
 for file in (ROOT/'scripts').rglob('*.gd'):
  path=file.relative_to(ROOT).as_posix();expected=gen.enable_versions(original(path).decode('utf-8'))
  if path=='scripts/ui/first_adventure.gd'and file.read_text(encoding='utf-8')!=expected:
   spec165=importlib.util.spec_from_file_location('sentinel_scope',ROOT/'tests/sentinel_turn/source_scope.py');scope165=importlib.util.module_from_spec(spec165);spec165.loader.exec_module(scope165);scope165.verify_ui()
   assert scope165.original(path).decode('utf-8')==expected,'Released33 source remains the original historical expectation'
  else:assert file.read_text(encoding='utf-8')==(scope34.recipe().enable_versions(expected)if scope34 else expected),path
 exporter='tools/release/export-game.mjs';expected_exporter=original(exporter).decode('utf-8').replace("'res://tests/ranger_steward/review.tscn'].includes(qaScene)","'res://tests/ranger_steward/review.tscn','res://tests/grove_summoner/review.tscn'].includes(qaScene)")
 if (ROOT/exporter).read_text(encoding='utf-8')!=expected_exporter:
  spec165=importlib.util.spec_from_file_location('sentinel_export_scope',ROOT/'tests/sentinel_turn/source_scope.py');scope165=importlib.util.module_from_spec(spec165);spec165.loader.exec_module(scope165)
  assert scope165.original(exporter).decode('utf-8')==expected_exporter
  assert (ROOT/exporter).read_text(encoding='utf-8')==scope165.expected_exporter(),'Exactly one additional approved Sentinel diagnostic scene'
 else:assert (ROOT/exporter).read_text(encoding='utf-8')==expected_exporter,'Original exporter plus exactly one approved QA scene'
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd','scripts/combat/combat_entities.gd']
 for path in frozen:assert (ROOT/path).read_bytes()==original(path),path
 for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data'],cwd=ROOT,text=True).splitlines():
  if path!='data/rules/packs.json':assert (ROOT/path).read_bytes()==original(path),path
 pin=manifest['packs'][-1]['rules_ref'];assert pin['pack_id']==b['pack_id']=='trhgd-character-v33'
 assert hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return dict(baseline=BASE,historical_pack_bytes_and_pins=32,rules_ref=pin,roster_unchanged=True,new_content_records=0,deltas=deltas,frozen_authorities=frozen,source_scope='Exact version enablement only, preserving the32 defeated-companion fix in33. Existing permanent spell-tier/parent gates, generic selected-caster advancement and supernatural form suppression correct four witnessed data gaps. No aura/form-policy, creature, combat, RNG, XP or save engine change.')
if __name__=='__main__':print(json.dumps(verify(),indent=2))
