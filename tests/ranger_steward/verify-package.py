"""Single stable Windows-native release. Original exporter, rules and save writer."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,struct,subprocess,sys,zipfile
assert os.name=='nt','Native Windows only'
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('ranger_steward_source',ROOT/'tests/ranger_steward/check-source.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard);scope=guard.verify()
base=Path(os.environ['RANGER_STEWARD_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='ranger-steward-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();manifest_bytes=(ROOT/'data/rules/packs.json').read_bytes()
pins={x['rules_ref']['pack_id']:x['rules_ref']for x in json.loads(manifest_bytes)['packs']};pin=pins['trhgd-character-v32']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/ranger_steward/review.tscn','--output',str(dist)],cwd=ROOT,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',RANGER_STEWARD_ROOT=str(base/'mechanics'),MONK_PALADIN_ROOT=str(base/'historical31'),MARTIAL_ROOT=str(base/'historical30'),RANGER_STEWARD_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_AUDIT_ROOT=str(base/'all-base'),GAME126_PACK='res://data/rules/trhgd-character-v32.json',GAME150_ROOT=str(base/'current-upper'),DUAL_ROOT=str(base/'historical29'),GAME133_ROOT=str(base/'historical18'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
for phase in ['probe','mechanics','input','journey','connected','capture','audit','current-upper','historical31','historical31-input','historical30','historical30-extended','historical30-input','historical29','historical18','legacy','compatibility']:
 for cold in ([False]if phase in ['probe','input','capture','historical30-input','historical31-input']else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,RANGER_STEWARD_PHASE=phase)
  for key in ['RANGER_STEWARD_RESTART','MONK_PALADIN_RESTART','MARTIAL_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART','GAME150_RESTART','DUAL_RESTART','GAME133_RESTART']:active[key]='1'if cold else'0'
  out=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=active,log=base/(label+'.log'),timeout=3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
for phase,folder,version in [('mechanics','mechanics','v32'),('journey','journeys/cohort-0','v32'),('connected','connected','v32'),('audit','all-base','v32'),('current-upper','current-upper','v32'),('historical31','historical31','v31'),('historical30','historical30','v30'),('historical30-extended','historical30/extended','v30'),('historical29','historical29','v29'),('historical18','historical18','v18'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16')]:
 for filename in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,filename)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,filename)
  proofs[phase+'/'+filename]=p
for key,filename in [('pinned31-probe','probe-proof.json'),('input','input-proof.json')]:
 p=json.loads((base/'mechanics'/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[key]=p
assert all(proofs['mechanics/proof.json']['contracts'][k]is True for k in ['ranged_actions','style_limits','quarry','nature_casting','persistent_growth','prestige','commands','creature_actions','summons','owner_survival','late_progression'])
assert all(proofs['mechanics/proof.json']['outcomes'][k]>0 for k in ['hits','misses','criticals'])
historical_input=json.loads((base/'historical30/input-proof.json').read_text(encoding='utf-8'));assert historical_input['checks']>0 and historical_input['failures']==0 and historical_input['suppressed_cases']==3 and historical_input['resisted_cases']==2
proofs['historical30-input']=historical_input
historical31_input=json.loads((base/'historical31/input-proof.json').read_text(encoding='utf-8'));assert historical31_input['checks']>0 and historical31_input['failures']==0 and historical31_input['rules_ref']==pins['trhgd-character-v31'];proofs['historical31-input']=historical31_input
j=proofs['journey/proof.json'];assert j['earned_xp']==490 and not j['xp_injected']and len(j['journeys'])==3 and {r['role']for r in j['builds'].values()}=={'archery','blade','steward'}
assert all(len(r['history'])==8 for r in j['journeys'])
assert j['earned_entry']['earned_xp']==j['earned_entry']['required_xp']==250 and all(j['earned_entry']['alternatives'].values())
assert proofs['connected/proof.json']['owned_action']['before_hp']>proofs['connected/proof.json']['owned_action']['after_hp']
assert set(proofs['connected/proof.json']['casts'].values())=={'ranger-archery-6','ranger-blade-6','steward-drive-3'}
audit=json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(x['complete_track']for x in audit['classes'].values())
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=18
assert all(any(image['file'].startswith('fixture-'+power+'-combat-')for image in captures['screenshots'])for power in ['aimed2019','swiftsteward-drive-33'])
for image in captures['screenshots']:
 file=base/'captures'/image['file'];raw=file.read_bytes();assert hashlib.sha256(raw).hexdigest()==image['sha256'];assert raw[:8]==b'\x89PNG\r\n\x1a\n';image['width'],image['height']=struct.unpack('>II',raw[16:24])
assert {r['width']for r in captures['screenshots']}=={640,1280,2560}
frozen=base/'frozen';out=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=ROOT,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=base/'frozen.log',timeout=600)
assert not out['exit_code']and not out['errors']and not out['timeout']
proofs['frozen']=json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'));assert proofs['frozen']['checks']==22181 and proofs['frozen']['failures']==0
assert guard.verify()==scope and (ROOT/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
out=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not out['exit_code']and not out['errors']and not out['timeout']
shutil.copy2(ROOT/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(ROOT/'data/rules/trhgd-character-v32.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('RANGER AND BEAST STEWARD REVIEW\n\nExtract the outer GitHub artifact ZIP, then the inner playable ZIP. Keep the entire folder and run road-has-gone-dark.exe. No installed Godot, Node or artwork is needed. Escape skips the intro. Fresh New Game uses v32; older campaigns retain their exact pins and mechanics without automatic upgrades.\n\nCreate Ranger adventurers, choose Archery or Blade style and a permanent quarry, then select actual compatible equipment. Aimed Shot needs an actual ranged weapon and spends both main and movement at+2 accuracy; there is no resolve cost. Paid Archery damage applies only to actual ranged attacks. Selected nature spells require legal Wisdom, prepared copies and their own shared tier slots. Companions are chosen at Ranger4 and have stable identity, real natural attacks, movement/reactions and distinct finite special actions where provided. Their art is a labelled humanoid fallback.\n\nEarn XP through existing adventures, return home and explicitly choose funded levels. Beast Steward is never a starting class or automatically awarded; it needs a permanent nature bond, relevant ranks, the stewardship feat and total level5. At earned250XP a qualified Ranger5 may enter or decline. Its five levels grow the existing pet, offer Swift/Enduring training, and pay finite commands for Rally or Pack Drive on legal allies. A defeated companion stays downed on advancement and recovers through existing eligible home rest. Permanent companions remain separate from duration-limited summons.\n\nAcceptance earns490XP/total8 for Archery Ranger/Wolf, Blade Ranger/Leopard and Ranger5/Steward3/Stag, plus actual connected pet damage, paid owner actions, exact cold continuation and home recovery. Higher-level images are labelled DEVELOPMENT FIXTURES, not earned20. Save, fully exit, relaunch and Resume. No QA executable or XP button ships.\n\nThe supported50 careers are unchanged. Technical43/7 acceptance requires matching-source native proof and remains separate from human balance. Existing global-round owner-defeat withdrawal, shared reaction/expiry policy, long-label/small-screen limits and humanoid LPC companion fallbacks remain. No ecology, pet AI framework, pantheon or world expansion is claimed.\n',encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt=dict(acceptance_cohort='ranger-steward',source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,captures=captures,source_guard=scope,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=3,earned_xp=490,earned_level=8,high_level_fixtures_not_earned=True)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(dict(archive=str(archive),sha256=sha),flush=True)
