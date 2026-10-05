#!/usr/bin/env python3
"""Run built helper + genuine worlds + lifecycle + existing regression checks."""
import argparse, os, pathlib, subprocess, shutil
parser = argparse.ArgumentParser()
parser.add_argument('--visual', action='store_true')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[2]
os.chdir(root)
logs = root / 'docs/implementation/game76/logs'
logs.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env.setdefault('GAME76_HELPER_ROOT', str(root / 'worldgen-helper'))
env.setdefault('GAME76_GENERATED_TEST_DIR', str(root / 'tools/worldgen/.tmp/game76-generated'))
def run(name, command, timeout=300):
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout, env=env)
    (logs / (name + '.txt')).write_text(result.stdout)
    print(result.stdout, end='', flush=True)
    if result.returncode != 0 or 'ERROR:' in result.stdout:
        raise SystemExit(name + ' failed; inspect the log')
node = env.get('NODE_BUILD_BIN', shutil.which('node'))
run('helper-' + ('windows' if os.name == 'nt' else 'linux'), [node, 'tests/world_library/helper-contract.mjs'])
shutil.copyfile(pathlib.Path(env['GAME76_GENERATED_TEST_DIR']) / 'helper-evidence.json', root / 'docs/implementation/game76/helper-proof.json')
engine = env.get('GODOT_BIN', 'godot')
run('import', [engine, '--headless', '--audio-driver', 'Dummy', '--editor', '--path', '.', '--quit'])
for name, path in [('library', 'tests/world_library/verify-library.gd'), ('game7', 'tests/game_world/smoke-game-world.gd'),
                   ('game74', 'tests/onboarding/verify-origin.gd'), ('reload-failure', 'tests/onboarding/verify-reload-failure.gd')]:
    run(name, [engine, '--headless', '--audio-driver', 'Dummy', '--path', '.', '--script', path])
for key in ['game-11-determinism', 'atlas-showcase']:
    run('validate-' + key, [node, 'tests/worldgen/validate-fixture.mjs', 'tests/worldgen/fixtures/' + key + '.json'])
if args.visual:
    run('game74-visual', [engine, '--audio-driver', 'Dummy', '--path', '.', '--script', 'tests/onboarding/capture-flow.gd'])
    run('visual', [engine, '--audio-driver', 'Dummy', '--path', '.', '--script', 'tests/world_library/capture-library.gd'])
print('PASS: GAME-76 requested helper/library/regression checks completed without Godot errors')
