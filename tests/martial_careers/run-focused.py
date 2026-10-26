"""Windows source engine diagnostics; no native-export or earned-XP claims."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['MARTIAL_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[];failed=[];warm={}
for phase,cold,filename in [('compile',False,''),('probe',False,'probe-proof.json'),('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json'),('extended',False,'extended/proof.json'),('extended',True,'extended/restart-proof.json')]:
 label=phase+('-cold'if cold else'')
 if (cold and not warm.get(phase,False))or(phase=='input'and not warm.get('mechanics',False)):
  failed.append(label+' unavailable because its warm dependency failed');continue
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/martial_careers/scene_runner.gd','--',phase],cwd=root,env=dict(os.environ,MARTIAL_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
 ok=not result['exit_code']and not result['errors']and not result['timeout']
 if ok and filename:
  p=json.loads((base/filename).read_text(encoding='utf-8'));ok=p['checks']>0 and p['failures']==0
 if not cold:warm[phase]=ok
 if not ok:
  failed.append(label);print((base/(label+'.log')).read_text(encoding='utf-8')[-18000:],flush=True)
 # Independent input/extended probes both report real failures in one job.
 # Failed warm proofs never authorize dependent cold or production-input work.
 if phase=='compile'and not ok:break
assert not failed,failed
