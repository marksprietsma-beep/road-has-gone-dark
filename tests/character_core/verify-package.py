"""Native exported V1/V2 journeys with bundled helper, no external Node or Godot."""
import hashlib,json,os,re,pathlib,subprocess,tarfile,zipfile,shutil
root=pathlib.Path(__file__).resolve().parents[2];base=pathlib.Path(os.environ['GAME101_TEST_ROOT']).resolve();release=base/'distribution';release.mkdir(exist_ok=True)
tag=os.environ.get('GAME_CHARACTER_REVIEW_TAG','game118-playable-core-characters')
name=tag+'-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name;engine=os.environ['GODOT_BIN'];helper=os.environ['GAME76_HELPER_ROOT']
subprocess.run(['node','tools/release/export-game.mjs','--helper',helper,'--godot',engine,'--qa','--qa-scene',os.environ.get('GAME_CHARACTER_REVIEW_SCENE','res://tests/character_core/review.tscn'),'--output',str(dist)],cwd=root,check=True)
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
(dist/'START-HERE.txt').write_text('GAME-118: FAMILIAR CORE CHARACTER REVIEW\n\nExtract the entire archive and run road-has-gone-dark.exe. Keep worldgen-helper and artwork beside it. No Godot or Node installation is needed. Escape skips intro.\n\nNew Game -> generate/select world -> origin -> hometown -> Build your adventurers. The first Race & class tab offers the familiar core classes automatically: Barbarian, Bard, Cleric, Druid, Fighter, Monk, Paladin, Ranger, Rogue, Sorcerer and Wizard. There is no content opt-in. Choose a race and compatible heritage separately from background and source-world culture. Build tabs contain Attributes, Skills, Feats, Equipment, Spells and Progression. Review Sheet, then Save adventurer. Repeat for all three -> Party ready -> Enter hometown.\n\nCharacters opens the permanent sheet. Explore contextual opportunities and fight a contested site. Use movement, weapon techniques and selected spells; slot/use counts are visible. Return home after victory. The first earned 10 XP unlocks level two under the new pinned policy. Advance reviews class, skill ranks and any bonus/general feat. Save spell selections at home: prepared selections may change, spontaneous known spells remain learned. Exit and Resume to check persistence. Existing campaigns keep their original exact content and XP policy; never delete them to upgrade.\n\nActual playable starting content: 9 race families, 14 heritage records, 11 original core-class adaptations, 26 selectable feats, 0 prestige classes in the new pack. Implemented class progression is levels 1-8; this is a substantial first batch, not the complete 403 ancestry / 66 base / 283 prestige catalogue, nor a verbatim tabletop rules port. Domain/bloodline/quarry options are currently fixed; Druid uses a woodland domain bond, not a companion. No animal-companion system, full high-level spell list, Improved Evasion or prestige programme is claimed complete. World presence metadata remains legacy prototype data. LPC has neutral humanoid fallbacks for unsupported anatomy and bear form; small races scale down and Monk sprites are unarmed.\n\nTab/Enter and mouse work. Unsigned review build. Saves: %APPDATA%/Godot/app_userdata/Road Has Gone Dark. Original licences are in artwork/ and worldgen-helper.\n',encoding='utf-8')
if tag.startswith('game119'):
 (dist/'START-HERE.txt').write_text('GAME-119 REVIEW\n\nExtract the entire archive; run road-has-gone-dark.exe. No Godot/Node install needed. New Game uses the latest supported career content; old campaigns keep exact original rules. Build -> Specialisation offers class choices. Characters -> Advancement offers legal multiclass and prestige paths with prerequisites. Core class caps are 12; four prestige paths have five playable levels. Ordinary earned XP remains unchanged. High-level development screenshots are explicitly labelled; no free XP or fixture saves are included in normal play. Full levels 13-20 and catalogue programme remain open.\n',encoding='utf-8')
for filename in ['builder-v1.json','builder-v2.json']:shutil.copy2(root/'data/characters'/filename,dist/filename)
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json')
shutil.copy2(root/'data/rules'/(re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
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
