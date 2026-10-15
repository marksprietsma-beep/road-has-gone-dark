"""Self-contained native Windows/Linux gameplay, then a distinct process restart."""
from pathlib import Path
import os,subprocess,json,hashlib,tarfile,zipfile,shutil,time,re
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"character_psychic"))
from checked_process import checked_process
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112W4_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True)
name='game112-character-catalogue-wave-four-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/character_wave_four/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa')
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None);rows=[]
for label,restart in [('native-gameplay',False),('native-process-restart',True)]:
 log=base/(label+'.log')
 result=checked_process([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME112W4_TEST_ROOT=str(base),GAME112W4_RESTART='1'if restart else'0',GAME112W3_TEST_ROOT=str(base),GAME112W3_RESTART='1'if restart else'0'),log=log,timeout=3600)
 text=log.read_text(encoding='utf-8');rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n')
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],text[-9000:]
proofs={key:json.loads((base/path).read_text())for key,path in [('mechanics','mechanics-proof.json'),('restart','restart-proof.json'),('journey','journey/proof.json')]}
latest=re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)
assert all(p['failures']==0 for p in proofs.values())
assert proofs['mechanics']['rules_ref']['pack_id']==proofs['restart']['rules_ref']['pack_id']=='trhgd-character-v14'
assert proofs['journey']['rules_ref']['pack_id']==latest
assert proofs['journey']['earned_xp']>=10 and 'power-kinetic-bolt'in proofs['journey']['actions_used']
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert not r.returncode and not any(s in r.stdout+r.stderr for s in ['ERROR:','SCRIPT ERROR:','Parse Error']),r.stdout+r.stderr
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules'/(latest+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-112 WAVE FOUR — INITIAL COHERENT BATCH\n\nExtract the GitHub artifact ZIP, then the playable ZIP. Run road-has-gone-dark.exe with every file/subfolder beside it. No installed Node or Godot needed. Escape skips intro. New Game defaults to v14; existing campaigns keep exact historical pins.\n\nCreate Erudite, Divine Mind or Marshal through Race/Class and Build. Choose powers/mantles/doctrines in Powers and Specialisation. Erudite learns two initial powers but can manifest only one distinct power per rest at level1; augmentation shares its identity. The saved allowance grows at4/8/12/16/20 and resets on returning home to rest, never on restart or encounter entry. Divine Mind learns mantle-restricted psychic powers and maintains one area aura. Marshal uses leadership auras and finite rally commands without spellcasting. Auras cost a main action and resolve to start/switch, affect living allies within3 orthogonal tiles with clear line of sight and cease when their source is downed or transformed. Effects do not stack with stronger bonuses of the same type.\n\nCognition Adept is an optional five-level earned psychic/martial path, requiring level6, INT13, BAB4, perception4, Psychic Discipline and permanent manifesting capability. Eligibility never assigns it; return home with earned XP and explicitly select a level, or continue a base class.\n\nBugbear/Ogre/Half-giant/Troglodyte are bounded original inherited adaptations. Unusual ancestry/form/creature art uses neutral humanoid LPC fallbacks; no aquatic/flight/environmental vision mechanics claimed. Keep artwork and licence notices together. Additional powers, spells, feats, summons and a scaled-guardian form reuse the existing authority. The wider catalogue and the Wave Four aspirational targets remain unfinished. See repository delivery for verified scope, test evidence, exact source and limitations.\n',encoding='utf-8')
for f in dist.glob('road-has-gone-dark-qa*'):f.unlink()
archive=release/(name+('.zip'if os.name=='nt'else'.tar.gz'))
if os.name=='nt':
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
  for f in dist.rglob('*'):
   if f.is_file():z.write(f,Path(name)/f.relative_to(dist))
else:
 with tarfile.open(archive,'w:gz')as z:z.add(dist,arcname=name)
if os.name=='nt':
 with zipfile.ZipFile(archive) as checked:assert checked.testzip() is None
digest=hashlib.sha256(archive.read_bytes()).hexdigest();Path(str(archive)+'.sha256').write_text(digest+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(archive=archive.name,sha256=digest,proofs=proofs,source_commit=json.loads((dist/'distribution.json').read_text())['source_commit'],source_helper_override=False,empty_path=True,timings=rows),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=digest)))
