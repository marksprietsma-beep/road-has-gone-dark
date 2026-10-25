"""Windows source-Godot preflight of the exact save-continuation harness, no export claim."""
from pathlib import Path
import os,json,subprocess,sys
assert os.name=='nt','Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
from earned_import import prepare
base=Path(os.environ['HYBRID_NATIVE_PROGRESS_ROOT']);base.mkdir(parents=True)
manifest=json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'));pin=manifest['packs'][-1]['rules_ref']
reuse=prepare(root,base,pin)
env=dict(os.environ,HYBRID_IMPORTED_EARNED=str(reuse['imported']),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_RESUME='1',GAME126_COHORT='0',HYBRID_NATIVE_ENTRY_ROOT=str(base/'entry'))
timings=[];proofs={}
for phase in ['native_entry','native_progress','native_connected']:
 for cold in [False,True]:
  active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0',HYBRID_RESTART='1'if cold else'0')
  label=phase+('-cold'if cold else'')
  result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/hybrid_acceptance/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=1800)
  timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(json.dumps(timings[-1]),flush=True)
  assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
for folder in ['journeys/cohort-0','connected']:
 for file in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[folder+'/'+file]=p
for file in ['entry-proof.json','entry-restart-proof.json']:
 p=json.loads((base/'entry'/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs['entry/'+file]=p
p=proofs['journeys/cohort-0/proof.json'];assert p['earned_xp']==1960 and p['native_earned_xp']==270 and not p['xp_injected'] and all(len(r['history'])==15 for r in p['journeys'])
(base/'native-progress-preflight.json').write_text(json.dumps(dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),source_godot_preflight_not_exported_native=True,reused_run=reuse['run'],proofs=proofs,timings=timings),indent=2)+'\n',encoding='utf-8')
