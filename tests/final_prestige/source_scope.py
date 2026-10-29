"""Exact v35 extension plus every archived v34 source/readiness assertion."""
from pathlib import Path
import hashlib,importlib.util,json,re,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[2];BASE='7c70fb27bfd3572505421c996102bd11e9b6da1a'
FUNCTION_GUARDS=['tests/dual_prestige_acceptance/check-source.py','tests/martial_careers/check-source.py','tests/monk_paladin/check-source.py','tests/ranger_steward/check-source.py','tests/grove_summoner/check-source.py']
CLI_GUARDS=['tests/sentinel_turn/check-source.py','tests/dragon_warshaper/check-source.py']
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def module_at(path,name):
 spec=importlib.util.spec_from_file_location(name,ROOT/path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

def recipe():return module_at('tools/character-content/build-final-prestige-pack.py','final_prestige_recipe')
def expected_bootstrap(path):
 text=original(path).decode('utf-8')
 lines=["if (ROOT/'data/rules/trhgd-character-v35.json').exists():"," import importlib.util as _extended_import"," spec=_extended_import.spec_from_file_location('final_prestige_source',ROOT/'tests/final_prestige/source_scope.py')"," extended=_extended_import.module_from_spec(spec);spec.loader.exec_module(extended)"," return extended.verify_all()"]
 if path in FUNCTION_GUARDS:
  match=re.search(r'^def verify\(\):\n( +)',text,re.M);assert match,path;indent=match.group(1)
  insertion=''.join(indent+line+'\n'for line in lines)
  return text[:match.end()-len(indent)]+insertion+text[match.end()-len(indent):]
 assert path in CLI_GUARDS
 top=["from pathlib import Path as _ScopePath","_scope_root=_ScopePath(__file__).resolve().parents[2]","if (_scope_root/'data/rules/trhgd-character-v35.json').exists():"," import importlib.util as _scope_import,json as _scope_json"," _scope_spec=_scope_import.spec_from_file_location('final_prestige_source',_scope_root/'tests/final_prestige/source_scope.py')"," _scope_module=_scope_import.module_from_spec(_scope_spec);_scope_spec.loader.exec_module(_scope_module)"," print(_scope_json.dumps(_scope_module.verify_all(),indent=2))"," raise SystemExit(0)",""]
 return '\n'.join(top)+'\n'+text

def expected_exporter():
 text=original('tools/release/export-game.mjs').decode();needle="'res://tests/dragon_warshaper/review.tscn'].includes(qaScene)";assert text.count(needle)==1
 return text.replace(needle,"'res://tests/dragon_warshaper/review.tscn','res://tests/final_prestige/review.tscn'].includes(qaScene)")

def verify_manifest():
 old=json.loads(original('data/rules/packs.json'));current=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'));assert len(old['packs'])==34 and len(current['packs'])==35 and current['packs'][:34]==old['packs']
 for row in old['packs']:
  path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
 pack=json.loads((ROOT/'data/rules/trhgd-character-v35.json').read_text(encoding='utf-8'));assert pack==recipe().content(),'Exact bounded recipe differs'
 pin=current['packs'][-1]['rules_ref'];assert pin['pack_id']==pack['pack_id']=='trhgd-character-v35'
 assert hashlib.sha256(json.dumps(pack,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 return current

def verify_readiness():
 path='docs/implementation/game129/READINESS.json';native=ROOT/'docs/implementation/game123-final-prestige/evidence/native-proof.json'
 if not native.exists():assert (ROOT/path).read_bytes()==original(path),'No promotion before full matching-source native acceptance';return
 module=module_at('tools/character-content/readiness_final_prestige.py','final_prestige_readiness');pack=json.loads((ROOT/'data/rules/trhgd-character-v35.json').read_text(encoding='utf-8'));pin=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'))['packs'][-1]['rules_ref']
 expected=module.expected_report(ROOT,pack,pin,json.loads(native.read_text(encoding='utf-8')));assert json.loads((ROOT/path).read_text(encoding='utf-8'))==expected,'Only exact three-career promotion is allowed'

def script_inventory(root,expected):
 present={p.relative_to(root).as_posix()for p in (root/'scripts').rglob('*')if p.is_file()}
 expected=set(expected);missing=expected-present;extra=present-expected
 assert not missing,dict(missing_production_files=sorted(missing))
 for path in sorted(extra):
  assert path.endswith('.gd.uid')and path[:-4]in expected,dict(unexpected_production_file=path,all_extras=sorted(extra))
  value=(root/path).read_text(encoding='utf-8').strip()
  assert re.fullmatch(r'uid://[a-z0-9]+',value),dict(invalid_generated_uid=path)
 return sorted(extra)

def verify_production():
 manifest=verify_manifest();m=recipe();before=json.loads(original('data/rules/trhgd-character-v34.json'));after=json.loads((ROOT/'data/rules/trhgd-character-v35.json').read_text(encoding='utf-8'))
 old_ids={k:{r['id']:r for r in before[k]}for k in ['classes','features','abilities','statuses','resources','equipment','feats','ancestries','creatures']};new_ids={k:{r['id']:r for r in after[k]}for k in old_ids}
 assert len(old_ids['classes'])==len(new_ids['classes'])and set(old_ids['classes'])==set(new_ids['classes'])
 assert {k for k in old_ids['classes']if old_ids['classes'][k]!=new_ids['classes'][k]}=={'eldritch-knight','shadowdancer','dwarven-defender'}
 for category in ['equipment','feats','ancestries','creatures']:assert old_ids[category]==new_ids[category],category
 scripts=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'scripts'],cwd=ROOT,text=True).splitlines()
 assert set(scripts)==set(subprocess.check_output(['git','ls-files','--','scripts'],cwd=ROOT,text=True).splitlines()),'Tracked production inventory changed'
 script_inventory(ROOT,scripts)
 for path in scripts:assert (ROOT/path).read_text(encoding='utf-8')==m.enable_versions(original(path).decode('utf-8')),path
 for path in subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'data'],cwd=ROOT,text=True).splitlines():
  if path!='data/rules/packs.json':assert (ROOT/path).read_bytes()==original(path),path
 for path in FUNCTION_GUARDS+CLI_GUARDS:assert (ROOT/path).read_text(encoding='utf-8')==expected_bootstrap(path),'Historical assertion body changed: '+path
 readiness=original('tools/character-content/build-readiness.py').decode('utf-8');needle="if args.pack=='trhgd-character-v34':";assert readiness.count(needle)==1
 expected=readiness.replace(needle,"if args.pack=='trhgd-character-v35':\n from readiness_final_prestige import generate\n generate(root,p,pin,args.native)\n raise SystemExit(0)\n"+needle)
 assert (ROOT/'tools/character-content/build-readiness.py').read_text(encoding='utf-8')==expected
 assert (ROOT/'tools/release/export-game.mjs').read_text(encoding='utf-8')==expected_exporter()
 for path in ['scripts/combat/tactical_combat.gd','scripts/combat/combat_entities.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']:assert (ROOT/path).read_bytes()==original(path),path
 verify_readiness()
 return dict(baseline=BASE,historical_pack_bytes_and_pins=34,rules_ref=manifest['packs'][-1]['rules_ref'],roster_unchanged=True,authority_unchanged=True,shared_spell_identities_added=0,channel_delivery_references_added=19,class_counters_added=2,scope='Exact v35 version support and bounded career data, plus new35-only original-spell suggestions; existing remaining-token self controls retained; previous47 accepted records retained.')

