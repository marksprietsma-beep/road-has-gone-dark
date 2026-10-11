"""Native exported V1/V2 journeys with bundled helper, no external Node or Godot."""
import hashlib,json,os,pathlib,subprocess,tarfile,zipfile
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME101_TEST_ROOT']).resolve();release=base/'distribution';release.mkdir(exist_ok=True)
name='game101-opportunities-v2-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name;engine=os.environ['GODOT_BIN'];helper=os.environ['GAME76_HELPER_ROOT']
subprocess.run(['node','tools/release/export-game.mjs','--helper',helper,'--godot',engine,'--qa','--qa-scene','res://tests/opportunities/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa');env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None)
with (base/'native-export.log').open('w',encoding='utf-8')as f:r=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=900)
text=(base/'native-export.log').read_text(encoding='utf-8');assert r.returncode==0 and not any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error']),text[-6000:]
proof=json.loads((base/'review-proof.json').read_text(encoding='utf-8'));assert not proof['source_helper_override'] and proof['empty_path'] and proof['failures']==0 and len(proof['journeys'])==6 and proof['existing_campaign']['results']
(base/'native-export-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
with (base/'native-restart.log').open('w',encoding='utf-8')as f:r=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME101_RESTART='1'),stdout=f,stderr=subprocess.STDOUT,timeout=180)
text=(base/'native-restart.log').read_text(encoding='utf-8');assert r.returncode==0 and not any(t in text for t in ['ERROR:','SCRIPT ERROR:','Parse Error']),text[-5000:]
restart=json.loads((base/'restart-proof.json').read_text());assert restart['failures']==0 and len(restart['journeys'])==6 and restart['empty_path'] and not restart['source_helper_override']
(base/'native-restart-proof.json').write_text(json.dumps(restart,indent=2)+'\n',encoding='utf-8')
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert r.returncode==0 and 'ERROR:'not in r.stdout+r.stderr
(dist/'START-HERE.txt').write_text('GAME-101: PROCEDURAL OPPORTUNITIES V2\n\nExtract the entire archive, then run road-has-gone-dark.exe. Keep worldgen-helper and artwork beside it. No Godot, Node or extra artwork installation is required. Escape skips intro. Continue / Resume Expedition preserves existing campaigns; V1 stays V1.\n\nNew Game -> generate or select world -> state/region -> hometown -> create and ready party -> Enter hometown -> Explore local opportunities. Select a report, Set out, Scout if unlocated, then Travel. Recovery offers checked versus quick stores; investigation offers careful versus quick evidence; a relevant saved profession may contribute. Contested sites offer a provision payment, observation, withdrawal or existing tactical combat. Buttons show actual costs and information; noncombat never grants battle XP. Return home & rest, use menu Resume Expedition or relaunch to inspect retained outcomes. Tab, Enter and mouse work in the scrollable choice panel.\n\nSaves: %APPDATA%/Godot/app_userdata/Road Has Gone Dark. Never reset or recreate an existing V1 campaign to use this build. This is an unsigned review build. Original LPC/Game-icons notices are in artwork/, REGIONAL-ART-NOTICE.txt and worldgen-helper/assets/map_icons/trials/game-icons/. Versioned V1 and V2 manifests are alongside the executable.\n',encoding='utf-8')
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
(base/'distribution-proof.json').write_text(json.dumps({'archive':archive.name,'archive_sha256':digest,'source_commit':os.environ.get('GITHUB_SHA','local'),'native_export':proof,'production_launch':True,'bundled_original_licences':True},indent=2)+'\n',encoding='utf-8')
print('Verified native V1/V2 saved journeys and packaged runtime:',archive,digest,flush=True)
