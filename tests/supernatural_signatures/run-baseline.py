"""Actual v20 baseline reproduction; Windows game execution only."""
from pathlib import Path
import os,sys,json
assert os.name=='nt'
r=Path(__file__).resolve().parents[2];sys.path.insert(0,str(r/'tests/character_psychic'))
from checked_process import checked_process
p=Path(os.environ['GAME148_ROOT']);p.mkdir(parents=True,exist_ok=True)
a=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(r),'res://tests/supernatural_signatures/baseline.tscn'],cwd=r,env=os.environ.copy(),log=p/'baseline.log',timeout=180)
assert a['exit_code']==0 and not a['errors']and not a['timeout'],a
proof=json.loads((p/'baseline-proof.json').read_text(encoding='utf-8'));assert proof['checks']>0 and not proof['failures'];print(json.dumps(proof))