def verify_all():
 receipt=verify_production()
 # Legacy guards intentionally freeze their own accepted native inputs. Run
 # EVERY original assertion in a clean owned v34 snapshot, then independently
 # scope-check the current35 extension above. Actual old pins are also exercised
 # through current Windows game code; this is not a replacement for runtime.
 with tempfile.TemporaryDirectory(prefix='trhgd-guard34-')as parent:
  owned=Path(parent)/'source'
  subprocess.run(['git','-c','core.longpaths=true','worktree','add','--quiet','--detach','--no-checkout',str(owned),BASE],cwd=ROOT,check=True)
  try:
   subprocess.run(['git','-c','core.longpaths=true','sparse-checkout','set','scripts','data','tools','tests','docs'],cwd=owned,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   subprocess.run(['git','-c','core.longpaths=true','checkout','--quiet',BASE],cwd=owned,check=True)
   result=subprocess.run([sys.executable,'tests/dual_prestige_acceptance/check-source.py'],cwd=owned,text=True,encoding='utf-8',capture_output=True)
   assert result.returncode==0,result.stdout+'\n'+result.stderr
   receipt.update(archived_assertions_retained=True,archived_input_source=BASE,archived_guard_output_sha256=hashlib.sha256(result.stdout.encode()).hexdigest())
  finally:subprocess.run(['git','-c','core.longpaths=true','worktree','remove','--force',str(owned)],cwd=ROOT,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 return receipt
