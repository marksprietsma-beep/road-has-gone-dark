"""ONE stable self-contained Windows release: full earned careers, all-base and history."""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,struct,subprocess,sys,zipfile
assert os.name=='nt','Native Windows only'
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec=importlib.util.spec_from_file_location('final_scope',ROOT/'tests/final_prestige/source_scope.py');guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard);scope=guard.verify_production()
base=Path(os.environ['FINAL_PRESTIGE_RELEASE_ROOT']).resolve();base.mkdir(parents=True,exist_ok=True);release=base/'distribution';release.mkdir(exist_ok=True);name='final-prestige-windows-x64';dist=release/name
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();manifest=(ROOT/'data/rules/packs.json').read_bytes();pins={x['rules_ref']['pack_id']:x['rules_ref']for x in json.loads(manifest)['packs']};pin=pins['trhgd-character-v35']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],'--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/final_prestige/review.tscn','--output',str(dist)],cwd=ROOT,check=True)
env=dict(os.environ,PATH='',NODE_PATH='',NODE_OPTIONS='',FINAL_PRESTIGE_ROOT=str(base/'mechanics'),FINAL_PRESTIGE_CAPTURE_ROOT=str(base/'captures'),FINAL_PRESTIGE_EARNED_FULL='1',DRAGON_WARSHAPER_ROOT=str(base/'historical34'),SENTINEL_ROOT=str(base/'sentinel'),GROVE_SUMMONER_ROOT=str(base/'historical33'),RANGER_STEWARD_ROOT=str(base/'historical32'),MONK_PALADIN_ROOT=str(base/'historical31'),MARTIAL_ROOT=str(base/'historical30'),GAME126_JOURNEY_ROOT=str(base/'journeys'),GAME126_COHORT='0',GAME126_RESUME='0',GAME129_CONNECTED_ROOT=str(base/'connected'),GAME126_AUDIT_ROOT=str(base/'all-base'),GAME126_PACK='res://data/rules/trhgd-character-v35.json',GAME150_ROOT=str(base/'current-upper'),DUAL_ROOT=str(base/'historical29'),GAME133_ROOT=str(base/'historical18'),GAME126_REPAIR_ROOT=str(base/'legacy-v16'),GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:env.pop(key,None)
# Tuple: phase, evidence folder, rules pin, one-process-only, evidence filename.
phases=[('pins','mechanics','v35',True,'pins-proof.json'),('probe','mechanics','v34',True,'probe-proof.json'),('mechanics','mechanics','v35',False,'proof.json'),('input','mechanics','v35',True,'input-proof.json'),('sentinel-probe','sentinel','v33',True,'probe-proof.json'),('sentinel-campaign','sentinel/campaign','v35',False,'proof.json'),('journey','journeys/cohort-0','v35',False,'proof.json'),('connected','connected','v35',False,'proof.json'),('portable','portable-cold','v35',True,'proof.json'),('capture','captures','v35',True,'screenshots.json'),('audit','all-base','v35',False,'proof.json'),('current-upper','current-upper','v35',False,'proof.json'),('historical34','historical34','v34',False,'proof.json'),('historical34-input','historical34','v34',True,'input-proof.json'),('historical33','historical33','v33',False,'proof.json'),('historical33-input','historical33','v33',True,'input-proof.json'),('historical32','historical32','v32',False,'proof.json'),('historical32-input','historical32','v32',True,'input-proof.json'),('historical31','historical31','v31',False,'proof.json'),('historical31-input','historical31','v31',True,'input-proof.json'),('historical30','historical30','v30',False,'proof.json'),('historical30-extended','historical30/extended','v30',False,'proof.json'),('historical30-input','historical30','v30',True,'input-proof.json'),('historical29','historical29','v29',False,'proof.json'),('historical18','historical18','v18',False,'proof.json'),('legacy','legacy-v16','v16',False,'proof.json'),('compatibility','compatibility-v16','v16',False,'proof.json')]
timings=[];proofs={}
restart_keys=['FINAL_PRESTIGE_RESTART','DRAGON_WARSHAPER_RESTART','SENTINEL_RESTART','GROVE_SUMMONER_RESTART','RANGER_STEWARD_RESTART','MONK_PALADIN_RESTART','MARTIAL_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART','GAME150_RESTART','DUAL_RESTART','GAME133_RESTART']
for phase,folder,version,single,filename in phases:
 for cold in ([False]if single else[False,True]):
  label=phase+('-cold'if cold else'');active=dict(env,FINAL_PRESTIGE_PHASE=phase)
  for key in restart_keys:active[key]='1'if cold else'0'
  graphic=phase in ['input','capture','sentinel-probe','sentinel-campaign']
  out=checked_process([str(dist/'road-has-gone-dark-qa.exe')]+([]if graphic else['--headless'])+['--audio-driver','Dummy'],cwd=dist,env=active,log=base/(label+'.log'),timeout=7200 if phase=='journey'else 1800)
  timings.append(dict(phase=label,**out));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8');print(timings[-1],flush=True)
  assert not out['exit_code']and not out['errors']and not out['timeout'],(base/(label+'.log')).read_text(encoding='utf-8')[-22000:]
  file='restart-proof.json'if cold else filename;p=json.loads((base/folder/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0,(phase,file)
  if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+version],(phase,file)
  proofs[phase if single else phase+'/'+file]=p
assert proofs['pins']['pack_count']==35
for row in json.loads(manifest)['packs']:
 assert proofs['pins']['raw_sha256'][row['rules_ref']['pack_id']]==hashlib.sha256((ROOT/row['path'].removeprefix('res://')).read_bytes()).hexdigest()
required=['entry','channels','knight','shadow','defender','resources','suppression','late']
assert all(proofs['mechanics/proof.json']['contracts'][key]is True for key in required)
assert all(proofs['mechanics/proof.json']['attacks'][key]>0 for key in ['hits','misses'])
j=proofs['journey/proof.json'];assert j['earned_xp']==1960 and not j['xp_injected']and j['full_careers']and len(j['journeys'])==len(j['builds'])==len(j['earned_entries'])==3
assert all(len(r['history'])==15 for r in j['builds'].values())
assert {r['role']for r in j['builds'].values()}=={'wizard-knight','rogue-shadow','dwarf-defender'}
for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(490 if info['path']=='eldritch-knight'else 250)and all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
c=proofs['connected/proof.json'];assert set(c['casts'].values())=={'eldritch-channel-wizard-enfeeble','shadowdancer-technique-10','dwarven-defender-technique-10'}
assert proofs['sentinel-campaign/proof.json']['expiry']==[2,1,0]and proofs['sentinel-campaign/restart-proof.json']['exact_cold']
audit=json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(x['complete_track']for x in audit['classes'].values())
captures=proofs['capture'];assert len(captures['screenshots'])>=24
for image in captures['screenshots']:
 raw=(base/'captures'/image['file']).read_bytes();assert hashlib.sha256(raw).hexdigest()==image['sha256'];assert raw[:8]==b'\x89PNG\r\n\x1a\n';image['width'],image['height']=struct.unpack('>II',raw[16:24])
assert {x['width']for x in captures['screenshots']}=={640,1280,2560}
footers=proofs['input']['screenshots'];assert len(footers)==4
for image in footers:
 raw=(base/'mechanics'/image['file']).read_bytes();assert hashlib.sha256(raw).hexdigest()==image['sha256'];assert struct.unpack('>II',raw[16:24])==(image['width'],image['height'])
frozen=base/'frozen';out=checked_process([sys.executable,'tests/rules/run-tests.py'],cwd=ROOT,env=dict(os.environ,GAME32_EVIDENCE=str(frozen)),log=base/'frozen.log',timeout=600)
assert not out['exit_code']and not out['errors']and not out['timeout'];timings.append(dict(phase='frozen',**out))
proofs['frozen']=json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'));assert proofs['frozen']['checks']==22181 and not proofs['frozen']['failures']
launch=checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],cwd=dist,env=env,log=base/'production-launch.log',timeout=90)
assert not launch['exit_code']and not launch['errors']and not launch['timeout'];timings.append(dict(phase='production-launch',**launch));(base/'timings.json').write_text(json.dumps(timings,indent=2)+'\n',encoding='utf-8')
assert guard.verify_production()==scope and (ROOT/'data/rules/packs.json').read_bytes()==manifest
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
shutil.copy2(ROOT/'data/rules/packs.json',dist/'CHARACTER-RULES-MANIFEST.json');shutil.copy2(ROOT/'data/rules/trhgd-character-v35.json',dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text((ROOT/'docs/implementation/game123-final-prestige/PLAYTEST.txt').read_text(encoding='utf-8'),encoding='utf-8')
review=dist/'OPTIONAL-REVIEW-CAMPAIGN';review.mkdir(exist_ok=True)
original_save=base/'journeys/cohort-0/saves'/(j['slot']+'.json');assert hashlib.file_digest(original_save.open('rb'),'sha256').hexdigest()==proofs['portable']['source_save_sha256'];shutil.copy2(original_save,review/original_save.name)
for file in dist.glob('road-has-gone-dark-qa*'):file.unlink()
archive=release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED)as z:
 for file in dist.rglob('*'):
  if file.is_file():z.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive)as z:assert z.testzip()is None
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n',encoding='utf-8')
receipt=dict(acceptance_cohort='final-prestige',source_commit=commit,rules_ref=pin,archive=archive.name,sha256=sha,proofs=proofs,proof_sources={key:commit for key in proofs},timings=timings,captures=captures,source_guard=scope,empty_path=True,source_helper_override=False,production_launch=True,separate_process_restart=True,earned_characters=3,earned_xp=1960,earned_level=15,earned_prestige_caps={'eldritch-knight':5,'shadowdancer':10,'dwarven-defender':10},high_level_fixtures_not_earned=True)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(dict(archive=str(archive),sha256=sha),flush=True)
