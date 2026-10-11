"""Versioned objectives, real geography, transaction reliability and process restarts."""
import argparse,json,os,pathlib,subprocess,time,shutil
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--visual',action='store_true');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(a.output).resolve();base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ);engine=env.get('GODOT_BIN',shutil.which('godot'));rows=[]
for key,name in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
 env.setdefault(key,str(base/'xdg'/name));pathlib.Path(env[key]).mkdir(parents=True,exist_ok=True)
def run(label,command,**extra):
 start=time.monotonic();log=base/(label+'.log')
 with log.open('w',encoding='utf-8')as f:r=subprocess.run(command,cwd=root,env=dict(env,**extra),stdout=f,stderr=subprocess.STDOUT,timeout=900)
 text=log.read_text(encoding='utf-8');errors=any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append(dict(check=label,exit_code=r.returncode,errors=errors,seconds=round(time.monotonic()-start,3)))
 (base/'run-results.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if r.returncode or errors:print(text[-7000:]);raise SystemExit(1)
run('import',[engine,'--headless','--audio-driver','Dummy','--path',str(root),'--import'])
run('ten-real-worlds',['node','tests/opportunities/prepare-corpus.mjs'],GAME101_TEST_ROOT=str(base/'corpus'))
run('weighted-generation',[engine,'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/opportunities/corpus.gd'],GAME101_TEST_ROOT=str(base/'corpus'))
for phase in ['create','replay','combat-restart']:
 run('v2-'+phase,[engine,'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/opportunities/lifecycle.gd'],GAME101_TEST_ROOT=str(base/'lifecycle'),GAME101_PHASE=phase)
for phase in ['create','replay']:
 run('v1-'+phase,[engine,'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/sandbox/lifecycle.gd'],GAME96_TEST_ROOT=str(base/'v1-lifecycle'),GAME96_PHASE=phase)
run('review-contexts',['node','tests/opportunities/prepare-review.mjs'],GAME101_TEST_ROOT=str(base))
run('production-review',[engine]+([]if a.visual else ['--headless'])+['--audio-driver','Dummy','--path',str(root),'--scene','res://tests/opportunities/review.tscn'],GAME101_TEST_ROOT=str(base))
run('fresh-process-restart',[engine]+([]if a.visual else ['--headless'])+['--audio-driver','Dummy','--path',str(root),'--scene','res://tests/opportunities/review.tscn'],GAME101_TEST_ROOT=str(base),GAME101_RESTART='1')
print('GAME101 passed:',base,flush=True)
