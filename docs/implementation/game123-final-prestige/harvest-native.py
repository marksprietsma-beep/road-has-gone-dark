"""Download successful Windows evidence, independently audit and gate ONLY this pair.
Usage: python docs/implementation/game123-final-prestige/harvest-native.py RUN WORK_DIR
Runs no Godot on the host; GitHub CLI authentication is required for artifacts.
"""
from pathlib import Path
import json,subprocess,sys,shutil
ROOT=Path(__file__).resolve().parents[3];RUN=int(sys.argv[1]);BASE=Path(sys.argv[2]).resolve();BASE.mkdir(parents=True,exist_ok=True)
def gh(*args):return subprocess.check_output(['gh',*map(str,args)],cwd=ROOT,text=True)
meta=json.loads(gh('api',f'repos/marksprietsma-beep/road-has-gone-dark/actions/runs/{RUN}'));assert meta['status']=='completed'and meta['conclusion']=='success';source=meta['head_sha']
(BASE/'run.json').write_text(json.dumps(meta,indent=2)+'\n');art=json.loads(gh('api',f'repos/marksprietsma-beep/road-has-gone-dark/actions/runs/{RUN}/artifacts'))['artifacts'];(BASE/'artifacts.json').write_text(json.dumps(art,indent=2)+'\n');links={}
for name,folder in [('final-prestige-windows-evidence','evidence'),('final-prestige-complete-windows-x64','build')]:
 a=next(a for a in art if a['name']==name);assert not a['expired']and a['workflow_run']['head_sha']==source
 dst=BASE/folder
 if not dst.exists():gh('run','download',RUN,'--repo','marksprietsma-beep/road-has-gone-dark','--name',name,'--dir',dst)
 links[folder]=f'https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/{RUN}/artifacts/{a["id"]}'
found=list((BASE/'evidence').rglob('distribution-proof.json'));assert len(found)==1;native=found[0].parent;n=json.loads(found[0].read_text(encoding='utf-8'));assert n['source_commit']==source
assert subprocess.check_output(['git','diff',source,'--','scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg'],cwd=ROOT)==b''
archive=BASE/'build'/n['archive'];assert archive.exists();subprocess.run([sys.executable,'docs/implementation/game123-final-prestige/audit-windows-delivery.py',str(archive),str(native)],cwd=ROOT,check=True)
assert n['acceptance_cohort']=='final-prestige'and n['rules_ref']['pack_id']=='trhgd-character-v35'
for key,p in n['proofs'].items():assert p['checks']>0 and p['failures']==0,key
out=ROOT/'docs/implementation/game123-final-prestige';(out/'evidence').mkdir(exist_ok=True);shutil.copy2(found[0],out/'evidence/native-proof.json')
subprocess.run([sys.executable,'tools/character-content/build-readiness.py','--pack','trhgd-character-v35','--native',str(native)],cwd=ROOT,check=True)
images=out/'screenshots';images.mkdir(exist_ok=True)
for image in n['captures']['screenshots']:shutil.copy2(native/'captures'/image['file'],images/image['file'])
for image in n['proofs']['input']['screenshots']:shutil.copy2(native/'mechanics'/image['file'],images/image['file'])
for image in n['proofs']['sentinel-campaign/proof.json']['measurements']:shutil.copy2(native/'sentinel/campaign'/image['file'],images/('sentinel-'+image['file']))
summary=dict(run=RUN,source=source,links=links,archive=str(archive),native_root=str(native),sha256=n['sha256'],rules_ref=n['rules_ref'],checks={k:dict(checks=p['checks'],failures=p['failures'])for k,p in n['proofs'].items()},captures=len(n['captures']['screenshots']),footer_images=len(n['proofs']['input']['screenshots']),sentinel_images=len(n['proofs']['sentinel-campaign/proof.json']['measurements']),timings=n['timings'])
(BASE/'harvest.json').write_text(json.dumps(summary,indent=2)+'\n');(out/'evidence/native-harvest.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
