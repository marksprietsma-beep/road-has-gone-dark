"""Promote Monk/Paladin only from unchanged-source native Windows evidence."""
import copy
import hashlib
import json
import subprocess


def generate(root, pack, pin, native_root):
    assert native_root is not None, 'Matching-source native Windows evidence required'
    native = json.loads((native_root / 'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort'] == 'monk-paladin' and native['rules_ref'] == pin
    assert native['production_launch'] and native['empty_path'] and native['separate_process_restart']
    assert not native['source_helper_override'] and native['high_level_fixtures_not_earned']
    source = native['source_commit']
    assert subprocess.check_output(['git', 'diff', source, 'HEAD', '--', 'scripts', 'data', 'scenes', 'assets', 'tests', 'tools', 'vendor', '.github', 'project.godot', 'export_presets.cfg'], cwd=root) == b'', 'Native inputs changed'
    proofs = native['proofs']
    for phase in ['mechanics', 'journey', 'connected', 'audit', 'current-upper', 'historical30', 'historical30-extended', 'historical29', 'historical18', 'legacy', 'compatibility']:
        for filename in ['proof.json', 'restart-proof.json']:
            key = phase + '/' + filename
            proof = proofs[key]
            assert proof['checks'] > 0 and proof['failures'] == 0 and native['proof_sources'][key] == source
            if 'rules_ref' in proof:
                version = {'historical30': 'v30', 'historical30-extended': 'v30', 'historical29': 'v29', 'historical18': 'v18', 'legacy': 'v16', 'compatibility': 'v16'}.get(phase, 'v31')
                pins = json.loads((root / 'data/rules/packs.json').read_text(encoding='utf-8'))['packs']
                assert proof['rules_ref'] == next(row['rules_ref'] for row in pins if row['rules_ref']['pack_id'] == 'trhgd-character-' + version)
    for key in ['pinned30-probe', 'input', 'historical30-input', 'frozen']:
        assert proofs[key]['checks'] > 0 and proofs[key]['failures'] == 0 and native['proof_sources'][key] == source
    assert proofs['frozen']['checks'] == 22181
    assert proofs['historical30-input']['suppressed_cases'] == 3 and proofs['historical30-input']['resisted_cases'] == 2
    assert all(proofs['mechanics/proof.json']['contracts'][key] is True for key in ['flurry', 'weapon_overrides', 'stances', 'smite', 'grace_healing', 'party_shelter', 'divine_casting', 'higher_tactical', 'resources', 'reaction_competition'])
    assert all(proofs['mechanics/proof.json']['outcomes'][key] > 0 for key in ['hits', 'misses', 'criticals'])
    journey = proofs['journey/proof.json']
    assert journey['earned_xp'] == 490 and not journey['xp_injected'] and len(journey['journeys']) == 3
    assert all(len(row['history']) == 8 for row in journey['journeys'])
    assert {row['role'] for row in journey['builds'].values()} == {'wind', 'mercy', 'justice'}
    primary = json.loads((native_root / 'journeys/cohort-0/saves' / (journey['slot'] + '.json')).read_text(encoding='utf-8'))
    assert primary['mechanics']['rules_ref'] == pin
    assert all(primary['mechanics']['records'][identity]['rules_ref'] == pin for identity in primary['party_ids'])
    assert set(proofs['connected/proof.json']['casts'].values()) == {'monk-wind-6', 'paladin-mercy-6', 'paladin-justice-6'}
    audit = json.loads((native_root / 'all-base/witnesses.json').read_text(encoding='utf-8'))
    assert len(audit['classes']) == 32 and all(row['complete_track'] for row in audit['classes'].values())
    captures = native['captures']
    assert captures['checks'] > 0 and captures['failures'] == 0 and len(captures['screenshots']) >= 18
    assert all(any(image['file'].startswith('fixture-' + power + '-combat-') for image in captures['screenshots']) for power in ['monk20', 'paladin20'])
    for image in captures['screenshots']:
        assert hashlib.sha256((native_root / 'captures' / image['file']).read_bytes()).hexdigest() == image['sha256']
    assert {image['width'] for image in captures['screenshots']} == {640, 1280, 2560}
    assert native['source_guard']['historical_pack_bytes_and_pins'] == 30
    receipt = json.loads((root / 'docs/implementation/game123-monk-paladin/READINESS-BASELINE.json').read_text(encoding='utf-8'))
    raw = subprocess.check_output(['git', 'show', receipt['source'] + ':' + receipt['path']], cwd=root)
    assert hashlib.sha256(raw).hexdigest() == receipt['sha256']
    baseline = json.loads(raw)
    assert len(baseline['classes']) == 50 and sum(row['status'] == 'COMPLETE' for row in baseline['classes']) == 39
    rows = copy.deepcopy(baseline['classes'])
    classes = {row['id']: row for row in pack['classes']}
    for row in rows:
        if row['id'] not in ['monk', 'paladin']:
            row['acceptance_carry_forward'] = dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior39 source-labelled accepted careers retained; current all-base20 and historical/frozen regression supplement rather than freshly reaccepting every career choice.')
            continue
        cls = classes[row['id']]
        row.update(status='COMPLETE', remaining=[], verified_source=source, level_cap=20, status_scope='Bounded original Monk/Paladin identities: actual effective-unarmed Flurry, paid ki disciplines and late palms; melee Smite, Charisma grace, healing/shelter, independent prepared divine resources and real multiclass casts. Finite resources, reaction/save counterplay, actual controls and exact cold continuation. Human balance remains separate.')
        row['previous_acceptance_pin'] = baseline['rules_ref']
        row['advancement'].update(cap=20, current_native_levels=list(range(1, 21)))
        row['defining_features'].update(description=cls['description'], source_features=sorted({feature['id'] for feature in cls['features']}))
        row['selections']['career_groups'] = [group['id'] for group in cls['career_choices']]
        row['early_mid_high'].update(current_tactical=True, scope='Lawful1/6/13/15/16/20 development histories and actual early/mid/late Flurry/stance/Smite/healing/party and spell outcomes, saves, misses, costs and counter-defeat. Separately three ordinary490XP/8 builds, connected paid Wind/Mercy/Justice, normal resolution and home recovery; no earned20 claim.')
        row['persistence']['current_native'] = True
        row['evidence'] += ['tests/monk_paladin/mechanics.gd', 'tests/monk_paladin/input.gd', 'tests/monk_paladin/journey.gd', 'tests/monk_paladin/connected.gd', 'docs/implementation/game123-monk-paladin/evidence/native-proof.json', 'docs/implementation/game123-monk-paladin/screenshots/README.md']
        row['limitations'] = ['Original bounded tactical adaptation, not exhaustive tabletop parity or final human balance.', 'Historical1–30 pins retain their exact original behavior and are never upgraded automatically.', 'Flurry requires an explicit current Unarmed loadout; manifestations and natural/held weapons do not qualify. Existing strict Monk armour rejection, including multiclass gear, is preserved. Global-round expiry and separate nonstacking buffers retain their existing policies. No alignment, pantheon or piety subsystem is claimed.', 'Long labels/small-screen usability and humanoid LPC fallbacks remain separate.']
    queue = []
    for item in baseline['repair_queue']:
        item = copy.deepcopy(item)
        item['cohort'] = [identity for identity in item['cohort'] if identity not in ['monk', 'paladin']]
        if item['cohort']:
            item['priority'] = len(queue) + 1
            queue.append(item)
    partial = {row['id'] for row in rows if row['status'] == 'PARTIAL'}
    assert {identity for item in queue for identity in item['cohort']} == partial and len(partial) == 9
    totals = {status: sum(row['status'] == status for row in rows) for status in ['COMPLETE', 'PARTIAL', 'BLOCKED']}
    assert totals == dict(COMPLETE=41, PARTIAL=9, BLOCKED=0)
    report = dict(baseline, classes=rows, rules_ref=pin, source_pack_sha256=hashlib.sha256((root / 'data/rules/trhgd-character-v31.json').read_bytes()).hexdigest(), repair_queue=queue, verified_source=source, current_acceptance_cohort=['monk', 'paladin'], milestone_complete=False, historical_acceptance_carry_forward=dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior39 source-labelled acceptance retained; only the current pair is promoted.'))
    out = root / 'docs/implementation/game129'
    (out / 'READINESS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    lines = ['# Supported character readiness', '', 'Matching-source native Windows accepts Monk and Paladin. Technical acceptance remains separate from human balance and research breadth.', '', str(totals), '', '| Career | Kind | Status | Remaining acceptance |', '|---|---|---|---|']
    lines += ['| ' + row['name'] + ' | ' + row['kind'] + ' | ' + row['status'] + ' | ' + ' '.join(row['remaining']) + ' |' for row in rows]
    lines += ['', '## Finite exit plan', '']
    lines += [str(item['priority']) + '. ' + ', '.join(item['cohort']) + ': ' + item['goal'] for item in queue]
    lines += ['', report['exit_policy']]
    (out / 'READINESS.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(dict(classes=50, statuses=totals)))
