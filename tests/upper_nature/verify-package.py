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
spec = importlib.util.spec_from_file_location('upper_nature_source', ROOT/'tests/upper_nature/check-source.py')
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)
source_guard = guard.verify()
base = Path(os.environ['UPPER_NATURE_RELEASE_ROOT']).resolve()
base.mkdir(parents=True, exist_ok=True)
release = base/'distribution'
release.mkdir(exist_ok=True)
name = 'sorcerer-druid-upper-tiers-windows-x64'
dist = release/name
commit = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()
manifest_bytes = (ROOT/'data/rules/packs.json').read_bytes()
pins = {r['rules_ref']['pack_id']:r['rules_ref'] for r in json.loads(manifest_bytes)['packs']}
pin = pins['trhgd-character-v27']
subprocess.run(['node','tools/release/export-game.mjs','--helper',os.environ['GAME76_HELPER_ROOT'],
                '--godot',os.environ['GODOT_BIN'],'--qa','--qa-scene','res://tests/upper_nature/review.tscn',
                '--output',str(dist)], cwd=ROOT, check=True)
env = dict(os.environ, PATH='', NODE_PATH='', NODE_OPTIONS='', UPPER_NATURE_ROOT=str(base/'mechanics'),
           UPPER_NATURE_CAPTURE_ROOT=str(base/'captures'), GAME126_JOURNEY_ROOT=str(base/'journeys'),
           GAME126_COHORT='0', GAME129_CONNECTED_ROOT=str(base/'connected'),
           GAME126_AUDIT_ROOT=str(base/'all-base'), GAME126_PACK='res://data/rules/trhgd-character-v27.json',
           GAME150_ROOT=str(base/'current-upper'), GAME127_PATH_ROOT=str(base/'historical26'),
           GAME133_ROOT=str(base/'historical18'), GAME126_REPAIR_ROOT=str(base/'legacy-v16'),
           GAME126_COMPATIBILITY_ROOT=str(base/'compatibility-v16'))
for key in ['GAME76_HELPER_ROOT','GODOT_BIN','GH_TOKEN','GITHUB_TOKEN']:
    env.pop(key, None)
timings = []
proofs = {}
phases = ['mechanics','input','journey','connected','capture','audit','current-upper','historical26','historical18','legacy','compatibility']
for phase in phases:
    for cold in ([False] if phase in ['input','capture'] else [False,True]):
        label = phase + ('-cold' if cold else '')
        active = dict(env, UPPER_NATURE_PHASE=phase)
        for key in ['UPPER_NATURE_RESTART','GAME127_PATH_RESTART','GAME150_RESTART','GAME133_RESTART','GAME126_AUDIT_RESTART','GAME129_RESTART']:
            active[key] = '1' if cold else '0'
        command = [str(dist/'road-has-gone-dark-qa.exe')]
        if phase!='capture':
            command.append('--headless')
        command += ['--audio-driver','Dummy']
        result = checked_process(command, cwd=dist, env=active, log=base/(label+'.log'), timeout=3600)
        timings.append(dict(phase=label, **result))
        (base/'timings.json').write_text(json.dumps(timings, indent=2)+'\n')
        print(json.dumps(timings[-1]), flush=True)
        assert not result['exit_code'] and not result['errors'] and not result['timeout'], (base/(label+'.log')).read_text(encoding='utf-8')[-18000:]
folders = [('mechanics','mechanics','v27'), ('journey','journeys/cohort-0','v27'),
           ('connected','connected','v27'), ('audit','all-base','v27'), ('current-upper','current-upper','v27'),
           ('historical26','historical26','v26'), ('historical18','historical18','v18'),
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
mechanics = proofs['mechanics/proof.json']
assert set(mechanics['new_spells'])=={'sorcerer-refraction-guard','sorcerer-cascade-well','druid-heartwood-renewal','druid-wildheart-mantle'}
assert all(mechanics['contracts'][key] is True for key in ['decoys','exchange','renewal','forms','permanent_choices','bloodlines','companions','hybrid'])
journey = proofs['journey/proof.json']
assert journey['earned_xp']==490 and journey['xp_injected'] is False and len(journey['journeys'])==3
assert {r['history'][0]['class_id'] for r in journey['journeys']}=={'sorcerer','druid','fighter'}
assert all(len(r['history'])==8 for r in journey['journeys'])
assert len(proofs['connected/proof.json']['casts'])==3 and proofs['connected/proof.json']['xp_injected'] is False
audit = json.loads((base/'all-base/witnesses.json').read_text(encoding='utf-8'))
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
shutil.copy2(ROOT/'data/rules/trhgd-character-v27.json', dist/'CORE-CHARACTER-CONTENT.json')
(dist/'START-HERE.txt').write_text('SORCERER AND DRUID UPPER TIERS\n\nExtract both ZIP layers; keep every support/helper/art/licence file together. Launch road-has-gone-dark.exe. No installed Godot or Node is needed; Escape skips intro.\n\nFresh campaigns use immutable v27. Existing saves retain their exact original pins; no migration or reset. Create Sorcerer (CHA) and Druid (WIS), learn permanent known spells or allocate prepared copies, earn XP normally, return home and advance deliberately. Tier8 unlocks at effective caster15, tier9 at17, with permanent CHA/WIS18/19. Total level alone is insufficient; hybrid tracks stay separate.\n\nSorcerer8 Refraction guard intercepts three weapon attempts; true sight and spells bypass, two global boundaries expire. Sorcerer9 Cascade well consumes one tier9 slot to recover up to two tier4 and one tier6 Sorcerer slots; never its own cost, other-class pools or new knowledge. Druid8 Heartwood renewal clears three root/slow statuses and heals12 at own activations while its finite boon survives. Druid9 Wildheart mantle gives a living ally/owned creature the existing bear form, actual natural attacks and equipment/casting suppression, preserving HP and identity. Revert costs one main action; expiry also restores equipment. No transformed casting, resurrection, flight or custom bear sprites.\n\nOrdinary acceptance campaigns earned490XP/level8. Upper tiers and total20 histories/screenshots are development fixtures, not claimed earned20. No XP button or QA executable ships. Save fully, exit/relaunch, Resume. Human balance/readability and existing nonhumanoid fallback remain separate.\n', encoding='utf-8')
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
receipt = dict(acceptance_cohort='sorcerer-druid-upper', source_commit=commit, rules_ref=pin,
    archive=archive.name, sha256=sha, proofs=proofs, proof_sources={key:commit for key in proofs},
    timings=timings, captures=captures, source_guard=source_guard, empty_path=True,
    source_helper_override=False, production_launch=True, separate_process_restart=True, earned_characters=3)
(base/'distribution-proof.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(dict(archive=str(archive), sha256=sha)), flush=True)
