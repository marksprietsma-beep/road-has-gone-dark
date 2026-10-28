"""Exact v34 data/version extension, retaining the proven GAME-165 footer."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE='0a7b690fe17f665c9ab1c581a0f0ddc91aa5d154'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def recipe():
 spec=importlib.util.spec_from_file_location('dragon_warshaper_recipe',ROOT/'tools/character-content/build-dragon-warshaper-pack.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def expected_exporter():
 text=original('tools/release/export-game.mjs').decode();old="'res://tests/sentinel_turn/review.tscn'].includes(qaScene)";assert text.count(old)==1
 return text.replace(old,"'res://tests/sentinel_turn/review.tscn','res://tests/dragon_warshaper/review.tscn'].includes(qaScene)")
def verify_readiness():
 path='docs/implementation/game129/READINESS.json'
 assert (ROOT/path).read_bytes()==original(path),'Readiness stays45/5 until strict matching-source native promotion is implemented and qualifies'
def verify_manifest():
 manifest=json.loads((ROOT/'data/rules/packs.json').read_text());old=json.loads(original('data/rules/packs.json'))
 assert len(old['packs'])==33 and len(manifest['packs'])==34 and manifest['packs'][:33]==old['packs']
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 p=json.loads((ROOT/'data/rules/trhgd-character-v34.json').read_text());assert p==recipe().content()
 pin=manifest['packs'][-1]['rules_ref'];assert pin['pack_id']==p['pack_id']=='trhgd-character-v34'
 assert hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return manifest

def verify_production():
 m=recipe();manifest=verify_manifest();deltas={}
 before=json.loads(original('data/rules/trhgd-character-v33.json'));after=json.loads((ROOT/'data/rules/trhgd-character-v34.json').read_text())
 expected={'classes':{'dragon-disciple','warshaper'},'features':{'dragon-disciple-scales'}|{'dragon-disciple-technique-'+str(n)+'-feature'for n in [1,4,7,10]}|{'warshaper-technique-'+str(n)+'-feature'for n in [1,3,5]},'resources':{'dragon-disciple-uses','warshaper-uses'},'statuses':{'warshaper-technique-'+str(n)+'-form'for n in [1,3,5]},'abilities':{'dragon-disciple-technique-'+str(n)for n in [1,4,7,10]}|{'warshaper-technique-'+str(n)for n in [1,3,5]}}
 for category in ['classes','features','feats','skills','resources','statuses','abilities','equipment','ancestries','backgrounds','creatures','psychic_powers']:
  a={r['id']:r for r in before[category]};b={r['id']:r for r in after[category]}
  assert set(b)-set(a)==({'dragon-disciple-scale-mantle'}if category=='statuses'else set()),category
  assert not set(a)-set(b),category
  changed={k for k in a if a[k]!=b[k]};assert changed==expected.get(category,set()),(category,changed)
  deltas[category]=sorted(changed)
 for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'scripts'],cwd=ROOT,text=True).splitlines():assert (ROOT/path).read_text(encoding='utf-8')==m.enable_versions(original(path).decode()),path
 for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data'],cwd=ROOT,text=True).splitlines():
  if path!='data/rules/packs.json':assert (ROOT/path).read_bytes()==original(path),path
 assert (ROOT/'tools/release/export-game.mjs').read_text()==expected_exporter()
 frozen=['scripts/combat/tactical_combat.gd','scripts/combat/combat_entities.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for path in frozen:assert (ROOT/path).read_bytes()==original(path),path
 verify_readiness()
 return dict(baseline=BASE,historical_pack_bytes_and_pins=33,rules_ref=manifest['packs'][-1]['rules_ref'],roster_unchanged=True,deltas=deltas,new_statuses=['dragon-disciple-scale-mantle'],frozen_authorities=frozen,source_scope='Only exact v34 version enablement and bounded existing Dragon/Warshaper data. Fixed Sentinel footer, all1–33 pins, original combat/RNG/XP/save authority retained.')
