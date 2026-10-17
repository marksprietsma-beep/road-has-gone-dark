"""Self-contained Windows-only gameplay, then a distinct process restart."""
from pathlib import Path
import os,subprocess,json,hashlib,tarfile,zipfile,shutil,time,re
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"character_psychic"))
from checked_process import checked_process
assert os.name=='nt','Windows is the only supported release target; run this native verifier on Windows CI'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112W5_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True)
source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
expected_manifest=(root/'data/rules/packs.json').read_bytes()
expected_ref=next(r['rules_ref'] for r in json.loads(expected_manifest)['packs'] if r['rules_ref']['pack_id']=='trhgd-character-v15')
name='game112-character-catalogue-wave-five-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/character_wave_five/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa')
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None);rows=[]
for label,restart in [('native-gameplay',False),('native-process-restart',True)]:
 log=base/(label+'.log')
 result=checked_process([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME112W5_TEST_ROOT=str(base),GAME112W5_RESTART='1'if restart else'0',GAME112W3_TEST_ROOT=str(base),GAME112W3_RESTART='1'if restart else'0'),log=log,timeout=3600)
 text=log.read_text(encoding='utf-8');rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n')
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],text[-9000:]
proofs={key:json.loads((base/path).read_text())for key,path in [('mechanics','mechanics-proof.json'),('restart','restart-proof.json'),('earned','earned/proof.json'),('earned_restart','earned/restart-proof.json')]}
latest=re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)
assert (root/'data/rules/packs.json').read_bytes()==expected_manifest,'Content changed during native verification'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==source_commit,'Source commit changed during native verification'
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==source_commit
latest_ref=next(r['rules_ref'] for r in json.loads(expected_manifest)['packs'] if r['rules_ref']['pack_id']==latest)
assert all(p['failures']==0 and p['rules_ref']==(latest_ref if key in ['earned','earned_restart'] else expected_ref) for key,p in proofs.items())
assert proofs['mechanics']['rules_ref']['pack_id']==proofs['restart']['rules_ref']['pack_id']=='trhgd-character-v15'
assert latest_ref['pack_id']==latest
assert proofs['earned']['earned_xp']>=360 and proofs['earned']['xp_injected']is False
assert proofs['earned']['history'][-1]['class_id']=='abjurant-champion'
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert not r.returncode and not any(s in r.stdout+r.stderr for s in ['ERROR:','SCRIPT ERROR:','Parse Error']),r.stdout+r.stderr
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules'/(latest+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-112 WAVE FIVE — FIRST COHORT\n\nExtract both ZIPs and launch road-has-gone-dark.exe with every supporting file beside it. No installed Godot or Node needed. Fresh New Game uses the latest supported pack; v15 regression fixtures and saved campaigns retain exact historical pins.\n\nDuskblade: choose INT, a known spell and a normal equipped melee weapon. At class3, Channel actions cost one main action and the original spell slot. Miss or concealment spends both without a spell effect; only an authoritative hit delivers the original spell once. No duplicate attack or free spell.\n\nSpirit Shaman: retrieve a bounded initial spell set. Casting spends tier slots. After returning from an actual expedition and resting at home, Spellbook permits one repertoire change. Saving a selection never restores spell slots; restarting does not reset the permit.\n\nAbjurant Champion and Grove Warden are optional earned prestige paths; review permanent requirements and explicitly spend a legal earned advancement. Qualification never assigns them and prestige is never a starting class.\n\nCatfolk, Riverborn, Wildborn and Ratfolk are original inherited adaptations with numerical traits. All unusual anatomy uses disclosed neutral humanoid LPC art. No aquatic/flight/exploration mechanics claimed. Higher-level fixtures are development-only; the separate prestige journey earns XP through ordinary objectives. The wider Wave Five scope and catalogue remain unfinished. See repository delivery for verified counts, source, evidence and limitations.\n',encoding='utf-8')
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
(base/'distribution-proof.json').write_text(json.dumps(dict(target='windows-x64',archive=archive.name,sha256=digest,proofs=proofs,source_commit=json.loads((dist/'distribution.json').read_text())['source_commit'],source_helper_override=False,empty_path=True,production_launch=True,separate_process_restart=True,timings=rows),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=digest)))
