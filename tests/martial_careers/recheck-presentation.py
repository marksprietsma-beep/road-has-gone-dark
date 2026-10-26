"""Fresh Windows renders from unchanged earned gameplay; never native release proof."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
source=os.environ['MARTIAL_EARNED_SOURCE'];run=int(os.environ['MARTIAL_EARNED_RUN'])
ui='scripts/ui/components/build_editor.gd'
paths=['scripts','data','scenes','assets','themes','vendor','project.godot','export_presets.cfg','tests/martial_careers/probe.gd','tests/martial_careers/journey.gd','tests/martial_careers/connected.gd','tests/nature_repertoires','tests/character_completeness','tests/adventure_cycles','tests/class_signatures/connected_driver.gd']
changed=subprocess.check_output(['git','diff','--name-only',source,'HEAD','--',*paths],cwd=root,text=True).splitlines()
assert set(changed)<=set([ui]),('Earned gameplay/fixture inputs changed',changed)
before=subprocess.check_output(['git','show',source+':'+ui],cwd=root).decode('utf-8')
expected=before.replace('if not why.is_empty():messages.append(source.definition("classes",id).name+": "+why)','if id==class_id and not why.is_empty():messages.append(source.definition("classes",id).name+": "+why)').replace('if not why.is_empty():messages.append(source.definition("feats",id).name+": "+why)','if id==feat_id and not why.is_empty():messages.append(source.definition("feats",id).name+": "+why)')
assert (root/ui).read_text(encoding='utf-8')==expected,'Only the reviewed selected-option diagnostic presentation may differ'
base=Path(os.environ['MARTIAL_PRESENTATION_ROOT']);base.mkdir(parents=True,exist_ok=True)
shutil.copytree(Path(os.environ['MARTIAL_PRESENTATION_INPUT'])/'martial-earned',base/'earned',dirs_exist_ok=True)
earned=json.loads((base/'earned/earned-proof.json').read_text(encoding='utf-8'));assert earned['source_commit']==source
for phase in ['journey','connected']:
 for name in ['proof.json','restart-proof.json']:
  p=earned['proofs'][phase+'/'+name];assert p['checks']>0 and p['failures']==0
j=earned['proofs']['journey/proof.json'];assert j['earned_xp']==490 and not j['xp_injected']and len(j['journeys'])==3 and all(len(row['history'])==8 for row in j['journeys'])
assert {row['role']for row in j['builds'].values()}=={'blade','bow','rage'}
focused=Path(os.environ['MARTIAL_ROOT'])
for path in ['proof.json','restart-proof.json','input-proof.json','extended/proof.json','extended/restart-proof.json']:
 p=json.loads((focused/path).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
protected={str(p):hashlib.sha256(p.read_bytes()).hexdigest()for folder in [base/'earned',focused]for p in folder.rglob('*.json')}
for p in (base/'earned/journeys/cohort-0/cache').rglob('*.json'):
 sidecar=Path(str(p)+'.sha')
 if not sidecar.exists():sidecar.write_text(hashlib.sha256(p.read_bytes()).hexdigest(),encoding='utf-8')
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'earned/journeys'),GAME129_CONNECTED_ROOT=str(base/'earned/connected'),MARTIAL_CAPTURE_ROOT=str(base/'captures'))
out=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/martial_careers/scene_runner.gd','--','capture'],cwd=root,env=env,log=base/'capture.log',timeout=900)
assert not out['exit_code']and not out['errors']and not out['timeout'],(base/'capture.log').read_text(encoding='utf-8')[-18000:]
for path,sha in protected.items():assert hashlib.sha256(Path(path).read_bytes()).hexdigest()==sha,path
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=20
for image in captures['screenshots']:assert hashlib.sha256((base/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
assert all(any(image['file'].startswith('fixture-'+power+'-combat-')for image in captures['screenshots'])for power in ['whirlwind','titan'])
receipt=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),reused_earned_run=run,reused_earned_source=source,source_evidence_not_native_export=True,scope='Original490XP/8 and connected/cold proof reused without gameplay changes; only reviewed selected-option diagnostic presentation differs. Fresh current-source controls, higher-power fixtures and original Godot renders. Native release must earn its own campaign.',protected_json_sha256=protected,captures=captures,timing=out)
(base/'presentation-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print('MARTIAL_WINDOWS_PRESENTATION_PASS',flush=True)
