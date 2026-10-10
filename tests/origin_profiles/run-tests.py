#!/usr/bin/env python3
"""GAME-80 native/offline production contract and real-input review evidence."""
import argparse,hashlib,json,os,pathlib,subprocess,tempfile,time
p=argparse.ArgumentParser();p.add_argument('--visual',action='store_true');p.add_argument('--regressions',action='store_true');p.add_argument('--work-dir');args=p.parse_args()
os.sys.stdout.reconfigure(encoding='utf-8')
root=pathlib.Path(__file__).resolve().parents[2];os.chdir(root);env=os.environ.copy();engine=env.get('GODOT_BIN','godot')
helper=pathlib.Path(env.get('GAME76_HELPER_ROOT',root/'worldgen-helper')).resolve();node=helper/('node.exe'if os.name=='nt'else'node')
evidence=root/'docs/implementation/game80';logs=evidence/'logs';logs.mkdir(parents=True,exist_ok=True)
def run(name,cmd,timeout=600,custom=None):
 start=time.perf_counter();path=logs/(name+'.txt')
 with path.open('w',encoding='utf-8')as log:r=subprocess.run(list(map(str,cmd)),env=custom or env,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
 text=path.read_text(encoding='utf-8');print(text,end='',flush=True)
 if r.returncode or 'ERROR:'in text:raise SystemExit(name+' failed')
 return time.perf_counter()-start
hashfile=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
fixtures=[root/('tests/worldgen/fixtures/'+key+'.json')for key in ['game-11-determinism','atlas-showcase']];before=list(map(hashfile,fixtures))
owned=tempfile.TemporaryDirectory(prefix='game80 profiles ')if not args.work_dir else None
base=pathlib.Path(args.work_dir or owned.name).resolve();base.mkdir(parents=True,exist_ok=True)
env['GAME80_TEST_ROOT']=str(base);env['GAME80_OLD_HELPER']=str(base/'old-helper');(base/'old-helper').mkdir(exist_ok=True)
run('profiles',[node,'--test','tests/origin_profiles/profiles.test.mjs'])
locked=dict(env,PATH='',NODE_OPTIONS='',NODE_PATH='');paths=list(fixtures);timings=[]
for i in range(5):
 seed='game80-world-'+str(i);world=base/'generated'/seed/'world.json';profiles=world.parent/'enrichment/profiles-v2'
 if not world.exists():run('generate-'+seed,[node,helper/'tools/worldgen/helper-entry.mjs','--seed',seed,'--output',world],150,locked)
 digest=hashfile(world)
 elapsed=run('profiles-'+seed,[node,helper/'tools/world_enrichment/profiles-world.mjs','--world',world,'--output',profiles],150,locked)
 original={f.name:hashfile(f)for f in profiles.iterdir()};run('replay-'+seed,[node,helper/'tools/world_enrichment/profiles-world.mjs','--world',world,'--output',profiles],150,locked)
 assert original=={f.name:hashfile(f)for f in profiles.iterdir()}and digest==hashfile(world)
 d=json.loads((profiles/'descriptor.json').read_text());timings.append({'seed':seed,'sha':digest,'seconds':elapsed,'descriptor':d,'bytes':sum(f.stat().st_size for f in profiles.iterdir())});paths.append(world)
repeat=base/'repeat/world.json'
if not repeat.exists():run('same-seed-world',[node,helper/'tools/worldgen/helper-entry.mjs','--seed','game80-world-0','--output',repeat],150,locked)
assert hashfile(repeat)==timings[0]['sha']
run('same-seed-profile',[node,helper/'tools/world_enrichment/profiles-world.mjs','--world',repeat,'--output',repeat.parent/'profiles-v2'],150,locked)
assert json.loads((repeat.parent/'profiles-v2/descriptor.json').read_text())==timings[0]['descriptor']
(evidence/'generated-worlds.json').write_text(json.dumps({'platform':os.name,'worlds':timings,'same_seed_replay':True,'offline_path_empty':True},indent=2)+'\n')
print('::notice title=GAME-80 platform timing::'+json.dumps([{'seed':t['seed'],'seconds':round(t['seconds'],3),'origins':t['descriptor']['origin_count'],'states':t['descriptor']['state_count'],'regions':t['descriptor']['region_count'],'bytes':t['bytes']}for t in timings],separators=(',',':')),flush=True)
run('quality',[node,'tests/origin_profiles/batch-quality.mjs',*paths])
run('import',[engine,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
run('presets',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/origin_profiles/verify-presets.gd'])
for phase in ['create','replay']:
 env['GAME80_PHASE']=phase;run('lifecycle-'+phase,[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/origin_profiles/verify-worlds.gd'])
run('postwrite-profile',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/origin_profiles/verify-postwrite.gd'])
if args.visual:run('input-render',[engine,'--audio-driver','Dummy','--path','.','--script','tests/origin_profiles/capture-profiles.gd'])
if args.regressions:run('game79-regressions',[os.sys.executable,'tests/world_enrichment/run-tests.py','--regressions']+(['--visual']if args.visual else []),2400)
assert list(map(hashfile,fixtures))==before
if owned:owned.cleanup()
print('PASS GAME-80: hierarchical profiles, five native worlds, exact replay, legacy pins and unchanged geography')
