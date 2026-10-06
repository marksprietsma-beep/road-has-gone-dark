"""GAME-84 exact offline-world, lifecycle, failure and real input/render proof."""
import argparse,hashlib,json,os,pathlib,subprocess,tempfile,time
p=argparse.ArgumentParser();p.add_argument('--visual',action='store_true');p.add_argument('--regressions',action='store_true');p.add_argument('--work-dir');args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];os.chdir(root);os.sys.stdout.reconfigure(encoding='utf-8');env=os.environ.copy()
engine=env.get('GODOT_BIN','godot');helper=pathlib.Path(env.get('GAME76_HELPER_ROOT',root/'worldgen-helper')).resolve();node=helper/('node.exe'if os.name=='nt'else'node')
docs=root/'docs/implementation/game84';logs=docs/'logs';logs.mkdir(parents=True,exist_ok=True)
def run(name,cmd,custom=None,timeout=1800):
 start=time.perf_counter()
 with (logs/(name+'.txt')).open('w',encoding='utf-8')as f:ret=subprocess.run(list(map(str,cmd)),env=custom or env,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
 text=(logs/(name+'.txt')).read_text(encoding='utf-8');print(text,end='',flush=True)
 if ret.returncode or 'ERROR:'in text:
  detail=(name+" failed: "+text[-6000:]).replace('%','%25').replace('\r','%0D').replace('\n','%0A')
  print('::error title=GAME-84 executed failure::'+detail,flush=True)
  raise SystemExit(name+' failed')
 return time.perf_counter()-start
owned=tempfile.TemporaryDirectory(prefix='game84-expedition-')if not args.work_dir else None
base=pathlib.Path(args.work_dir or owned.name).resolve();base.mkdir(parents=True,exist_ok=True);env['GAME84_TEST_ROOT']=str(base)
fixtures=[root/'tests/worldgen/fixtures'/f'{s}.json'for s in ['game-11-determinism','atlas-showcase']]
frozen=[*fixtures,*sorted((root/'data/world_enrichment').glob('runtime*.json')),*[p for n in ['presets','presets-profiles-v2','presets-peoples-v1']for p in (root/'data/world_enrichment'/n).rglob('*.json')]]
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();before={str(p):digest(p)for p in frozen}
locked=dict(env,PATH='',NODE_OPTIONS='',NODE_PATH='');worlds=list(fixtures)
for i in range(5):
 seed=f'game84-expedition-{i}';world=base/'generated'/seed/'world.json'
 if not world.exists():run('generate-'+seed,[node,helper/'tools/worldgen/helper-entry.mjs','--seed',seed,'--output',world],locked,180)
 worlds.append(world)
run('import',[engine,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
run('lifecycle-create',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/lifecycle.gd'],dict(env,GAME84_PHASE='create'))
run('lifecycle-replay',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/lifecycle.gd'],dict(env,GAME84_PHASE='replay'))
run('cache-integrity',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/cache-integrity.gd'])
run('failure-safety',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/failures.gd'])
run('outcome-corpus',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/outcome-corpus.gd'],timeout=1800)
run('cold-cache-performance',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/expedition/benchmark.gd'])
specs=[]
for w in worlds:
 sha=digest(w);geo=base/'cache'/sha/(sha+'.geography.json');assert geo.exists();specs.append({'world':str(w),'geometry':str(geo)})
spec=base/'world-specs.json';spec.write_text(json.dumps(specs));run('batch',[node,'tests/expedition/batch.mjs',spec],timeout=1800)
if args.visual:run('input-render',[engine,'--audio-driver','Dummy','--path','.','--script','tests/expedition/capture-flow.gd'])
if args.regressions:
 run('game81-regressions',[os.sys.executable,'tests/party/run-tests.py','--regressions']+(['--visual']if args.visual else[]),timeout=5400)
 run('game62-source-projection',[node,'tests/regiongen/verify-source-projection.mjs'])
assert before=={str(p):digest(p)for p in frozen}
print('PASS GAME-84 two presets, five fresh worlds, actual party + two expeditions, independent knowledge, restart snapshots, failures, batches and frozen inputs')
if owned:owned.cleanup()
