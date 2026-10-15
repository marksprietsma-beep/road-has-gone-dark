"""Timed source execution and fresh-process persistence; error output is fatal."""
from pathlib import Path
import os,subprocess,json,time
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"character_psychic"))
from checked_process import checked_process
root=Path(__file__).resolve().parents[2]
base=Path(os.environ['GAME112W4_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
rows=[]
imported=checked_process([os.environ.get("GODOT_BIN","godot"),"--headless","--editor","--audio-driver","Dummy","--path",str(root),"--quit"],cwd=root,env=os.environ.copy(),log=base/"import.log",timeout=300)
rows.append(dict(test="import",**imported))
if imported["exit_code"] or imported["errors"] or imported["timeout"]:raise RuntimeError((base/"import.log").read_text()[-9000:])
for label,script,restart in [('mechanics','mechanics',False),('cohort','cohort',False),('mechanics-restart','mechanics',True),('cohort-restart','cohort',True),('earned','earned',False),('earned-restart','earned',True),('journey','journey',False),('journey-restart','journey',True)]:
 log=base/(label+'.log')
 result=checked_process([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(root),'--script',f'tests/character_wave_four/launch.gd'],cwd=root,env=dict(os.environ,GAME112W4_RESTART='1'if restart else'0',GAME112W4_PHASE=script,GAME112W3_TEST_ROOT=str(base),GAME112W3_RESTART='1'if restart else'0'),log=log,timeout=2700)
 text=log.read_text();errors=result['errors'] or result['timeout']
 rows.append(dict(test=label,seconds=result['seconds'],exit_code=result['exit_code'],errors=errors));(base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if result['exit_code'] or errors:raise RuntimeError(text[-9000:])
