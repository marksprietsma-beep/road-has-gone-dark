"""Real multi-world geography, generated-map/oracle and multi-site restart proof."""
import argparse, json, os, pathlib, shutil, subprocess, tempfile, time
ROOT = pathlib.Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--godot', default=os.environ.get('GODOT_BIN', shutil.which('godot')))
p.add_argument('--output')
a = p.parse_args()
base = pathlib.Path(a.output or tempfile.mkdtemp(prefix='game96-sandbox-')).resolve()
base.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, GAME96_TEST_ROOT=str(base/'corpus'))
for key, directory in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
    env.setdefault(key,str(base/directory))
    pathlib.Path(env[key]).mkdir(parents=True,exist_ok=True)
results = []
def run(label, command, **extra):
    start = time.monotonic()
    log = base/(label+'.log')
    with log.open('w',encoding='utf-8') as output:
        ret = subprocess.run(command,cwd=ROOT,env=dict(env,**extra),stdout=output,stderr=subprocess.STDOUT,timeout=900)
    text = log.read_text(encoding='utf-8')
    errors = any(s in text for s in ['ERROR:','SCRIPT ERROR:','Parse Error'])
    row = dict(check=label,seconds=round(time.monotonic()-start,3),exit_code=ret.returncode,errors=errors)
    results.append(row)
    (base/'results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(row),flush=True)
    if ret.returncode or errors:
        print(text[-10000:]);raise SystemExit(1)
run('prepare-real-worlds',['node','tests/sandbox/prepare-corpus.mjs'])
run('import',[a.godot,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
run('generated-corpus',[a.godot,'--headless','--audio-driver','Dummy','--path','.','--script','tests/sandbox/corpus.gd'])
for phase in ['create','replay']:
    run('multi-opportunity-'+phase,[a.godot,'--headless','--audio-driver','Dummy','--path','.','--script','tests/sandbox/lifecycle.gd'],GAME96_TEST_ROOT=str(base/'lifecycle'),GAME96_PHASE=phase)
print('GAME96 passed: '+str(base),flush=True)
