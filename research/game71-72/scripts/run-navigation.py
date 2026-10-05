"""Execute unchanged GAME-70 assertions, redirecting evidence into this task."""
from pathlib import Path
import os, subprocess, shutil
root=Path(__file__).resolve().parents[3]
os.chdir(root)
tmp=root/'research/game71-72/.tmp'; tmp.mkdir(exist_ok=True)
source=(root/'research/game70/tests/capture-flow.gd').read_text()
source=source.replace('res://research/game70/evidence/', 'res://research/game71-72/.tmp/')
runner=tmp/'game70-check.gd'; runner.write_text(source)
result=subprocess.run(['godot','--path',str(root),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--script',str(runner)],capture_output=True,text=True)
evidence=root/'research/game71-72/evidence'
(evidence/'game70-tests.txt').write_text(result.stdout+result.stderr)
if result.returncode: raise SystemExit(result.returncode)
shutil.copyfile(tmp/'godot-results.json',evidence/'game70-results.json')
for image in tmp.glob('*.png'): image.unlink()
print(result.stdout)
