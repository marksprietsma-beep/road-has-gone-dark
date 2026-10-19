"""Reuse only verified unchanged completed native phases, never a failed phase."""
from pathlib import Path
import os,json,subprocess,re,shutil,hashlib

def prepare(root,base,pins):
 run=os.environ.get('GAME148_REUSE_RUN','')
 if not run:return dict(phases=[],timings=[],metadata=None)
 assert re.fullmatch(r'[0-9]{6,}',run),'A numeric source workflow run is required'
 repo=os.environ['GITHUB_REPOSITORY'];current=os.environ['GITHUB_RUN_ID']
 assert run!=current
 def api(path):return json.loads(subprocess.check_output(['gh','api',path]))
 old=api(f'repos/{repo}/actions/runs/{run}');now=api(f'repos/{repo}/actions/runs/{current}')
 assert old['status']=='completed' and old['workflow_id']==now['workflow_id'] and old['head_branch']==now['head_branch']
 old_sha=old['head_sha'];assert re.fullmatch('[0-9a-f]{40}',old_sha)
 subprocess.run(['git','fetch','--no-tags','--depth=1','origin',old_sha],cwd=root,check=True)
 head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
 changed=subprocess.check_output(['git','diff','--name-only',old_sha,head],cwd=root,text=True).splitlines()
 # Only CI/reporting and the previously failed (always rerun) journey/preflight
 # may differ. No reused driver or production file receives a hash waiver.
 allowed={'tests/nature_repertoires/mechanics_driver.gd','tests/supernatural_signatures/journey.gd','tests/supernatural_signatures/compile_driver.gd','tests/supernatural_signatures/native_checkpoint.py','tests/supernatural_signatures/run-tests.py','tests/supernatural_signatures/verify-package.py','.github/workflows/verify-supernatural-signatures.yml'}
 forbidden=[p for p in changed if not p.startswith(('docs/','tools/character-content/'))and p not in allowed]
 assert not forbidden,('Runtime or reused driver changed; run a fresh full suite',forbidden)
 previous=base.parent/'game148-previous'
 subprocess.run(['gh','run','download',run,'--repo',repo,'--name','game148-native-evidence','--dir',str(previous)],check=True)
 timing_files=list(previous.rglob('native-timings.json'));assert len(timing_files)==1;previous=timing_files[0].parent
 anchor=json.loads((previous/'distribution/game148-supernatural-signatures-windows-x64/distribution.json').read_text(encoding='utf-8'));assert anchor['source_commit']==old_sha
 times=json.loads((previous/'native-timings.json').read_text(encoding='utf-8'))
 phases=[('mechanics','mechanics','trhgd-character-v21'),('input','mechanics','trhgd-character-v21'),('current-signatures','current-signatures','trhgd-character-v21'),('current-mobile','current-mobile','trhgd-character-v21'),('v20','v20','trhgd-character-v20'),('v19','v19','trhgd-character-v19'),('v18','v18','trhgd-character-v18'),('legacy','legacy-v16','trhgd-character-v16'),('compatibility','compatibility-v16','trhgd-character-v16'),('audit','readiness-audit','trhgd-character-v21')]
 reused=[];receipts=[];copied=set()
 for phase,folder,pack in phases:
  if phase=='v18' and 'tests/nature_repertoires/mechanics_driver.gd' in changed:continue
  labels=[phase]if phase=='input'else[phase,phase+'-cold']
  for label in labels:
   matches=[t for t in times if t['phase']==label];assert len(matches)==1
   timing=matches[0];assert timing['exit_code']==0 and not timing['errors']and not timing['timeout'],label
   receipts.append(dict(timing,reused=True,source_commit=old_sha,workflow_run=int(run)))
   shutil.copyfile(previous/(label+'.log'),base/(label+'.log'))
  files=['input-proof.json']if phase=='input'else['proof.json','restart-proof.json']
  for file in files:
   p=json.loads((previous/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
   if 'rules_ref'in p:assert p['rules_ref']==pins[pack],(phase,'exact pin')
  if folder not in copied:shutil.copytree(previous/folder,base/folder);copied.add(folder)
  reused.append(phase)
 assert (base/'mechanics/saved.json').is_file()
 metadata=dict(workflow_run=int(run),workflow_url=old['html_url'],source_commit=old_sha,source_workflow_conclusion=old['conclusion'],phase_sources={p:old_sha for p in reused},changed_paths=changed,unchanged_runtime_and_reused_drivers=True,policy='Completed native prefix receipts reused with exact pins/zero failures and an explicit source diff. Changed v18 driver, failed journey, connected battle, captures, new production startup and final archive are rerun; no fresh testing claimed for reused phases.',original_export=anchor)
 (base/'native-reuse.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
 print('Verified native checkpoint reuse:',json.dumps(metadata),flush=True)
 return dict(phases=reused,timings=receipts,metadata=metadata)
