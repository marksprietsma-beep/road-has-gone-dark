"""Windows-only diagnostic/acceptance runner; every engine error remains fatal."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['HYBRID_ROOT']);base.mkdir(parents=True,exist_ok=True)
result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/hybrid_acceptance/scene_runner.gd','--','probe'],cwd=root,env=dict(os.environ),log=base/'probe.log',timeout=900)
(base/'timings.json').write_text(json.dumps(result,indent=2)+'\n');assert not result['exit_code']and not result['errors']and not result['timeout'],(base/'probe.log').read_text(encoding='utf-8')[-16000:]
p=json.loads((base/'probe-proof.json').read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;print(json.dumps(p),flush=True)
