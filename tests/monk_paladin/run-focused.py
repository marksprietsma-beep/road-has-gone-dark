"""Windows-only source diagnostics; native and earned acceptance are separate."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['MONK_PALADIN_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[]
for phase,cold,filename in [('probe',False,'probe-proof.json'),('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json')]:
 label=phase+('-cold'if cold else'')
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/monk_paladin/scene_runner.gd','--',phase],cwd=root,env=dict(os.environ,MONK_PALADIN_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
 if result['exit_code']or result['errors']or result['timeout']:print((base/(label+'.log')).read_text(encoding='utf-8')[-22000:],flush=True)
 assert not result['exit_code']and not result['errors']and not result['timeout'],label
 p=json.loads((base/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
