"""33 original worlds, fixed seed coverage, independent process logs/checkpoints."""
import argparse,concurrent.futures,json,pathlib,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--workers',type=int,default=3);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(a.output).resolve();base.mkdir(parents=True,exist_ok=True)
specs=[('game96-sandbox-review-v2',None),('game-11-determinism','tests/worldgen/fixtures/game-11-determinism.json'),('atlas-showcase-06','tests/worldgen/fixtures/atlas-showcase.json')]+[(f'game99-independent-{i:02d}',None)for i in range(30)]
rows={};start=time.monotonic()
def run(spec,phase):
 seed,fixture=spec;d=base/seed;d.mkdir(exist_ok=True);command=['node','tests/geography_repair/world.mjs',seed,str(d)]+([fixture]if fixture else[])+[phase]
 try:
  with(d/('generate.log'if phase=='--generate-only'else'run.log')).open('w',encoding='utf-8')as log:r=subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT,timeout=600)
  if r.returncode:return {'seed':seed,'success':False,'exit_code':r.returncode,'log':str(d/'run.log')}
  return {'seed':seed,'success':True,'generated':True}if phase=='--generate-only'else json.loads((d/'result.json').read_text())
 except Exception as e:return {'seed':seed,'success':False,'error':str(e)}
# Node generation is independent; the existing Town Forge adapter compiles to
# one shared directory on first use in EACH process. Validate regions serially
# instead of racing its writes or altering production decoration in this repair.
generated={}
with concurrent.futures.ThreadPoolExecutor(max_workers=a.workers)as pool:
 for f in concurrent.futures.as_completed([pool.submit(run,s,'--generate-only')for s in specs]):
  row=f.result();generated[row['seed']]=row
  (base/'generation-checkpoint.json').write_text(json.dumps([generated[s]for s,_ in specs if s in generated],indent=2)+'\n')
  print(json.dumps({'generated':len(generated),'seed':row['seed'],'success':row['success']}),flush=True)
for spec in specs:
 seed,_=spec;row=run(spec,'--validate-only')if generated[seed]['success']else generated[seed];rows[seed]=row
 ordered=[rows[s]for s,_ in specs if s in rows];report={'planned_worlds':len(specs),'completed':len(rows),'successes':sum(r['success']for r in ordered),'failures':sum(not r['success']for r in ordered),'seconds':time.monotonic()-start,'worlds':ordered}
 (base/'summary.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'completed':len(rows),'seed':seed,'success':row['success']}),flush=True)
raise SystemExit(0 if all(r['success']for r in rows.values())else 1)
