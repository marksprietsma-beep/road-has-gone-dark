"""Short, genuine Windows entry/decline campaign before the one full native release."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DRAGON_WARSHAPER_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),DRAGON_WARSHAPER_EARNED_FULL='0',DRAGON_WARSHAPER_CAPTURE_ROOT=str(base/'captures'))
proofs={};timings=[]
for phase in ['journey','connected','capture']:
 for cold in ([False]if phase=='capture'else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/dragon_warshaper/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-22000:]
  folder=base/'captures'if phase=='capture'else base/'journeys/cohort-0'if phase=='journey'else base/'connected';file='screenshots.json'if phase=='capture'else'restart-proof.json'if cold else'proof.json';p=json.loads((folder/file).read_text(encoding='utf-8'))
  assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+file]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==480 and not j['xp_injected']and not j['full_careers']and len(j['earned_entries'])==3
assert all(len(r['history'])==7 for r in j['builds'].values())
for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(250 if info['parent']=='wizard'else 360)and all(info['alternatives'].values())and info['decline_committed']
c=proofs['connected/proof.json'];assert set(c['owned_actions'])=={'summon','companion'}and all(r['before_hp']>r['after_hp']for r in c['owned_actions'].values())
assert len(proofs['capture/screenshots.json']['screenshots'])>=24
(base/'earned-proof.json').write_text(json.dumps(dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Short source-engine Windows campaign:480 genuineXP/level7, optional earned entry/committed decline, real creatures/class costs and cold. Full native campaign separately earns2280XP/level16 and both entire prestige tracks. No earned20 claim.',proofs=proofs,timings=timings),indent=2)+'\n',encoding='utf-8')
print('DRAGON_WARSHAPER_EARNED_SOURCE_PASS',flush=True)
