"""Native exported V1/V2 journeys with bundled helper, no external Node or Godot."""
import hashlib,json,os,pathlib,subprocess,tarfile,zipfile,shutil
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME101_TEST_ROOT']).resolve();release=base/'distribution';release.mkdir(exist_ok=True)
name='game103-character-builder-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name;engine=os.environ['GODOT_BIN'];helper=os.environ['GAME76_HELPER_ROOT']
subprocess.run(['node','tools/release/export-game.mjs','--helper',helper,'--godot',engine,'--qa','--qa-scene','res://tests/character_builder/review.tscn','--output',str(dist)],cwd=root,check=True)
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
(dist/'START-HERE.txt').write_text('GAME-103: CHARACTER BUILDER\n\nExtract the entire archive and run road-has-gone-dark.exe. Keep worldgen-helper and artwork beside it. No Godot or Node installation is needed. Escape skips intro.\n\nNew Game -> generate/select world -> origin -> hometown -> Build your adventurers. Select each of the three characters. Edit Identity, then Build: allocate scores, class, skills, feat, equipment and preparations. Review Sheet, then Save adventurer. Confirm all three before Ready party -> Enter hometown. Narrative role is distinct from mechanical class. Explore local opportunities, fight, return home. Characters opens the permanent sheet. Advance requires actual journey XP and being at home; no XP is granted here. Existing campaigns continue without recreation.\n\nTab/Enter and mouse work in scrollable tabs. Eight prototype peoples are provisional, with one neutral heritage each. Three base classes and a prerequisite-gated prestige class are pinned GAME-32 options; some kernel abilities remain unconnected to V0 tactical combat and are labelled honestly. Original licences are in artwork/ and worldgen-helper. Unsigned review build. Saves: %APPDATA%/Godot/app_userdata/Road Has Gone Dark.\n',encoding='utf-8')
shutil.copy2(root/'data/characters/builder-v1.json',dist/'CHARACTER-BUILDER-POLICY.json')
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
