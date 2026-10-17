"""Exact Windows-export tests. No installed Node/Godot used by game processes."""
from pathlib import Path
import os,subprocess,json,hashlib,zipfile,shutil,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
assert os.name=='nt','Windows only; source-host checks are not Linux CI/builds'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME133_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game133-spell-repertoires-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest_bytes=(root/'data/rules/packs.json').read_bytes();manifest=json.loads(manifest_bytes)
expected=next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v18')
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/nature_repertoires/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME133_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'));env.pop('GAME76_HELPER_ROOT',None)
rows=[]
def run(label,extra,visual=False):
 result=checked_process([str(qa)]+([]if visual else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=base/(label+'.log'),timeout=3600)
 rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text()[-16000:]
for restart in [False,True]:run('mechanics'+('-restart'if restart else''),dict(GAME133_PHASE='mechanics',GAME133_RESTART='1'if restart else'0'))
run('combat-input',dict(GAME133_PHASE='input'))
for restart in [False,True]:run('legacy-v16'+('-restart'if restart else''),dict(GAME133_PHASE='legacy',GAME126_AUDIT_RESTART='1'if restart else'0'))
for restart in [False,True]:run('compatibility-v16'+('-restart'if restart else''),dict(GAME133_PHASE='compatibility',GAME126_AUDIT_RESTART='1'if restart else'0'))
for restart in [False,True]:run('earned-journey'+('-restart'if restart else''),dict(GAME133_PHASE='journey',GAME126_AUDIT_RESTART='1'if restart else'0'))
for restart in [False,True]:run('connected-combat'+('-restart'if restart else''),dict(GAME133_PHASE='connected',GAME133_RESTART='1'if restart else'0'))
run('godot-captures',dict(GAME133_PHASE='capture',GAME126_AUDIT_RESTART='0'),True)
proofs={}
input_proof=json.loads((base/'mechanics/input-proof.json').read_text());assert input_proof['checks']>=5 and input_proof['failures']==0
proofs['combat-input']=input_proof
for file in ['proof.json','restart-proof.json']:
 p=json.loads((base/'connected'/file).read_text());assert p['failures']==0 and p['checks']>0 and p['rules_ref']==expected
 proofs['connected/'+file]=p
assert len(proofs['connected/proof.json']['casts'])==2 and proofs['connected/proof.json']['xp_injected']is False
for phase,folder in [('mechanics','mechanics'),('legacy','legacy-v16'),('compatibility','compatibility-v16'),('journey','journeys/cohort-0')]:
 for file in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/file).read_text());assert p['checks']>0 and p['failures']==0
  if phase=='mechanics':assert p['rules_ref']==expected
  if phase in ['legacy','compatibility']:assert p['rules_ref']==next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v16')
  if phase=='journey'and file=='proof.json':
   assert p['rules_ref']==expected and p['earned_xp']==490 and p['xp_injected']is False and len(p['journeys'])==3
   assert set(p['combat_actions'].values())=={'sorcerer-crystal-reservoir','druid-bramble-tether','attack'}
  proofs[phase+'/'+file]=p
captures=json.loads((base/'captures/screenshots.json').read_text());assert captures['failures']==0 and len(captures['screenshots'])>=8
assert (root/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text())['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code'] and not r['errors'] and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v18.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-133 SORCERER AND DRUID REPERTOIRES\n\nExtract the outer GitHub artifact ZIP, then this inner playable ZIP. Run road-has-gone-dark.exe. Keep every support folder, worldgen-helper and licence beside it. No installed Godot or Node required. Escape skips the introduction.\n\nNew Game -> world -> origin -> hometown -> create three characters. Fresh games use v18; existing saves retain exact original pins. Sorcerer casts spontaneously with CHA and permanent known spells: cannot forget them at rest. Druid uses WIS, prepared copies and shared tier slots. Tier4 unlocks at Sorcerer8/Druid7, tier5 at10/9, tier6 at12/11 and tier7 at13/13. Each spell shows its actual required score (14-17).\n\nEarn XP from ordinary opportunities. Return home to advance deliberately. Character Sheet -> Spellbook: search by name or tier; check Sorcerer known spells or choose Druid copy counts, then Save spell selections. Selecting spells never restores spent shared slots. Real eligible home-return rest restores resources. In combat select a spell and highlighted living target. Druid buffs can help companions and natural-form weapon attacks; transformed characters remain unable to cast spells.\n\nThe native proof has three ordinary characters at level8/490 earned XP through49 real objectives. Level20 and hybrid screenshots are explicitly DEVELOPMENT FIXTURES, not earned20. No XP buttons or QA executable shipped. Upper tiers8-9, other caster repertoires and conditional feat/career signatures remain unfinished.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,rules_ref=expected,archive=archive.name,sha256=sha,proofs=proofs,timings=rows,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,earned_characters=3),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
