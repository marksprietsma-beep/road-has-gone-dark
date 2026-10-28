"""Cheap Windows diagnostics first; no native release or Linux execution."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DRAGON_WARSHAPER_ROOT']);base.mkdir(parents=True,exist_ok=True)
out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/dragon_warshaper/scene_runner.gd','--','probe'],cwd=root,env=os.environ.copy(),log=base/'probe.log',timeout=1200)
(base/'timings.json').write_text(json.dumps([dict(phase='probe',**out)],indent=2)+'\n');print(json.dumps(out),flush=True)
if out['exit_code']or out['errors']or out['timeout']:print((base/'probe.log').read_text(encoding='utf-8')[-24000:],flush=True)
assert not out['exit_code']and not out['errors']and not out['timeout']
p=json.loads((base/'probe-proof.json').read_text());assert p['checks']>0 and p['failures']==0
