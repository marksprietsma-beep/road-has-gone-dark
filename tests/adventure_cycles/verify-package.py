"""Self-contained native earned-progression game and separate-process restart."""
import hashlib,json,os,pathlib,subprocess,tarfile,zipfile,shutil,re
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME121_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game121-sustainable-adventures-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name
engine=os.environ['GODOT_BIN'];helper=os.environ['GAME76_HELPER_ROOT']
subprocess.run(['node','tools/release/export-game.mjs','--helper',helper,'--godot',engine,'--qa','--qa-scene','res://tests/adventure_cycles/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa');env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None)
for label,restart in [('native-earned',False),('native-restart',True)]:
 with (base/(label+'.log')).open('w',encoding='utf-8')as f:r=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME121_TEST_ROOT=str(base/'earned'),GAME121_RESTART='1'if restart else'0'),stdout=f,stderr=subprocess.STDOUT,timeout=1800)
 text=(base/(label+'.log')).read_text(encoding='utf-8');assert r.returncode==0 and not any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error']),text[-6000:]
proof=json.loads((base/'earned/earned-proof.json').read_text());assert proof['failures']==0 and proof['xp']>=360 and proof['empty_path'] and not proof['source_helper_override'] and any(s['class_id']=='arcane-trickster'for s in proof['history'])
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90);assert r.returncode==0 and 'ERROR:'not in r.stdout+r.stderr
for f in ['builder-v1.json','builder-v2.json']:shutil.copy2(root/'data/characters'/f,dist/f)
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules'/(re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-121 REVIEW\n\nExtract both ZIP layers. Keep worldgen-helper and artwork beside road-has-gone-dark.exe; run that executable. No Godot or Node install needed. Escape skips intro. New Game -> world -> origin -> hometown -> create three adventurers -> enter hometown -> Seek new leads. Complete recovery/investigation/peaceful access or combat for one10-XP objective reward. Return home and open Characters to review/commit earned advancement. Resolve all current reports, then Seek new leads again. Adventure journal retains older results. Returning home before completion preserves an unfinished report. Existing saves keep rules, XP policies and prior rewards. Core classes1-12 and four prestige classes1-5 remain the current character batch; wider programme is open.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+('.zip'if os.name=='nt'else'.tar.gz'))
if os.name=='nt':
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
  for p in dist.rglob('*'):
   if p.is_file():z.write(p,pathlib.Path(name)/p.relative_to(dist))
else:
 with tarfile.open(archive,'w:gz')as t:t.add(dist,arcname=name)
digest=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();(release/(archive.name+'.sha256')).write_text(digest+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps({'source_commit':os.environ.get('GITHUB_SHA','local'),'archive':archive.name,'archive_sha256':digest,'native_earned':proof,'production_launch':True,'bundled_helper':True,'separate_process_restart':True},indent=2)+'\n')
print('Verified native earned prestige package',archive,digest,flush=True)
