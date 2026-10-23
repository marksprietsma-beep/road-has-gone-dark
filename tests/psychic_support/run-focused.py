"""Windows-only focused identity acceptance; baseline stage precedes fixes."""
from pathlib import Path
import os,sys,json
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME127_ROOT']);base.mkdir(parents=True,exist_ok=True)
phases=[('baseline',False,'baseline-proof.json')]
if (root/'tests/psychic_support/mechanics.gd').exists():
 phases += [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]
if os.environ.get('GAME127_JOURNEY')=='1':
 phases += [('journey',False,'journeys/cohort-0/proof.json'),('journey',True,'journeys/cohort-0/restart-proof.json'),('connected',False,'connected/proof.json'),('connected',True,'connected/restart-proof.json'),('capture',False,'captures/screenshots.json')]
receipts=[]
if (root/'tests/psychic_support/mechanics.gd').exists():
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_support/compile.gd'],cwd=root,env=os.environ.copy(),log=base/'compile.log',timeout=90)
 assert not r['exit_code']and not r['errors']and not r['timeout'],(base/'compile.log').read_text(encoding='utf-8')
for phase,cold,file in phases:
 r=checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_support/scene_runner.gd','--',phase,'cold'if cold else'warm'],cwd=root,env=dict(os.environ,GAME127_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME129_RESTART='1'if cold else'0'),log=base/(phase+('-cold'if cold else'')+'.log'),timeout=1800)
 receipts.append(dict(phase=phase,cold=cold,**r));(base/'timings.json').write_text(json.dumps(receipts,indent=2)+'\n')
 assert not r['exit_code']and not r['errors']and not r['timeout'],(base/(phase+('-cold'if cold else'')+'.log')).read_text(encoding='utf-8')[-14000:]
 proof=json.loads((base/file).read_text());assert proof['checks']>0 and proof['failures']==0
 print(json.dumps(dict(phase=phase,cold=cold,checks=proof['checks'])),flush=True)
