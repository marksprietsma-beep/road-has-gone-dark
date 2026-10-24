"""Evidence-gated two-career promotion; historical acceptance remains source-labelled."""
import copy
import hashlib
import json
import subprocess


def generate(root, pack, pin, native_root):
    assert native_root is not None, 'Matching native Windows release required'
    native = json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort']=='sorcerer-druid-upper' and native['rules_ref']==pin
    assert native['production_launch'] and native['empty_path'] and native['separate_process_restart'] and not native['source_helper_override']
    source = native['source_commit']
    assert subprocess.check_output(['git','diff',source,'HEAD','--','scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg'],cwd=root)==b''
    for phase in ['mechanics','journey','connected','audit','current-upper','historical26','historical18','legacy','compatibility']:
        for file in ['proof.json','restart-proof.json']:
            key = phase+'/'+file
            row = native['proofs'][key]
            assert row['checks']>0 and row['failures']==0 and native['proof_sources'][key]==source
            if phase in ['mechanics','journey','connected','audit','current-upper']:
                assert row['rules_ref']==pin
    for key in ['input','frozen']:
        assert native['proofs'][key]['checks']>0 and native['proofs'][key]['failures']==0
    assert native['proofs']['frozen']['checks']==22181
    mechanics = native['proofs']['mechanics/proof.json']
    assert set(mechanics['classes'])=={'sorcerer','druid'}
    assert all(mechanics['contracts'][key] is True for key in ['decoys','exchange','renewal','forms','permanent_choices','bloodlines','companions','hybrid'])
    assert mechanics['contracts']['owned_forms']>=4
    journey = native['proofs']['journey/proof.json']
    assert journey['earned_xp']==490 and journey['xp_injected'] is False and len(journey['journeys'])==3
    assert all(len(row['history'])==8 for row in journey['journeys'])
    assert set(native['proofs']['connected/proof.json']['casts'].values())=={'sorcerer-draconic-6','druid-growth-6','attack'}
    captures = native['captures']
    assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=18
    for image in captures['screenshots']:
        assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
    baseline_path = root/'docs/implementation/game133-upper/READINESS-V26-BASELINE.json'
    baseline = json.loads(baseline_path.read_text(encoding='utf-8'))
    original = json.loads(subprocess.check_output(['git','show','3e62d5cfc4959269f607ee7f64008842882f1c48:docs/implementation/game129/READINESS.json'],cwd=root))
    assert baseline==original and len(baseline['classes'])==50
    assert sum(row['status']=='COMPLETE' for row in baseline['classes'])==31
    rows = copy.deepcopy(baseline['classes'])
    for row in rows:
        if row['id'] not in ['sorcerer','druid']:
            row['acceptance_carry_forward'] = dict(pin=baseline['rules_ref'],source=baseline['verified_source'],
                scope='Retained source-labelled prior acceptance, unchanged career definitions; fresh v27 all-base20 audit/current Wizard-Cleric and frozen/historical checks supplement it. Not every other career choice freshly reaccepted.')
            continue
        row.update(status='COMPLETE',remaining=[],verified_source=source,
            status_scope='Bounded supported original identity: executable upper tiers, permanent known/prepared and bloodline/nature choices, actual creatures/forms/resources/counterplay, production controls and cold continuation. Not exhaustive tabletop conversion or human balance.')
        row['previous_acceptance_pin'] = baseline['rules_ref']
        row['advancement']['current_native_levels'] = list(range(1,21))
        row['early_mid_high'].update(current_tactical=True,scope='Actual1/6/20 specialisations, tier8/9 unlock/score boundaries and real effects; lawful total20/hybrid17/7 development fixtures. Separate ordinary490XP/8 journeys, not earned20.')
        row['persistence']['current_native'] = True
        row['evidence'] += ['tests/upper_nature/mechanics.gd','tests/upper_nature/input.gd','tests/upper_nature/journey.gd','tests/upper_nature/connected.gd','docs/implementation/game133-upper/evidence/native-proof.json','docs/implementation/game133-upper/screenshots/README.md']
        row['limitations'] = ['Finite original tactical repertoire, not full sourcebook spell conversion.','Transformed casting is unsupported; creature/form art remains the existing labelled humanoid fallback.','Human balance/readability, scrolling and GAME89/92/140 remain separate.']
    queue = []
    for old in baseline['repair_queue']:
        item = copy.deepcopy(old)
        item['cohort'] = [c for c in item['cohort'] if c not in ['sorcerer','druid']]
        if item['cohort']:
            item['priority'] = len(queue)+1
            queue.append(item)
    partial = {r['id'] for r in rows if r['status']=='PARTIAL'}
    assert {c for q in queue for c in q['cohort']}==partial
    report = dict(baseline,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v27.json').read_bytes()).hexdigest(),repair_queue=queue,verified_source=source,current_acceptance_cohort=['sorcerer','druid'],milestone_complete=False)
    report.pop('unchanged_runtime_native_inheritance',None)
    report['historical_acceptance_carry_forward'] = dict(source=baseline['verified_source'],pin=baseline['rules_ref'],scope='Prior evidence remains labelled. New27 has narrowly scoped additions; no claim that all production inputs are identical to26 or every career was freshly accepted.')
    out = root/'docs/implementation/game129'
    (out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n')
    totals = {s:sum(r['status']==s for r in rows) for s in ['COMPLETE','PARTIAL','BLOCKED']}
    lines = ['# Supported character readiness','','Matching-source native Windows evidence accepts Sorcerer/Druid upper tiers. Other career acceptance remains source-labelled, with fresh all-base20 and relevant legacy/current regressions. Technical COMPLETE is separate from human playtest acceptance and sourcebook breadth.','',str(totals),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
    for row in rows:
        lines.append('| '+row['name']+' | '+row['kind']+' | '+row['status']+' | '+' '.join(row['remaining'])+' |')
    lines += ['','## Finite exit plan','']
    for q in queue:
        lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
    lines += ['',report['exit_policy']]
    (out/'READINESS.md').write_text('\n'.join(lines)+'\n')
    print(json.dumps(dict(classes=len(rows),statuses=totals)))
