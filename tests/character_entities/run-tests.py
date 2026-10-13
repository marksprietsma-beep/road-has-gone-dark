"""Timed real source mechanics, production campaign saves and process restart."""
from pathlib import Path
import os,subprocess,json,time
root=Path(__file__).resolve().parents[2]
base=Path(os.environ['GAME112W2_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
rows=[]
for label,script,restart in [('mechanics','mechanics',False),('mechanics-restart','mechanics',True),('journey','journey',False),('journey-restart','journey',True)]:
 start=time.monotonic();log=base/(label+'.log')
 with log.open('w',encoding='utf-8')as stream:
  result=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(root),'--script',f'tests/character_entities/{script}.gd'],cwd=root,env=dict(os.environ,GAME112W2_RESTART='1'if restart else'0'),stdout=stream,stderr=subprocess.STDOUT,timeout=2700)
 text=log.read_text();errors=any(s in text for s in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append(dict(test=label,seconds=round(time.monotonic()-start,3),exit_code=result.returncode,errors=errors));(base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if result.returncode or errors:raise RuntimeError(text[-9000:])
