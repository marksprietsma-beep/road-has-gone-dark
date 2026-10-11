"""Fresh-process custom/legacy builds and actual creation/sheet/advancement UI."""
import os,pathlib,subprocess,time,json
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME103_TEST_ROOT']);base.mkdir(parents=True,exist_ok=True)
engine=os.environ.get('GODOT_BIN','godot');results=[]
for phase in ['create','reload']:
 start=time.monotonic();env=dict(os.environ,GAME103_PHASE=phase)
 with (base/(phase+'.log')).open('w',encoding='utf-8')as log:r=subprocess.run([engine,'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/character_builder/lifecycle.gd'],cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=360)
 text=(base/(phase+'.log')).read_text(encoding='utf-8');proof=json.loads((base/('results-'+phase+'.json')).read_text())
 results.append(dict(phase=phase,seconds=round(time.monotonic()-start,3),**proof));(base/'timings.json').write_text(json.dumps(results,indent=2))
 assert r.returncode==0 and proof['failures']==0 and 'ERROR:'not in text,text[-6000:]
 print(results[-1],flush=True)
