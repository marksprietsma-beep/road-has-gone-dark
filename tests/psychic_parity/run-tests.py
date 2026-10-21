"""Focused Windows evidence first; no Linux gameplay execution."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME152_ROOT']);base.mkdir(parents=True,exist_ok=True)
r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_parity/baseline.gd'],cwd=root,env=os.environ.copy(),log=base/'baseline.log',timeout=180)
(base/'timings.json').write_text(json.dumps(r,indent=2)+'\n')
assert not r['exit_code']and not r['errors']and not r['timeout'],(base/'baseline.log').read_text(encoding='utf-8')
p=json.loads((base/'baseline-proof.json').read_text());assert p['checks']>0 and p['failures']==0
print(json.dumps(p),flush=True)
