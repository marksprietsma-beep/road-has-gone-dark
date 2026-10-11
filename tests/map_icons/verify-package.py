"""Export matching game/helper; decode original SVGs in native Windows/Linux game."""
import hashlib,json,os,pathlib,subprocess,tarfile,zipfile
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME98_TEST_ROOT']).resolve();release=base/'distribution';release.mkdir(exist_ok=True)
name='game98-local-game-icons-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name;engine=os.environ['GODOT_BIN'];helper=os.environ['GAME76_HELPER_ROOT']
subprocess.run(['node','tools/release/export-game.mjs','--helper',helper,'--godot',engine,'--qa','--qa-scene','res://tests/map_icons/verify-distribution.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa');env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None)
with (base/'native-export.log').open('w',encoding='utf-8')as f:r=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=900)
text=(base/'native-export.log').read_text(encoding='utf-8');assert r.returncode==0 and not any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error']),text[-6000:]
proof=json.loads((base/'map-icons-proof.json').read_text());assert not proof['source_helper_override'] and proof['empty_path'] and proof['failures']==0
(base/'native-export-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert r.returncode==0 and 'ERROR:'not in r.stdout+r.stderr
(dist/'START-HERE.txt').write_text('GAME-98: APPROVED LOCAL GAME-ICONS\n\nExtract the entire archive and run road-has-gone-dark.exe on Windows. Keep worldgen-helper and artwork beside it. No Godot or Node installation needed. Escape skips intro. Continue / Resume Expedition preserves your existing campaign. Select a known opportunity: parchment icons show its meaning, gold rim its selection, pennant party position, small tick completion. Rumours remain off-map until scouting. Existing GAME-99 geography repair remains included.\n\nNew Game -> world -> origin -> hometown -> party ready -> Enter hometown -> Explore local opportunities -> select -> Set out -> Scout if rumoured -> Travel -> Engage occupants -> resolve -> Return to regional play -> Return home & rest. Saved rewards and sites remain recorded.\n\nSaves: %APPDATA%/Godot/app_userdata/Road Has Gone Dark. Do not reset or recreate your campaign. Unsigned review build. Game-icons credits/source revisions are in REGIONAL-ART-NOTICE.txt and worldgen-helper/assets/map_icons/trials/game-icons/.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
if os.name=='nt':
 archive=release/(name+'.zip')
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
  for p in dist.rglob('*'):
   if p.is_file():z.write(p,pathlib.Path(name)/p.relative_to(dist))
else:
 archive=release/(name+'.tar.gz')
 with tarfile.open(archive,'w:gz')as t:t.add(dist,arcname=name)
digest=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();(release/(archive.name+'.sha256')).write_text(digest+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps({'archive':archive.name,'archive_sha256':digest,'source_commit':os.environ.get('GITHUB_SHA','local'),'original_icons_bundled_in_helper':True,'native_export':proof,'production_launch':True},indent=2)+'\n')
print('Verified native map icons, saved campaign and packaged runtime:',archive,digest,flush=True)
