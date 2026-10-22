"""Windows native cohort gate. No host game execution."""
from pathlib import Path
import os,sys,json
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME127_ROOT']);base.mkdir(parents=True,exist_ok=True)
phases=[('baseline',False,'baseline-proof.json')]
receipts=[]
for phase,cold,file in phases:
 log=base/(phase+('-cold'if cold else'')+'.log')
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_support/scene_runner.gd','--',phase,'cold'if cold else'warm'],cwd=root,env=os.environ.copy(),log=log,timeout=1200)
 receipts.append(dict(phase=phase,cold=cold,**r));(base/'timings.json').write_text(json.dumps(receipts,indent=2)+'\n')
 assert not r['exit_code']and not r['errors']and not r['timeout'],log.read_text(encoding='utf-8')[-16000:]
 proof=json.loads((base/file).read_text());assert proof['checks']>0 and proof['failures']==0
 print(json.dumps(dict(phase=phase,cold=cold,checks=proof['checks'])),flush=True)
