"""Focused Windows source earned entry/campaign continuation; native export is separate."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['HYBRID_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME129_CONNECTED_ROOT=str(base/'connected'))
rows=[]
for phase in ['journey','connected']:
 for cold in [False,True]:
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/hybrid_acceptance/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=7200 if phase=='journey'and not cold else 1200)
  rows.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
  assert not result['exit_code']and not result['errors']and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-16000:]
proofs={}
for phase,folder in [('journey',base/'journeys/cohort-0'),('connected',base/'connected')]:
 for file in ['proof.json','restart-proof.json']:
  p=json.loads((folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+file]=p
journey=proofs['journey/proof.json'];assert journey['earned_xp']==1690 and not journey['xp_injected'] and len(journey['journeys'])==3
assert all(len(r['history'])==14 for r in journey['journeys'])
assert set(journey['earned_entry_witnesses'])=={'wizard','sorcerer'}
assert set(proofs['connected/proof.json']['casts'].values())=={'channel-duskblade-searing-grasp','high-arcana-force-1','high-arcana-ward-1'}
receipt=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Windows source-Godot genuine1690XP/14 and real campaign/cold authority; not exported-native evidence.',proofs=proofs,timings=rows)
(base/'earned-proof.json').write_text(json.dumps(receipt,indent=2)+'\n');print('GENUINE_EARNED_HYBRID_PASS',flush=True)
