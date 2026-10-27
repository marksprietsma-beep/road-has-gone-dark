"""Windows source earned campaign and real connected cold battle, not an export."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['RANGER_STEWARD_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),RANGER_STEWARD_CAPTURE_ROOT=str(base/'captures'))
timings=[];proofs={}
for phase in ['journey','connected','capture']:
 for cold in ([False]if phase=='capture'else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/ranger_steward/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600 if phase=='journey'else 1200)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
  folder=base/'captures'if phase=='capture'else base/'journeys/cohort-0'if phase=='journey'else base/'connected';name='screenshots.json'if phase=='capture'else'restart-proof.json'if cold else'proof.json'
  p=json.loads((folder/name).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+name]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==490 and not j['xp_injected']and len(j['journeys'])==3 and len(j['builds'])==3
assert {v['role']for v in j['builds'].values()}=={'archery','blade','steward'}and all(len(r['history'])==8 for r in j['journeys'])
assert j['earned_entry']['earned_xp']==j['earned_entry']['required_xp']==250 and all(j['earned_entry']['alternatives'].values())
assert proofs['connected/proof.json']['owned_action']['before_hp']>proofs['connected/proof.json']['owned_action']['after_hp']
assert set(proofs['connected/proof.json']['casts'].values())=={'ranger-archery-6','ranger-blade-6','steward-drive-3'}
assert len(proofs['capture/screenshots.json']['screenshots'])>=18
assert all(any(image['file'].startswith('fixture-'+power+'-combat-')for image in proofs['capture/screenshots.json']['screenshots'])for power in ['aimed2019','swiftsteward-drive-33'])
receipt=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Ordinary490XP/8 with deliberately distinct saved Ranger/Steward builds, connected campaign commands, exact cold battle continuation and eligible home recovery. Source engine, not exported native evidence.',proofs=proofs,timings=timings)
(base/'earned-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('RANGER_STEWARD_EARNED_SOURCE_PASS',flush=True)
