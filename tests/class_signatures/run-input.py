"""Small Windows production-control gate before the existing full native suite."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME129_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[]
for phase,cold,filename in [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]:
 label=phase+('-cold'if cold else'')
 out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'res://tests/class_signatures/review.tscn'],cwd=root,env=dict(os.environ,GAME129_PHASE=phase,GAME129_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**out));(base/'input-timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
 assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-14000:]
 p=json.loads((base/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
print('GAME129_FOCUSED_PRODUCTION_CONTROLS_PASS',flush=True)
