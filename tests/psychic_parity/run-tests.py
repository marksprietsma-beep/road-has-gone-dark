"""Focused Windows mechanics, retained historical observations and cold restart."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME152_ROOT']);base.mkdir(parents=True,exist_ok=True)
preflight=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_parity/compile.gd'],cwd=root,env=os.environ.copy(),log=base/'compile.log',timeout=90)
assert not preflight['exit_code']and not preflight['errors']and not preflight['timeout'],(base/'compile.log').read_text(encoding='utf-8')
timings=[]
for phase,restart,file in [('baseline',False,'baseline-proof.json'),('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json'),('input',False,'input-proof.json')]:
 log=base/(phase+('-cold'if restart else'')+'.log')
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'res://tests/psychic_parity/review.tscn'],cwd=root,env=dict(os.environ,GAME152_PHASE=phase,GAME152_RESTART='1'if restart else'0'),log=log,timeout=600)
 timings.append(dict(phase=phase,restart=restart,**r));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 assert not r['exit_code']and not r['errors']and not r['timeout'],log.read_text(encoding='utf-8')[-16000:]
 p=json.loads((base/file).read_text());assert p['checks']>0 and p['failures']==0
 print(json.dumps(dict(phase=phase,restart=restart,checks=p['checks'],failures=p['failures'],timing=r)),flush=True)
