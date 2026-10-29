"""Cheap Windows gates before the single stable full native release."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['FINAL_PRESTIGE_ROOT']);base.mkdir(parents=True,exist_ok=True);timings=[]
phases=[('probe',False,'probe-proof.json')]
if (root/'data/rules/trhgd-character-v35.json').exists():phases.append(('schema',False,'schema-proof.json'))
if (root/'tests/final_prestige/mechanics.gd').exists():phases.extend([('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json')])
for phase,cold,file in phases:
 label=phase+('-cold'if cold else'');env=dict(os.environ,FINAL_PRESTIGE_RESTART='1'if cold else'0')
 out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/final_prestige/scene_runner.gd','--',phase],cwd=root,env=env,log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8')
 if out['exit_code']or out['errors']or out['timeout']:print((base/(label+'.log')).read_text(encoding='utf-8')[-24000:],flush=True)
 assert not out['exit_code']and not out['errors']and not out['timeout'],phase
 p=json.loads((base/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
 print('FINAL_PRESTIGE',phase,p['checks'],'failures',p['failures'],flush=True)
