"""Focused repair gate: captured geometry, real writer journey, cold reload and native QA."""
from pathlib import Path
import os,sys,json
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112W2_TEST_ROOT']);base.mkdir(parents=True,exist_ok=True)
rows=[]
steps=[('import',['--editor','--quit'],{}),('blocked-surge',['--script','tests/character_entities/blocked_surge.gd'],{}),('journey',['--script','tests/character_entities/journey.gd'],{'GAME112W2_RESTART':'0'}),('journey-restart',['--script','tests/character_entities/journey.gd'],{'GAME112W2_RESTART':'1'})]
for label,args,extra in steps:
 result=checked_process([os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),*args],cwd=root,env=dict(os.environ,**extra),log=base/(label+'.log'),timeout=1800)
 rows.append(dict(test=label,**result));(base/'repair-timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-9000:]
proof=json.loads((base/'journey/proof.json').read_text(encoding='utf-8'))
assert proof['failures']==0 and proof['earned_xp']>=10 and 'wilder-surge'in proof['demonstration_actions']
assert 'wizard-summon-sentinel'in proof['demonstration_actions'] and any(':companion'in s for s in proof['demonstration_actions']) and any(':summon:'in s for s in proof['demonstration_actions'])

blocked=json.loads((base/"blocked-surge-proof.json").read_text(encoding="utf-8"))
assert blocked["checks"]>=15 and blocked["failures"]==0 and blocked["development_fixture"]
