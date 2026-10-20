"""One Windows-native acceptance gate for GAME-150. No Linux game execution."""
from pathlib import Path
import os,subprocess,json,hashlib,zipfile,shutil,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME150_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game150-upper-prepared-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest_bytes=(root/'data/rules/packs.json').read_bytes();manifest=json.loads(manifest_bytes);pins={r['rules_ref']['pack_id']:r['rules_ref']for r in manifest['packs']};expected=pins['trhgd-character-v23']
checkpoint=dict(phases=[],timings=[],metadata=None)
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/upper_prepared/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME150_ROOT=str(base/'mechanics'),GAME149_ROOT=str(base/'v22'),GAME148_ROOT=str(base/'v21'),GAME146_ROOT=str(base/'v20'),GAME129_ROOT=str(base/'v19'),GAME133_ROOT=str(base/'v18'),GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'),GAME126_AUDIT_ROOT=str(base/'readiness-audit'),GAME126_PACK='res://data/rules/trhgd-character-v23.json');env.pop('GAME76_HELPER_ROOT',None);env.pop('GH_TOKEN',None);env.pop('GITHUB_TOKEN',None)
rows=checkpoint['timings'].copy()
def run(phase,restart=False,visual=False):
 extra=dict(GAME149_ROOT=str(base/('current-performance'if phase in ['current-performance','current-performance-input']else'v22')),GAME149_RESTART='1'if restart else'0',GAME150_PHASE=phase,GAME150_RESTART='1'if restart else'0',GAME146_RESTART='1'if restart else'0',GAME129_RESTART='1'if restart else'0',GAME133_RESTART='1'if restart else'0',GAME126_AUDIT_RESTART='1'if restart else'0');label=phase+('-cold'if restart else'');extra['GAME148_ROOT']=str(base/('current-supernatural'if phase=='current-supernatural'else'v21'));extra['GAME148_RESTART']='1'if restart else'0';extra['GAME129_ROOT']=str(base/('current-signatures'if phase=='current-signatures'else'v19'));extra['GAME146_ROOT']=str(base/('current-mobile'if phase=='current-mobile'else'v20'))
 result=checked_process([str(qa)]+([]if visual else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=base/(label+'.log'),timeout=3600)
 rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-14000:]
for phase in ['mechanics', 'input', 'journey', 'connected', 'capture', 'current-performance', 'current-performance-input', 'v22', 'current-supernatural', 'current-signatures', 'current-mobile', 'v21', 'v20', 'v19', 'v18', 'legacy', 'compatibility', 'audit']:
 if phase in checkpoint['phases']:continue
 run(phase,visual=phase=='capture')
 if phase not in ['input','capture','current-performance-input']:run(phase,True)
proofs={}
for phase,folder,pin in [('mechanics','mechanics',expected),('current-performance','current-performance',expected),('v22','v22',pins['trhgd-character-v22']),('current-supernatural','current-supernatural',expected),('v21','v21',pins['trhgd-character-v21']),('current-signatures','current-signatures',expected),('current-mobile','current-mobile',expected),('v20','v20',pins['trhgd-character-v20']),('v19','v19',pins['trhgd-character-v19']),('v18','v18',pins['trhgd-character-v18']),('legacy','legacy-v16',pins['trhgd-character-v16']),('compatibility','compatibility-v16',pins['trhgd-character-v16']),('audit','readiness-audit',expected),('journey','journeys/cohort-0',expected),('connected','connected',expected)]:
 for file in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0
  if 'rules_ref'in p:assert p['rules_ref']==pin
  proofs[phase+'/'+file]=p
p=json.loads((base/'mechanics/input-proof.json').read_text(encoding='utf-8'));assert p['checks']>=15 and p['failures']==0;proofs['input']=p
p=json.loads((base/'current-performance/input-proof.json').read_text(encoding='utf-8'));assert p['checks']>=72 and p['failures']==0;proofs['current-performance-input']=p
journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False and len(journey['journeys'])==3
assert {r['history'][0]['class_id']for r in journey['journeys']}=={'wizard','cleric','fighter'}
assert len(proofs['connected/proof.json']['casts'])==3 and proofs['connected/proof.json']['xp_injected']is False
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['failures']==0 and len(captures['screenshots'])>=10
for row in captures['screenshots']:
 file=base/'captures'/row['file'];assert hashlib.sha256(file.read_bytes()).hexdigest()==row['sha256']
assert (root/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code'] and not r['errors'] and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v23.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-150 UPPER PREPARED CASTING\n\nExtract both ZIP layers; keep every support/helper/art/licence file together and launch road-has-gone-dark.exe. No installed Godot or Node needed. Escape skips intro.\n\nFresh New Game uses immutable23; existing campaigns keep their original pins. Wizard gains tier8 Unweaving tide (saved area removal of explicit boons) and tier9 Stillness lattice (saved loss of one main action; movement/reactions remain). Cleric gains tier8 Concord of release (group control cleanse/prevention) and tier9 Renewing benediction (immediate and activation healing; no resurrection). All use a slot, prepared copy and main action. Advanced school/domain buffers now belong to the selected ally, and advanced domains require their matching original selection.\n\nSpellbook shows staged copies/daily capacity and current shared slots. Home preparation refills selected copy allocations but never shared daily slots; eligible rest refills slots. Over-budget or under-attribute preparations reject.\n\nNative earned Wizard/Cleric/Fighter campaigns reach8 with490XP; high20 and Theurge examples are labelled development fixtures. No XP buttons or diagnostic executable ship. Save fully, exit/relaunch, resume. Caption/tooltip layout and final human balance remain review limits.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,native_reuse=checkpoint['metadata'],rules_ref=expected,archive=archive.name,sha256=sha,proofs=proofs,timings=rows,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,earned_characters=3),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
