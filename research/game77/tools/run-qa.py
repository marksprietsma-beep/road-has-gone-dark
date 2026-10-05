#!/usr/bin/env python3
"""Read-only base checks; QA evidence written only beneath research/game77."""
import argparse, hashlib, os, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[3]
os.chdir(root)
p = argparse.ArgumentParser()
p.add_argument('--visual', action='store_true')
p.add_argument('--helper-contract', action='store_true')
a = p.parse_args()
logs = root / 'research/game77/evidence/logs'
logs.mkdir(parents=True, exist_ok=True)
helper = pathlib.Path(os.environ.get('GAME76_HELPER_ROOT', str(root / 'worldgen-helper')))
node = os.environ.get('CONTENT_NODE_BIN', str(helper / ('node.exe' if os.name == 'nt' else 'node')) if helper.exists() else 'node')
godot = os.environ.get('GODOT_BIN', 'godot')
def run(name, command, timeout=300):
    r = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='strict', timeout=timeout)
    (logs / (name + '.txt')).write_text(r.stdout, encoding='utf-8')
    print(r.stdout, end='', flush=True)
    if r.returncode or 'ERROR:' in r.stdout or 'SCRIPT ERROR:' in r.stdout:
        raise SystemExit(name + ' failed')
original = {k: hashlib.sha256((root / 'tests/worldgen/fixtures' / (k + '.json')).read_bytes()).hexdigest() for k in ['game-11-determinism','atlas-showcase']}
assert original == {'game-11-determinism':'2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5','atlas-showcase':'9f942b07bb73c2af17c4039d009561b696864e02ec67f2e8dd3a5ef6a757ebb3'}
run('framework-offline', [node, '--import', './research/game77/tests/offline-guard.mjs', '--test', 'research/game77/tests/framework.test.mjs'])
run('generate-offline', [node, '--import', './research/game77/tests/offline-guard.mjs', 'research/game77/tools/generate.mjs'])
run('quality', [node, 'research/game77/tools/quality-audit.mjs'])
run('canonical-json', [node, '--test', 'tests/worldgen/canonical-json.test.mjs'])
for key in original:
    run('validate-'+key, [node, 'tests/worldgen/validate-fixture.mjs','tests/worldgen/fixtures/'+key+'.json'])
run('import', [godot,'--headless','--audio-driver','Dummy','--editor','--path','.','--quit'])
for name, script in [('adapter','research/game77/tests/verify-origin-lore.gd'),('game7','tests/game_world/smoke-game-world.gd'),('game74','tests/onboarding/verify-origin.gd'),('reload-failure','tests/onboarding/verify-reload-failure.gd')]:
    run(name,[godot,'--headless','--audio-driver','Dummy','--path','.','--script',script])
if a.helper_contract:
    run('game76-helper', [node,'tests/world_library/helper-contract.mjs'])
    run('game76-library', [godot,'--headless','--audio-driver','Dummy','--path','.','--script','tests/world_library/verify-library.gd'])
if a.visual:
    run('public-origin-render', [godot,'--audio-driver','Dummy','--path','.','--script','research/game77/tools/capture-origin.gd'])
    run('game74-input-render', [godot,'--audio-driver','Dummy','--path','.','--script','tests/onboarding/capture-flow.gd'])
    if a.helper_contract:
        run('game76-input-render',[godot,'--audio-driver','Dummy','--path','.','--script','tests/world_library/capture-library.gd'])
assert original == {k:hashlib.sha256((root/'tests/worldgen/fixtures'/(k+'.json')).read_bytes()).hexdigest() for k in original}
(root/'research/game77/evidence/base-byte-proof.json').write_text(__import__('json').dumps({'sha256':original,'unchanged':True},indent=2)+'\n',encoding='utf-8')
print('PASS: GAME-77 requested QA; fixture bytes unchanged; no Godot errors')
