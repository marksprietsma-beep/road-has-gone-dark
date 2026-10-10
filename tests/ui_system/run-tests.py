"""GAME-83 runs the original gameplay proofs, then the production UI journey."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--visual', action='store_true')
parser.add_argument('--regressions', action='store_true')
parser.add_argument('--work-dir')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
os.chdir(root)
sys.stdout.reconfigure(encoding='utf-8')
owned = tempfile.TemporaryDirectory(prefix='game83-ui-') if not args.work_dir else None
base = Path(args.work_dir or owned.name).resolve()
base.mkdir(parents=True, exist_ok=True)
logs = root/'docs/implementation/game83/logs'
logs.mkdir(parents=True, exist_ok=True)
environment = dict(os.environ, GAME84_TEST_ROOT=str(base), GAME83_STAGE='after')
engine = environment.get('GODOT_BIN', 'godot')

def run(name, command, timeout=5400):
    with (logs/(name+'.txt')).open('w', encoding='utf-8') as handle:
        result = subprocess.run(command, env=environment, stdout=handle, stderr=subprocess.STDOUT, timeout=timeout)
    output = (logs/(name+'.txt')).read_text(encoding='utf-8')
    print(output, end='', flush=True)
    if result.returncode or 'ERROR:' in output:
        detail = (name+': '+output[-6000:]).replace('%','%25').replace('\r','%0D').replace('\n','%0A')
        print('::error title=GAME-83 verification::'+detail, flush=True)
        raise SystemExit(name+' failed')

run('import', [engine,'--headless','--editor','--path','.','--quit'], 600)
run('presentation', [engine,'--headless','--path','.','--script','tests/ui_system/presentation.gd'], 120)
command = [sys.executable,'tests/expedition/run-tests.py','--work-dir',str(base)]
if args.visual: command.append('--visual')
if args.regressions: command.append('--regressions')
run('game84-and-foundations', command)
if args.visual:
    run('list-visibility', [engine,'--path','.','--audio-driver','Dummy','--script','tests/ui_system/list-visibility.gd'], 180)
    run('after-origin', [engine,'--path','.','--audio-driver','Dummy','--script','tests/ui_system/capture-origin.gd'], 1200)
    run('after-expedition', [engine,'--path','.','--audio-driver','Dummy','--script','tests/ui_system/capture-expedition.gd'], 1200)
if owned: owned.cleanup()
print('PASS GAME-83 production UI and original campaign regressions')
