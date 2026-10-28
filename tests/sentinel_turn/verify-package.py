"""Focused native UI smoke release; no full32-class acceptance repetition."""
from pathlib import Path
import hashlib,json,os,shutil,struct,subprocess,sys,zipfile
assert os.name=='nt','Windows native Godot only'
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['SENTINEL_RELEASE_ROOT']);base.mkdir(parents=True,exist_ok=True);work=base/'evidence';work.mkdir(exist_ok=True);dist=base/'distribution/sentinel-turn-windows-x64'
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
subprocess.run([sys.executable,'tests/sentinel_turn/check-source.py'],cwd=root,check=True)
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/sentinel_turn/review.tscn','--output',str(dist)],cwd=root,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',SENTINEL_ROOT=str(work),GAME126_COMPATIBILITY_ROOT=str(work/'legacy'))
for key in ['GH_TOKEN','GITHUB_TOKEN','GAME76_HELPER_ROOT','GODOT_BIN']:env.pop(key,None)
timings=[];proofs={}
for phase,cold in [('probe',False),('campaign',False),('campaign',True),('legacy',False),('legacy',True)]:
 label=phase+('-cold'if cold else'');active=dict(env,SENTINEL_PHASE=phase,SENTINEL_RESTART='1'if cold else'0',GAME126_AUDIT_RESTART='1'if cold else'0')
 out=checked_process([str(dist/'road-has-gone-dark-qa.exe'),'--audio-driver','Dummy']+(['--headless']if phase=='legacy'else[]),cwd=dist,env=active,log=work/(label+'.log'),timeout=900)
 timings.append(dict(phase=label,**out));(work/'timings.json').write_text(json.dumps(timings,indent=2));print(timings[-1],flush=True)
 assert not out['exit_code']and not out['errors']and not out['timeout'],(work/(label+'.log')).read_text(encoding='utf-8')[-24000:]
 file=work/'probe-proof.json'if phase=='probe'else work/('campaign'if phase=='campaign'else'legacy')/('restart-proof.json'if cold else'proof.json')
 p=json.loads(file.read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[label]=p
frozen=work/'frozen';out=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=root,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=work/'frozen.log',timeout=600)
assert not out['exit_code']and not out['errors']and not out['timeout'];timings.append(dict(phase='frozen',**out))
proofs['frozen']=json.loads((frozen/'kernel-results.json').read_text());assert proofs['frozen']['checks']==22181 and not proofs['frozen']['failures']
manifest=(root/'data/rules/packs.json').read_bytes();pins=json.loads(manifest)['packs'];pin=pins[-1]['rules_ref'];assert pin['pack_id']=='trhgd-character-v33'
assert proofs['probe']['rules_ref']==proofs['campaign']['rules_ref']==proofs['campaign-cold']['rules_ref']==pin
assert all(x['end_on_screen']and x['withdraw_on_screen']and x['genuine_visible_click_emits_end']for x in proofs['probe']['observations'])
assert proofs['campaign']['expiry']==[2,1,0]and proofs['campaign-cold']['exact_cold']and not proofs['campaign']['private_save_used']
images=proofs['campaign']['measurements'];assert len(images)>=6 and any(x['fullscreen']for x in images)
for im in images:
 raw=(work/'campaign'/im['file']).read_bytes();assert hashlib.sha256(raw).hexdigest()==im['sha256'];assert struct.unpack('>II',raw[16:24])==(im['width'],im['height'])
assert {640,1280}<={im['width']for im in images}
launch=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=work/'production-launch.log',timeout=90)
assert not launch['exit_code']and not launch['errors']and not launch['timeout'];timings.append(dict(phase='production-launch',**launch));(work/'timings.json').write_text(json.dumps(timings,indent=2))
metadata=json.loads((dist/'distribution.json').read_text());assert metadata['source_commit']==source
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v33.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-165 SENTINEL TURN UI REPAIR\n\nExtract the outer GitHub artifact, then sentinel-turn-windows-x64.zip. Keep the complete folder and run road-has-gone-dark.exe. No installed Godot, Node or artwork needed.\n\nResume your existing campaign or start New Game. All historical rules pins remain exact; no v34 or silent upgrades. End turn is now the leading gold footer action, visible after movement/actions are spent and after Summon sentinel. Wait for the short action presentation, then End turn: Sentinel receives its own activation immediately after its caster. It can move/attack/end normally. Withdraw is a distinct defeat action and is never required to advance.\n\nThis prevents future forced withdrawals; it does not rewrite a previously saved retreat/defeat or award lost XP. The private player save was not accessed or published. Diagnostics reconstruct a minimal legal level-one Sorcerer/Knight/Ogre Druid/Wolf encounter from reported facts, use original combat/service/save authority and real Windows controls, and verify separate-process cold continuation. The direct-authority all-pass duration fixture separately proves3 global boundaries, without confusing expiry with owner death.\n\nExisting long ability-label clipping/creature-art fallbacks remain; this is a narrow progression-control repair, not a character-browser or combat redesign.\n',encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=dist.parent/'sentinel-turn-windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(dist.name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
subprocess.run([sys.executable,'tests/sentinel_turn/check-source.py'],cwd=root,check=True);assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==source
receipt=dict(source_commit=source,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,timings=timings,images=images,empty_path=True,production_launch=True,independent_cold=True,private_save_used=False,full_class_suite_repeated=False)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(dict(source=source,archive=str(archive),sha256=sha)),flush=True)
