"""Package and execute the production Windows build and isolated diagnostics."""
import hashlib, json, os, pathlib, platform, subprocess, zipfile
root = pathlib.Path(__file__).resolve().parents[2]
base = pathlib.Path(os.environ['ADVENTURE_RELEASE_ROOT']).resolve()
evidence = base / 'evidence'
evidence.mkdir(parents=True, exist_ok=True)
engine = os.environ.get('GODOT_BIN', 'godot')
helper = os.environ['GAME76_HELPER_ROOT']
distribution = base / 'game94-lpc-v1-windows-x64'
assert os.name == 'nt', 'Produce and verify Windows on the native Windows runner'
subprocess.run(['node',str(root/'tools/release/export-game.mjs'),'--helper',helper,'--godot',engine,'--qa',
                '--qa-scene','res://tests/adventure/review-flow.tscn','--output',str(distribution)],cwd=root,check=True)
environment = dict(os.environ)
environment.pop('GAME76_HELPER_ROOT', None)
environment.update(PATH='',NODE_PATH='',NODE_OPTIONS='',ADVENTURE_REVIEW_ROOT=str(base/'clean-profile'))
qa = distribution/'road-has-gone-dark-qa.exe'
log = evidence/'windows-native.log'
with log.open('w',encoding='utf-8') as stream:
    result = subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=distribution,env=environment,
                            stdout=stream,stderr=subprocess.STDOUT,timeout=900)
text = log.read_text(encoding='utf-8')
print(text,flush=True)
proof = json.loads((base/'clean-profile/review-proof.json').read_text())
assert result.returncode == 0 and 'ERROR:' not in text and proof['failures']==0 and proof['checks']>=60
assert proof['empty_path'] and not proof['source_helper_override']
assert proof['art']['styles']==['lpc']
# Check the exported program's preference in two separate native processes.
for phase in ['write','read']:
    replay=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=distribution,
                          env=dict(environment,GAME94_PREF_ONLY=phase),capture_output=True,text=True,timeout=90)
    (evidence/('windows-preference-'+phase+'.log')).write_text(replay.stdout+replay.stderr,encoding='utf-8')
    assert replay.returncode==0 and 'ERROR:' not in replay.stdout+replay.stderr
proof['preference_restart']=True
assert not any((distribution/'artwork'/name).exists() for name in ['kenney','0x72','navinius'])
# Audit all distributed original resources independently of Godot import remaps.
art_manifest=json.loads((distribution/'artwork/sources.json').read_text())
for row in art_manifest['files']:
    original=distribution/'artwork'/pathlib.Path(row['path']).relative_to('assets/combat')
    assert hashlib.file_digest(original.open('rb'),'sha256').hexdigest()==row['sha256']
proof['original_art_files']=len(art_manifest['files'])
production = distribution/'road-has-gone-dark.exe'
smoke = subprocess.run([str(production),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=distribution,
                       env=environment,capture_output=True,text=True,timeout=90)
(evidence/'windows-production-launch.log').write_text(smoke.stdout+smoke.stderr,encoding='utf-8')
assert smoke.returncode==0 and 'ERROR:' not in smoke.stdout+smoke.stderr
for path in distribution.glob('road-has-gone-dark-qa*'): path.unlink()
(distribution/'START-HERE.txt').write_text('GAME-94 UNIVERSAL LPC CHARACTER PRESENTATION V1\n\nExtract the entire ZIP. Run road-has-gone-dark.exe. Keep worldgen-helper and artwork beside it. No Node or Godot installation is required.\n\nEscape skips the intro. New Game -> generate/select world -> state -> region -> hometown -> Confirm origin -> Party ready -> Enter hometown. Prepare first adventure -> select local account -> Accept -> Begin expedition -> Scout if needed -> Travel -> Fight.\n\nLPC is the production art direction; F7 and the four-style selector are retired. Legacy presentation preferences default safely to LPC. Move then click a dotted tile; Attack/ability then a highlighted target; End turn. Watch walking, blade swings, bow draw/release, Lantern Spark casting, damage/miss feedback and defeat. Vanguard Guard uses the actual shield. Art credits are available in combat and artwork/.\n\nVictory or Withdraw -> Return to regional play -> hometown. Main menu/Resume Expedition preserve the battle. Saves remain in %APPDATA%/Godot/app_userdata/Road Has Gone Dark. This unsigned review build requires human Windows desktop/GPU playtest.\n',encoding='utf-8')
archive = base/'game94-lpc-v1-windows-x64.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as package:
    for path in sorted(distribution.rglob('*')):
        if path.is_file(): package.write(path,pathlib.Path(distribution.name)/path.relative_to(distribution))
digest = hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()
(base/(archive.name+'.sha256')).write_text(digest+'  '+archive.name+'\n')
proof.update(production_launch=True,archive_sha256=digest,archive=archive.name,distribution=json.loads((distribution/'distribution.json').read_text()))
(evidence/'windows-proof.json').write_text(json.dumps(proof,indent=2)+'\n')
print('::notice title=First Adventure Windows proof::'+json.dumps(proof,separators=(',',':')),flush=True)
