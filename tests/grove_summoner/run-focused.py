"""Focused Windows source diagnostics, before any full native release."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GROVE_SUMMONER_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[]
for phase,cold,filename in [('compile',False,''),('probe',False,'probe-proof.json'),('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json')]:
 label=phase+('-cold'if cold else'')
 out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/grove_summoner/scene_runner.gd','--',phase],cwd=root,env=dict(os.environ,GROVE_SUMMONER_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1800)
 timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n');print(timings[-1],flush=True)
 if out['exit_code']or out['errors']or out['timeout']:print((base/(label+'.log')).read_text(encoding='utf-8')[-24000:],flush=True)
 assert not out['exit_code']and not out['errors']and not out['timeout'],label
 if filename:
  p=json.loads((base/filename).read_text());assert p['checks']>0 and p['failures']==0
