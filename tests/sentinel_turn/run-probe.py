from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['SENTINEL_ROOT']);base.mkdir(parents=True,exist_ok=True)
out=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/sentinel_turn/runner.gd'],cwd=root,env=os.environ.copy(),log=base/'probe.log',timeout=600)
(base/'timings.json').write_text(json.dumps(out,indent=2))
assert not out['exit_code']and not out['errors']and not out['timeout'],(base/'probe.log').read_text(encoding='utf-8')[-24000:]
p=json.loads((base/'probe-proof.json').read_text());assert p['checks']>0 and p['failures']==0

for cold in [False,True]:
 label='campaign-cold'if cold else'campaign'
 result=checked_process([os.environ['GODOT_BIN'],'--audio-driver','Dummy','--path',str(root),'--script','res://tests/sentinel_turn/runner.gd','--','campaign'],cwd=root,env=dict(os.environ,SENTINEL_RESTART='1'if cold else'0'),log=base/(label+'.log'),timeout=900)
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-24000:]
 proof=json.loads((base/'campaign'/('restart-proof.json'if cold else'proof.json')).read_text());assert proof['checks']>0 and proof['failures']==0
