"""Windows-only diagnostic/acceptance runner; every engine error remains fatal."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['HYBRID_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
phases=[('compile',False),('earned_probe',False),('earned_probe',True)]
if os.environ.get('HYBRID_PLANNER_PROBE')!='1':phases += [('probe',False),('mechanics',False),('mechanics',True),('input',False)]
for phase,cold in phases:
 label=phase+('-cold'if cold else'');command=[os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script']
 command+=['res://tests/hybrid_acceptance/compile.gd']if phase=='compile'else['res://tests/hybrid_acceptance/scene_runner.gd','--',phase]
 result=checked_process(command,cwd=root,env=dict(os.environ,HYBRID_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8',newline='\n');print(json.dumps(timings[-1]),flush=True)
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-16000:]
 if phase!='compile':
  file=('planner-restart-proof.json'if cold else'planner-proof.json')if phase=='earned_probe'else'probe-proof.json'if phase=='probe'else 'input-proof.json'if phase=='input'else 'restart-proof.json'if cold else'proof.json'
  proof=json.loads((base/file).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
