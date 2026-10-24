"""Windows-only focused mechanics, cold-process equality and production controls."""
from pathlib import Path
import json
import os
import subprocess
import sys

assert os.name == 'nt', 'Windows game validation only'
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/character_psychic'))
from checked_process import checked_process
base = Path(os.environ['UPPER_NATURE_ROOT'])
base.mkdir(parents=True, exist_ok=True)
subprocess.run([sys.executable, 'tests/upper_nature/check-source.py'], cwd=ROOT, check=True)
timings = []
for phase, cold in [('compile',False), ('mechanics',False), ('mechanics',True), ('input',False)]:
    label = phase + ('-cold' if cold else '')
    command = [os.environ['GODOT_BIN'], '--headless', '--audio-driver', 'Dummy', '--path', str(ROOT), '--script']
    command += ['res://tests/upper_nature/compile.gd'] if phase=='compile' else ['res://tests/upper_nature/scene_runner.gd', '--', phase, 'cold' if cold else 'warm']
    result = checked_process(command, cwd=ROOT, env=os.environ.copy(), log=base/(label+'.log'), timeout=1200)
    timings.append(dict(phase=label, **result))
    (base/'timings.json').write_text(json.dumps(timings, indent=2)+'\n')
    assert not result['exit_code'] and not result['errors'] and not result['timeout'], (base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
    if phase!='compile':
        proof = json.loads((base/('input-proof.json' if phase=='input' else 'restart-proof.json' if cold else 'proof.json')).read_text(encoding='utf-8'))
        assert proof['checks'] > 0 and proof['failures'] == 0
        print(json.dumps(dict(phase=label, checks=proof['checks'], failures=0)), flush=True)
