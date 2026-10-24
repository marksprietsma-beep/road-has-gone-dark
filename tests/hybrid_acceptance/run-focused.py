"""Windows-only diagnostic/acceptance runner; every engine error remains fatal."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['HYBRID_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
for phase,cold in [('compile',False),('probe',False),('mechanics',False),('mechanics',True)]:
 label=phase+('-cold'if cold else'');command=[os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script']
 command+=['res://tests/hybrid_acceptance/compile.gd']if phase=='compile'else['res://tests/hybrid_acceptance/scene_runner.gd','--',phase]
 result=checked_process(command,cwd=root,env=dict(os.environ,HYBRID_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=1200)
 timings.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n');print(json.dumps(timings[-1]),flush=True)
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-16000:]
 if phase!='compile':
  file='probe-proof.json'if phase=='probe'else 'restart-proof.json'if cold else'proof.json'
  proof=json.loads((base/file).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
