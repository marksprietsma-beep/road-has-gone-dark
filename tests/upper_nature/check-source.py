"""Host/static guard; never runs Godot or a game on non-Windows hosts."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = '3e62d5cfc4959269f607ee7f64008842882f1c48'


def verify():
    rows = json.loads((ROOT/'tests/upper_nature/historical-pins.json').read_text(encoding='utf-8'))
    assert len(rows)==26
    manifest = json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'))
    original = json.loads(subprocess.check_output(['git','show',BASE+':data/rules/packs.json'], cwd=ROOT))
    assert manifest['packs'][:26]==original['packs']
    # This historical suite remains pinned to27 when later packs are appended.
    # Protect the exact released prefix/bytes rather than assuming it is last.
    released = json.loads(subprocess.check_output(['git','show','c48d6df:data/rules/packs.json'],cwd=ROOT))
    assert manifest['packs'][:27]==released['packs'] and len(manifest['packs'])>=27
    assert (ROOT/'data/rules/trhgd-character-v27.json').read_bytes()==subprocess.check_output(['git','show','c48d6df:data/rules/trhgd-character-v27.json'],cwd=ROOT)
    assert len({r['rules_ref']['pack_id']for r in manifest['packs']})==len(manifest['packs'])
    for appended in manifest['packs'][27:]:
        data=json.loads((ROOT/appended['path'].removeprefix('res://')).read_text(encoding='utf-8'))
        assert data['pack_id']==appended['rules_ref']['pack_id']
        assert hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==appended['rules_ref']['content_hash']
    for row in rows:
        content = (ROOT/row['path']).read_bytes()
        assert content==subprocess.check_output(['git','show',BASE+':'+row['path']], cwd=ROOT)
        assert hashlib.sha256(content).hexdigest()==row['sha256']
    before = json.loads((ROOT/'data/rules/trhgd-character-v26.json').read_text(encoding='utf-8'))
    after = json.loads((ROOT/'data/rules/trhgd-character-v27.json').read_text(encoding='utf-8'))
    delta = {}
    for category in ['classes','abilities','features','resources','statuses','ancestries','feats','equipment','creatures','psychic_powers','skills']:
        old = {r['id']:r for r in before[category]};new = {r['id']:r for r in after[category]}
        assert all(new[i]==v for i,v in old.items() if category!='features')
        assert set(old)<=set(new)
        delta[category] = sorted(set(new)-set(old))
        if category=='features':
            changed = [i for i in old if old[i]!=new[i]]
            assert set(changed)=={'sorcerer-casting-8','sorcerer-casting-9','druid-casting-8','druid-casting-9'}
            for i in changed:
                assert all(new[i][k]==v for k,v in old[i].items() if k not in ['abilities','resources'])
                assert new[i]['abilities'][:len(old[i]['abilities'])]==old[i]['abilities']
                assert new[i]['resources'][:len(old[i]['resources'])]==old[i]['resources']
    assert len(delta['abilities'])==4 and len(delta['resources'])==2 and len(delta['statuses'])==4
    assert all(not delta[c] for c in ['classes','ancestries','feats','equipment','creatures','psychic_powers','skills'])
    pin = next(r['rules_ref'] for r in manifest['packs'] if r['rules_ref']['pack_id']=='trhgd-character-v27')
    assert pin['pack_id']=='trhgd-character-v27'
    assert hashlib.sha256(json.dumps(after,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
    assert subprocess.check_output(['git','diff',BASE,'--','scripts/combat/tactical_combat.gd'],cwd=ROOT)==b''
    return dict(baseline=BASE,historical_packs=26,roster_unchanged=True,frozen_tactical_authority=True,delta=delta,rules_ref=pin)


if __name__=='__main__':
    print(json.dumps(verify(),indent=2))
