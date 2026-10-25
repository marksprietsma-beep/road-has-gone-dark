"""Windows source-Godot diagnostics first; no exported-native claims."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DUAL_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
phases=[('compile',False,''),('probe',False,'probe-proof.json')]
if (root/'data/rules/trhgd-character-v29.json').exists():
    phases += [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json'),('interactions',False,'interactions-proof.json'),('interactions',True,'interactions-restart-proof.json')]
for phase,cold,file in phases:
    label=phase+('-cold'if cold else'')
    result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/dual_prestige_acceptance/scene_runner.gd','--',phase],cwd=root,env=dict(os.environ,DUAL_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
    timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(timings[-1]),flush=True)
    assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-16000:]
    if file:
        proof=json.loads((base/file).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
print('DUAL_PRESTIGE_SOURCE_FOCUSED_PASS')
