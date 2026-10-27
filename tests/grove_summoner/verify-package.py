"""Single stable Windows-native release. Original exporter, rules and save writer."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,struct,subprocess,sys,zipfile
assert os.name=='nt','Native Windows only'
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('grove_summoner_source',ROOT/'tests/grove_summoner/check-source.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard);scope=guard.verify()
base=Path(os.environ['GROVE_SUMMONER_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True)
release=base/'distribution';release.mkdir(exist_ok=True);name='grove-summoner-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();manifest_bytes=(ROOT/'data/rules/packs.json').read_bytes()
pins={x['rules_ref']['pack_id']:x['rules_ref']for x in json.loads(manifest_bytes)['packs']};pin=pins['trhgd-character-v33']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/grove_summoner/review.tscn','--output',str(dist)],cwd=ROOT,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',GROVE_SUMMONER_ROOT=str(base/'mechanics'),RANGER_STEWARD_ROOT=str(base/'historical32'),MONK_PALADIN_ROOT=str(base/'historical31'),MARTIAL_ROOT=str(base/'historical30'),GROVE_SUMMONER_CAPTURE_ROOT=str(base/'captures'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_AUDIT_ROOT=str(base/'all-base'),GAME126_PACK='res://data/rules/trhgd-character-v33.json',GAME150_ROOT=str(base/'current-upper'),DUAL_ROOT=str(base/'historical29'),GAME133_ROOT=str(base/'historical18'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
timings=[];proofs={}
for phase in ['probe','mechanics','input','journey','connected','capture','audit','current-upper','historical32','historical32-input','historical31','historical31-input','historical30','historical30-extended','historical30-input','historical29','historical18','legacy','compatibility']:
 for cold in ([False]if phase in ['probe','input','capture','historical30-input','historical31-input','historical32-input']else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,GROVE_SUMMONER_PHASE=phase)
  for key in ['GROVE_SUMMONER_RESTART','RANGER_STEWARD_RESTART','MONK_PALADIN_RESTART','MARTIAL_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART','GAME150_RESTART','DUAL_RESTART','GAME133_RESTART']:active[key]='1'if cold else'0'
  out=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if phase=='capture'else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=active,log=base/(label+'.log'),timeout=3600)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
for phase,folder,version in [('mechanics','mechanics','v33'),('journey','journeys/cohort-0','v33'),('connected','connected','v33'),('audit','all-base','v33'),('current-upper','current-upper','v33'),('historical32','historical32','v32'),('historical31','historical31','v31'),('historical30','historical30','v30'),('historical30-extended','historical30/extended','v30'),('historical29','historical29','v29'),('historical18','historical18','v18'),('legacy','legacy-v16','v16'),('compatibility','compatibility-v16','v16')]:
 for filename in ['proof.json','restart-proof.json']:
  p=json.loads((base/folder/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,filename)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,filename)
  proofs[phase+'/'+filename]=p
for key,filename in [('pinned32-probe','probe-proof.json'),('input','input-proof.json')]:
 p=json.loads((base/'mechanics'/filename).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0;proofs[key]=p
assert all(proofs['mechanics/proof.json']['contracts'][k]is True for k in ['entry','aura','renewal','casting','calls','creatures','limits','forms','late'])
assert all(proofs['mechanics/proof.json']['attacks'][k]>0 for k in ['hits','misses'])
historical_input=json.loads((base/'historical30/input-proof.json').read_text(encoding='utf-8'));assert historical_input['checks']>0 and historical_input['failures']==0 and historical_input['suppressed_cases']==3 and historical_input['resisted_cases']==2
proofs['historical30-input']=historical_input
historical31_input=json.loads((base/'historical31/input-proof.json').read_text(encoding='utf-8'));assert historical31_input['checks']>0 and historical31_input['failures']==0 and historical31_input['rules_ref']==pins['trhgd-character-v31'];proofs['historical31-input']=historical31_input
historical32_input=json.loads((base/'historical32/input-proof.json').read_text(encoding='utf-8'));assert historical32_input['checks']>0 and historical32_input['failures']==0 and historical32_input['rules_ref']==pins['trhgd-character-v32'];proofs['historical32-input']=historical32_input
j=proofs['journey/proof.json'];assert j['earned_xp']==810 and not j['xp_injected']and len(j['journeys'])==3 and {r['role']for r in j['builds'].values()}=={'grove-shaman','bonded-wizard','grove-druid'}
assert all(len(r['history'])==10 for r in j['journeys'])
assert len(j['earned_entries'])==3
for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(250 if info['path']=='bonded-summoner'else 360) and all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
assert j['retrieval']['second_change_rejected']and j['retrieval']['spent']==0 and j['retrieval']['recovered']==1
assert set(proofs['connected/proof.json']['owned_actions'])=={'summon','companion'}and all(x['before_hp']>x['after_hp']for x in proofs['connected/proof.json']['owned_actions'].values())
assert set(proofs['connected/proof.json']['casts'].values())=={'grove-protection-1','bonded-summoner-technique-5','grove-protection-2'}
audit=json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(x['complete_track']for x in audit['classes'].values())
captures=json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'));assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=24
assert all(any(image['file'].startswith('fixture-'+power+'-combat-')for image in captures['screenshots'])for power in ['active-call5','sanctuary_saved_hit'])
for image in captures['screenshots']:
 file=base/'captures'/image['file'];raw=file.read_bytes();assert hashlib.sha256(raw).hexdigest()==image['sha256'];assert raw[:8]==b'\x89PNG\r\n\x1a\n';image['width'],image['height']=struct.unpack('>II',raw[16:24])
assert {r['width']for r in captures['screenshots']}=={640,1280,2560}
frozen=base/'frozen';out=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=ROOT,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=base/'frozen.log',timeout=600)
assert not out['exit_code']and not out['errors']and not out['timeout']
timings.append(dict(phase='frozen',**out))
proofs['frozen']=json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'));assert proofs['frozen']['checks']==22181 and proofs['frozen']['failures']==0
assert guard.verify()==scope and (ROOT/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
out=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not out['exit_code']and not out['errors']and not out['timeout']
timings.append(dict(phase='production-launch',**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8')
shutil.copy2(ROOT/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(ROOT/'data/rules/trhgd-character-v33.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text("GROVE WARDEN AND BONDED SUMMONER REVIEW\n\nExtract the outer GitHub artifact ZIP, then the inner grove-summoner-windows-x64.zip. Keep the entire folder and run road-has-gone-dark.exe. No installed Godot, Node or artwork is needed. Escape skips the intro. Fresh New Game uses v33; existing campaigns retain exact historical pins and mechanics without automatic upgrades.\n\nCreate actual Spirit Shaman, Wizard and Druid characters through the existing party creator. Pick ancestry, skills, feats, equipment, class specialisations and real known/prepared/retrieved spells. Both prestige careers are earned optional advancement, never starting classes or automatically granted. Grove Warden needs prior total6, Nature6, Insight4, Spirit Reserve, permanent usable divine tier3 magic and an existing nature parent of at least3 levels. Spirit Reserve itself needs a Spirit Shaman level, so do not assume a pure Druid/Ranger route. A funded Shaman6 may enter or decline at360XP. Bonded Summoner needs prior total5, Arcana4, genuine permanent arcane tier3 spells and an actual existing arcane parent; a Wizard5 may enter or decline at250XP.\n\nChoose the actual caster parent explicitly. Each prestige level advances that parent's own tiers, slots, repertoire and casting attribute. Prepared copies, permanent spontaneous knowledge and Spirit Shaman eligible-rest retrieval stay distinct; class-call uses and Grove Favour never substitute for spell slots. Junior multiclass parents progress from their own levels.\n\nGrove Warden has3 prestige levels: finite three-boundary radius2 sanctuary with line of sight; paid single-ally healing/cleanse; and area recovery/temporaryHP/resistance. It protects living allies and actual owned creatures, loses projection outside range or when the provider is down, and respects the existing suppression of supernatural actions/projection in altered bodies. It does not add forest travel or terrain simulation.\n\nBonded Summoner has5 prestige levels. Its existing ten supernatural calls use a finite separate reserve and a main action. Varied temporary creatures keep their actual natural attacks and distinct finite support/control/damage abilities. They have their own movement, attack and reaction turns. The existing one-active-summon limit is shared with normal spells; summons retain real identity, growth, duration, defeat and dismissal. Permanent nature companions remain separate. Owner defeat withdraws creatures at the existing next global boundary. Magical calls are now correctly suppressed by altered bodies. Creature artwork is explicitly labelled humanoid LPC fallback.\n\nAcceptance actually earns810XP/total10 for Shaman7/Grove3, Wizard5/Bonded5 and Druid6/Shaman1/Grove3 with Leopard. Saved funded entry and truly committed decline forks, rest retrieval, real temporary/permanent creature damage, class costs, connected cold resolution and home recovery are verified. Total20 screenshots are labelled DEVELOPMENT FIXTURES, not earned20. Save, fully exit, relaunch and Resume. No QA executable or XP button ships.\n\nThe50-career roster is unchanged.45/5 technical readiness needs matching-source native evidence and remains separate from human balance and UI usability. Shared label clipping/small-window limits and the separate class-browser task remain. No monsters, new creatures, religion or living-world development is claimed.\n",encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt=dict(acceptance_cohort='grove-summoner',source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,captures=captures,source_guard=scope,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=3,earned_xp=810,earned_level=10,earned_prestige_caps={'grove-warden':3,'bonded-summoner':5},high_level_fixtures_not_earned=True)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(dict(archive=str(archive),sha256=sha),flush=True)
