#!/usr/bin/env python3
"""Real Godot combat, campaign/restart and optional rendered input checks."""
import argparse, json, os, pathlib, shutil, subprocess, tempfile, time
ROOT = pathlib.Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--godot', default=shutil.which('godot'))
p.add_argument('--work-dir')
p.add_argument('--visual', action='store_true')
a = p.parse_args()
base = pathlib.Path(a.work_dir or tempfile.mkdtemp(prefix='trhgd-adventure-'))
base.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, ADVENTURE_TEST_ROOT=str(base))
for key, folder in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
    env.setdefault(key, str(base / folder))
    pathlib.Path(env[key]).mkdir(parents=True, exist_ok=True)
results = []
def run(label, args, **variables):
    start = time.monotonic()
    log = base / (label + '.log')
    with log.open('w') as stream:
        completed = subprocess.run(args, cwd=ROOT, env=dict(env, **variables), text=True, stdout=stream, stderr=subprocess.STDOUT, timeout=240)
    output = log.read_text()
    errors = any(word in output for word in ('SCRIPT ERROR:', 'ERROR:', 'Parse Error'))
    results.append(dict(check=label, seconds=round(time.monotonic()-start,3), exit_code=completed.returncode, errors=errors))
    print(json.dumps(results[-1]), flush=True)
    if completed.returncode or errors:
        print(output)
        raise SystemExit(1)
run('import', [a.godot,'--audio-driver','Dummy','--headless','--editor','--path',str(ROOT),'--quit'])
run('combat', [a.godot,'--audio-driver','Dummy','--headless','--path',str(ROOT),'--script','tests/adventure/combat.gd'])
for phase in ['create','reload']:
    run('campaign-'+phase, [a.godot,'--audio-driver','Dummy','--headless','--path',str(ROOT),'--script','tests/adventure/campaign.gd'], ADVENTURE_PHASE=phase)
if a.visual:
    run('visual', ['xvfb-run','-a',a.godot,'--audio-driver','Dummy','--path',str(ROOT),'--script','tests/adventure/capture-flow.gd'])
(base / 'results.json').write_text(json.dumps(results,indent=2)+'\n')
print('Adventure checks passed; evidence: '+str(base))
