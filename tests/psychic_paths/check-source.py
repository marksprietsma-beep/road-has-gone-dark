"""Static source/pin guard; this script never executes a game on the host."""
from pathlib import Path
import hashlib,json,subprocess

ROOT=Path(__file__).resolve().parents[2]
BASELINE='aab717eaf8ee1e59c5e8394920c6716aadb362ea'
NATIVE_SOURCE='e65d098a68858ef9247a7644a94b2485f671a323'

def verify():
    manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'))
    installed={row['rules_ref']['pack_id']:row for row in manifest['packs']}
    historical=json.loads((ROOT/'tests/psychic_paths/historical-pins.json').read_text(encoding='utf-8'))
    assert len(historical['packs'])==26
    for row in historical['packs']:
        assert hashlib.sha256((ROOT/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
        assert installed[row['rules_ref']['pack_id']]==dict(path='res://'+row['path'],rules_ref=row['rules_ref'])
    # No gameplay correction has been justified by this acceptance cohort.
    # Reuse prior native scopes only while every production input is identical.
    scopes=['scripts','data','scenes','assets','vendor','project.godot','export_presets.cfg']
    for source in [BASELINE,NATIVE_SOURCE]:
        assert subprocess.check_output(['git','diff',source,'HEAD','--']+scopes,cwd=ROOT)==b'',source
    previous=subprocess.check_output(['git','show',BASELINE+':tools/release/export-game.mjs'],cwd=ROOT,text=True,encoding='utf-8')
    current=(ROOT/'tools/release/export-game.mjs').read_text(encoding='utf-8')
    assert current.replace(",\x27res://tests/psychic_paths/review.tscn\x27",'')==previous,'Only the approved diagnostic entry may change exporter code'
    old=ROOT/'docs/implementation/game127-support/evidence/native-proof.json'
    old_blob=subprocess.check_output(['git','show',BASELINE+':'+str(old.relative_to(ROOT))],cwd=ROOT)
    assert json.loads(old.read_text(encoding='utf-8'))==json.loads(old_blob)
    receipt=json.loads(old.read_text(encoding='utf-8'));assert receipt['source_commit']==NATIVE_SOURCE
    assert receipt['production_launch']and receipt['empty_path']and receipt['separate_process_restart']
    assert all(p['checks']>0 and p['failures']==0 for p in receipt['proofs'].values())
    result=dict(baseline=BASELINE,previous_native_source=NATIVE_SOURCE,previous_native_run=39882645495,
                unchanged_production_scopes=scopes,historical_packs=26,exporter_delta='One approved diagnostic scene only',
                prior_native_receipt_sha256=hashlib.sha256(old_blob).hexdigest(),
                reuse_scope='Labelled prior v26 full-native historical/current acceptance only. This cohort must supply fresh mechanics, controls, earned/connected cold and renders.')
    return result

if __name__=='__main__':print(json.dumps(verify(),indent=2))
