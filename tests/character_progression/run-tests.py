"""Actual career replay, prestige and tactical effects; failures preserve engine logs."""
import json,os,subprocess,time
from pathlib import Path
root=Path(__file__).resolve().parents[2]
base=Path(os.environ.get('GAME119_TEST_ROOT','/tmp/game119-checks'));base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME119_TEST_ROOT=str(base))
rows=[]
for name in ['careers','prestige','choices','prestige-combat','tactical']:
 start=time.monotonic()
 with (base/(name+'.log')).open('w',encoding='utf-8') as f:
  result=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(root),'--script',f'tests/character_progression/{name}.gd'],cwd=root,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=900)
 text=(base/(name+'.log')).read_text(encoding='utf-8')
 rows.append(dict(test=name,seconds=round(time.monotonic()-start,3),exit_code=result.returncode,errors=any(x in text for x in ['ERROR:','SCRIPT ERROR:','Parse Error'])))
 (base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n')
 assert result.returncode==0 and not rows[-1]['errors'],text[-7000:]
 print(rows[-1],flush=True)
