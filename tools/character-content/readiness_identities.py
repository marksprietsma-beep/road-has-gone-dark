"""Evidence-gated v25 continuation of the finite50-career acceptance matrix."""
from pathlib import Path
import copy,hashlib,json,subprocess

def generate(root,pack,pin,native_root):
 assert native_root is not None,'No v25 promotion without complete native Windows evidence'
 native=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
 assert native['rules_ref']==pin and native['production_launch']and native['separate_process_restart']and native['empty_path']
 proofs=native['proofs'];source=native['source_commit']
 phases=['mechanics','current-psychic','current-upper','current-performance','current-supernatural','current-signatures','current-mobile','audit','journey','connected','historical24','historical23','historical13','legacy','compatibility']
 for phase in phases:
  for name in ['proof.json','restart-proof.json']:
   p=proofs[phase+'/'+name];assert p['checks']>0 and p['failures']==0,(phase,name)
   assert native['proof_sources'][phase+'/'+name]==source,'No substituted old-source native release'
   if phase.startswith('current-')or phase in ['mechanics','audit','journey','connected']:
    if 'rules_ref'in p:assert p['rules_ref']==pin,(phase,name)
 for phase in ['input','current-upper-input','current-performance-input','historical24-input','frozen-rules','baseline']:
  assert proofs[phase]['checks']>0 and proofs[phase]['failures']==0 and native['proof_sources'][phase]==source
 assert proofs['frozen-rules']['checks']==22181
 assert proofs['baseline']['traces']==dict(distinct_backend_rejected=True,distinct_button_enabled=True,reach_ambush_accepted=True)
 assert proofs['historical24/proof.json']['rules_ref']['pack_id']=='trhgd-character-v24'
 mechanics=proofs['mechanics/proof.json'];assert set(mechanics['classes'])=={'ardent','lurk','erudite'}
 for cls in mechanics['classes']:
  for level in [1,4,8,15,20]:assert mechanics['levels'][cls+str(level)]['history']==level
 journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False
 assert {r['history'][0]['class_id']for r in journey['journeys']}==set(mechanics['classes'])
 assert all(len(r['history'])==8 for r in journey['journeys'])and len(proofs['connected/proof.json']['casts'])==3
 assert proofs['connected/proof.json']['xp_injected']is False
 captures=native['captures'];assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=20
 for image in captures['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
 baseline=json.loads((root/'docs/implementation/game127/evidence/readiness-v24-baseline.json').read_text());assert baseline['rules_ref']['pack_id']=='trhgd-character-v24'
 assert len(baseline['classes'])==50 and sum(r['status']=='COMPLETE'for r in baseline['classes'])==23
 # Exact semantic data diff: no unrelated class, feat, ancestry or spell changes.
 old=json.loads((root/'data/rules/trhgd-character-v24.json').read_text());expected=copy.deepcopy(old)
 for k in ['pack_id','rules_version','provenance']:expected[k]=pack[k]
 old_ambush=next(r for r in expected['abilities']if r['id']=='lurk-psychic-ambush');new_ambush=next(r for r in pack['abilities']if r['id']==old_ambush['id'])
 for k in ['requires_melee','requires_adjacent','description','provenance']:old_ambush[k]=new_ambush[k]
 assert old_ambush['requires_melee']is True and old_ambush['requires_adjacent']is True and expected==pack
 old_projection=subprocess.check_output(['git','show','e96c235c6dfe244801b9d4ef09d8dcfd929f0e2f:scripts/rules/rules_wave_four.gd'],cwd=root,text=True).split('static func project_auras',1)[1]
 current_projection=(root/'scripts/rules/rules_wave_four.gd').read_text().split('static func project_auras',1)[1]
 assert old_projection==current_projection,'Historical aura reuse needs unchanged producer/consumer and referenced data'
 rows=copy.deepcopy(baseline['classes']);cohorts={'current-signatures':['soulknife','warblade','crusader','swordsage'],'current-mobile':['scout','rogue','swashbuckler','knight','duelist','arcane-trickster'],'current-supernatural':['warlock','binder','dragonfire-adept'],'current-performance':['bard','beguiler','spirit-shaman'],'current-upper':['wizard','cleric'],'current-psychic':['psion','wilder','cerebremancer'],'mechanics':['ardent','lurk','erudite']}
 for row in rows:
  cls=row['id'];row['previous_acceptance_pin']=baseline['rules_ref']
  row['evidence']=[x.replace('data/rules/trhgd-character-v24.json#','data/rules/trhgd-character-v25.json#')for x in row['evidence']]
  row['current_kernel_evidence']='docs/implementation/game127/evidence/current-native-witnesses.json#classes/'+cls if row['kind']=='base'else'Inherited exact prerequisite/history evidence remains labelled; supported targeted paths also have current tactical/cold proofs.'
  phase=next((p for p,ids in cohorts.items()if cls in ids),None)
  if phase:
   row['verified_source']=source;row['persistence']['current_native']=True;row['early_mid_high']['current_tactical']=True
   row['evidence'].append('docs/implementation/game127/evidence/native-proof.json#proofs/'+phase)
   row['acceptance_sources']={'current':'Fresh matching-source v25 '+phase+' native tactics and exact cold replay, plus all-base legal1–20 native audit.','reused':'Prior source-labelled GUI/earned acceptance only where unchanged. This wave freshly captures Ardent/Lurk/Erudite plus inherited prepared/performance native controls; not every historical UI permutation.'}
  if cls in mechanics['classes']:
   row['status']='COMPLETE';row['remaining']=[];row['status_scope']='Bounded original psychic identity: permanent choices, meaningful legal power/veil/ambush/identity use, resources and counterplay, actual production controls, lawful advancement and exact cold persistence; human balance/readability separate.'
   row['advancement']['current_native_levels']=[1,4,8,15,20]
   row['early_mid_high']['scope']='Development1/4/8/15/20, separately three actual490XP/level8 careers and saved generated encounter. No earned20 claim.'
   row['limitations']=['Original finite shared manifesting pool, not complete tabletop conversion.','Lurk direct psychic effect precedes a separate weapon roll; veil is25% weapon concealment, not invisibility.','Human Windows balance/readability acceptance remains pending.']
   row['evidence']+=['tests/psychic_identities/input.gd','tests/psychic_identities/journey.gd','tests/psychic_identities/connected.gd','docs/implementation/game127/evidence/screenshots.json']
  elif cls in ['marshal','war-chanter']:
   row['acceptance_sources']['v25_reuse']='Unchanged class/referenced data and exact aura projection versus v24; fresh current-psychic Weakened consumer and all-base audit. No new targeted aura encounter claimed.'
 queue=copy.deepcopy(baseline['repair_queue'])
 for q in queue:q['cohort']=[c for c in q['cohort']if c not in mechanics['classes']]
 queued=[c for q in queue for c in q['cohort']];remaining={r['id']for r in rows if r['status']=='PARTIAL'}
 assert set(queued)==remaining and len(queued)==len(set(queued))==24
 statuses={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']};assert statuses==dict(COMPLETE=26,PARTIAL=24,BLOCKED=0)
 report=dict(baseline,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v25.json').read_bytes()).hexdigest(),classes=rows,repair_queue=queue,verified_source=source,milestone_complete=False)
 out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
 lines=['# Supported character readiness','','Generated from fresh v25 Windows receipts and explicitly labelled historical acceptance. Technical COMPLETE is a bounded original adaptation, not sourcebook completeness or human acceptance.','',str(statuses),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 for r in rows:lines.append('| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |')
 lines+=['','## Finite exit plan','']
 for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
 lines+=['',report['exit_policy']];(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
 print(json.dumps(dict(classes=50,statuses=statuses)))
