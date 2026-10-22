"""Complete Windows gate, or exact-source-guarded native presentation recheck."""
from pathlib import Path
import os,subprocess,json,hashlib,zipfile,shutil,sys
assert os.name=='nt','Native Windows only'
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tests/character_psychic'))
from checked_process import checked_process
base=Path(os.environ['GAME152_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='game152-psychic-parity-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
manifest_bytes=(root/'data/rules/packs.json').read_bytes();pins={x['rules_ref']['pack_id']:x['rules_ref']for x in json.loads(manifest_bytes)['packs']};pin=pins['trhgd-character-v24']
reuse=None;original=None
if os.environ.get('GAME152_REUSE_RUN'):
 reuse=json.loads((base/'reuse-manifest.json').read_text(encoding='utf-8'));original=json.loads((base/'reuse-original-distribution-proof.json').read_text(encoding='utf-8'))
 assert reuse['run_id']==39578198867 and reuse['conclusion']=='success'and original['source_commit']==reuse['source_commit']=='59f1b20b8bbb2a4a7029ee71b10190e774b9ed74'
 assert original['rules_ref']==pin and original['production_launch']and original['separate_process_restart']and all(p['checks']>0 and p['failures']==0 for p in original['proofs'].values())
 changed=subprocess.check_output(['git','diff','--name-only',original['source_commit'],commit],cwd=root,text=True).splitlines()
 allowed={'scripts/ui/first_adventure.gd','tests/psychic_parity/input.gd','tests/psychic_parity/verify-package.py','tests/psychic_parity/reuse-native.py','.github/workflows/verify-psychic-parity.yml','tools/character-content/build-readiness.py','tools/character-content/readiness_psychic.py'}
 assert all(p.startswith('docs/')or p in allowed for p in changed),changed
 previous=subprocess.check_output(['git','show',original['source_commit']+':scripts/ui/first_adventure.gd'],cwd=root,text=True,encoding='utf-8')
 current=(root/'scripts/ui/first_adventure.gd').read_text(encoding='utf-8')
 line='  if RulesPsychic.parity_enabled(source):button.disabled=button.disabled or snapshot.tags.has("main_action_suppressed") or not engine.eligible(battle(),actor,actor,selected_id)\n'
 targeted='   if RulesPsychic.parity_enabled(engine.registry) and derived.ok and int(row.get("cost",{}).get("main",0))>0 and derived.snapshot.tags.has("main_action_suppressed"):button.disabled=true\n'
 assert current.count(line)==1 and current.count(targeted)==1 and current.replace(line,'',1).replace(targeted,'',1)==previous,'Only the two exact self/targeted display gates may differ; all authority/rules/service/other UI source must remain unchanged'
 # Evidence retains JSON but not the expedition packet's .json.sha. Restore only
 # the exact fixture checksum matching the already-saved packet pin; never edit saves.
 journey=base/'journeys/cohort-0';receipt=json.loads((journey/'proof.json').read_text(encoding='utf-8'))
 saved=json.loads((journey/'saves'/(receipt['slot']+'.json')).read_text(encoding='utf-8'))
 packet=saved['expedition']['packet_sha'];candidates=[p for p in (journey/'cache').rglob('*.json')if hashlib.sha256(p.read_bytes()).hexdigest()==packet]
 assert len(candidates)==1,'Saved fixture packet unavailable; no save/packet reconstruction permitted'
 Path(str(candidates[0])+'.sha').write_text(packet,encoding='ascii')
 reuse.update(changed_paths=changed,authority_and_rules_unchanged=True,presentation_change='Self-power eligibility and targeted main-suppression display gates; no combat semantics change',fresh_phases=['baseline','mechanics','input','capture'],restored_fixture_packet_checksum=packet)
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/psychic_parity/review.tscn','--output',str(dist)],cwd=root,check=True)
qa=dist/'road-has-gone-dark-qa.exe'
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GAME152_ROOT=str(base/'mechanics'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'),GAME126_AUDIT_ROOT=str(base/'readiness-audit'),GAME126_PACK='res://data/rules/trhgd-character-v24.json',GAME112W3_TEST_ROOT=str(base/'historical13'))
for key in ['GAME76_HELPER_ROOT','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[]
def run(phase,restart=False,visual=False):
 extra=dict(GAME152_PHASE=phase,GAME152_RESTART='1'if restart else'0',GAME126_AUDIT_RESTART='1'if restart else'0',GAME129_RESTART='1'if restart else'0',GAME146_RESTART='1'if restart else'0',GAME148_RESTART='1'if restart else'0',GAME149_RESTART='1'if restart else'0',GAME150_RESTART='1'if restart else'0',GAME112W3_RESTART='1'if restart else'0',GAME150_ROOT=str(base/('historical23'if phase=='historical23'else'current-upper')),GAME149_ROOT=str(base/'current-performance'),GAME148_ROOT=str(base/'current-supernatural'),GAME146_ROOT=str(base/'current-mobile'),GAME129_ROOT=str(base/'current-signatures'))
 label=phase+('-cold'if restart else'');log=base/(label+'.log')
 r=checked_process([str(qa)]+([]if visual else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=dict(env,**extra),log=log,timeout=1800)
 timings.append(dict(phase=label,**r));(base/'native-timings.json').write_text(json.dumps(timings,indent=2)+'\n')
 print(json.dumps(timings[-1]),flush=True)
 assert not r['exit_code']and not r['errors']and not r['timeout'],log.read_text(encoding='utf-8')[-14000:]
phases=['baseline','mechanics','input','capture']if reuse else['baseline','mechanics','input','journey','connected','capture','current-upper','current-upper-input','current-performance','current-performance-input','current-supernatural','current-signatures','current-mobile','historical23','historical13','legacy','compatibility','audit']
for phase in phases:
 run(phase,visual=phase=='capture')
 if phase not in ['baseline','input','capture','current-upper-input','current-performance-input']:run(phase,True)
proofs={}
for phase,folder,pack in [('mechanics','mechanics','v24'),('journey','journeys/cohort-0','v24'),('connected','connected','v24'),('current-upper','current-upper','v24'),('current-performance','current-performance','v24'),('current-supernatural','current-supernatural','v24'),('current-signatures','current-signatures','v24'),('current-mobile','current-mobile','v24'),('historical23','historical23','v23'),('historical13','historical13','v13'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16'),('audit','readiness-audit','v24')]:
 for file in ['proof.json','restart-proof.json']:
  actual=('mechanics-restart-proof.json'if file=='restart-proof.json'else'mechanics-proof.json')if phase=='historical13'else file
  p=json.loads((base/folder/actual).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,file)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+pack],(phase,file,p['rules_ref'])
  proofs[phase+'/'+file]=p
for phase,folder,file in [('baseline','mechanics','baseline-proof.json'),('input','mechanics','input-proof.json'),('current-upper-input','current-upper','input-proof.json'),('current-performance-input','current-performance','input-proof.json')]:
 p=json.loads((base/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[phase]=p
journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False and len(journey['journeys'])==3
assert {x['history'][0]['class_id']for x in journey['journeys']}=={'psion','wilder'}
assert any(sum(s['class_id']=='cerebremancer'for s in x['history'])==2 for x in journey['journeys'])
assert len(proofs['connected/proof.json']['casts'])==3 and proofs['connected/proof.json']['xp_injected']is False
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['failures']==0 and len(captures['screenshots'])>=15
for row in captures['screenshots']:
 image=base/'captures'/row['file'];assert hashlib.sha256(image.read_bytes()).hexdigest()==row['sha256']
# Same source, frozen GAME-32 oracle/migration on Windows; isolated evidence, not tracked files.
if reuse:
 proofs['frozen-rules']=original['proofs']['frozen-rules']
else:
 frozen_env=dict(os.environ,GAME32_EVIDENCE=str(base/'frozen-rules'))
 result=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=root,env=frozen_env,log=base/'frozen-rules.log',timeout=600)
 assert not result['exit_code']and not result['errors']and not result['timeout'],(base/'frozen-rules.log').read_text(encoding='utf-8')[-12000:]
 proofs['frozen-rules']=json.loads((base/'frozen-rules/kernel-results.json').read_text())
assert proofs['frozen-rules']['checks']==22181 and proofs['frozen-rules']['failures']==0
proof_sources={key:original['source_commit']if reuse and key.split('/')[0]not in phases else commit for key in proofs}
assert (root/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
r=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not r['exit_code']and not r['errors']and not r['timeout']
shutil.copy2(root/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(root/'data/rules/trhgd-character-v24.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('GAME-152 PSYCHIC RESOURCE PARITY\n\nExtract BOTH ZIP layers, keep every support/helper/art/licence file beside road-has-gone-dark.exe and launch it. No Godot or Node installation required. Escape skips intro.\n\nFresh New Game uses immutable24. Existing campaigns keep exact old rules pins. Select Psion or Wilder in the ordinary creator; Build > Specialisation/Powers lets you choose discipline and known powers. In combat choose a known power and its affordable augmentation, then its action/target. Tooltips show costs and owning class attribute; no tactical RNG is used by selection. Assault adds2 to positive psychic damage; Wilder surge costs4 points/main and leaves3-round Weakened reducing later psychic damage by2. Existing saved23 campaigns retain old mechanics.\n\nCerebremancer remains an earned optional prestige choice, not a starting class or automatic promotion. Permanent levels, skills, feat and a usable arcane spell are required. Arcane slots and power points never convert. Earn real opportunity XP, return home, deliberately commit advancement. Rest restores normal resources. Save, exit completely, relaunch and resume.\n\nVerification includes three actual490XP/level8 journeys with a Psion3/Wizard3/Cerebremancer2 history;20-level and all5prestige examples are explicitly development fixtures. No XP button or QA executable ships. Original adaptations, finite shared manifesting pool, no full tabletop conversion. Human visual/balance acceptance remains pending.\n',encoding='utf-8')
for p in dist.glob('road-has-gone-dark-qa*'):p.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for p in dist.rglob('*'):
  if p.is_file():z.write(p,Path(name)/p.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
(base/'distribution-proof.json').write_text(json.dumps(dict(source_commit=commit,native_reuse=reuse,proof_sources=proof_sources,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,timings=timings,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,captures=captures,earned_characters=3,historical_scope='Fresh affected v13/v23 native mechanics/cold, v16 repair/compatibility, all23 exact historical bytes/pins; earlier cohort earned/GUI receipts reused only for unchanged definitions/controllers and explicitly labelled.'),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),sha256=sha)),flush=True)
