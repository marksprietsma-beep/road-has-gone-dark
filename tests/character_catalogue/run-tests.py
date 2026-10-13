"""Real new-pack mechanics, tactical commands, production saves and process restart."""
import json, os, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
base=Path(os.environ['GAME112_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
rows=[]
for name,script,restart in [('mechanics','mechanics',False),('tactical','tactical',False),('fresh','fresh',False),('fresh-restart','fresh',True)]:
    start=time.monotonic();log=base/(name+'.log')
    with log.open('w',encoding='utf-8') as stream:
        result=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(ROOT),'--script',f'tests/character_catalogue/{script}.gd'],cwd=ROOT,env=dict(os.environ,GAME112_RESTART='1' if restart else '0'),stdout=stream,stderr=subprocess.STDOUT,timeout=1800)
    text=log.read_text(encoding='utf-8');errors=any(word in text for word in ['ERROR:','SCRIPT ERROR:','Parse Error'])
    rows.append(dict(test=name,seconds=round(time.monotonic()-start,3),exit_code=result.returncode,errors=errors))
    (base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n')
    print(rows[-1],flush=True)
    if result.returncode or errors:raise RuntimeError(text[-9000:])
