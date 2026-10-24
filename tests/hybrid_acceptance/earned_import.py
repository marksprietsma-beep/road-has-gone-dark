"""Read/guard successful source-earned evidence; no gameplay or alternate writer."""
from pathlib import Path
import os,json,shutil,hashlib,subprocess

def prepare(root,base,pin):
    # Exact-source reuse, explicitly source evidence: original1690XP is never
    # represented as exported-native earning. The executable earns270 more itself.
    earned_source=os.environ['HYBRID_EARNED_SOURCE'];earned_run=int(os.environ['HYBRID_EARNED_RUN'])
    protected_inputs=['scripts','data','scenes','assets','vendor','project.godot','export_presets.cfg','tools/release/export-game.mjs','tests/hybrid_acceptance/journey.gd','tests/hybrid_acceptance/connected.gd','tests/nature_repertoires/journey_driver.gd','tests/nature_repertoires/caster_planner.gd','tests/character_completeness/prestige_driver.gd','tests/adventure_cycles/earned_driver.gd']
    assert subprocess.check_output(['git','diff',earned_source,'HEAD','--',*protected_inputs],cwd=root)==b'', 'Source earned runtime/planner changed'
    imported=base/'source-earned'
    shutil.copytree(Path(os.environ['HYBRID_IMPORTED_INPUT'])/'hybrid-earned',imported)
    protected={str(p.relative_to(imported)):hashlib.sha256(p.read_bytes()).hexdigest()for p in imported.rglob('*.json')}
    source_proofs={}
    for folder in ['journeys/cohort-0','connected']:
        for file in ['proof.json','restart-proof.json']:
            row=json.loads((imported/folder/file).read_text(encoding='utf-8'));assert row['checks']>0 and row['failures']==0;source_proofs[folder+'/'+file]=row
    paid=source_proofs['journeys/cohort-0/proof.json'];assert paid['rules_ref']==pin and paid['earned_xp']==1690 and paid['xp_injected'] is False and set(paid['earned_entry_witnesses'])=={'wizard','sorcerer'}
    assert all(len(r['history'])==14 for r in paid['journeys'])
    source_timings=json.loads((imported/'timings.json').read_text(encoding='utf-8'));assert {r['phase']for r in source_timings}=={'journey','journey-cold','connected','connected-cold'} and all(r['exit_code']==0 and not r['errors'] and not r['timeout'] for r in source_timings)
    # Restore absent checksum sidecars only in isolated copies, retaining raw bytes.
    original=imported/'journeys/cohort-0';target=base/'journeys/cohort-0';target.mkdir(parents=True)
    for folder in ['cache','library','failed-check']:
        if (original/folder).exists():shutil.copytree(original/folder,target/folder)
    for file in original.glob('earned-qualified-*.json'):shutil.copy2(file,target/file.name)
    for path in target.glob('cache/**/*.json'):
        if not Path(str(path)+'.sha').exists():Path(str(path)+'.sha').write_text(hashlib.sha256(path.read_bytes()).hexdigest(),encoding='utf-8')
    return dict(imported=imported,source=earned_source,run=earned_run,protected=protected,proofs=source_proofs,timings=source_timings)
