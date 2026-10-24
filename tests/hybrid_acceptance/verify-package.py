"""One stable, complete Windows release; no Linux game execution or hidden reuse."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import zipfile

assert os.name=='nt', 'Native Windows validation only'
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tests/character_psychic'))
from checked_process import checked_process
spec = importlib.util.spec_from_file_location('hybrid_source', ROOT/'tests/hybrid_acceptance/check-source.py')
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)
source_guard = guard.verify()
base = Path(os.environ['HYBRID_RELEASE_ROOT']).resolve()
base.mkdir(parents=True, exist_ok=True)
release = base/'distribution'
release.mkdir(exist_ok=True)
name = 'duskblade-archmage-windows-x64'
dist = release/name
commit = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()
manifest_bytes = (ROOT/'data/rules/packs.json').read_bytes()
pins = {r['rules_ref']['pack_id']:r['rules_ref'] for r in json.loads(manifest_bytes)['packs']}
pin = pins['trhgd-character-v28']
from earned_import import prepare
reuse=prepare(ROOT,base,pin)
imported=reuse['imported'];earned_source=reuse['source'];earned_run=reuse['run']
protected=reuse['protected'];source_proofs=reuse['proofs'];source_timings=reuse['timings']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],
                '--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/hybrid_acceptance/review.tscn',
                '--output',str(dist)], cwd=ROOT, check=True)
env = dict(os.environ, PATH='', NODE_PATH='', NODE_OPTIONS='', HYBRID_ROOT=str(base/'mechanics'),
           HYBRID_CAPTURE_ROOT=str(base/'captures'), GAME126_JOURNEY_ROOT=str(base/'journeys'),
           GAME126_COHORT='0', GAME126_RESUME='1', HYBRID_IMPORTED_EARNED=str(imported), GAME129_CONNECTED_ROOT=str(base/'connected'),
           GAME126_AUDIT_ROOT=str(base/'all-base'), GAME126_PACK='res://data/rules/trhgd-character-v28.json',
           GAME150_ROOT=str(base/'current-upper'), UPPER_NATURE_ROOT=str(base/'historical27'),
           GAME133_ROOT=str(base/'historical18'), GAME126_REPAIR_ROOT=str(base/'legacy-v16'),
           GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:
    env.pop(key, None)
timings = []
proofs = {}
phases = ['probe','earned_probe','mechanics','input','journey','connected','capture','audit','current-upper','historical27','historical18','legacy','compatibility']
for phase in phases:
    for cold in ([False] if phase in ['probe','input','capture'] else [False,True]):
        label = phase + ('-cold' if cold else '')
        active = dict(env, HYBRID_PHASE=phase)
        for key in ['HYBRID_RESTART','UPPER_NATURE_RESTART','GAME150_RESTART','GAME133_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART']:
            active[key] = '1' if cold else '0'
        command = [str(dist/'road-has-gone-dark-qa.exe')]
        if phase!='capture':
            command.append('--headless')
        command += ['--audio-driver','Dummy']
        result = checked_process(command, cwd=dist, env=active, log=base/(label+'.log'), timeout=7200 if phase=='journey' else 3600)
        timings.append(dict(phase=label, **result))
        (base/'timings.json').write_text(json.dumps(timings, indent=2)+'\n',encoding='utf-8')
        print(json.dumps(timings[-1]), flush=True)
        assert not result['exit_code'] and not result['errors'] and not result['timeout'], (base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
folders = [('mechanics','mechanics','v28'), ('journey','journeys/cohort-0','v28'),
           ('connected','connected','v28'), ('audit','all-base','v28'), ('current-upper','current-upper','v28'),
           ('historical27','historical27','v27'), ('historical18','historical18','v18'),
           ('legacy','legacy-v16','v16'), ('compatibility','compatibility-v16','v16')]
for phase, folder, version in folders:
    for file in ['proof.json','restart-proof.json']:
        p = json.loads((base/folder/file).read_text(encoding='utf-8'))
        assert p['checks']>0 and p['failures']==0, (phase,file)
        if 'rules_ref' in p:
            assert p['rules_ref']==pins['trhgd-character-'+version], (phase,file)
        proofs[phase+'/'+file] = p
controls = json.loads((base/'mechanics/input-proof.json').read_text(encoding='utf-8'))
assert controls['checks']>0 and controls['failures']==0
proofs['input'] = controls
probe = json.loads((base/'mechanics/probe-proof.json').read_text(encoding='utf-8'))
assert probe['checks']>0 and probe['failures']==0
proofs['pinned27-probe'] = probe
for key,file in [('planner','planner-proof.json'),('planner-cold','planner-restart-proof.json')]:
    p=json.loads((base/'mechanics'/file).read_text(encoding='utf-8'));assert p['checks']>0 and p['failures']==0 and p['rules_ref']==pin;proofs[key]=p
mechanics = proofs['mechanics/proof.json']
assert mechanics['contracts']['channels']==10
assert all(mechanics['contracts'][key] is True for key in ['multiclass','refraction','high_arcana','ward_progression','existing_beguiler_route','independent_archmage_tracks','permanent_entry','body_suppression','resources'])
journey = proofs['journey/proof.json']
assert journey['earned_xp']==1960 and journey['native_earned_xp']==270 and journey['source_import']['original_earned_xp']==1690 and journey['xp_injected'] is False and len(journey['journeys'])==3
assert {r['history'][0]['class_id'] for r in journey['journeys']}=={'duskblade','wizard','sorcerer'}
assert all(len(r['history'])==15 for r in journey['journeys'])
assert set(journey['earned_entry_witnesses'])=={'wizard','sorcerer'}
assert set(proofs['connected/proof.json']['casts'].values())=={'channel-duskblade-searing-grasp','high-arcana-force-1','high-arcana-ward-1'}
audit = json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'))
for file,sha in protected.items():assert hashlib.sha256((imported/file).read_bytes()).hexdigest()==sha
assert len(audit['classes'])==32 and all(r['complete_track'] for r in audit['classes'].values())
captures = json.loads((base/'captures/screenshots.json').read_text(encoding='utf-8'))
assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=18
for image in captures['screenshots']:
    assert hashlib.sha256((base/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
frozen = base/'frozen'
result = checked_process([sys.executable,'tests/rules/run-tests.py'], cwd=ROOT,
    env=dict(os.environ, GAME32_EVIDENCE=str(frozen)), log=base/'frozen.log', timeout=600)
assert not result['exit_code'] and not result['errors'] and not result['timeout']
proofs['frozen'] = json.loads((frozen/'kernel-results.json').read_text(encoding='utf-8'))
assert proofs['frozen']['checks']==22181 and proofs['frozen']['failures']==0
assert guard.verify()==source_guard
assert (ROOT/'data/rules/packs.json').read_bytes()==manifest_bytes
assert subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()==commit
assert json.loads((dist/'distribution.json').read_text(encoding='utf-8'))['source_commit']==commit
result = checked_process([str(dist/'road-has-gone-dark.exe'),'--headless','--audio-driver','Dummy','--quit-after','30'],
    cwd=dist, env=env, log=base/'production-launch.log', timeout=90)
assert not result['exit_code'] and not result['errors'] and not result['timeout']
shutil.copy2(ROOT/'data/rules/packs.json', dist/'CHARACTER-RULES-MANIFEST.json')
shutil.copy2(ROOT/'data/rules/trhgd-character-v28.json', dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('DUSKBLADE AND ARCHMAGE ACCEPTANCE\n\nExtract both ZIP layers, retaining every file. Launch road-has-gone-dark.exe. No installed Godot or Node is needed; Escape skips intro. Fresh campaigns use v28; existing saves keep their exact original rules pins.\n\nDuskblade: create with INT for casting and a melee weapon. Select original known spells, not separate channel wrappers. From class3 channel a known single-target enemy spell through an adjacent weapon attack: one main action and its original Duskblade slot are spent even on a miss; only a hit delivers the spell. Bow, range, exhausted slots, spent actions and concealment retain their real restrictions. Later tiers unlock at class5/9/13/17; Wizard multiclass pools remain independent.\n\nArchmage is earned optional advancement, never a starting class or an automatic award. Meet permanent level13, Arcana10, Spellcraft10, the actual Spell focus / Greater spell focus feat chain, and genuine arcane tier7 access (known for spontaneous casters). Earn1690XP through objectives to fund total14. At home select Archmage deliberately, choose the parent casting track and Force or Ward. Continue the base class instead if desired. Path maximum5.\n\nForce uses the selected Wizard/Beguiler INT or Sorcerer CHA. Advanced powers spend one main action and finite high-arcana use. Existing forms which suppress supernatural casting also suppress these abilities. Ward1 protects; Ward3 additionally clears Weakened and Arcane tether; Ward5 additionally clears Slowed, Unsteady concentration and Stillness lattice. Other effects remain; no healing, resurrection, free actions or restored slots. The three-boundary ward status and separate nonstacking temporary-HP buffer follow existing policies. Eligible home return restores resources.\n\nAcceptance first earned1690XP/level14 in Windows source Godot, with explicit Wizard/Sorcerer Archmage1. The exported executable loaded that unchanged save and earned270 additional XP through real opportunities, funding1960XP/level15 and Archmage2. These evidence scopes are separate. Total20/path5 and attack-roll/status screenshots are labelled development fixtures, not claimed earned20. Save completely, exit, relaunch and Resume. No QA executable or XP button ships. GAME89/92 combat usability and GAME140 humanoid art fallbacks remain separate.\n', encoding='utf-8')
for file in dist.glob('road-has-gone-dark-qa*'):
    file.unlink()
archive = release/(name+'.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as zipped:
    for file in dist.rglob('*'):
        if file.is_file():
            zipped.write(file,Path(name)/file.relative_to(dist))
with zipfile.ZipFile(archive) as zipped:
    assert zipped.testzip() is None
sha = hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()
Path(str(archive)+'.sha256').write_text(sha+'  '+archive.name+'\n')
receipt = dict(acceptance_cohort='duskblade-archmage', source_commit=commit, rules_ref=pin,
    archive=archive.name, sha256=sha, proofs=proofs, proof_sources={key:commit for key in proofs},
    timings=timings, captures=captures, source_guard=source_guard, reused_source_earned=dict(run_id=earned_run,source_commit=earned_source,original_xp=1690,native_additional_xp=270,raw_files_unchanged=protected,proofs=source_proofs,timings=source_timings), empty_path=True,
    source_helper_override=False, production_launch=True, separate_process_restart=True, earned_characters=3)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(archive=str(archive), sha256=sha)), flush=True)
