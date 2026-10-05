import argparse, os, pathlib, subprocess, sys
root=pathlib.Path(__file__).resolve().parents[2]
os.chdir(root)
sys.stdout.reconfigure(encoding="utf-8")
p=argparse.ArgumentParser();p.add_argument('--visual',action='store_true');a=p.parse_args()
logs=root/'research/game77-integration/evidence/logs';logs.mkdir(parents=True,exist_ok=True)
engine=os.environ.get('GODOT_BIN','godot')
for name,script,visual in [('public-adapter','research/game77-integration/verify-public.gd',False)]+([('actual-flow','research/game77-integration/verify-flow.gd',True)] if a.visual else []):
 command=[engine]+([] if visual else ['--headless'])+['--audio-driver','Dummy','--path','.','--script',script]
 r=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',timeout=120)
 (logs/(name+'.txt')).write_text(r.stdout,encoding='utf-8');print(r.stdout,end='',flush=True)
 if r.returncode or 'ERROR:' in r.stdout:raise SystemExit(name+' failed')
print('PASS: isolated GAME-77 public-origin integration checks')
