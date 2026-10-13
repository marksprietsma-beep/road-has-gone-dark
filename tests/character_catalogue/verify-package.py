"""Export the same engine, exercise new content natively, preserve complete notices."""
import hashlib,json,os,subprocess,tarfile,zipfile,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME112_TEST_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True)
name='game112-character-catalogue-wave-one-'+('windows'if os.name=='nt'else'linux')+'-x64';dist=release/name
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/character_catalogue/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/('road-has-gone-dark-qa.exe'if os.name=='nt'else'road-has-gone-dark-qa')
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='');env.pop('GAME76_HELPER_ROOT',None)
for label,restart in [('native-content',False),('native-restart',True)]:
    with (base/(label+'.log')).open('w',encoding='utf-8')as stream:
        result=subprocess.run([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,GAME112_TEST_ROOT=str(base),GAME112_RESTART='1'if restart else'0'),stdout=stream,stderr=subprocess.STDOUT,timeout=2700)
    text=(base/(label+'.log')).read_text(encoding='utf-8')
    assert result.returncode==0 and not any(s in text for s in ['ERROR:','SCRIPT ERROR:','Parse Error']),text[-9000:]
proofs={label:json.loads((base/path).read_text())for label,path in [('mechanics','mechanics-proof.json'),('tactical','tactical-proof.json'),('fresh','fresh/new-party-proof.json')]}
assert all(p['failures']==0 and p['rules_ref']['pack_id']=='trhgd-character-v11'for p in proofs.values())
assert proofs['fresh']['used_actions'] and len(proofs['fresh']['development_saves'])==3
exe=dist/('road-has-gone-dark.exe'if os.name=='nt'else'road-has-gone-dark')
r=subprocess.run([str(exe),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,capture_output=True,text=True,timeout=90)
assert r.returncode==0 and not any(s in r.stdout+r.stderr for s in ['ERROR:','SCRIPT ERROR:','Parse Error'])
for f in ['builder-v1.json','builder-v2.json']:shutil.copy2(root/'data/characters'/f,dist/f)
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v11.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-112 CHARACTER CATALOGUE WAVE ONE REVIEW\n\nExtract both ZIP layers and run road-has-gone-dark.exe. Keep worldgen-helper, artwork and notices beside it; no Node or Godot installation is required. Escape skips intro. New Game -> world -> origin -> hometown -> review three characters. New games default to v11:19 base tracks,8 prestige paths,17 ancestry families/26 inherited records,40 feats. Eleven original core tracks now have executable features through20; eight new tracks initially stop at12. Older campaigns keep exact pins and never upgrade silently. Finish adventures for earned XP, return home, use Characters -> Advance and Spellbook. Seek new leads sustains the existing loop. High-level review captures are explicitly labelled development fixtures; no production XP button exists. Companion/summon/binding/incarnum systems and much of the403/66/283 research programme remain unfinished. New nonhumanoid ancestry art uses honest neutral humanoid fallback. Do not merge before review.\n',encoding='utf-8')
for f in dist.glob('road-has-gone-dark-qa*'):f.unlink()
archive=release/(name+('.zip'if os.name=='nt'else'.tar.gz'))
if os.name=='nt':
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
        for f in dist.rglob('*'):
            if f.is_file():z.write(f,Path(name)/f.relative_to(dist))
else:
    with tarfile.open(archive,'w:gz')as t:t.add(dist,arcname=name)
digest=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();(release/(archive.name+'.sha256')).write_text(digest+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=os.environ.get('GITHUB_SHA',subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()),archive=archive.name,archive_sha256=digest,native=proofs,production_launch=True,separate_process_restart=True,empty_path=True,source_helper_override=False),indent=2)+'\n')
print('Verified complete native catalogue distribution',archive,digest,flush=True)
