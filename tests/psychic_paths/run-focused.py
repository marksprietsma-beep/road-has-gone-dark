"""Current two-path Windows acceptance; no game execution on other hosts."""
from pathlib import Path
import os,sys,json,hashlib
assert os.name=='nt','Windows game validation only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME127_PATH_ROOT']);base.mkdir(parents=True,exist_ok=True)
installed={p['rules_ref']['pack_id']:p for p in json.loads((root/'data/rules/packs.json').read_text())['packs']}
for row in json.loads((root/'tests/psychic_paths/historical-pins.json').read_text())['packs']:
 assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256']
 assert installed[row['rules_ref']['pack_id']]==dict(path='res://'+row['path'],rules_ref=row['rules_ref'])
timings=[]
for phase,cold,file in [('mechanics',False,'proof.json'),('mechanics',True,'restart-proof.json')]:
 log=base/(phase+('-cold'if cold else'')+'.log')
 r=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/psychic_paths/scene_runner.gd','--',phase,'cold'if cold else'warm'],cwd=root,env=os.environ.copy(),log=log,timeout=1800)
 timings.append(dict(phase=phase,cold=cold,**r));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 assert not r['exit_code']and not r['errors']and not r['timeout'],log.read_text(encoding='utf-8')[-16000:]
 p=json.loads((base/file).read_text());assert p['checks']>0 and p['failures']==0
 print(json.dumps(dict(phase=phase,cold=cold,checks=p['checks'])),flush=True)
