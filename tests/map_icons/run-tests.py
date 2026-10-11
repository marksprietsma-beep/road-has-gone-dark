"""Shared roles, real six-region public rendering and an existing GAME99 campaign."""
import argparse,json,os,pathlib,subprocess,time,shutil
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--visual',action='store_true');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(a.output).resolve();base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME98_TEST_ROOT=str(base));engine=env.get('GODOT_BIN',shutil.which('godot'));rows=[]
for key,name in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
 env.setdefault(key,str(base/'xdg'/name));pathlib.Path(env[key]).mkdir(parents=True,exist_ok=True)
def run(label,command):
 start=time.monotonic();log=base/(label+'.log')
 with log.open('w',encoding='utf-8')as f:r=subprocess.run(command,cwd=root,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=900)
 text=log.read_text(encoding='utf-8');errors=any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append(dict(check=label,exit_code=r.returncode,errors=errors,seconds=round(time.monotonic()-start,3)))
 (base/'run-results.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if r.returncode or errors:print(text[-6000:]);raise SystemExit(1)
run('shared-semantics',['node','--test','tests/map_icons/semantics.test.mjs'])
run('six-existing-regions',['node','tests/map_icons/prepare-contexts.mjs'])
run('import',[engine,'--headless','--audio-driver','Dummy','--path',str(root),'--import'])
run('production-map-contracts',[engine]+([]if a.visual else ['--headless'])+['--audio-driver','Dummy','--path',str(root),'--scene','res://tests/map_icons/verify-distribution.tscn'])
proof=json.loads((base/'map-icons-proof.json').read_text());assert proof['failures']==0 and len(proof['regions'])==6
print('GAME98 passed:',base,flush=True)
