"""Fresh Windows captures of successful, exact-source-guarded source evidence."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DUAL_PRESENTATION_ROOT']);base.mkdir(parents=True,exist_ok=True)
source=os.environ['DUAL_EARNED_SOURCE'];run=int(os.environ['DUAL_EARNED_RUN'])
paths=['scripts','data','scenes','assets','themes','project.godot','vendor','tests/dual_prestige_acceptance/base.gd','tests/dual_prestige_acceptance/mechanics.gd','tests/dual_prestige_acceptance/input.gd','tests/dual_prestige_acceptance/journey.gd','tests/dual_prestige_acceptance/entry.gd','tests/dual_prestige_acceptance/connected.gd','tests/nature_repertoires','tests/character_completeness']
assert subprocess.check_output(['git','diff',source,'HEAD','--',*paths],cwd=root)==b'','Evidence runtime or fixture inputs changed'
incoming=Path(os.environ['DUAL_PRESENTATION_INPUT'])
shutil.copytree(incoming/'dual-focused',base/'mechanics',dirs_exist_ok=True);shutil.copytree(incoming/'dual-earned',base/'earned',dirs_exist_ok=True)
protected={str(p.relative_to(base)):hashlib.sha256(p.read_bytes()).hexdigest()for p in base.rglob('*.json')}
for p in (base/'earned/journeys/cohort-0/cache').rglob('*.json'):
 sidecar=Path(str(p)+'.sha')
 if not sidecar.exists():sidecar.write_text(hashlib.sha256(p.read_bytes()).hexdigest(),encoding='utf-8')
earned=json.loads((base/'earned/earned-proof.json').read_text(encoding='utf-8'));assert earned['source_commit']==source
assert earned['proofs']['journey/proof.json']['earned_xp']==640
for phase in ['journey','connected-a','connected-b']:
 for filename in ['proof.json','restart-proof.json']:assert earned['proofs'][phase+'/'+filename]['failures']==0
for filename in ['proof.json','restart-proof.json','input-proof.json']:
 p=json.loads((base/'mechanics'/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
env=dict(os.environ,DUAL_ROOT=str(base/'mechanics'),DUAL_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'earned/journeys'),DUAL_CONNECTED_BASE=str(base/'earned'))
out=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/dual_prestige_acceptance/scene_runner.gd','--','capture'],cwd=root,env=env,log=base/'capture.log',timeout=900)
assert not out['exit_code']and not out['errors']and not out['timeout'],(base/'capture.log').read_text(encoding='utf-8')[-18000:]
for filename,sha in protected.items():assert hashlib.sha256((base/filename).read_bytes()).hexdigest()==sha,filename
p=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0 and len(p['screenshots'])>=18
for item in p['screenshots']:assert hashlib.sha256((base/'captures'/item['file']).read_bytes()).hexdigest()==item['sha256']
(base/'presentation-proof.json').write_text(json.dumps(dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),input_run=run,input_source=source,source_evidence_not_native_export=True,protected_bytes=protected,captures=p,timing=out),indent=2)+'\n',encoding='utf-8')
print('DUAL_PRESTIGE_WINDOWS_PRESENTATION_PASS',flush=True)
