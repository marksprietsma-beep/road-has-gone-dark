"""Earned prestige via actual production services; no XP/level fixture injection."""
import argparse,json,os,pathlib,subprocess,time,shutil
p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(a.output).resolve();base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ);engine=env.get('GODOT_BIN',shutil.which('godot'));rows=[]
for key,name in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
 env.setdefault(key,str(base/'xdg'/name));pathlib.Path(env[key]).mkdir(parents=True,exist_ok=True)
pins=json.loads((root/'tests/adventure_cycles/source-pins.json').read_text())
from pin_guard import verify
verify(root,pins)
for label,script,folder,restart in [('legacy','legacy.gd','legacy',False),('negative','negative.gd','negative',False),('earned','progression.gd','earned',False),('earned-restart','progression.gd','earned',True)]:
 start=time.monotonic();log=base/(label+'.log')
 with log.open('w',encoding='utf-8')as f:r=subprocess.run([engine,'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/adventure_cycles/'+script],cwd=root,env=dict(env,GAME121_TEST_ROOT=str(base/folder),GAME121_RESTART='1'if restart else'0'),stdout=f,stderr=subprocess.STDOUT,timeout=1800)
 text=log.read_text(encoding='utf-8');errors=any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append(dict(check=label,exit_code=r.returncode,errors=errors,seconds=round(time.monotonic()-start,3)))
 (base/'run-results.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 if r.returncode or errors:print(text[-6000:]);raise SystemExit(1)
