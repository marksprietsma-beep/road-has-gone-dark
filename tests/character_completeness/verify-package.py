"""Windows exported execution of complete careers, skills, earned journeys and legacy routes."""
from pathlib import Path
import re,os,subprocess,json,hashlib,zipfile,shutil,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'character_psychic'))
from checked_process import checked_process
assert os.name=='nt','Windows only: no Linux build or CI is authorised'
root=Path(__file__).resolve().parents[2];base=Path(os.environ['GAME126_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game126-character-completeness-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest_bytes=(root/'data/rules/packs.json').read_bytes();manifest=json.loads(manifest_bytes)
default_id=re.search(r'const NEW_PACK := "([^"]+)"',(root/'scripts/rules/rules_records.gd').read_text()).group(1)
default_pin=next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']==default_id)
expected=next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v16')
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/character_completeness/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME126_ROOT=str(base),GAME112W5_TEST_ROOT=str(base/'legacy-v15'),GAME126_AUDIT_ROOT=str(base/'audit'),GAME126_REPAIR_ROOT=str(base/'repair'),GAME126_OPTIONS_ROOT=str(base/'options'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_PACK='res://data/rules/trhgd-character-v16.json');env.pop('GAME76_HELPER_ROOT',None)
rows=[]
def run(label,extra):
 result=checked_process([str(qa),'--headless','--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=base/(label+'.log'),timeout=3600)
 rows.append(dict(phase=label,**result));(base/'native-timings.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
 assert result['exit_code']==0 and not result['errors'] and not result['timeout'],(base/(label+'.log')).read_text()[-12000:]
for restart in [False,True]:run('legacy-mechanics'+('-restart'if restart else''),dict(GAME126_PHASE='legacy_mechanics',GAME112W5_RESTART='1'if restart else'0'))
for phase in ['repair','options','audit','compatibility']:
 for restart in [False,True]:run(phase+('-restart'if restart else''),dict(GAME126_PHASE=phase,GAME126_AUDIT_RESTART='1'if restart else'0'))
run('legacy-routes',dict(GAME126_PHASE='legacy_routes',GAME126_AUDIT_RESTART='0'))
for cohort in range(4):
 for restart in [False,True]:run(f'journey-{cohort}'+('-restart'if restart else''),dict(GAME126_PHASE='journey',GAME126_COHORT=str(cohort),GAME126_AUDIT_RESTART='1'if restart else'0'))
proofs={}
for phase in ['repair','options','audit','compatibility']:
 for filename in ['proof.json','restart-proof.json']:
  p=json.loads((base/phase/filename).read_text());assert p['checks']>0 and p['failures']==0 and p['rules_ref']==expected;proofs[phase+'/'+filename]=p
for filename in ['mechanics-proof.json','restart-proof.json']:
 p=json.loads((base/'legacy-v15'/filename).read_text());assert p['failures']==0 and p['rules_ref']==next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v15');proofs['legacy-v15/'+filename]=p
skills=set();journeys=[]
for cohort in range(4):
 d=base/'journeys'/f'cohort-{cohort}';p=json.loads((d/'proof.json').read_text());cold=json.loads((d/'restart-proof.json').read_text())
 assert p['failures']==cold['failures']==0 and p['rules_ref']==default_pin and p['earned_xp']==360 and p['xp_injected']is False
 assert len(p['journeys'])==3 and len(p['combat_actions'])==3
 journeys+=p['journeys'];skills.update(p['skills']);proofs[f'journey-{cohort}']=p;proofs[f'journey-{cohort}-restart']=cold
assert len(journeys)==12
assert {'skill:'+s for s in ['athletics','stealth','acrobatics','spellcraft','animal-handling']}<=skills,skills
legacy=json.loads((base/'legacy-routes-proof.json').read_text());assert legacy['checks']==485 and legacy['failures']==0
assert legacy['rules_ref']==next(x['rules_ref']for x in manifest['packs']if x['rules_ref']['pack_id']=='trhgd-character-v15')
assert (root/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text())['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code'] and not r['errors'] and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/('data/rules/'+default_id+'.json'),dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-126 CHARACTER COMPLETENESS\n\nExtract the outer GitHub artifact ZIP, then the inner playable ZIP. Run road-has-gone-dark.exe. Keep worldgen-helper, artwork, licences and every other supporting file beside it. No installed Godot or Node is needed. Escape skips the introduction.\n\nNew Game -> world -> origin -> hometown -> three characters. Fresh campaigns use the current pack named in CHARACTER-RULES-MANIFEST.json; archived GAME-126 mechanics remain pinned to v16. Existing saved campaigns retain their exact original rules and character identities. There are no new base classes in this repair.\n\nInvest ranks in Athletics, Stealth, Acrobatics, Spellcraft or Animal Handling. Seek new leads and travel to a matching existing opportunity. Contextual trained approaches show the actor, skill bonus, DC and purpose; read the supply/time costs. Failed checks award no XP. Completed objectives grant one ordinary reward. Return home to advance manually with earned XP. Character Sheet explains where each skill is used.\n\nArchmage is an optional earned prestige path requiring permanent legal seventh-tier arcane spell access. Nominal slots and temporary effects do not qualify. Spending slots does not erase permanent competence. It is never a starting class or automatically awarded.\n\nLevel20 and exhaustive prestige compatibility proofs are development fixtures. Twelve separate review characters earned level7 through ordinary opportunities. No XP button is shipped. Thin repertoires, conditional-effect audit gaps, unimplemented environmental senses and neutral humanoid fallback art remain documented limitations. See repository GAME-126 delivery and completeness matrix; the full character programme remains open.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,rules_ref=expected,default_rules_ref=default_pin,archive=archive.name,sha256=sha,proofs=proofs,legacy=legacy,timings=rows,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=12),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
