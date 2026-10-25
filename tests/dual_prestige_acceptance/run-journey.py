"""Windows source campaign proof, explicitly distinct from an exported game."""
from pathlib import Path
import json,os,subprocess,sys
assert os.name=='nt','Windows Godot only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['DUAL_JOURNEY_ROOT']);base.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',DUAL_ENTRY_ROOT=str(base/'entry'))
timings=[]
for phase in ['journey','entry','connected-a','connected-b']:
    for cold in [False,True]:
        label=phase+('-cold'if cold else'')
        active=dict(env,GAME126_AUDIT_RESTART='1'if cold else'0',DUAL_RESTART='1'if cold else'0',GAME129_RESTART='1'if cold else'0',DUAL_CONNECTED_VARIANT='b'if phase.endswith('-b')else'a',GAME129_CONNECTED_ROOT=str(base/('connected-b'if phase.endswith('-b')else'connected-a')))
        out=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','res://tests/dual_prestige_acceptance/scene_runner.gd','--',phase],cwd=root,env=active,log=base/(label+'.log'),timeout=3600 if phase=='journey'and not cold else 1200)
        timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(json.dumps(timings[-1]),flush=True)
        assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
proofs={}
for phase,folder in [('journey',base/'journeys/cohort-0'),('connected-a',base/'connected-a'),('connected-b',base/'connected-b')]:
    for name in ['proof.json','restart-proof.json']:
        p=json.loads((folder/name).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase+'/'+name]=p
for name in ['entry-proof.json','entry-restart-proof.json']:
    p=json.loads((base/'entry'/name).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs['entry/'+name]=p
j=proofs['journey/proof.json'];assert j['earned_xp']==640 and not j['xp_injected']and len(j['journeys'])==3
assert all(len(r['history'])==9 for r in j['journeys'])
assert set(j['earned_entry_witnesses'])=={'wizard','sorcerer','duskblade'}
for phase,abilities in [('connected-a',{'wizard-arcane-bolt','cleric-bless','abjurant-retaliation-1'}),('connected-b',{'cleric-bless','sorcerer-arcane-bolt','abjurant-aegis-3'})]:assert set(proofs[phase+'/proof.json']['casts'].values())==abilities
receipt=dict(source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),scope='Fresh Windows source-Godot640XP/9 and actual funded optional entry/decline, two isolated connected forks, exact restart and home recovery. Not exported-native evidence; fork rewards are not accumulated in primary.',proofs=proofs,timings=timings)
(base/'earned-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('DUAL_PRESTIGE_EARNED_SOURCE_PASS')
