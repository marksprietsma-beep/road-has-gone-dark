"""Download only the successful complete pre-UI-fix Windows receipt, never a partial run."""
from pathlib import Path
import os,json,subprocess,hashlib
assert os.name=='nt'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME152_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
run=os.environ['GAME152_REUSE_RUN'];assert run=='39578198867'
repo='marksprietsma-beep/road-has-gone-dark'
record=json.loads(subprocess.check_output(['gh','api',f'repos/{repo}/actions/runs/{run}'],cwd=root,text=True,encoding='utf-8'))
assert record['status']=='completed'and record['conclusion']=='success'
assert record['head_sha']=='59f1b20b8bbb2a4a7029ee71b10190e774b9ed74'and record['path']=='.github/workflows/verify-psychic-parity.yml'
subprocess.run(['gh','run','download',run,'--repo',repo,'--name','game152-native-evidence','--dir',str(base)],cwd=root,check=True)
original=json.loads((base/'distribution-proof.json').read_text(encoding='utf-8'))
assert original['source_commit']==record['head_sha']and original['production_launch']and original['separate_process_restart']
assert all(p['checks']>0 and p['failures']==0 for p in original['proofs'].values())
(base/'reuse-manifest.json').write_text(json.dumps(dict(run_id=int(run),source_commit=record['head_sha'],conclusion='success',url=record['html_url'],original_proof_sha256=hashlib.sha256((base/'distribution-proof.json').read_bytes()).hexdigest()),indent=2)+'\n')
(base/'reuse-original-distribution-proof.json').write_bytes((base/'distribution-proof.json').read_bytes())
print('Trusted complete native receipt downloaded:',record['head_sha'],flush=True)
