"""Short, genuine Windows entry/decline campaign before the one full native release."""
from pathlib import Path
import json,os,shutil,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DRAGON_WARSHAPER_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),DRAGON_WARSHAPER_EARNED_FULL='0',DRAGON_WARSHAPER_CAPTURE_ROOT=str(base/'captures'))
reuse=os.environ.get('DRAGON_WARSHAPER_REUSE_EARNED_RUN','').strip();origin=None
if reuse:
 assert reuse.isdecimal(),'An actual completed Actions run ID is required'
 meta=json.loads(subprocess.check_output(['gh','api',f'repos/marksprietsma-beep/road-has-gone-dark/actions/runs/{reuse}'],text=True));assert meta['status']=='completed'
 source=meta['head_sha']
 # Reuse only the successful XP component, never the failed connected phase.
 inputs=['scripts','data','scenes','assets','vendor','project.godot','tests/dragon_warshaper/journey.gd','tests/nature_repertoires','tests/adventure_cycles','tests/dual_prestige_acceptance/base.gd']
 assert subprocess.check_output(['git','diff',source,'--',*inputs],cwd=root)==b'','Earned-campaign inputs changed'
 downloaded=base/'reused-actions-evidence'
 subprocess.run(['gh','run','download',reuse,'--repo','marksprietsma-beep/road-has-gone-dark','--name','dragon-warshaper-windows-evidence','--dir',str(downloaded)],check=True)
 previous=downloaded/'dragon-warshaper-earned/journeys';j=json.loads((previous/'cohort-0/proof.json').read_text(encoding='utf-8'));cold=json.loads((previous/'cohort-0/restart-proof.json').read_text(encoding='utf-8'))
 assert j['checks']>0 and j['failures']==0 and cold['checks']>0 and cold['failures']==0 and j['earned_xp']==480 and not j['xp_injected']and not j['full_careers']
 assert j['rules_ref']==json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs'][-1]['rules_ref']
 shutil.copytree(previous,base/'journeys',dirs_exist_ok=True)
 origin=dict(run=int(reuse),source_commit=source,scope='Previously passed real480XP journey component and its original raw saves; fresh current-source cold/connected/capture below. No regenerated XP or claim of a new warm journey.')
 (base/'reused-earned-source.json').write_text(json.dumps(origin,indent=2)+'\n',encoding='utf-8')
for key in ['GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
proofs={};timings=[]
for phase in ['journey','connected','capture']:
 for cold in ([False]if phase=='capture'else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=dict(seconds=0,exit_code=0,errors=False,timeout=False,reused=origin)if phase=='journey'and not cold and origin else checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/dragon_warshaper/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-22000:]
  folder=base/'captures'if phase=='capture'else base/'journeys/cohort-0'if phase=='journey'else base/'connected';file='screenshots.json'if phase=='capture'else'restart-proof.json'if cold else'proof.json';p=json.loads((folder/file).read_text(encoding='utf-8'))
  assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+file]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==480 and not j['xp_injected']and not j['full_careers']and len(j['earned_entries'])==3
assert all(len(r['history'])==7 for r in j['builds'].values())
for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(250 if info['parent']=='wizard'else 360)and all(info['alternatives'].values())and info['decline_committed']
c=proofs['connected/proof.json'];assert set(c['owned_actions'])=={'summon','companion'}and all(r['before_hp']>r['after_hp']for r in c['owned_actions'].values())
assert len(proofs['capture/screenshots.json']['screenshots'])>=24
(base/'earned-proof.json').write_text(json.dumps(dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),reused_earned_origin=origin,scope='Short source-engine Windows campaign:480 genuineXP/level7, optional earned entry/committed decline, real creatures/class costs and cold. Full native campaign separately earns2280XP/level16 and both entire prestige tracks. No earned20 claim.',proofs=proofs,timings=timings),indent=2)+'\n',encoding='utf-8')
print('DRAGON_WARSHAPER_EARNED_SOURCE_PASS',flush=True)
