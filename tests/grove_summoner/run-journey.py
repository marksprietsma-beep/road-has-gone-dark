"""Windows source earned/cold/capture proof. This is not a native export."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GROVE_SUMMONER_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GROVE_SUMMONER_CAPTURE_ROOT=str(base/'captures'))
timings=[];proofs={}
for phase in ['journey','connected','capture']:
 for cold in ([False]if phase=='capture'else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0')
  out=checked_process([os.environ['GODOT_BIN']]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy','--path',str(root),'--script','res://tests/grove_summoner/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600 if phase=='journey'else 1800)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-20000:]
  folder=base/'captures'if phase=='capture'else base/'journeys/cohort-0'if phase=='journey'else base/'connected';name='screenshots.json'if phase=='capture'else'restart-proof.json'if cold else'proof.json'
  p=json.loads((folder/name).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+name]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==810 and not j['xp_injected']and len(j['journeys'])==len(j['builds'])==len(j['earned_entries'])==3
assert {x['role']for x in j['builds'].values()}=={'grove-shaman','bonded-wizard','grove-druid'}and all(len(x['history'])==10 for x in j['journeys'])
for info in j['earned_entries'].values():
 assert info['earned_xp']==info['required_xp']==(250 if info['path']=='bonded-summoner'else 360)
 assert all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
assert j['retrieval']['second_change_rejected']and j['retrieval']['spent']==0 and j['retrieval']['recovered']==1
c=proofs['connected/proof.json'];assert set(c['owned_actions'])=={'summon','companion'}and all(x['before_hp']>x['after_hp']for x in c['owned_actions'].values())
assert set(c['casts'].values())=={'grove-protection-1','bonded-summoner-technique-5','grove-protection-2'}
assert len(proofs['capture/screenshots.json']['screenshots'])>=24
(base/'earned-proof.json').write_text(json.dumps(dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Actual810XP/10, three funded optional prestige/decline saves, Spirit retrieval, real summon/companion attacks and costs, exact cold resolution/home and original Godot renders. Source engine, not native acceptance.',proofs=proofs,timings=timings),indent=2)+'\n',encoding='utf-8')
print('GROVE_SUMMONER_EARNED_SOURCE_PASS',flush=True)
