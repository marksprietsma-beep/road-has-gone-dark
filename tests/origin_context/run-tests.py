#!/usr/bin/env python3
"""Reproduce GAME-75 context against real bundled-helper worlds and Godot."""
import argparse, hashlib, json, os, pathlib, subprocess, tempfile
parser = argparse.ArgumentParser()
parser.add_argument('--visual', action='store_true')
parser.add_argument('--regressions', action='store_true')
args = parser.parse_args()
os.sys.stdout.reconfigure(encoding="utf-8")
root = pathlib.Path(__file__).resolve().parents[2]
os.chdir(root)
env = os.environ.copy()
helper = pathlib.Path(env.get('GAME76_HELPER_ROOT', root / 'worldgen-helper')).resolve()
engine = env.get('GODOT_BIN', 'godot')
node = helper / ('node.exe' if os.name == 'nt' else 'node')
evidence = root / 'docs/implementation/game75'
logs = evidence / 'logs'
logs.mkdir(parents=True, exist_ok=True)
fixture_paths = [root / ('tests/worldgen/fixtures/' + key + '.json') for key in ['game-11-determinism','atlas-showcase']]
digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
before = [digest(p) for p in fixture_paths]
def run(name, command, timeout=300, process_env=None):
    result = subprocess.run(list(map(str,command)), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, encoding="utf-8", timeout=timeout, env=process_env or env)
    (logs / (name + '.txt')).write_text(result.stdout, encoding="utf-8")
    print(result.stdout, end='', flush=True)
    if result.returncode or 'ERROR:' in result.stdout or 'Unicode parsing error' in result.stdout:
        raise SystemExit(name + ' failed; see log')
with tempfile.TemporaryDirectory(prefix='game75 generated worlds ') as directory:
    env['GAME75_GENERATED_DIR'] = directory
    worlds = []
    runtime = json.loads((helper / 'runtime.json').read_text(encoding='utf-8'))
    assert digest(node) == runtime['runtimeSha256']
    for seed in ['game75-context-a','game75-context-b','game75-context-c']:
        path = pathlib.Path(directory) / seed / 'world.json'
        locked_env = dict(env, PATH='', NODE_OPTIONS='', NODE_PATH='')
        run('generate-' + seed, [node, helper / 'tools/worldgen/helper-entry.mjs', '--seed', seed, '--output', path], 150, locked_env)
        raw = json.loads(path.read_text(encoding='utf-8'))
        assert raw['seed'] == seed
        assert raw['generator']['version'] == '1.153.1'
        assert digest(path) not in before
        worlds.append({'seed':seed,'sha256':digest(path),'generator':raw['generator'],
                       'cells':len(raw['cells']['ids']),'settlements':len(raw['settlements'])-1})
    assert len({w['sha256'] for w in worlds}) == 3
    (evidence / 'generated-proof.json').write_text(json.dumps({'runtime':runtime['nodeVersion'],
        'helper_runtime_sha256':runtime['runtimeSha256'],'worlds':worlds},indent=2)+'\n', encoding='utf-8')
    run('import', [engine,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
    run('context', [engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/origin_context/verify-context.gd'],600)
    run("independent-source-audit",[os.sys.executable,"tests/origin_context/check-proof.py"])
    if args.visual:
        run('visual', [engine,'--audio-driver','Dummy','--path','.','--script','tests/origin_context/capture-context.gd'],300)
    if args.regressions:
        run('existing-regressions',[os.sys.executable,'tests/world_library/run-tests.py']+(['--visual'] if args.visual else []),1200)
        # Keep new QA in its own directory; legacy scripts deliberately still
        # write their existing GAME-74/76 evidence locations.
        import shutil
        shutil.copytree(root / 'docs/implementation/game76/logs',logs / 'legacy',dirs_exist_ok=True)
        for name in ['helper','library','ui']:
            path=root / ('docs/implementation/game76/'+name+'-proof.json')
            if path.exists(): shutil.copyfile(path,evidence / ('game76-'+name+'-proof.json'))
        run('canonical-json',[node,'--test','tests/worldgen/canonical-json.test.mjs'])
        run('landmark-taxonomy',[node,'tools/worldgen/verify-landmark-icons.mjs'])
        for kind in ['key','inspection']:
            run('landmark-'+kind,[engine,'--headless','--audio-driver','Dummy','--path','.','--script','tests/worldgen/smoke-landmark-'+kind+'.gd'])
assert [digest(p) for p in fixture_paths] == before
print('PASS: GAME-75 requested checks; canonical fixture bytes unchanged')
