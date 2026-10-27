"""Small Windows source diagnostic. Never runs Godot on a Linux host."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GROVE_SUMMONER_ROOT']);base.mkdir(parents=True,exist_ok=True)
out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/grove_summoner/scene_runner.gd'],cwd=root,env=dict(os.environ),log=base/'probe.log',timeout=900)
(base/'timings.json').write_text(json.dumps(out,indent=2)+'\n');print(out,flush=True)
if out['exit_code']or out['errors']or out['timeout']:print((base/'probe.log').read_text(encoding='utf-8')[-24000:],flush=True)
assert not out['exit_code']and not out['errors']and not out['timeout']
p=json.loads((base/'probe-proof.json').read_text());assert p['checks']>0 and p['failures']==0
