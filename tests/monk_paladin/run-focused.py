"""Windows-only source diagnostics; no native or earned-play claim."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['MONK_PALADIN_ROOT']);base.mkdir(parents=True,exist_ok=True)
result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/monk_paladin/scene_runner.gd','--','probe'],cwd=root,env=os.environ.copy(),log=base/'probe.log',timeout=600)
(base/'timings.json').write_text(json.dumps([dict(phase='probe',**result)],indent=2)+'\n',encoding='utf-8')
print(result,flush=True)
if result['exit_code']or result['errors']or result['timeout']:print((base/'probe.log').read_text(encoding='utf-8')[-18000:],flush=True)
assert not result['exit_code']and not result['errors']and not result['timeout']
p=json.loads((base/'probe-proof.json').read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
