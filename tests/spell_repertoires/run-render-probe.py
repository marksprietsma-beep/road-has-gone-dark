"""Focused Windows reproduction and exact separate-process restart only."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows native validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME151_ROOT']);base.mkdir(parents=True,exist_ok=True)
timings=[]
for restart in [False,True]:
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/spell_repertoires/historical_render_probe.gd'],cwd=root,env=dict(os.environ,GAME151_RESTART='1'if restart else'0'),log=base/('cold.log'if restart else'focused.log'),timeout=120)
 timings.append(dict(restart=restart,**result));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/('cold.log'if restart else'focused.log')).read_text(encoding='utf-8')
 proof=json.loads((base/('restart-proof.json'if restart else'proof.json')).read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
 print(json.dumps(proof),flush=True)
