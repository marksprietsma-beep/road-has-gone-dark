"""Exact Windows-export tests. No installed Node/Godot used by game processes."""
from pathlib import Path
import re,os,subprocess,json,hashlib,zipfile,shutil,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
assert os.name=='nt','Windows only; source-host checks are not Linux CI/builds'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME130_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game130-spell-repertoires-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest_bytes=(root/'data/rules/packs.json').read_bytes();manifest=json.loads(manifest_bytes)
default_id=re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)
default_pin=next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']==default_id)
expected=next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v17')
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/spell_repertoires/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME130_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_REPAIR_ROOT=str(base/'legacy-v16'));env.pop('GAME76_HELPER_ROOT',None)
rows=[]
def run(label,extra,visual=False):
 result=checked_process([str(qa)]+([]if visual else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=base/(label+'.log'),timeout=3600)
 rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert not result['exit_code'] and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text()[-16000:]
for restart in [False,True]:run('mechanics'+('-restart'if restart else''),dict(GAME130_PHASE='mechanics',GAME130_RESTART='1'if restart else'0'))
run('combat-input',dict(GAME130_PHASE='input'))
for restart in [False,True]:run('legacy-v16'+('-restart'if restart else''),dict(GAME130_PHASE='legacy',GAME126_AUDIT_RESTART='1'if restart else'0'))
for restart in [False,True]:run('earned-journey'+('-restart'if restart else''),dict(GAME130_PHASE='journey',GAME126_AUDIT_RESTART='1'if restart else'0'))
for restart in [False,True]:run('connected-combat'+('-restart'if restart else''),dict(GAME130_PHASE='connected',GAME130_RESTART='1'if restart else'0'))
run('godot-captures',dict(GAME130_PHASE='capture',GAME126_AUDIT_RESTART='0'),True)
proofs={}
input_proof=json.loads((base/'mechanics/input-proof.json').read_text());assert input_proof['checks']>=5 and input_proof['failures']==0
proofs['combat-input']=input_proof
for file in ['proof.json','restart-proof.json']:
 p=json.loads((base/'connected'/file).read_text());assert p['failures']==0 and p['checks']>0 and p['rules_ref']==default_pin
 proofs['connected/'+file]=p
assert len(proofs['connected/proof.json']['casts'])==2 and proofs['connected/proof.json']['xp_injected']is False
for phase,folder in [('mechanics','mechanics'),('legacy','legacy-v16'),('journey','journeys/cohort-0')]:
 for file in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/file).read_text());assert p['checks']>0 and p['failures']==0
  if phase=='mechanics':assert p['rules_ref']==expected
  if phase=='legacy':assert p['rules_ref']==next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v16')
  if phase=='journey'and file=='proof.json':
   assert p['rules_ref']==default_pin and p['earned_xp']==360 and p['xp_injected']is False and len(p['journeys'])==3
   assert set(p['combat_actions'].values())=={'wizard-gravitic-snare','cleric-freedom-path','attack'}
  proofs[phase+'/'+file]=p
captures=json.loads((base/'captures/screenshots.json').read_text());assert captures['failures']==0 and len(captures['screenshots'])>=8
assert (root/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text())['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code'] and not r['errors'] and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/('data/rules/'+default_id+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-130 SPELL REPERTOIRES\n\nExtract the outer GitHub artifact ZIP, then this inner playable ZIP. Run road-has-gone-dark.exe. Keep worldgen-helper, artwork, licences and all supporting files beside it. No Godot or Node installation required. Escape skips the introduction.\n\nNew Game -> world -> origin -> hometown -> three characters. Fresh games use the current pack named in CHARACTER-RULES-MANIFEST.json; the archived mechanics acceptance remains pinned to v17. Existing campaigns keep their exact original pins; no automatic upgrade. Wizard requires INT and Cleric WIS. Earn XP through ordinary opportunities, return home and advance deliberately. Tier4 first becomes available at effective casting level7; tiers5/6/7 at9/11/13. Meet the actual score requirement shown beside each spell.\n\nCharacter Sheet -> Spellbook: search by spell name or tier, set prepared copies and Save spell selections at home. Slots are shared per class/tier; preparing spells never refills spent slots. Eligible home-return rest restores slots/copies. Spell descriptions state targets, saves, costs and duration. In combat select the spell then a highlighted target. Return to breath can target the displayed downed ally only if its tile is unoccupied. Spell suppression disables spell actions, not weapons/psychic/supernatural abilities.\n\nQA high-level histories and screenshots are DEVELOPMENT FIXTURES, not earned level20 campaigns. The ordinary earned example reaches level7/360XP with new tier4 spells. No XP button, review fixture or alternate save writer is shipped. Full catalogue and other caster repertoires remain incomplete.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,rules_ref=expected,default_rules_ref=default_pin,archive=archive.name,sha256=sha,proofs=proofs,timings=rows,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,earned_characters=3),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
