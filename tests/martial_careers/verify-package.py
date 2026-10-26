"""Single stable Windows-native release. Original exporter, rules and save writer."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,struct,subprocess,sys,zipfile
assert os.name=='nt','Native Windows only'
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('martial_source',ROOT/'tests/martial_careers/check-source.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard);scope=guard.verify()
base=Path(os.environ['MARTIAL_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='fighter-barbarian-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();manifest_bytes=(ROOT/'data/rules/packs.json').read_bytes()
pins={x['rules_ref']['pack_id']:x['rules_ref']for x in json.loads(manifest_bytes)['packs']};pin=pins['trhgd-character-v30']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/martial_careers/review.tscn','--output',str(dist)],cwd=ROOT,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',MARTIAL_ROOT=str(base/'mechanics'),MARTIAL_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_AUDIT_ROOT=str(base/'all-base'),GAME126_PACK='res://data/rules/trhgd-character-v30.json',GAME150_ROOT=str(base/'current-upper'),DUAL_ROOT=str(base/'historical29'),GAME133_ROOT=str(base/'historical18'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
for phase in ['probe','mechanics','input','extended','journey','connected','capture','audit','current-upper','historical29','historical18','legacy','compatibility']:
 for cold in ([False]if phase in ['probe','input','capture']else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,MARTIAL_PHASE=phase)
  for key in ['MARTIAL_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART','GAME150_RESTART','DUAL_RESTART','GAME133_RESTART']:active[key]='1'if cold else'0'
  out=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=active,log=base/(label+'.log'),timeout=3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
for phase,folder,version in [('mechanics','mechanics','v30'),('extended','mechanics/extended','v30'),('journey','journeys/cohort-0','v30'),('connected','connected','v30'),('audit','all-base','v30'),('current-upper','current-upper','v30'),('historical29','historical29','v29'),('historical18','historical18','v18'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16')]:
 for filename in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,filename)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,filename)
  proofs[phase+'/'+filename]=p
for key,filename in [('pinned29-probe','probe-proof.json'),('input','input-proof.json')]:
 p=json.loads((base/'mechanics'/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[key]=p
assert all(proofs['mechanics/proof.json']['contracts'][k]is True for k in ['training','equipment_disciplines','actual_attacks','resilient_mastery','rage_tradeoffs','resources_and_expiry','feat_choices','weapon_overrides'])
assert proofs['input']['suppressed_cases']==3 and proofs['input']['resisted_cases']==2
assert all(proofs['extended/proof.json']['contracts'][k]is True for k in ['guard_reactions','power_strike','higher_features','exhaustion','exact_rage_duration','reaction_weapon','rage_combat','higher_tactical'])
j=proofs['journey/proof.json'];assert j['earned_xp']==490 and not j['xp_injected']and len(j['journeys'])==3 and {r['role']for r in j['builds'].values()}=={'blade','bow','rage'}
assert all(len(r['history'])==8 for r in j['journeys'])
assert set(proofs['connected/proof.json']['casts'].values())=={'fighter-blade-6','fighter-bow-6','barbarian-resilient-6'}
audit=json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(x['complete_track']for x in audit['classes'].values())
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=18
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
shutil.copy2(ROOT/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(ROOT/'data/rules/trhgd-character-v30.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('FIGHTER AND BARBARIAN REVIEW\n\nExtract the outer GitHub artifact ZIP and then the inner playable ZIP. Keep every file and run road-has-gone-dark.exe. Godot and Node need not be installed. Escape skips the intro. Fresh New Game uses v30; existing campaigns retain exact old pins with no automatic upgrade.\n\nNew Game -> world -> origin -> hometown -> three characters. Fighter: choose Blade or Bow discipline and a matching active weapon in Equipment. Disciplines share finite Fighter resolve with healing/advanced techniques and spend a main action. Actual weapon, natural-form/manifested overrides and inherited attacks remain relevant. Veteran/Pointblank and ranged discipline bonuses now genuinely function; same-type maxima still apply.\n\nBarbarian: choose Reckless assault or Resilient rage. Each activation spends its own main action and finite Rage use. The existing paid combinations remain legal; each status has its own short global-round expiry. Reckless attack competes against defence; Resilient supports defence/Fortitude. Resilient mastery at15 adds real Fortitude. Home-return rest recovers daily uses; a new encounter alone does not. Temporary HP remains a separate finite nonstacking buffer.\n\nEarn XP through ordinary opportunities, return home and choose levels/feats deliberately. Class selection never generates XP. Native acceptance earned490XP/class8 for Blade Fighter, Bow Fighter and Barbarian, then forked an actual battle through the original writer, paid for all three class actions and proved exact process-restart/normal resolution/home recovery. High20 screenshots are explicitly DEVELOPMENT FIXTURES, not earned20. Save, exit completely, relaunch and Resume. No QA executable or XP button ships.\n\nThe roster stays50 careers; matching-source native evidence promotes this pair only. Human balance, shared long-label/small-screen limits and humanoid art fallbacks remain separate.\n',encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt=dict(acceptance_cohort='fighter-barbarian',source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,captures=captures,source_guard=scope,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=3,earned_xp=490,earned_level=8,high_level_fixtures_not_earned=True)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(dict(archive=str(archive),sha256=sha),flush=True)
