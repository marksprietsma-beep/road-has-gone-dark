"""Fresh Windows Godot captures from exact-source-guarded earned/source receipts."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
assert os.name=='nt','Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['HYBRID_PRESENTATION_ROOT']);base.mkdir(parents=True,exist_ok=True)
# Input artifacts are sealed original Windows source-Godot results, not native
# exported results. Only presentation is freshly exercised here.
earned_source=os.environ['HYBRID_EARNED_SOURCE'];earned_run=int(os.environ['HYBRID_EARNED_RUN'])
assert subprocess.check_output(['git','diff',earned_source,'HEAD','--','tests/hybrid_acceptance/journey.gd','tests/nature_repertoires/caster_planner.gd','tests/nature_repertoires/journey_driver.gd','tests/character_completeness/prestige_driver.gd'],cwd=root)==b'', 'Earned planner changed after evidence'
for source in [earned_source,'98bd4fdfe45b21f0e7170752832af594fbbf37ac']:
 assert subprocess.check_output(['git','diff',source,'HEAD','--','scripts','data','scenes','assets','project.godot','vendor'],cwd=root)==b'', 'Rules/production changed since input evidence'
shutil.copytree(Path(os.environ['HYBRID_PRESENTATION_INPUT'])/'hybrid-earned',base/'earned',dirs_exist_ok=True)
shutil.copytree(Path(os.environ['HYBRID_PRESENTATION_INPUT'])/'hybrid-focused',base/'mechanics',dirs_exist_ok=True)
protected={str(p.relative_to(base)):hashlib.sha256(p.read_bytes()).hexdigest()for p in base.rglob('*.json')}
for p in (base/'earned/journeys/cohort-0/cache').rglob('*.json'):
 sidecar=Path(str(p)+'.sha')
 if not sidecar.exists():sidecar.write_text(hashlib.sha256(p.read_bytes()).hexdigest(),encoding='utf-8')
journey=json.loads((base/'earned/journeys/cohort-0/proof.json').read_text(encoding='utf-8'))
assert journey['failures']==0 and journey['earned_xp']==1690 and not journey['xp_injected'] and set(journey['earned_entry_witnesses'])=={'wizard','sorcerer'}
for file in ['proof.json','restart-proof.json','input-proof.json']:
 p=json.loads((base/'mechanics'/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
for file in ['proof.json','restart-proof.json']:
 p=json.loads((base/'earned/connected'/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
captures=base/'captures'
env=dict(os.environ,HYBRID_ROOT=str(base/'mechanics'),HYBRID_CAPTURE_ROOT=str(captures),GAME126_JOURNEY_ROOT=str(base/'earned/journeys'),GAME129_CONNECTED_ROOT=str(base/'earned/connected'))
result=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/hybrid_acceptance/scene_runner.gd','--','capture'],cwd=root,env=env,log=base/'capture.log',timeout=900)
assert not result['exit_code']and not result['errors']and not result['timeout'],(base/'capture.log').read_text(encoding='utf-8')[-20000:]
for file,sha in protected.items():assert hashlib.sha256((base/file).read_bytes()).hexdigest()==sha,file
p=json.loads((captures/'screenshots.json').read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0 and len(p['screenshots'])>=18
for image in p['screenshots']:assert hashlib.sha256((captures/image['file']).read_bytes()).hexdigest()==image['sha256']
proof=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),input_runs=[40081154951,earned_run],production_and_rules_unchanged=True,source_evidence_not_native_export=True,protected_bytes=protected,captures=p,timing=result)
(base/'presentation-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8');print('HYBRID_WINDOWS_PRESENTATION_PASS',flush=True)
