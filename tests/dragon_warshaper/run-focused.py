"""Cheap Windows diagnostics first; no native release or Linux execution."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DRAGON_WARSHAPER_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
for phase,cold,file in [('probe',False,'probe-proof.json'),('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]:
 label=phase+('-cold'if cold else'');active=dict(os.environ,DRAGON_WARSHAPER_RESTART='1'if cold else'0')
 out=checked_process([os.environ['GODOT_BIN']]+([]if phase=='input'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/dragon_warshaper/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=1800)
 timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n');print(timings[-1],flush=True)
 if out['exit_code']or out['errors']or out['timeout']:print((base/(label+'.log')).read_text(encoding='utf-8')[-24000:],flush=True)
 assert not out['exit_code']and not out['errors']and not out['timeout'],label
 p=json.loads((base/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
