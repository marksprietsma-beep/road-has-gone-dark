"""Two-career evidence gate. Reading receipts here never executes the game."""
import copy
import hashlib
import json
import subprocess


def generate(root, pack, pin, native_root):
    assert native_root is not None, 'Matching-source native Windows evidence required'
    native = json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort']=='duskblade-archmage' and native['rules_ref']==pin
    assert native['production_launch'] and native['empty_path'] and native['separate_process_restart'] and not native['source_helper_override']
    source = native['source_commit']
    assert subprocess.check_output(['git','diff',source,'HEAD','--','scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg'],cwd=root)==b'', 'Native build inputs changed after verification'
    for phase in ['mechanics','journey','connected','audit','current-upper','historical27','historical18','legacy','compatibility']:
        for file in ['proof.json','restart-proof.json']:
            key=phase+'/'+file;row=native['proofs'][key]
            assert row['checks']>0 and row['failures']==0 and native['proof_sources'][key]==source
            if phase in ['mechanics','journey','connected','audit','current-upper']:
                if key=='journey/restart-proof.json':
                    assert set(row)=={'checks','failures'}
                    warm=native['proofs']['journey/proof.json']
                    saved=json.loads((native_root/'journeys/cohort-0/saves'/(warm['slot']+'.json')).read_text(encoding='utf-8'))
                    assert saved['mechanics']['rules_ref']==pin
                    assert all(saved['mechanics']['records'][id]['rules_ref']==pin for id in saved['party_ids'])
                else:assert row['rules_ref']==pin
    for key in ['input','frozen','pinned27-probe','planner','planner-cold','entry','entry-cold']:
        assert native['proofs'][key]['checks']>0 and native['proofs'][key]['failures']==0
    assert native['proofs']['frozen']['checks']==22181
    contracts=native['proofs']['mechanics/proof.json']['contracts']
    assert contracts['channels']==10 and all(contracts[k] is True for k in ['multiclass','refraction','high_arcana','ward_progression','existing_beguiler_route','independent_archmage_tracks','permanent_entry','body_suppression','resources'])
    journey=native['proofs']['journey/proof.json']
    assert journey['earned_xp']==1960 and journey['native_earned_xp']==270 and journey['source_import']['original_earned_xp']==1690 and journey['xp_injected'] is False and len(journey['journeys'])==3
    assert all(len(r['history'])==15 for r in journey['journeys'])
    assert set(journey['earned_entry_witnesses'])=={'wizard','sorcerer'}
    for cls,w in journey['earned_entry_witnesses'].items():
        assert w['current_level']==13 and w['next_level']==14 and w['earned_xp']==1690 and w['class_assigned'] is False
    for row in journey['journeys']:
        if row['history'][0]['class_id'] in ['wizard','sorcerer']:
            assert row['history'][-1]['class_id']=='archmage'
            assert sum(s['class_id']=='archmage' for s in row['history'])==2
    reused=native['reused_source_earned'];assert reused['original_xp']==1690 and reused['native_additional_xp']==270
    assert all(r['checks']>0 and r['failures']==0 for r in reused['proofs'].values())
    for file,sha in reused['raw_files_unchanged'].items():assert hashlib.sha256((native_root/'source-earned'/file).read_bytes()).hexdigest()==sha
    assert set(native['proofs']['connected/proof.json']['casts'].values())=={'channel-duskblade-searing-grasp','high-arcana-force-1','high-arcana-ward-1'}
    captures=native['captures'];assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=21
    for image in captures['screenshots']:
        assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
    assert native['source_guard']['historical_pack_bytes_and_pins']==27
    baseline=json.loads((root/'docs/implementation/game123-hybrids/READINESS-V27-BASELINE.json').read_text(encoding='utf-8'))
    original=json.loads(subprocess.check_output(['git','show','c48d6df:docs/implementation/game129/READINESS.json'],cwd=root))
    assert baseline==original and len(baseline['classes'])==50
    assert sum(r['status']=='COMPLETE'for r in baseline['classes'])==33
    rows=copy.deepcopy(baseline['classes'])
    for row in rows:
        if row['id'] not in ['duskblade','archmage']:
            row['acceptance_carry_forward']=dict(pin=baseline['rules_ref'],source=baseline['verified_source'],scope='Retained prior source-labelled acceptance. Fresh v28 all-base20/current upper, pinned27/18/16 and frozen regression supplement it; not all other career choices freshly reaccepted.')
            continue
        row.update(status='COMPLETE',remaining=[],verified_source=source,status_scope='Bounded supported original identity, actual choices/costs/targets/counterplay, production controls, legitimate earned advancement and exact cold continuation. Not exhaustive tabletop conversion or human balance.')
        row['previous_acceptance_pin']=baseline['rules_ref']
        row['advancement']['current_native_levels']=list(range(1,21)) if row['id']=='duskblade' else list(range(1,6))
        row['early_mid_high'].update(current_tactical=True,scope='Duskblade1/3/5/9/13/17/20 and all10 original legal channels; Archmage every supported path level1–5, Wizard/Sorcerer total20 and existing Beguiler14/Arch5 integration. Development fixtures, separate source1690XP/14 and exported-native additional270XP/1960XP total15 paths.')
        row['persistence']['current_native']=True
        row['evidence']+=['tests/hybrid_acceptance/mechanics.gd','tests/hybrid_acceptance/input.gd','tests/hybrid_acceptance/journey.gd','tests/hybrid_acceptance/connected.gd','docs/implementation/game123-hybrids/evidence/native-proof.json','docs/implementation/game123-hybrids/screenshots/README.md']
        row['limitations']=['Finite original tactical adaptations, not a full tabletop repertoire conversion.','Historical pins retain original mechanics, including prior advanced DC/body/Ward behavior. No automatic migration.','Human balance/readability and GAME89/92/140 remain separate.']
    queue=[]
    for old in baseline['repair_queue']:
        item=copy.deepcopy(old);item['cohort']=[c for c in item['cohort']if c not in ['duskblade','archmage']]
        if item['cohort']:item['priority']=len(queue)+1;queue.append(item)
    partial={r['id']for r in rows if r['status']=='PARTIAL'}
    assert {c for q in queue for c in q['cohort']}==partial and len(partial)==15
    report=dict(baseline,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v28.json').read_bytes()).hexdigest(),repair_queue=queue,verified_source=source,current_acceptance_cohort=['duskblade','archmage'],milestone_complete=False)
    report['historical_acceptance_carry_forward']=dict(source=baseline['verified_source'],pin=baseline['rules_ref'],scope='Source-labelled prior33 accepted careers. Older pack bytes/pins and original action/RNG/save authorities are unchanged. No claim that all gameplay inputs are identical to27 or every other career freshly accepted.')
    out=root/'docs/implementation/game129'
    (out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    totals={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']}
    lines=['# Supported character readiness','','Matching-source native Windows evidence accepts Duskblade/Archmage. Other career acceptance remains source-labelled; technical COMPLETE remains separate from human playtest and sourcebook breadth.','',str(totals),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
    for row in rows:lines.append('| '+row['name']+' | '+row['kind']+' | '+row['status']+' | '+' '.join(row['remaining'])+' |')
    lines+=['','## Finite exit plan','']
    for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
    lines+=['',report['exit_policy']]
    (out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print(json.dumps(dict(classes=len(rows),statuses=totals)))
