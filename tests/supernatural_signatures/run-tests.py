"""Run focused Windows reproductions, retaining errors and enforcing cold receipts."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','GAME-148 native verification is Windows-only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME148_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
for phase,restart,file in [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]:
 log=base/('input.log'if phase=='input'else'cold.log'if restart else'focused.log')
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'res://tests/supernatural_signatures/review.tscn'],cwd=root,env=dict(os.environ,GAME148_PHASE=phase,GAME148_RESTART='1'if restart else'0'),log=log,timeout=180)
 timings.append(dict(phase=phase,restart=restart,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 assert result['exit_code']==0 and not result['errors']and not result['timeout'],log.read_text(encoding='utf-8')
 proof=json.loads((base/file).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
 print(json.dumps(dict(restart=restart,proof=proof,timing=result)),flush=True)
