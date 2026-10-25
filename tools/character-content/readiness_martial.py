"""Promote Fighter/Barbarian only from unchanged-source native Windows evidence."""
import copy
import hashlib
import json
import subprocess


def generate(root, pack, pin, native_root):
    assert native_root is not None, 'Matching-source native Windows evidence required'
    native = json.loads((native_root / 'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort'] == 'fighter-barbarian' and native['rules_ref'] == pin
    assert native['production_launch'] and native['empty_path'] and native['separate_process_restart']
    assert not native['source_helper_override'] and native['high_level_fixtures_not_earned']
    source = native['source_commit']
    assert subprocess.check_output(['git', 'diff', source, 'HEAD', '--', 'scripts', 'data', 'scenes', 'assets', 'tests', 'tools', 'vendor', '.github', 'project.godot', 'export_presets.cfg'], cwd=root) == b'', 'Native inputs changed'
    proofs = native['proofs']
    for phase in ['mechanics', 'extended', 'journey', 'connected', 'audit', 'current-upper', 'historical29', 'historical18', 'legacy', 'compatibility']:
        for filename in ['proof.json', 'restart-proof.json']:
            key = phase + '/' + filename
            proof = proofs[key]
            assert proof['checks'] > 0 and proof['failures'] == 0 and native['proof_sources'][key] == source
            if 'rules_ref' in proof:
                version = {'historical29': 'v29', 'historical18': 'v18', 'legacy': 'v16', 'compatibility': 'v16'}.get(phase, 'v30')
                pins = json.loads((root / 'data/rules/packs.json').read_text(encoding='utf-8'))['packs']
                assert proof['rules_ref'] == next(row['rules_ref'] for row in pins if row['rules_ref']['pack_id'] == 'trhgd-character-' + version)
    for key in ['pinned29-probe', 'input', 'frozen']:
        assert proofs[key]['checks'] > 0 and proofs[key]['failures'] == 0 and native['proof_sources'][key] == source
    assert proofs['frozen']['checks'] == 22181
    assert all(proofs['mechanics/proof.json']['contracts'][key] is True for key in ['training', 'equipment_disciplines', 'actual_attacks', 'resilient_mastery', 'rage_tradeoffs', 'resources_and_expiry', 'feat_choices', 'weapon_overrides'])
    assert all(proofs['extended/proof.json']['contracts'][key] is True for key in ['guard_reactions', 'power_strike', 'higher_features', 'exhaustion', 'exact_rage_duration', 'reaction_weapon'])
    outcomes = proofs['mechanics/proof.json']['attack_outcomes']
    assert all(outcomes[key] > 0 for key in ['hits', 'misses', 'criticals', 'changed_hits'])
    journey = proofs['journey/proof.json']
    assert journey['earned_xp'] == 490 and not journey['xp_injected'] and len(journey['journeys']) == 3
    assert all(len(row['history']) == 8 for row in journey['journeys'])
    assert {row['role'] for row in journey['builds'].values()} == {'blade', 'bow', 'rage'}
    primary = json.loads((native_root / 'journeys/cohort-0/saves' / (journey['slot'] + '.json')).read_text(encoding='utf-8'))
    assert primary['mechanics']['rules_ref'] == pin
    assert all(primary['mechanics']['records'][identity]['rules_ref'] == pin for identity in primary['party_ids'])
    assert set(proofs['connected/proof.json']['casts'].values()) == {'fighter-blade-6', 'fighter-bow-6', 'barbarian-resilient-6'}
    audit = json.loads((native_root / 'all-base/witnesses.json').read_text(encoding='utf-8'))
    assert len(audit['classes']) == 32 and all(row['complete_track'] for row in audit['classes'].values())
    captures = native['captures']
    assert captures['checks'] > 0 and captures['failures'] == 0 and len(captures['screenshots']) >= 18
    for image in captures['screenshots']:
        assert hashlib.sha256((native_root / 'captures' / image['file']).read_bytes()).hexdigest() == image['sha256']
    assert {image['width'] for image in captures['screenshots']} == {640, 1280, 2560}
    assert native['source_guard']['historical_pack_bytes_and_pins'] == 29
    receipt = json.loads((root / 'docs/implementation/game123-martial-acceptance/READINESS-BASELINE.json').read_text(encoding='utf-8'))
    raw = subprocess.check_output(['git', 'show', receipt['source'] + ':' + receipt['path']], cwd=root)
    assert hashlib.sha256(raw).hexdigest() == receipt['sha256']
    baseline = json.loads(raw)
    assert len(baseline['classes']) == 50 and sum(row['status'] == 'COMPLETE' for row in baseline['classes']) == 37
    rows = copy.deepcopy(baseline['classes'])
    classes = {row['id']: row for row in pack['classes']}
    for row in rows:
        if row['id'] not in ['fighter', 'barbarian']:
            row['acceptance_carry_forward'] = dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior37 source-labelled accepted careers retained; current all-base20 and historical/frozen regression supplement rather than freshly reaccepting every career choice.')
            continue
        cls = classes[row['id']]
        row.update(status='COMPLETE', remaining=[], verified_source=source, level_cap=20, status_scope='Bounded original martial identity: actual weapon/feat/gear choices, paid discipline/rage trade-offs, attack and protective reaction outcomes, finite resources/expiry/recovery, production controls and exact cold continuation. Human balance remains separate.')
        row['previous_acceptance_pin'] = baseline['rules_ref']
        row['advancement'].update(cap=20, current_native_levels=list(range(1, 21)))
        row['defining_features'].update(description=cls['description'], source_features=sorted({feature['id'] for feature in cls['features']}))
        row['selections']['career_groups'] = [group['id'] for group in cls['career_choices']]
        row['early_mid_high'].update(current_tactical=True, scope='Lawful1/6/15/20 development histories and actual early/mid/late weapon/rage outcomes, higher paid actions, crits/misses, armour/guard and effective-weapon overrides. Separately three ordinary490XP/8 campaign builds with connected combat, cold resolution and home recovery; no earned20 claim.')
        row['persistence']['current_native'] = True
        row['evidence'] += ['tests/martial_careers/mechanics.gd', 'tests/martial_careers/extended.gd', 'tests/martial_careers/input.gd', 'tests/martial_careers/journey.gd', 'tests/martial_careers/connected.gd', 'docs/implementation/game123-martial-acceptance/evidence/native-proof.json', 'docs/implementation/game123-martial-acceptance/screenshots/README.md']
        row['limitations'] = ['Original bounded tactical adaptation, not exhaustive tabletop parity or final human balance.', 'Historical1–29 pins retain their exact original behavior and are never upgraded automatically.', 'Disciplines require actual matching active equipment; natural/manifested attacks use their actual profiles. Existing paid Rage combinations, global-round expiry and independent temporary HP remain deliberate limits.', 'Long labels/small-screen usability and humanoid LPC fallbacks remain separate.']
    queue = []
    for item in baseline['repair_queue']:
        item = copy.deepcopy(item)
        item['cohort'] = [identity for identity in item['cohort'] if identity not in ['fighter', 'barbarian']]
        if item['cohort']:
            item['priority'] = len(queue) + 1
            queue.append(item)
    partial = {row['id'] for row in rows if row['status'] == 'PARTIAL'}
    assert {identity for item in queue for identity in item['cohort']} == partial and len(partial) == 11
    totals = {status: sum(row['status'] == status for row in rows) for status in ['COMPLETE', 'PARTIAL', 'BLOCKED']}
    assert totals == dict(COMPLETE=39, PARTIAL=11, BLOCKED=0)
    report = dict(baseline, classes=rows, rules_ref=pin, source_pack_sha256=hashlib.sha256((root / 'data/rules/trhgd-character-v30.json').read_bytes()).hexdigest(), repair_queue=queue, verified_source=source, current_acceptance_cohort=['fighter', 'barbarian'], milestone_complete=False, historical_acceptance_carry_forward=dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior37 source-labelled acceptance retained; only the current pair is promoted.'))
    out = root / 'docs/implementation/game129'
    (out / 'READINESS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    lines = ['# Supported character readiness', '', 'Matching-source native Windows accepts Fighter and Barbarian. Technical acceptance remains separate from human balance and research breadth.', '', str(totals), '', '| Career | Kind | Status | Remaining acceptance |', '|---|---|---|---|']
    lines += ['| ' + row['name'] + ' | ' + row['kind'] + ' | ' + row['status'] + ' | ' + ' '.join(row['remaining']) + ' |' for row in rows]
    lines += ['', '## Finite exit plan', '']
    lines += [str(item['priority']) + '. ' + ', '.join(item['cohort']) + ': ' + item['goal'] for item in queue]
    lines += ['', report['exit_policy']]
    (out / 'READINESS.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(dict(classes=50, statuses=totals)))
