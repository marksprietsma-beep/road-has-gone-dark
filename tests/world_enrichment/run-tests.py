#!/usr/bin/env python3
"""Production offline contract: five worlds, exact replay, two Godot processes."""
import argparse,hashlib,json,os,pathlib,subprocess,tempfile,time
p=argparse.ArgumentParser();p.add_argument('--visual',action='store_true');p.add_argument('--regressions',action='store_true');args=p.parse_args()
os.sys.stdout.reconfigure(encoding='utf-8')
root=pathlib.Path(__file__).resolve().parents[2];os.chdir(root)
env=os.environ.copy();engine=env.get('GODOT_BIN','godot')
helper=pathlib.Path(env.get('GAME76_HELPER_ROOT',root/'worldgen-helper')).resolve()
node=helper/('node.exe' if os.name=='nt' else 'node')
evidence=root/'docs/implementation/game79';logs=evidence/'logs';logs.mkdir(parents=True,exist_ok=True)
def run(name,command,timeout=600,custom=None):
 start=time.perf_counter();r=subprocess.run(list(map(str,command)),env=custom or env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',timeout=timeout)
 (logs/(name+'.txt')).write_text(r.stdout,encoding='utf-8');print(r.stdout,end='',flush=True)
 if r.returncode or 'ERROR:' in r.stdout:
  print('::error::'+(name+' failed: '+r.stdout[-2000:]).replace('\n','%0A').replace('\r',''),flush=True)
  raise SystemExit(name+' failed')
 return time.perf_counter()-start
hashfile=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
fixtures=[root/('tests/worldgen/fixtures/'+key+'.json')for key in ['game-11-determinism','atlas-showcase']];before=list(map(hashfile,fixtures))
with tempfile.TemporaryDirectory(prefix='game79 production worlds ') as temp:
 base=pathlib.Path(temp);env['GAME79_TEST_ROOT']=str(base/'lifecycle');env['GAME79_GENERATED_DIR']=str(base/'generated')
 measurements=[]
 run('compiler',[node,'--test','tests/world_enrichment/compiler.test.mjs'])
 locked=dict(env,PATH='',NODE_OPTIONS='',NODE_PATH='')
 for i in range(5):
  seed='game79-world-'+str(i);world=base/'generated'/seed/'world.json';sidecar=world.parent/'enrichment/origin-v1'
  generation=run('generate-'+seed,[node,helper/'tools/worldgen/helper-entry.mjs','--seed',seed,'--output',world],150,locked)
  original=hashfile(world)
  enrichment=run('enrich-'+seed,[node,helper/'tools/world_enrichment/origin-world.mjs','--world',world,'--output',sidecar],150,locked)
  first={p.name:hashfile(p) for p in sidecar.iterdir()}
  run('replay-'+seed,[node,helper/'tools/world_enrichment/origin-world.mjs','--world',world,'--output',sidecar],150,locked)
  assert first=={p.name:hashfile(p)for p in sidecar.iterdir()} and original==hashfile(world)
  d=json.loads((sidecar/'descriptor.json').read_text());measurements.append({'seed':seed,'world_sha':original,'generation_seconds':generation,'enrichment_seconds':enrichment,'origins':d['origin_count'],'descriptor':d,'storage_bytes':sum(p.stat().st_size for p in sidecar.iterdir())})
 repeat=base/'repeat/world.json'
 run('same-seed-generation',[node,helper/'tools/worldgen/helper-entry.mjs','--seed','game79-world-0','--output',repeat],150,locked)
 assert hashfile(repeat)==measurements[0]['world_sha']
 run('same-seed-enrichment',[node,helper/'tools/world_enrichment/origin-world.mjs','--world',repeat,'--output',repeat.parent/'enrichment/origin-v1'],150,locked)
 assert json.loads((repeat.parent/'enrichment/origin-v1/descriptor.json').read_text())==measurements[0]['descriptor']
 print('::notice title=GAME-79 platform timing::'+json.dumps([{'seed':m['seed'],'generation_seconds':round(m['generation_seconds'],3),'enrichment_seconds':round(m['enrichment_seconds'],3),'origins':m['origins'],'storage_bytes':m['storage_bytes']}for m in measurements],separators=(',',':')),flush=True)
 assert len({m['world_sha']for m in measurements})==5 and len({m['descriptor']['enrichment_sha']for m in measurements})==5
 (evidence/'generated-worlds.json').write_text(json.dumps({'platform':os.name,'node':subprocess.check_output([node,'--version'],text=True).strip(),'worlds':measurements,'same_seed_replay':True,'offline_path_empty':True},indent=2)+'\n')
 run('import',[engine,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
 for phase in ['create','replay']:
  env['GAME79_PHASE']=phase
  run('lifecycle-'+phase,[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/world_enrichment/verify-lifecycle.gd'])
 run('postwrite-lore',[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/world_enrichment/verify-reload.gd'])
 if args.visual:run('input-render',[engine,'--audio-driver','Dummy','--path','.','--script','tests/world_enrichment/capture-origin.gd'])
 if args.regressions:run('regressions',[os.sys.executable,'tests/origin_context/run-tests.py','--regressions']+(['--visual']if args.visual else []),1800)
assert list(map(hashfile,fixtures))==before
print('PASS GAME-79: immutable fixtures, five offline generated worlds, exact replay and production lifecycle')
