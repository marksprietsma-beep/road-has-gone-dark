"""Windows source engine diagnostics; no native-export or earned-XP claims."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['MARTIAL_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[]
for phase,filename in [('compile',''),('probe','probe-proof.json')]:
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/martial_careers/scene_runner.gd','--',phase],cwd=root,env=os.environ.copy(),log=base/(phase+'.log'),timeout=1200)
 timings.append(dict(phase=phase,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(phase+'.log')).read_text(encoding='utf-8')[-18000:]
 if filename:
  p=json.loads((base/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
