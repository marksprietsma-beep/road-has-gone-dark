"""Windows source earned campaign and real connected cold battle, not an export."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['MARTIAL_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'))
timings=[];proofs={}
for phase in ['journey','connected']:
 for cold in [False,True]:
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/martial_careers/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600 if phase=='journey'else 1200)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
  folder=base/'journeys/cohort-0'if phase=='journey'else base/'connected';name='restart-proof.json'if cold else'proof.json'
  p=json.loads((folder/name).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+name]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==490 and not j['xp_injected']and len(j['journeys'])==3 and len(j['builds'])==3
assert {v['role']for v in j['builds'].values()}=={'blade','bow','rage'}and all(len(r['history'])==8 for r in j['journeys'])
assert set(proofs['connected/proof.json']['casts'].values())=={'fighter-blade-6','fighter-bow-6','barbarian-resilient-6'}
receipt=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Ordinary490XP/8 with deliberately distinct saved martial builds, connected campaign commands, exact cold battle continuation and eligible home recovery. Source engine, not exported native evidence.',proofs=proofs,timings=timings)
(base/'earned-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('MARTIAL_EARNED_SOURCE_PASS',flush=True)
