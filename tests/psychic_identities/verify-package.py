"""One complete Windows native release; no historical-source reuse for changed rules."""
from pathlib import Path
import os,sys,json,hashlib,subprocess,zipfile,shutil
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME127_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game127-psychic-identities-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest=(root/'data/rules/packs.json').read_bytes();pins={p['rules_ref']['pack_id']:p['rules_ref']for p in json.loads(manifest)['packs']};pin=pins['trhgd-character-v25']
subprocess.run([sys.executable,'tests/psychic_identities/check-history.py'],cwd=root,check=True)
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/psychic_identities/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME127_ROOT=str(base/'mechanics'),GAME152_ROOT=str(base/'historical24'),GAME127_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'),GAME126_AUDIT_ROOT=str(base/'readiness-audit'),GAME126_PACK='res://data/rules/trhgd-character-v25.json',GAME112W3_TEST_ROOT=str(base/'historical13'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
def run(phase,cold=False):
 extra=dict(GAME152_ROOT=str(base/('current-psychic'if phase=='current-psychic'else'historical24')),GAME127_PHASE=phase,GAME127_RESTART='1'if cold else'0',GAME152_RESTART='1'if cold else'0',GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0',GAME146_RESTART='1'if cold else'0',GAME148_RESTART='1'if cold else'0',GAME149_RESTART='1'if cold else'0',GAME150_RESTART='1'if cold else'0',GAME112W3_RESTART='1'if cold else'0',GAME150_ROOT=str(base/('historical23'if phase=='historical23'else'current-upper')),GAME149_ROOT=str(base/'current-performance'),GAME148_ROOT=str(base/'current-supernatural'),GAME146_ROOT=str(base/'current-mobile'),GAME129_ROOT=str(base/'current-signatures'))
 log=base/(phase+('-cold'if cold else'')+'.log')
 r=checked_process([str(qa)]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=log,timeout=1800)
 timings.append(dict(phase=phase,cold=cold,**r));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 print(json.dumps(timings[-1]),flush=True)
 assert not r['exit_code']and not r['errors']and not r['timeout'],log.read_text(encoding='utf-8')[-16000:]
phases=['baseline','mechanics','input','journey','connected','capture','current-upper','current-upper-input','current-performance','current-performance-input','current-supernatural','current-signatures','current-mobile','current-psychic','historical24','historical24-input','historical23','historical13','legacy','compatibility','audit']
for phase in phases:
 run(phase)
 if phase not in ['baseline','input','capture','current-upper-input','current-performance-input','historical24-input']:run(phase,True)
for phase,folder,version in [('mechanics','mechanics','v25'),('journey','journeys/cohort-0','v25'),('connected','connected','v25'),('current-upper','current-upper','v25'),('current-performance','current-performance','v25'),('current-supernatural','current-supernatural','v25'),('current-signatures','current-signatures','v25'),('current-mobile','current-mobile','v25'),('current-psychic','current-psychic','v25'),('historical24','historical24','v24'),('historical23','historical23','v23'),('historical13','historical13','v13'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16'),('audit','readiness-audit','v25')]:
 for file in ['proof.json','restart-proof.json']:
  actual=('mechanics-restart-proof.json'if file=='restart-proof.json'else'mechanics-proof.json')if phase=='historical13'else file
  p=json.loads((base/folder/actual).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,file)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,file)
  proofs[phase+'/'+file]=p
for phase,folder,file in [('baseline','mechanics','baseline-proof.json'),('input','mechanics','input-proof.json'),('historical24-input','historical24','input-proof.json'),('current-upper-input','current-upper','input-proof.json'),('current-performance-input','current-performance','input-proof.json')]:
 p=json.loads((base/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase]=p
journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False and len(journey['journeys'])==3
assert {x['history'][0]['class_id']for x in journey['journeys']}=={'ardent','lurk','erudite'}
assert all(len(x['history'])==8 for x in journey['journeys'])
assert len(proofs['connected/proof.json']['casts'])==3 and proofs['connected/proof.json']['xp_injected']is False
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=20
for row in captures['screenshots']:assert hashlib.sha256((base/'captures'/row['file']).read_bytes()).hexdigest()==row['sha256']
frozen_env=dict(os.environ,GAME32_EVIDENCE=str(base/'frozen-rules'))
r=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=root,env=frozen_env,log=base/'frozen-rules.log',timeout=600)
assert not r['exit_code']and not r['errors']and not r['timeout'],(base/'frozen-rules.log').read_text(encoding='utf-8')[-12000:]
proofs['frozen-rules']=json.loads((base/'frozen-rules/kernel-results.json').read_text());assert proofs['frozen-rules']['checks']==22181 and proofs['frozen-rules']['failures']==0
assert (root/'data/rules/packs.json').read_bytes()==manifest
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code']and not r['errors']and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v25.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-127 ARDENT / LURK / ERUDITE\n\nExtract the GitHub artifact ZIP, then the inner playable ZIP. Keep ALL support files beside road-has-gone-dark.exe and launch it. No installed Godot or Node needed. Escape skips intro.\n\nFresh New Game defaults to immutable v25. Existing campaigns keep their exact historical rules; no save migration. Choose Ardent, Lurk or Erudite in the normal creator. Build > Specialisation / Powers displays persistent choices and restrictions. Ardent selects distinct mantles and eligible powers; shared PP never replaces the owning class attribute.\n\nLurk spends a main action and focus to veil (25% weapon concealment for two global rounds, not invisibility). A later adjacent melee ambush consumes main/focus/PP and the veil. Its original direct psychic damage and off-balance precede a separate weapon roll that can miss. Ordinary extra weapon reach does not extend ambush. A starting Lurk may lack focus to pay both actions before resting; advance normally.\n\nErudite has 1 + floor(Erudite level/4) distinct power identities per eligible rest. Repeats/augmentation share an identity but still spend PP/actions. A new exhausted identity is shown with a disabled action and explanation. Encounters and reloads never reset it. Return home and rest to restore eligible reserves and allowance.\n\nEarn real adventure XP, return home and commit advancement deliberately; no free XP control. Verification includes three actual490XP/level8 careers and saved generated combat; level20 screenshots are labelled development fixtures. Save, exit the process, relaunch and Resume. No QA executable ships. No full tabletop conversion, invisibility engine or expanded roster. Human balance/readability acceptance remains pending.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,earned_characters=3,historical_scope='Fresh native historical24 mechanics/input/cold, historical23/13 mechanics/cold and v16 legacy/compatibility. All24 historical source bytes/pins unchanged.'),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
