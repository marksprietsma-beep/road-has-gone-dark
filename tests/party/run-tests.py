#!/usr/bin/env python3
"""Repeatable native party proof; every script error is a failure."""
import argparse,hashlib,json,os,pathlib,subprocess,tempfile,time,shutil
p=argparse.ArgumentParser();p.add_argument('--visual',action='store_true');p.add_argument('--regressions',action='store_true');p.add_argument('--work-dir');args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];os.chdir(root);os.sys.stdout.reconfigure(encoding='utf-8')
env=os.environ.copy();engine=env.get('GODOT_BIN','godot');helper=pathlib.Path(env.get('GAME76_HELPER_ROOT',root/'worldgen-helper')).resolve();node=helper/('node.exe'if os.name=='nt'else'node')
docs=root/'docs/implementation/game81';logs=docs/'logs';logs.mkdir(parents=True,exist_ok=True)
def run(name,cmd,custom=None,timeout=900):
 start=time.perf_counter()
 with (logs/(name+'.txt')).open('w',encoding='utf-8')as log:r=subprocess.run(list(map(str,cmd)),env=custom or env,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
 text=(logs/(name+'.txt')).read_text(encoding='utf-8');print(text,end='',flush=True)
 if r.returncode or 'ERROR:'in text:raise SystemExit(name+' failed')
 return time.perf_counter()-start
hashfile=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
fixtures=[root/('tests/worldgen/fixtures/'+key+'.json')for key in ['game-11-determinism','atlas-showcase']]
frozen=[*fixtures,*sorted((root/'data/world_enrichment').glob('runtime-*.json'))]
frozen+=[p for prefix in ['presets','presets-profiles-v2']for p in (root/'data/world_enrichment'/prefix).rglob('*.json')]
before={str(p):hashfile(p)for p in frozen};owned=tempfile.TemporaryDirectory(prefix='game81 party ')if not args.work_dir else None
base=pathlib.Path(args.work_dir or owned.name).resolve();base.mkdir(parents=True,exist_ok=True);env['GAME81_TEST_ROOT']=str(base)
run('generator',[node,'--test','tests/party/generator.test.mjs'])
locked=dict(env,PATH='',NODE_OPTIONS='',NODE_PATH='');paths=list(fixtures);timings=[]
for i in range(5):
 seed='game81-party-world-'+str(i);world=base/'generated'/seed/'world.json';package=world.parent/'enrichment/peoples-v1';request=world.parent/'request.json';output=world.parent/'people-result.json'
 if not world.exists():run('generate-'+seed,[node,helper/'tools/worldgen/helper-entry.mjs','--seed',seed,'--output',world],locked,180)
 request.write_text(json.dumps({'operation':'ensure'}));output.unlink(missing_ok=True)
 elapsed=run('people-'+seed,[node,helper/'tools/party/entry.mjs','--world',world,'--peoples',package,'--request',request,'--output',output],locked,180)
 original={p.name:hashfile(p)for p in package.iterdir()};output.unlink()
 run('replay-'+seed,[node,helper/'tools/party/entry.mjs','--world',world,'--peoples',package,'--request',request,'--output',output],locked,180)
 assert original=={p.name:hashfile(p)for p in package.iterdir()};timings.append({'seed':seed,'sha':hashfile(world),'seconds':elapsed,'descriptor':json.loads((package/'descriptor.json').read_text())});paths.append(world)
(docs/'generated-worlds.json').write_text(json.dumps({'platform':os.name,'worlds':timings,'offline_empty_path':True},indent=2)+'\n')
run('batch-quality',[node,'tests/party/batch-quality.mjs',*paths],timeout=1200)
run('import',[engine,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
for name in ['smoke-party','reader-failures','failures']:
 run(name,[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/party/'+name+'.gd'])
if (base/'saves').exists():shutil.rmtree(base/'saves') # This runner owns its test root, never the player's save root.
for phase in ['create','replay']:
 env['GAME81_PHASE']=phase;run('lifecycle-'+phase,[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/party/lifecycle.gd'])
if args.visual:run('input-render',[engine,'--audio-driver','Dummy','--path','.','--script','tests/party/capture-flow.gd'])
if args.regressions:run('game80-regressions',[os.sys.executable,'tests/origin_profiles/run-tests.py','--regressions']+(['--visual']if args.visual else[]),timeout=3600)
assert before=={str(p):hashfile(p)for p in frozen}
if owned:owned.cleanup()
print('PASS GAME-81 party generation, five fresh worlds, 1,050 backgrounds, save and failure recovery; frozen fixtures/packages unchanged')
