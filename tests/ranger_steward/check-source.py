"""Strict current32 scope, all released1–31 bytes/pins and frozen authority."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE='f9880ed0865f163a8f90a19b2a650365b664dd96'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
 manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'));old=json.loads(original('data/rules/packs.json'))
 newer=len(manifest['packs'])>32
 assert len(old['packs'])==31 and len(manifest['packs'])in [32,33,34] and manifest['packs'][:31]==old['packs']
 released32='09c48ba785bbca020168cc9b7e37c09f5f9370f2'
 def current_bytes(path):return subprocess.check_output(['git','show',released32+':'+path],cwd=ROOT) if newer else (ROOT/path).read_bytes()
 if newer:
  archived=json.loads(subprocess.check_output(['git','show',released32+':data/rules/packs.json'],cwd=ROOT));assert manifest['packs'][:32]==archived['packs']
  spec=importlib.util.spec_from_file_location('current_grove_summoner_source',ROOT/'tests/grove_summoner/check-source.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);module.verify()
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 a=json.loads(original('data/rules/trhgd-character-v31.json'));b=json.loads((ROOT/'data/rules/trhgd-character-v32.json').read_text(encoding='utf-8'))
 spec=importlib.util.spec_from_file_location('ranger_steward_recipe',ROOT/'tools/character-content/build-ranger-steward-pack.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen);assert b==gen.content()
 assert {k for k in a if a[k]!=b[k]}=={'pack_id','rules_version','provenance','classes','features','statuses','abilities'}
 expected={'classes':{'ranger'},'features':{'ranger-archery-1-feature','ranger-archery-6-feature'},'statuses':{'ranger-archery-1-status','ranger-archery-6-status'},'abilities':{'aimed-shot','ranger-archery-1','ranger-archery-6'}};deltas={}
 for category in ['classes','features','feats','skills','resources','statuses','abilities','equipment','ancestries','backgrounds','creatures','psychic_powers']:
  x={r['id']:r for r in a[category]};y={r['id']:r for r in b[category]};assert set(x)==set(y),category
  changed={k for k in x if x[k]!=y[k]};assert changed==expected.get(category,set()),(category,changed);deltas[category]=sorted(changed)
 for file in (ROOT/'scripts').rglob('*.gd'):
  path=file.relative_to(ROOT).as_posix();assert current_bytes(path).decode('utf-8')==gen.enable_versions(original(path).decode('utf-8')),path
 exporter='tools/release/export-game.mjs'
 expected_exporter=original(exporter).decode('utf-8').replace("'res://tests/monk_paladin/review.tscn'].includes(qaScene)","'res://tests/monk_paladin/review.tscn','res://tests/ranger_steward/review.tscn'].includes(qaScene)")
 assert current_bytes(exporter).decode('utf-8')==expected_exporter,'Original exporter plus exactly one approved QA scene'
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for path in frozen:assert (ROOT/path).read_bytes()==original(path)
 for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data'],cwd=ROOT,text=True).splitlines():
  if path!='data/rules/packs.json':assert (ROOT/path).read_bytes()==original(path),path
 pin=next(row['rules_ref']for row in manifest['packs']if row['rules_ref']['pack_id']=='trhgd-character-v32');assert pin['pack_id']==b['pack_id']=='trhgd-character-v32'
 assert hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return dict(baseline=BASE,historical_pack_bytes_and_pins=31,rules_ref=pin,roster_unchanged=True,new_content_records=0,deltas=deltas,frozen_authorities=frozen,source_scope='Exact version enablement plus32-only preservation of zeroHP on companion growth. Existing effective-weapon requirements/conditional modifiers repair ranged attacks without replacing attack, RNG, XP or persistence authority.')
if __name__=='__main__':print(json.dumps(verify(),indent=2))
