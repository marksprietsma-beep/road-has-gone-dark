"""Correct visual evidence only; retain the successful complete native release."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
assert os.name=='nt','Windows Godot captures only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME150_RECAPTURE_ROOT']).resolve()
original=json.loads((base/'distribution-proof.json').read_text(encoding='utf-8'))
assert original['source_commit']=='8b37e0d03ed38df138bc6bf2fdf6bba221673d85'
assert original['production_launch']and original['separate_process_restart']and all(r['failures']==0 for r in original['proofs'].values())
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
changed=subprocess.check_output(['git','diff','--name-only',original['source_commit'],source],cwd=root,text=True).splitlines()
allowed={'tests/upper_prepared/capture.gd','tests/upper_prepared/input.gd','tests/upper_prepared/recapture.py','.github/workflows/capture-upper-prepared.yml'}
assert all(p.startswith('docs/')or p in allowed for p in changed),changed
pack=json.loads((root/'data/rules/trhgd-character-v23.json').read_text(encoding='utf-8'))
assert hashlib.sha256(json.dumps(pack,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==original['rules_ref']['content_hash']
dist=base/'recapture-export'
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/upper_prepared/review.tscn','--output',str(dist)],cwd=root,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME150_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME129_CONNECTED_ROOT=str(base/'connected'))
for key in ['GAME76_HELPER_ROOT','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[]
for phase in ['input','capture']:
 result=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME150_PHASE=phase,GAME150_RESTART='0'),log=base/('recapture-'+phase+'.log'),timeout=180)
 assert not result['exit_code']and not result['errors']and not result['timeout'],result
 timings.append(dict(phase=phase,**result))
controls=json.loads((base/'mechanics/input-proof.json').read_text(encoding='utf-8'));assert controls['checks']>=30 and controls['failures']==0
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['failures']==0 and len(captures['screenshots'])>=25
for row in captures['screenshots']:assert hashlib.sha256((base/'captures'/row['file']).read_bytes()).hexdigest()==row['sha256']
report=dict(source_commit=source,original_release_source=original['source_commit'],original_release_run=39423972908,rules_ref=original['rules_ref'],runtime_and_rules_unchanged=True,changed_paths=changed,controls=controls,captures=captures,timings=timings,scope='Windows-only correction of capture interactions: emit actual typing signal, open visible specialisation tab, scroll actual spell controls/logs. Existing complete release and gameplay results retained, not rerun or claimed fresh.')
(base/'recapture-proof.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report),flush=True)
