"""Old production source creates saves; repaired production resumes the exact files."""
import argparse,io,json,os,pathlib,shutil,subprocess,tarfile,time
p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(a.output).resolve();base.mkdir(parents=True,exist_ok=True)
engine=os.environ.get('GODOT_BIN','godot');helper=pathlib.Path(os.environ['GAME76_HELPER_ROOT']).resolve();node=helper/('node.exe'if os.name=='nt'else'node')
old=base/'original-main';old.mkdir();archive=subprocess.check_output(['git','archive','1263f146ad5422945b355869ab2d977f14e0a4ef'],cwd=root)
with tarfile.open(fileobj=io.BytesIO(archive))as t:t.extractall(old,filter='data')
(old/'tests/geography_repair').mkdir();shutil.copy2(root/'tests/geography_repair/campaign.gd',old/'tests/geography_repair/campaign.gd')
shutil.copytree(helper/'vendor/azgaar/node_modules',old/'vendor/azgaar/node_modules')
# These are Node dependencies, never Godot resources. Avoid importing upstream
# example fonts into either project's cold editor; no game assets are excluded.
for project in [old,root]:(project/'vendor/azgaar/node_modules/.gdignore').write_text('')
env=dict(os.environ);rows=[]
for key,name in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[key]=str(base/name)
def run(name,cmd,cwd=root,**extra):
 start=time.monotonic();log=base/(name+'.log')
 with log.open('w',encoding='utf-8')as f:r=subprocess.run(list(map(str,cmd)),cwd=cwd,env=dict(env,**extra),stdout=f,stderr=subprocess.STDOUT,timeout=300)
 text=log.read_text(encoding='utf-8');bad=any(s in text for s in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append({'check':name,'exit_code':r.returncode,'errors':bad,'seconds':time.monotonic()-start});(base/'results.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
 if r.returncode or bad:print(text[-6000:]);raise SystemExit(1)
legacy=base/'original-helper'
run('package-original-helper',[node,old/'tools/worldgen/package-helper.mjs','--output',legacy,'--runtime-license',helper/'NODE-LICENSE'],cwd=old)
run('import-original',[engine,'--headless','--audio-driver','Dummy','--import','--path',old])
run('import-repaired',[engine,'--headless','--audio-driver','Dummy','--import','--path',root])
for phase in ['blocked','recover','replay']:
 project=old if phase=='blocked'else root
 run('campaign-'+phase,[engine,'--headless','--audio-driver','Dummy','--path',project,'--script','tests/geography_repair/campaign.gd'],GAME76_HELPER_ROOT=str(legacy if phase=='blocked'else helper),GAME99_CAMPAIGN_ROOT=str(base/'blocked-campaign'),GAME99_CAMPAIGN_PHASE=phase,GAME99_WORLD=str(base.parent/'corpus/game96-sandbox-review-v2/world.json'))
 if phase=='blocked':shutil.copytree(base/'blocked-campaign',base/'exported-blocked-campaign')
for phase in ['create','replay']:
 project=old if phase=='create'else root
 run('previously-valid-'+phase,[engine,'--headless','--audio-driver','Dummy','--path',project,'--script','tests/sandbox/lifecycle.gd'],GAME76_HELPER_ROOT=str(legacy if phase=='create'else helper),GAME96_TEST_ROOT=str(base/'valid-campaign'),GAME96_PHASE=phase)
print('PASS old failed and valid campaigns preserved through actual source-version handoff',flush=True)
