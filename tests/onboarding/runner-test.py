"""Exercise the real runner's failed-process evidence without launching world tests."""
import ast
from pathlib import Path
import subprocess
import sys
import tempfile

# Only isolate the helper; importing run-tests.py would execute the whole suite.
script=Path(__file__).with_name('run-tests.py')
function=next(node for node in ast.parse(script.read_text(encoding='utf-8')).body if isinstance(node,ast.FunctionDef)and node.name=='run')
with tempfile.TemporaryDirectory(prefix='onboarding-runner-')as directory:
 logs=Path(directory)
 namespace=dict(logs=logs,subprocess=subprocess)
 exec(compile(ast.Module(body=[function],type_ignores=[]),str(script),'exec'),namespace)
 run=namespace['run']
 path=logs/'import.txt';path.write_text('historical successful import',encoding='utf-8')
 try:
  run('import',[sys.executable,'-c','import time; print("current import partial output",flush=True); time.sleep(30)'],timeout=.5)
 except subprocess.TimeoutExpired:pass
 else:raise AssertionError('A timed-out import was accepted')
 text=path.read_text(encoding='utf-8')
 assert 'current import partial output'in text and 'historical successful import'not in text
 for name,code in [('script-error','print("SCRIPT ERROR: invalid source")'),('nonzero','raise SystemExit(3)')]:
  try:run(name,[sys.executable,'-c',code])
  except AssertionError:pass
  else:raise AssertionError(name+' was accepted')
 run('success',[sys.executable,'-c','print("fresh successful run")'])
 assert(logs/'success.txt').read_text(encoding='utf-8').strip()=='fresh successful run'
print('PASS: live timeout evidence replaces stale logs; script errors/nonzero exits remain fatal')
