"""Self-contained native Windows/Linux gameplay, then a distinct process restart."""
from pathlib import Path
import os,subprocess,json,hashlib,tarfile,zipfile,shutil,time,re
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112W3_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True)
name='game112-character-catalogue-wave-three-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/character_psychic/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa')
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None);rows=[]
for label,restart in [('native-gameplay',False),('native-process-restart',True)]:
 start=time.monotonic();log=base/(label+'.log')
 with log.open('w',encoding='utf-8')as stream:r=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME112W3_TEST_ROOT=str(base),GAME112W3_RESTART='1'if restart else'0'),stdout=stream,stderr=subprocess.STDOUT,timeout=3600)
 text=log.read_text(encoding='utf-8');errors=any(s in text for s in ['ERROR:','SCRIPT ERROR:','Parse Error'])
 rows.append(dict(phase=label,seconds=round(time.monotonic()-start,3),exit_code=r.returncode,errors=errors));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n')
 assert not r.returncode and not errors,text[-9000:]
proofs={key:json.loads((base/path).read_text())for key,path in [('mechanics','mechanics-proof.json'),('restart','mechanics-restart-proof.json'),('journey','journey/proof.json')]}
latest=re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)
assert all(p['failures']==0 for p in proofs.values())
assert proofs['mechanics']['rules_ref']['pack_id']==proofs['restart']['rules_ref']['pack_id']=='trhgd-character-v13'
assert proofs['journey']['rules_ref']['pack_id']==latest
assert proofs['journey']['earned_xp']>=10 and 'power-kinetic-bolt'in proofs['journey']['actions_used']
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert not r.returncode and not any(s in r.stdout+r.stderr for s in ['ERROR:','SCRIPT ERROR:','Parse Error']),r.stdout+r.stderr
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules'/(latest+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-112 CHARACTER CATALOGUE WAVE THREE\n\nExtract the GitHub artifact ZIP, then the playable ZIP. Run road-has-gone-dark.exe with all files kept beside it. No installed Node or Godot needed. Escape skips intro. New Game uses v13; existing campaigns keep their exact historical pins. In the creator, choose Race/Class, then Build > Specialisation and Powers. Psion learns two distinct starting powers. Ardent selects two starting mantles restricting its powers. Lurk uses Psychic veil before costed Psychic ambush. In combat, select a learned power and an augmentation amount; cost cannot exceed manifesting level, and a main action is required. Rest at home restores eligible reserves. Druid/Ranger choose a persistent companion; each has its own normal turn and bounded special-action effort. Prepared summons cost slots/copies and expire. Druid forms change physical stats/natural attacks; gear and spells/powers suppressed, HP/identity unchanged. Revert costs an action. Unusual ancestry/creature/form artwork is a labelled neutral humanoid fallback. Earn XP through adventures, return home to advance, exit and Resume. Higher-level fixture screenshots are development tests, not earned levels. See the repository delivery for exact verified scope and limitations. Full403/66/283 catalogue is unfinished.\n',encoding='utf-8')
for f in dist.glob('road-has-gone-dark-qa*'):f.unlink()
archive=release/(name+('.zip'if os.name=='nt'else'.tar.gz'))
if os.name=='nt':
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
  for f in dist.rglob('*'):
   if f.is_file():z.write(f,Path(name)/f.relative_to(dist))
else:
 with tarfile.open(archive,'w:gz')as z:z.add(dist,arcname=name)
digest=hashlib.sha256(archive.read_bytes()).hexdigest();Path(str(archive)+'.sha256').write_text(digest+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(archive=archive.name,sha256=digest,proofs=proofs,source_helper_override=False,empty_path=True,timings=rows),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=digest)))
