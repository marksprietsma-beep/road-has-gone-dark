#!/usr/bin/env python3
"""Run from repository root. --visual requires an X11 display (or xvfb-run)."""
import argparse, hashlib, os, pathlib, subprocess
parser = argparse.ArgumentParser()
parser.add_argument('--visual', action='store_true')
args = parser.parse_args()
logs = pathlib.Path('docs/implementation/game74/logs')
logs.mkdir(parents=True, exist_ok=True)
def run(name, command):
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    (logs / (name + '.txt')).write_text(result.stdout)
    print(result.stdout, end='')
    assert result.returncode == 0 and 'ERROR:' not in result.stdout, name + ' failed (see log)'
for key, digest in {
    'game-11-determinism': '2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5',
    'atlas-showcase': '9f942b07bb73c2af17c4039d009561b696864e02ec67f2e8dd3a5ef6a757ebb3',
}.items():
    path = pathlib.Path('tests/worldgen/fixtures') / (key + '.json')
    assert hashlib.sha256(path.read_bytes()).hexdigest() == digest
    run('validate-' + key, ['node', 'tests/worldgen/validate-fixture.mjs', str(path)])
run('canonical-json', ['node', '--test', 'tests/worldgen/canonical-json.test.mjs'])
engine = os.environ.get('GODOT_BIN', 'godot')
run('import', [engine, '--headless', '--audio-driver', 'Dummy', '--editor', '--path', '.', '--quit'])
for name, script in [('game7', 'tests/game_world/smoke-game-world.gd'), ('game74', 'tests/onboarding/verify-origin.gd'), ('landmark-inspection', 'tests/worldgen/smoke-landmark-inspection.gd')]:
    run(name, [engine, '--headless', '--audio-driver', 'Dummy', '--path', '.', '--script', script])
if args.visual:
    run('visual', [engine, '--audio-driver', 'Dummy', '--path', '.', '--script', 'tests/onboarding/capture-flow.gd'])
print('PASS: all requested checks completed; no Godot runtime errors')
