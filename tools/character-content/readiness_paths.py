"""Promote only the two existing paths from matching native acceptance evidence."""
from pathlib import Path
import copy,hashlib,json,subprocess,importlib.util

def generate(root,pack,pin,native_root):
    assert native_root is not None,'Matching native Windows evidence required'
    native=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
    assert native['acceptance_cohort']=='metamind-pyrokineticist'and native['rules_ref']==pin
    assert native['production_launch']and native['empty_path']and native['separate_process_restart']and not native['source_helper_override']
    source=native['source_commit'];proofs=native['proofs']
    assert not subprocess.check_output(['git','diff',source,'HEAD','--','scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg'],cwd=root)
    spec=importlib.util.spec_from_file_location('path_source_guard',root/'tests/psychic_paths/check-source.py')
    guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)
    assert guard.verify()==native['reused_previous_native']
    for phase in ['mechanics','journey','connected','current-support','legacy']:
        for file in ['proof.json','restart-proof.json']:
            key=phase+'/'+file;p=proofs[key]
            assert p['checks']>0 and p['failures']==0 and native['proof_sources'][key]==source
            if 'rules_ref'in p:assert p['rules_ref']==pin if phase!='legacy'else p['rules_ref']['pack_id']=='trhgd-character-v16'
    for key in ['input','current-support-input','frozen-rules']:
        assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and native['proof_sources'][key]==source
    assert proofs['frozen-rules']['checks']==22181
    mechanics=proofs['mechanics/proof.json'];assert set(mechanics['classes'])=={'metamind','pyrokineticist'}
    for cls in mechanics['classes']:
        assert all(mechanics['levels'][cls+str(at)]['prestige_levels']==at for at in range(11))
    assert set(mechanics['traces']['reserve'])=={'1','4','5','8','10'}
    assert set(mechanics['traces']['fire'])=={'1','4','7','10'}
    assert mechanics['traces']['counterplay']==dict(actual_fire_resistance=8,weakened_immunity=True,elemental_immunity_claimed=False)
    journey=proofs['journey/proof.json'];assert journey['earned_xp']==810 and journey['xp_injected']is False
    assert len(journey['journeys'])==3 and all(len(r['history'])==10 for r in journey['journeys'])
    assert [s['class_id']for s in journey['journeys'][0]['history']]==['psion']*8+['metamind']*2
    assert [s['class_id']for s in journey['journeys'][1]['history']]==['psion']*5+['pyrokineticist']*5
    assert journey['earned_entries']['metamind']['earned_xp']==640 and journey['earned_entries']['metamind']['next_level']==9
    assert journey['earned_entries']['pyrokineticist']['earned_xp']==250 and journey['earned_entries']['pyrokineticist']['next_level']==6
    connected=proofs['connected/proof.json'];assert connected['earned_xp_before_combat']==810 and connected['xp_injected']is False
    assert set(connected['casts'].values())=={'metamind-reclaim','pyrokineticist-technique-4','power-force-screen-aug2'}
    captures=native['captures'];assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=15
    for image in captures['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
    baseline=json.loads((root/'docs/implementation/game127-paths/evidence/readiness-v26-baseline.json').read_text(encoding='utf-8'))
    assert baseline['rules_ref']==pin and len(baseline['classes'])==50
    assert sum(row['status']=='COMPLETE'for row in baseline['classes'])==29
    rows=copy.deepcopy(baseline['classes'])
    for row in rows:
        if row['id']not in mechanics['classes']:continue
        row['status']='COMPLETE';row['remaining']=[];row['verified_source']=source
        row['status_scope']='Bounded original ten-level prestige identity: permanent optional earned entry, real finite resources/effects/counterplay, production controls and exact cold continuation. Human balance/usability remains separate.'
        row['advancement']['current_native_levels']=list(range(1,11))
        row['early_mid_high']['current_tactical']=True
        row['early_mid_high']['scope']='All ten lawful path levels; actual tactical1/4/7/10; total20 development histories. Genuine810XP/total10 gives Metamind2 and Pyrokineticist5, not earned20.'
        row['persistence']['current_native']=True
        row['evidence']+=['tests/psychic_paths/mechanics.gd','tests/psychic_paths/input.gd','tests/psychic_paths/journey.gd','tests/psychic_paths/connected.gd','docs/implementation/game127-paths/evidence/native-proof.json','docs/implementation/game127-paths/screenshots/README.md']
        row['acceptance_sources']={'current':source+' native two-path mechanics/controls/earned/connected/cold/render contracts.','retained':'Other career acceptance remains explicitly source-labelled v26 evidence, guarded by identical production inputs and frozen1–26 bytes/pins.'}
        row['limitations']=['Original finite shared psychic pool; independent arcane resources and owning-class power attributes.','Pyrokineticist uses save-based fire ignitions, not weapon-flame riders or a general elemental immunity system.','Natural-form suppression and existing art/scrolling limitations remain; GAME89/92/140 and human balance/readability are separate.']
    queue=[]
    for old in baseline['repair_queue']:
        q=copy.deepcopy(old);q['cohort']=[c for c in q['cohort']if c not in mechanics['classes']]
        if q['cohort']:q['priority']=len(queue)+1;queue.append(q)
    partial={r['id']for r in rows if r['status']=='PARTIAL'};queued=[c for q in queue for c in q['cohort']]
    assert set(queued)==partial and len(queued)==len(set(queued))
    statuses={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']}
    report=dict(baseline,classes=rows,repair_queue=queue,verified_source=source,milestone_complete=False,
                current_acceptance_cohort=mechanics['classes'],unchanged_runtime_native_inheritance=native['reused_previous_native'])
    out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    lines=['# Supported character readiness','','Matching-source native Windows evidence accepts the current two paths; unchanged v26 acceptance for other careers remains explicitly source-labelled. Technical COMPLETE does not replace human playtest acceptance or imply full sourcebook conversion.','',str(statuses),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
    for row in rows:lines.append('| '+row['name']+' | '+row['kind']+' | '+row['status']+' | '+' '.join(row['remaining'])+' |')
    lines+=['','## Finite exit plan','']
    for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
    lines+=['',report['exit_policy']];(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(dict(classes=len(rows),statuses=statuses)))
