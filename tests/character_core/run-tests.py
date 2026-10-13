"""Authoritative core mechanics and actual creator choices, including negative gates."""
import json,os,pathlib,subprocess,time,sys
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME118_TEST_ROOT']);base.mkdir(parents=True,exist_ok=True)
rows=[]
for name in (['atomic','pinned-campaign'] if '--atomic' in sys.argv else ['availability','tactical','continuation']):
 start=time.monotonic();log=base/(name+'.log')
 with log.open('w',encoding='utf-8')as f:r=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--audio-driver','Dummy','--path',str(root),'--script',f'tests/character_core/{name}.gd'],cwd=root,stdout=f,stderr=subprocess.STDOUT,timeout=180)
 text=log.read_text(encoding='utf-8');errors=any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append({'test':name,'seconds':round(time.monotonic()-start,3),'exit_code':r.returncode,'errors':errors})
 (base/('atomic-timings.json' if '--atomic' in sys.argv else 'timings.json')).write_text(json.dumps(rows,indent=2)+'\n')
 assert r.returncode==0 and not errors,text[-6000:]
 print(rows[-1],flush=True)
