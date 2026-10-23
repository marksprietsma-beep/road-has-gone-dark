"""One stable Windows native release, with explicitly guarded prior v26 scopes."""
from pathlib import Path
import os,sys,json,hashlib,subprocess,zipfile,shutil,importlib.util
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('path_source_guard',root/'tests/psychic_paths/check-source.py')
guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)
reuse=guard.verify()
base=Path(os.environ['GAME127_PATH_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game127-advanced-psychic-paths-windows-x64';dist=release/name
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest=(root/'data/rules/packs.json').read_bytes()
pins={r['rules_ref']['pack_id']:r['rules_ref']for r in json.loads(manifest)['packs']};pin=pins['trhgd-character-v26']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/psychic_paths/review.tscn','--output',str(dist)],cwd=root,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME127_PATH_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME127_PATH_CAPTURE_ROOT=str(base/'captures'),GAME127_ROOT=str(base/'current-support'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
def run(phase,cold=False):
    run_env=dict(env,GAME127_PATH_PHASE=phase,GAME127_PATH_RESTART='1'if cold else'0',GAME127_RESTART='1'if cold else'0',GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
    log=base/(phase+('-cold'if cold else'')+'.log')
    result=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=run_env,log=log,timeout=1800)
    timings.append(dict(phase=phase,cold=cold,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
    print(json.dumps(timings[-1]),flush=True)
    assert not result['exit_code']and not result['errors']and not result['timeout'],log.read_text(encoding='utf-8')[-16000:]
for phase in ['mechanics','input','journey','connected','capture','current-support','current-support-input','legacy']:
    run(phase)
    if phase not in ['input','capture','current-support-input']:run(phase,True)
for phase,folder,version in [('mechanics','mechanics','v26'),('journey','journeys/cohort-0','v26'),('connected','connected','v26'),('current-support','current-support','v26'),('legacy','legacy-v16','v16')]:
    for file in ['proof.json','restart-proof.json']:
        proof=json.loads((base/folder/file).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0,(phase,file)
        if 'rules_ref'in proof:assert proof['rules_ref']==pins['trhgd-character-'+version]
        proofs[phase+'/'+file]=proof
for phase,folder in [('input','mechanics'),('current-support-input','current-support')]:
    proof=json.loads((base/folder/'input-proof.json').read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0;proofs[phase]=proof
journey=proofs['journey/proof.json'];assert journey['earned_xp']==810 and journey['xp_injected']is False
assert len(journey['journeys'])==3 and all(len(r['history'])==10 for r in journey['journeys'])
assert [s['class_id']for s in journey['journeys'][0]['history']]==['psion']*8+['metamind']*2
assert [s['class_id']for s in journey['journeys'][1]['history']]==['psion']*5+['pyrokineticist']*5
assert journey['earned_entries']['metamind']['earned_xp']==640 and journey['earned_entries']['metamind']['next_level']==9
assert journey['earned_entries']['pyrokineticist']['earned_xp']==250 and journey['earned_entries']['pyrokineticist']['next_level']==6
assert len(proofs['connected/proof.json']['casts'])==3 and proofs['connected/proof.json']['earned_xp_before_combat']==810
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=15
for image in captures['screenshots']:assert hashlib.sha256((base/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
frozen=base/'frozen-rules'
result=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=root,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=base/'frozen-rules.log',timeout=600)
assert not result['exit_code']and not result['errors']and not result['timeout']
proofs['frozen-rules']=json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'));assert proofs['frozen-rules']['checks']==22181 and proofs['frozen-rules']['failures']==0
assert guard.verify()==reuse and subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==source
assert (root/'data/rules/packs.json').read_bytes()==manifest
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==source
result=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not result['exit_code']and not result['errors']and not result['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json')
shutil.copy2(root/'data/rules/trhgd-character-v26.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-127: METAMIND AND PYROKINETICIST\n\nExtract the outer GitHub ZIP, then this inner ZIP. Keep every supporting file together and launch road-has-gone-dark.exe. No installed Godot or Node required. Escape skips intro.\n\nRules remain immutable v26; no save migration or new roster. Start a base class such as Psion. Metamind/Pyrokineticist are optional prestige choices, never starting classes or automatic rewards. Earn normal adventure XP, return home, meet permanent requirements and commit advancement manually. Metamind requires total8,INT13,Arcana8,Deep Reserve and actual manifesting; first entry is total9 at640XP. Pyrokineticist requires total5,Arcana4 and permanent PP capacity6; first entry is total6 at250XP. Both paths support10 prestige levels.\n\nMetamind: main action/one finite reserve charge reclaims4+path level points up to capacity. Eligible home rest restores reserves; new encounters/reload do not. This does not reset Erudite distinct powers or refill arcane slots. Pyrokineticist: finite two-point/main fire ignitions use Reflex saves; success halves fire, failure adds Weakened. Fire resistance and condition immunity remain separate; no general elemental immunity or weapon-flame system is claimed. Natural forms suppress psychic fire actions.\n\nThis acceptance demonstrates genuine810XP/total10 careers, including Psion8/Metamind2 and Psion5/Pyrokineticist5. Total20 and full ten-level path renders are explicitly development fixtures. Save, exit, relaunch and Resume. No QA executable ships. Human balance/readability and nonhumanoid sprites remain separate review items.\n',encoding='utf-8')
for path in dist.glob('road-has-gone-dark-qa*'):path.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
    for path in dist.rglob('*'):
        if path.is_file():z.write(path,Path(name)/path.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt=dict(acceptance_cohort='metamind-pyrokineticist',source_commit=source,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={k:source for k in proofs},timings=timings,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,reused_previous_native=reuse,earned_characters=3)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
