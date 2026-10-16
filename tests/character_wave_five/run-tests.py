"""Focused v15 authority, actual earned progression/rest selection and separate-process restart."""
from pathlib import Path
import os,subprocess,json,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112W5_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
rows=[]
commands=[('import',[os.environ['GODOT_BIN'],'--headless','--editor','--audio-driver','Dummy','--path',str(root),'--quit'],{})]
for phase in ['mechanics','earned']:
 for restart in [False,True]:commands.append((phase+('-restart'if restart else''),[os.environ['GODOT_BIN'],'--headless','--audio-driver','Dummy','--path',str(root),'--script','tests/character_wave_five/launch.gd'],dict(GAME112W5_PHASE=phase,GAME112W5_RESTART='1'if restart else'0')))
for label,args,extra in commands:
 result=checked_process(args,cwd=root,env=dict(os.environ,**extra),log=base/(label+'.log'),timeout=1800)
 rows.append(dict(phase=label,**result));(base/'timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text()[-10000:]
for path in ['mechanics-proof.json','restart-proof.json','earned/proof.json','earned/restart-proof.json']:
 proof=json.loads((base/path).read_text());assert proof['checks']>0 and proof['failures']==0 and proof['rules_ref']['pack_id']=='trhgd-character-v15'
