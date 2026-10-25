"""One complete Windows-native release, with a fresh earned campaign in the export."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,subprocess,sys,zipfile
assert os.name=='nt','Windows game validation only'
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('dual_source',ROOT/'tests/dual_prestige_acceptance/check-source.py')
guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard);source_guard=guard.verify()
base=Path(os.environ['DUAL_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='theurge-abjurant-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
manifest_bytes=(ROOT/'data/rules/packs.json').read_bytes();pins={r['rules_ref']['pack_id']:r['rules_ref']for r in json.loads(manifest_bytes)['packs']};pin=pins['trhgd-character-v29']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/dual_prestige_acceptance/review.tscn','--output',str(dist)],cwd=ROOT,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',DUAL_ROOT=str(base/'mechanics'),DUAL_CAPTURE_ROOT=str(base/'captures'),DUAL_ENTRY_ROOT=str(base/'entry'),DUAL_CONNECTED_BASE=str(base),
 GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME126_AUDIT_ROOT=str(base/'all-base'),GAME126_PACK='res://data/rules/trhgd-character-v29.json',
 GAME150_ROOT=str(base/'current-upper'),GAME133_ROOT=str(base/'historical18'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
for phase in ['probe','mechanics','input','journey','entry','connected-a','connected-b','capture','audit','current-upper','historical28','historical18','legacy','compatibility']:
 for cold in ([False]if phase in ['probe','input','capture']else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,DUAL_PHASE=phase,DUAL_CONNECTED_VARIANT='b'if phase=='connected-b'else'a',GAME129_CONNECTED_ROOT=str(base/('connected-b'if phase=='connected-b'else'connected-a')))
  if phase=='historical28':active['GAME150_ROOT']=str(base/'historical28')
  for key in ['DUAL_RESTART','GAME150_RESTART','GAME133_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART']:active[key]='1'if cold else'0'
  command=[str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy']
  out=checked_process(command,cwd=dist,env=active,log=base/(label+'.log'),timeout=7200 if phase=='journey'else 3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(json.dumps(timings[-1]),flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
for phase,folder,version in [('mechanics','mechanics','v29'),('journey','journeys/cohort-0','v29'),('connected-a','connected-a','v29'),('connected-b','connected-b','v29'),('audit','all-base','v29'),('current-upper','current-upper','v29'),('historical28','historical28','v28'),('historical18','historical18','v18'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16')]:
 for filename in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,filename)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,filename)
  proofs[phase+'/'+filename]=p
for key,folder,filename in [('input','mechanics','input-proof.json'),('pinned28-probe','mechanics','probe-proof.json'),('entry','entry','entry-proof.json'),('entry-cold','entry','entry-restart-proof.json')]:
 p=json.loads((base/folder/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[key]=p
m=proofs['mechanics/proof.json'];assert all(m['contracts'][k]is True for k in ['permanent_entry','historical_pins','dual_casting','champion_progression','total20','independent_resources','casting_attributes','distinct_support','martial_outcomes','body_suppression','recovery'])
j=proofs['journey/proof.json'];assert j['earned_xp']==640 and not j['xp_injected']and len(j['journeys'])==3
assert all(len(r['history'])==9 for r in j['journeys'])and set(j['earned_entry_witnesses'])=={'wizard','sorcerer','duskblade'}
for phase,abilities in [('connected-a',{'wizard-arcane-bolt','cleric-bless','abjurant-retaliation-1'}),('connected-b',{'cleric-bless','sorcerer-arcane-bolt','abjurant-aegis-3'})]:assert set(proofs[phase+'/proof.json']['casts'].values())==abilities
audit=json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(r['complete_track']for r in audit['classes'].values())
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=18
for item in captures['screenshots']:assert hashlib.sha256((base/'captures'/item['file']).read_bytes()).hexdigest()==item['sha256']
frozen=base/'frozen';out=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=ROOT,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=base/'frozen.log',timeout=600)
assert not out['exit_code']and not out['errors']and not out['timeout']
proofs['frozen']=json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'));assert proofs['frozen']['checks']==22181 and proofs['frozen']['failures']==0
assert guard.verify()==source_guard and (ROOT/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
out=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not out['exit_code']and not out['errors']and not out['timeout']
shutil.copy2(ROOT/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(ROOT/'data/rules/trhgd-character-v29.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('MYSTIC THEURGE AND ABJURANT CHAMPION REVIEW\n\nExtract both ZIP layers, retaining every file. Run road-has-gone-dark.exe. No installed Godot or Node is required; Escape skips the intro. New campaigns use v29. Existing campaigns retain their exact original rules pins; do not reset them to inspect the new content.\n\nPrestige is NEVER an initial class or automatic reward. Create Wizard/Cleric (INT/WIS), Sorcerer/Cleric (CHA/WIS) or a melee Duskblade (INT). Earn XP from ordinary opportunities. At home use the advancement tab, inspect prerequisites and deliberately select the prestige path or continue a base class instead. The selector grants no XP.\n\nMystic Theurge: meet permanent dual casting levels, actual tier2 arcane and divine spell access and skill requirements. Select each real parent separately. The path has ten levels. It advances only those casting tracks, with their own attributes, prepared copies or permanent spontaneous knowledge and separate slots. It never grants all parent class powers. Later support offers larger recovery, a smaller precise Weakened/Arcane tether cleanse, or nonstacking preventive temporary HP. Every action spends a main action and the same finite path-use pool; no free healing or slot recovery.\n\nAbjurant Champion: meet durable level/BAB/casting/skill prerequisites and select an actual arcane parent. Five levels offer deliberate Aegis or Retaliation doctrine. Aegis spends a main action and resolve to protect. Retaliation spends the same costs even on a miss, makes one ordinary adjacent melee attack, and grants a pre-hit buffer. Bow, range, body suppression, depleted resolve, spent main action and normal reaction rules still apply. Eligible home return recovers resources.\n\nWindows acceptance earned640XP and level9 for three adventurers in the exported executable through normal objectives. Six isolated forks demonstrated explicit prestige acceptance or deliberate base advancement, with unchanged XP. Two further isolated combat forks proved both casting traditions and Champion actions, exact cold continuation, normal consequences and recovery; fork rewards are never added to the primary campaign. Total20 / Theurge10 / Champion5 screenshots are labelled development fixtures, not earned20. Save, exit completely, relaunch and Resume. QA executables and XP controls do not ship. Humanoid LPC fallback art and general long-list/small-screen usability remain separate limitations.\n',encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt=dict(acceptance_cohort='mystic-theurge-abjurant-champion',source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,captures=captures,source_guard=source_guard,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=3,earned_xp=640,earned_level=9,high_level_fixtures_not_earned=True)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
