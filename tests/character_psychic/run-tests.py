"""Timed source execution and fresh-process persistence; error output is fatal."""
from pathlib import Path
import os,subprocess,json,time
from checked_process import checked_process
root=Path(__file__).resolve().parents[2]
base=Path(os.environ['GAME112W3_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
rows=[]
for label,script,restart in [('mechanics','mechanics',False),('mechanics-restart','mechanics',True),('journey','journey',False),('journey-restart','journey',True)]:
 log=base/(label+'.log')
 result=checked_process([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(root),'--script',f'tests/character_psychic/{script}.gd'],cwd=root,env=dict(os.environ,GAME112W3_RESTART='1'if restart else'0'),log=log,timeout=2700)
 text=log.read_text();errors=result['errors'] or result['timeout']
 rows.append(dict(test=label,seconds=result['seconds'],exit_code=result['exit_code'],errors=errors));(base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if result['exit_code'] or errors:raise RuntimeError(text[-9000:])
