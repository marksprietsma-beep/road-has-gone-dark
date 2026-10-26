"""Strict current31 source guard plus unchanged released1–30 bytes/pins."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE='5a8de72b07b0e8acaf0488afdece972f296616a4'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
 manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'));old=json.loads(original('data/rules/packs.json'))
 assert len(old['packs'])==30 and len(manifest['packs'])==31 and manifest['packs'][:30]==old['packs']
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 a=json.loads(original('data/rules/trhgd-character-v30.json'));b=json.loads((ROOT/'data/rules/trhgd-character-v31.json').read_text(encoding='utf-8'))
 spec=importlib.util.spec_from_file_location('monk_paladin_recipe',ROOT/'tools/character-content/build-monk-paladin-pack.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen);assert b==gen.content()
 assert {k for k in a if a[k]!=b[k]}=={'pack_id','rules_version','provenance','classes','features','statuses','abilities'}
 expected={'classes':{'monk'},'features':{'monk-wind-1-feature','monk-wind-6-feature'},'statuses':{'monk-wind-1-status','monk-wind-6-status'},'abilities':{'flurry','smite','monk-wind-1','monk-wind-6'}};deltas={}
 for category in ['classes','features','feats','skills','resources','statuses','abilities','equipment','ancestries','backgrounds','creatures','psychic_powers']:
  x={r['id']:r for r in a[category]};y={r['id']:r for r in b[category]};assert set(x)==set(y),category
  changed={k for k in x if x[k]!=y[k]};assert changed==expected.get(category,set()),(category,changed);deltas[category]=sorted(changed)
 for file in (ROOT/'scripts').rglob('*.gd'):
  path=file.relative_to(ROOT).as_posix();assert file.read_text(encoding='utf-8')==gen.enable_versions(original(path).decode('utf-8')),path
 exporter='tools/release/export-game.mjs'
 expected_exporter=original(exporter).decode('utf-8').replace("'res://tests/martial_careers/review.tscn'].includes(qaScene)","'res://tests/martial_careers/review.tscn','res://tests/monk_paladin/review.tscn'].includes(qaScene)")
 assert (ROOT/exporter).read_text(encoding='utf-8')==expected_exporter,'Original exporter plus exactly one approved QA scene'
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for path in frozen:assert (ROOT/path).read_bytes()==original(path)
 pin=manifest['packs'][-1]['rules_ref'];assert pin['pack_id']==b['pack_id']=='trhgd-character-v31'
 assert hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return dict(baseline=BASE,historical_pack_bytes_and_pins=30,rules_ref=pin,roster_unchanged=True,new_content_records=0,deltas=deltas,frozen_authorities=frozen,source_scope='Exact version enablement plus a reviewed31-only target check through the same existing RulesExpressions authority; data uses existing weapon contexts and insight modifiers. No new combat/resource/XP/save resolver.')
if __name__=='__main__':print(json.dumps(verify(),indent=2))
