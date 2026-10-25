"""Windows source-Godot diagnostics first; no exported-native claims."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DUAL_ROOT']);base.mkdir(parents=True,exist_ok=True)
result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/dual_prestige_acceptance/probe.gd'],cwd=root,env=os.environ.copy(),log=base/'probe.log',timeout=1200)
(base/'timings.json').write_text(json.dumps([dict(phase='pinned28-probe',**result)],indent=2)+'\n',encoding='utf-8')
assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/'probe.log').read_text(encoding='utf-8')[-16000:]
proof=json.loads((base/'probe-proof.json').read_text(encoding='utf-8'));assert proof['checks']>0 and proof['failures']==0
print('DUAL_PRESTIGE_SOURCE_PROBE_PASS')
