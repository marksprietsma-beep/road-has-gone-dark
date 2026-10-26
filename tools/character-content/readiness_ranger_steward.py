"""Promote Ranger/Beast Steward only from unchanged-source native Windows evidence."""
import copy
import hashlib
import json
import subprocess


def generate(root, pack, pin, native_root):
    assert native_root is not None, 'Matching-source native Windows evidence required'
    native = json.loads((native_root / 'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort'] == 'ranger-steward' and native['rules_ref'] == pin
    assert native['production_launch'] and native['empty_path'] and native['separate_process_restart']
    assert not native['source_helper_override'] and native['high_level_fixtures_not_earned']
    source = native['source_commit']
    assert subprocess.check_output(['git', 'diff', source, 'HEAD', '--', 'scripts', 'data', 'scenes', 'assets', 'tests', 'tools', 'vendor', '.github', 'project.godot', 'export_presets.cfg'], cwd=root) == b'', 'Native inputs changed'
    proofs = native['proofs']
    for phase in ['mechanics', 'journey', 'connected', 'audit', 'current-upper', 'historical31', 'historical30', 'historical30-extended', 'historical29', 'historical18', 'legacy', 'compatibility']:
        for filename in ['proof.json', 'restart-proof.json']:
            key = phase + '/' + filename
            proof = proofs[key]
            assert proof['checks'] > 0 and proof['failures'] == 0 and native['proof_sources'][key] == source
            if 'rules_ref' in proof:
                version = {'historical31':'v31','historical30': 'v30', 'historical30-extended': 'v30', 'historical29': 'v29', 'historical18': 'v18', 'legacy': 'v16', 'compatibility': 'v16'}.get(phase, 'v32')
                pins = json.loads((root / 'data/rules/packs.json').read_text(encoding='utf-8'))['packs']
                assert proof['rules_ref'] == next(row['rules_ref'] for row in pins if row['rules_ref']['pack_id'] == 'trhgd-character-' + version)
    for key in ['pinned31-probe', 'input', 'historical31-input', 'historical30-input', 'frozen']:
        assert proofs[key]['checks'] > 0 and proofs[key]['failures'] == 0 and native['proof_sources'][key] == source
    assert proofs['frozen']['checks'] == 22181
    assert proofs['historical30-input']['suppressed_cases'] == 3 and proofs['historical30-input']['resisted_cases'] == 2
    assert all(proofs['mechanics/proof.json']['contracts'][key] is True for key in ['ranged_actions','style_limits','quarry','nature_casting','persistent_growth','prestige','commands','creature_actions','summons','owner_survival','late_progression'])
    assert all(proofs['mechanics/proof.json']['outcomes'][key] > 0 for key in ['hits', 'misses', 'criticals'])
    journey = proofs['journey/proof.json']
    assert journey['earned_xp'] == 490 and not journey['xp_injected'] and len(journey['journeys']) == 3
    assert all(len(row['history']) == 8 for row in journey['journeys'])
    assert {row['role'] for row in journey['builds'].values()} == {'archery','blade','steward'}
    assert journey['earned_entry']['earned_xp']==journey['earned_entry']['required_xp']==250 and all(journey['earned_entry']['alternatives'].values())
    assert len(journey['earned_entry']['original_history'])==5
    owned=proofs['connected/proof.json']['owned_action'];assert owned['before_hp']>owned['after_hp'] and owned['kind']=='attack'
    primary = json.loads((native_root / 'journeys/cohort-0/saves' / (journey['slot'] + '.json')).read_text(encoding='utf-8'))
    assert primary['mechanics']['rules_ref'] == pin
    assert all(primary['mechanics']['records'][identity]['rules_ref'] == pin for identity in primary['party_ids'])
    assert set(proofs['connected/proof.json']['casts'].values()) == {'ranger-archery-6','ranger-blade-6','steward-drive-3'}
    audit = json.loads((native_root / 'all-base/witnesses.json').read_text(encoding='utf-8'))
    assert len(audit['classes']) == 32 and all(row['complete_track'] for row in audit['classes'].values())
    captures = native['captures']
    assert captures['checks'] > 0 and captures['failures'] == 0 and len(captures['screenshots']) >= 18
    assert all(any(image['file'].startswith('fixture-' + power + '-combat-') for image in captures['screenshots']) for power in ['aimed2019','swiftsteward-drive-33'])
    for image in captures['screenshots']:
        assert hashlib.sha256((native_root / 'captures' / image['file']).read_bytes()).hexdigest() == image['sha256']
    assert {image['width'] for image in captures['screenshots']} == {640, 1280, 2560}
    assert native['source_guard']['historical_pack_bytes_and_pins'] == 31
    receipt = json.loads((root / 'docs/implementation/game123-ranger-steward/READINESS-BASELINE.json').read_text(encoding='utf-8'))
    raw = subprocess.check_output(['git', 'show', receipt['source'] + ':' + receipt['path']], cwd=root)
    assert hashlib.sha256(raw).hexdigest() == receipt['sha256']
    baseline = json.loads(raw)
    assert len(baseline['classes']) == 50 and sum(row['status'] == 'COMPLETE' for row in baseline['classes']) == 41
    rows = copy.deepcopy(baseline['classes'])
    classes = {row['id']: row for row in pack['classes']}
    for row in rows:
        if row['id'] not in ['ranger', 'beast-steward']:
            row['acceptance_carry_forward'] = dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior41 source-labelled accepted careers retained; current all-base20 and historical/frozen regression supplement rather than freshly reaccepting every career choice.')
            continue
        cls = classes[row['id']]
        row.update(status='COMPLETE', remaining=[], verified_source=source, level_cap=cls['max_level'], status_scope='Bounded Ranger/Beast Steward acceptance: actual ranged actions/style/quarry, prepared nature slots, permanent companion identity/growth/commands and survival, explicit earned prestige entry/decline, all five prestige levels and total20 development histories. Human balance remains separate.')
        row['previous_acceptance_pin'] = baseline['rules_ref']
        row['advancement'].update(cap=cls['max_level'], current_native_levels=list(range(1, cls['max_level']+1)), total_character_level_cap=20)
        features={feature['id']for feature in cls['features']}
        features.update(feature for group in cls['career_choices']for option in group['options']for feature in option['features'])
        row['defining_features'].update(description=cls['description'],source_features=sorted(features))
        row['current_kernel_evidence']='docs/implementation/game123-ranger-steward/evidence/native-track-index.json#classes/ranger'if row['id']=='ranger'else'docs/implementation/game123-ranger-steward/evidence/native-proof.json#mechanics/proof.json'
        row['selections']['career_groups'] = [group['id'] for group in cls['career_choices']]
        row['early_mid_high'].update(current_tactical=True, scope='Every Ranger level1–20, Swift/Enduring Steward1–5 and Ranger15/Steward5 development histories; positive/negative ranged, nature, command, creature and survival effects with finite costs/recovery/cold. Separately three ordinary490XP/total8 builds including earned250XP Ranger5 optional prestige entry/decline and eventual Steward3; actual pet attack, connected owner actions, resolution/home recovery. No earned20 or earned prestige5 claim.')
        row['persistence']['current_native'] = True
        row['evidence'] += ['tests/ranger_steward/mechanics.gd', 'tests/ranger_steward/input.gd', 'tests/ranger_steward/journey.gd', 'tests/ranger_steward/connected.gd', 'docs/implementation/game123-ranger-steward/evidence/native-proof.json', 'docs/implementation/game123-ranger-steward/screenshots/README.md']
        row['limitations'] = ['Original bounded tactical adaptation, not exhaustive tabletop parity or final human balance.', 'Historical1–31 campaigns retain exact pins/behavior without automatic upgrades.', 'Quarry uses existing humanoid raider and hostile ranged profiles, not an unimplemented monster taxonomy. Creature art remains labelled humanoid LPC fallback. Original global-round owner-defeat withdrawal and ally-wide Steward support remain; no new AI/ecology/pantheon system.', 'Long labels/small-screen presentation and the separate50-career browser redesign remain outside this cohort.']
        if row['id']=='beast-steward':
            row['prestige'].update(requirements=cls['requirements'], automatic_entry=False, starting_class=False, current_native=True, earned_entry_xp=250, earned_prestige_levels=3, development_prestige_levels=5)

    queue = []
    for item in baseline['repair_queue']:
        item = copy.deepcopy(item)
        item['cohort'] = [identity for identity in item['cohort'] if identity not in ['ranger', 'beast-steward']]
        if item['cohort']:
            item['priority'] = len(queue) + 1
            queue.append(item)
    partial = {row['id'] for row in rows if row['status'] == 'PARTIAL'}
    assert {identity for item in queue for identity in item['cohort']} == partial and len(partial) == 7
    totals = {status: sum(row['status'] == status for row in rows) for status in ['COMPLETE', 'PARTIAL', 'BLOCKED']}
    assert totals == dict(COMPLETE=43, PARTIAL=7, BLOCKED=0)
    report = dict(baseline, classes=rows, rules_ref=pin, source_pack_sha256=hashlib.sha256((root / 'data/rules/trhgd-character-v32.json').read_bytes()).hexdigest(), repair_queue=queue, verified_source=source, current_acceptance_cohort=['ranger', 'beast-steward'], milestone_complete=False, historical_acceptance_carry_forward=dict(pin=baseline['rules_ref'], source=baseline['verified_source'], scope='Prior41 source-labelled acceptance retained; only the current pair is promoted.'))
    out = root / 'docs/implementation/game129'
    (out / 'READINESS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    lines = ['# Supported character readiness', '', 'Matching-source native Windows accepts Ranger and Beast Steward. Technical acceptance remains separate from human balance and research breadth.', '', str(totals), '', '| Career | Kind | Status | Remaining acceptance |', '|---|---|---|---|']
    lines += ['| ' + row['name'] + ' | ' + row['kind'] + ' | ' + row['status'] + ' | ' + ' '.join(row['remaining']) + ' |' for row in rows]
    lines += ['', '## Finite exit plan', '']
    lines += [str(item['priority']) + '. ' + ', '.join(item['cohort']) + ': ' + item['goal'] for item in queue]
    lines += ['', report['exit_policy']]
    (out / 'READINESS.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(dict(classes=50, statuses=totals)))
