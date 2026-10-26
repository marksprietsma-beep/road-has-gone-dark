"""Static scope/byte guard. Gameplay acceptance executes only on Windows."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE='a583939cb111778d350df137d0691839da39ee30'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
 manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'));old=json.loads(original('data/rules/packs.json'))
 newer=len(manifest['packs'])>30
 assert len(old['packs'])==29 and len(manifest['packs']) in [30,31,32] and manifest['packs'][:29]==old['packs']
 released30='5a8de72b07b0e8acaf0488afdece972f296616a4'
 def current_bytes(path):return subprocess.check_output(['git','show',released30+':'+path],cwd=ROOT) if newer else (ROOT/path).read_bytes()
 if newer:
  archived=json.loads(subprocess.check_output(['git','show',released30+':data/rules/packs.json'],cwd=ROOT));assert manifest['packs'][:30]==archived['packs']
  spec=importlib.util.spec_from_file_location('current_monk_paladin_source',ROOT/'tests/monk_paladin/check-source.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);module.verify()
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 a=json.loads(original('data/rules/trhgd-character-v29.json'));b=json.loads((ROOT/'data/rules/trhgd-character-v30.json').read_text(encoding='utf-8'))
 assert set(a)==set(b)and {k for k in a if a[k]!=b[k]}=={'pack_id','rules_version','provenance','classes','features','statuses','abilities','resources'}
 allowed={'classes':{'fighter','barbarian'},'features':{'fighter-veteran','point-blank-shot-feature','barbarian-master-choice-resilient'}|{f'fighter-{s}-{n}-feature'for s in ['blade','bow']for n in [1,6]},'statuses':{f'fighter-{s}-{n}-status'for s in ['blade','bow']for n in [1,6]},'abilities':{f'fighter-{s}-{n}'for s in ['blade','bow']for n in [1,6]},'resources':{'fighter-resolve'}}
 deltas={}
 for category in ['classes','features','feats','skills','resources','statuses','abilities','equipment','ancestries','backgrounds','creatures','psychic_powers']:
  x={r['id']:r for r in a[category]};y={r['id']:r for r in b[category]};assert set(x)==set(y),category
  changed={k for k in x if x[k]!=y[k]};assert changed==allowed.get(category,set()),(category,changed);deltas[category]=sorted(changed)
 spec=importlib.util.spec_from_file_location('martial_content',ROOT/'tools/character-content/build-martial-acceptance-pack.py');gen=importlib.util.module_from_spec(spec);spec.loader.exec_module(gen);assert b==gen.content(),'Candidate must match its reviewed reproducible authoring recipe'
 approved=json.loads((ROOT/'tests/martial_careers/approved-source-sha256.json').read_text())
 assert set(approved)=={'scripts/rules/rules_character.gd','scripts/rules/rules_martial.gd','scripts/combat/tactical_auras.gd','scripts/ui/first_adventure.gd','scripts/ui/components/build_editor.gd'}
 for file in (ROOT/'scripts').rglob('*.gd'):
  path=file.relative_to(ROOT).as_posix()
  if path in approved:assert hashlib.sha256(current_bytes(path)).hexdigest()==approved[path],path
  else:assert current_bytes(path).decode('utf-8')==gen.enable_versions(original(path).decode('utf-8')),path
 exporter='tools/release/export-game.mjs'
 expected_exporter=original(exporter).decode('utf-8').replace("'res://tests/dual_prestige_acceptance/review.tscn'].includes(qaScene)","'res://tests/dual_prestige_acceptance/review.tscn','res://tests/martial_careers/review.tscn'].includes(qaScene)")
 assert current_bytes(exporter).decode('utf-8')==expected_exporter,'Only the one explicit martial QA entry may be added to the original exporter'
 assert "'res://tests/martial_careers/review.tscn'"in expected_exporter
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for path in frozen:assert (ROOT/path).read_bytes()==original(path)
 pin=next(row['rules_ref']for row in manifest['packs']if row['rules_ref']['pack_id']=='trhgd-character-v30');assert pin['pack_id']==b['pack_id']=='trhgd-character-v30'
 assert hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return dict(baseline=BASE,historical_pack_bytes_and_pins=29,rules_ref=pin,roster_unchanged=True,new_content_records=0,deltas=deltas,frozen_authorities=frozen,source_scope='Version enablement plus reviewed transient effective-weapon modifier context, matching UI requirements and empty-search creator list repair; original attack/RNG/save authority inherited.')
if __name__=='__main__':print(json.dumps(verify(),indent=2))
