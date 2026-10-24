"""Windows Godot render recheck of immutable raw failed-run evidence, not a rebuild."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
assert os.name=='nt','Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
original=Path(os.environ['HYBRID_HISTORICAL_INPUT']);base=Path(os.environ['HYBRID_HISTORICAL_ROOT'])
shutil.copytree(original,base,dirs_exist_ok=True)
protected=[base/'mechanics/saved.json',base/'journeys/cohort-0/proof.json']+list((base/'journeys/cohort-0/saves').glob('*.json'))
hashes={str(p.relative_to(base)):hashlib.sha256(p.read_bytes()).hexdigest()for p in protected}
env=dict(os.environ,GAME133_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME133_CONNECTED_ROOT=str(base/'connected'),GAME126_AUDIT_RESTART='0',GAME126_COHORT='0')
result=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/hybrid_acceptance/scene_runner.gd','--','historical_capture'],cwd=root,env=env,log=base/'recheck.log',timeout=600)
assert not result['exit_code']and not result['errors']and not result['timeout'],(base/'recheck.log').read_text(encoding='utf-8')[-18000:]
for file,sha in hashes.items():assert hashlib.sha256((base/file).read_bytes()).hexdigest()==sha
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=8
for image in captures['screenshots']:assert hashlib.sha256((base/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
p=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),reused_run=40068624106,reused_native_source='c48d6df3e08fe17d8893294aab029e02a7be20e9',original_mechanics_campaign_bytes_unchanged=hashes,captures=captures,timing=result,scope='Fresh actual Windows source-Godot capture of archived native18 mechanics/earned27 state. No claim of another native release; original records, campaign pins, XP and save bytes retained.')
(base/'recheck-proof.json').write_text(json.dumps(p,indent=2)+'\n');print(json.dumps({'captures':len(captures['screenshots']),'failures':0}),flush=True)
