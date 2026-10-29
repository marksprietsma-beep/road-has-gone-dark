"""Real810XP source campaign, exact cold, connected tactical authority and original renders."""
from pathlib import Path
import json,os,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['FINAL_PRESTIGE_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),FINAL_PRESTIGE_EARNED_FULL='0',FINAL_PRESTIGE_CAPTURE_ROOT=str(base/'captures'))
for key in ['GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
proofs={};timings=[]
for phase in ['journey','connected','capture']:
 for cold in ([False]if phase=='capture'else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/final_prestige/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=5400)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-22000:]
  folder=base/'captures'if phase=='capture'else base/'journeys/cohort-0'if phase=='journey'else base/'connected';file='screenshots.json'if phase=='capture'else'restart-proof.json'if cold else'proof.json';p=json.loads((folder/file).read_text(encoding='utf-8'))
  assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+file]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==810 and not j['xp_injected']and not j['full_careers']and len(j['earned_entries'])==3
assert all(len(r['history'])==10 for r in j['builds'].values())
for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(490 if info['path']=='eldritch-knight'else 250)and all(info['alternatives'].values())and info['decline_committed']
assert set(proofs['connected/proof.json']['casts'].values())=={'eldritch-channel-wizard-enfeeble','shadowdancer-technique-4','dwarven-defender-technique-4'}
assert len(proofs['capture/screenshots.json']['screenshots'])>=24
(base/'earned-proof.json').write_text(json.dumps(dict(scope='Real810XP/total10, earned Knight3, Shadow5 and Defender5. Full native campaign separately earns1960XP/total15/all three prestige caps. Total20 figures are development fixtures.',proofs=proofs,timings=timings),indent=2)+'\n',encoding='utf-8')
print('FINAL_PRESTIGE_EARNED_SOURCE_PASS',flush=True)
