"""Windows-only focused identity acceptance; baseline stage precedes fixes."""
from pathlib import Path
import os,sys,json
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME127_ROOT']);base.mkdir(parents=True,exist_ok=True)
phases=[('baseline',False,'baseline-proof.json')]
if (root/'tests/psychic_identities/mechanics.gd').exists():
 phases += [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]
receipts=[]
if (root/'tests/psychic_identities/mechanics.gd').exists():
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_identities/compile.gd'],cwd=root,env=os.environ.copy(),log=base/'compile.log',timeout=90)
 assert not r['exit_code']and not r['errors']and not r['timeout'],(base/'compile.log').read_text(encoding='utf-8')
for phase,cold,file in phases:
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_identities/scene_runner.gd','--',phase,'cold'if cold else'warm'],cwd=root,env=os.environ.copy(),log=base/(phase+('-cold'if cold else'')+'.log'),timeout=600)
 receipts.append(dict(phase=phase,cold=cold,**r));(base/'timings.json').write_text(json.dumps(receipts,indent=2)+'\n')
 assert not r['exit_code']and not r['errors']and not r['timeout'],(base/(phase+('-cold'if cold else'')+'.log')).read_text(encoding='utf-8')[-14000:]
 proof=json.loads((base/file).read_text());assert proof['checks']>0 and proof['failures']==0
 print(json.dumps(dict(phase=phase,cold=cold,checks=proof['checks'])),flush=True)
