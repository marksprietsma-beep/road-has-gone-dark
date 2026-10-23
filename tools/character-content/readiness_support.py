"""Promote this bounded cohort only from matching native Windows contracts."""
from pathlib import Path
import copy,hashlib,json,subprocess

def generate(root,pack,pin,native_root):
 assert native_root is not None,'Native Windows evidence is mandatory'
 native=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'));source=native['source_commit'];proofs=native['proofs']
 assert native['rules_ref']==pin and native['production_launch']and native['empty_path']and native['separate_process_restart']
 phases=['mechanics','journey','connected','current-upper','current-performance','current-supernatural','current-signatures','current-mobile','current-psychic','current-identities','historical25','historical24','historical23','historical13','legacy','compatibility','audit']
 for phase in phases:
  for file in ['proof.json','restart-proof.json']:
   key=phase+'/'+file;p=proofs[key]
   assert p['checks']>0 and p['failures']==0 and native['proof_sources'][key]==source,(phase,file)
   if phase.startswith('current-')or phase in ['mechanics','journey','connected','audit']:
    if 'rules_ref'in p:assert p['rules_ref']==pin,(phase,file)
 for key in ['input','current-identities-input','current-upper-input','current-performance-input','historical25-input','historical24-input','baseline','frozen-rules']:
  assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and native['proof_sources'][key]==source
 assert proofs['frozen-rules']['checks']==22181
 baseline=json.loads((root/'docs/implementation/game127-support/evidence/readiness-v25-baseline.json').read_text());assert baseline['rules_ref']['pack_id']=='trhgd-character-v25'
 assert len(baseline['classes'])==50 and sum(r['status']=='COMPLETE'for r in baseline['classes'])==26
 old=json.loads((root/'data/rules/trhgd-character-v25.json').read_text());expected=copy.deepcopy(old)
 for key in ['pack_id','rules_version','provenance']:expected[key]=pack[key]
 for before in expected['abilities']:
  if before['id'].startswith('cognition-strike-'):
   after=next(a for a in pack['abilities']if a['id']==before['id'])
   for key in ['requires_melee','requires_adjacent','description','provenance']:before[key]=after[key]
   assert after['requires_melee']is True and after['requires_adjacent']is True
 assert expected==pack,'No acceptance inheritance across unrelated rules changes'
 previous=subprocess.check_output(['git','show','0a01cea0088bb48af177cb71d2a7c098340a45bb:scripts/rules/rules_wave_four.gd'],cwd=root,text=True).split('static func project_auras',1)[1]
 assert previous==(root/'scripts/rules/rules_wave_four.gd').read_text().split('static func project_auras',1)[1]
 capture=native['captures'];assert capture['checks']>0 and capture['failures']==0 and len(capture['screenshots'])>=20
 for image in capture['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
 journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False and len(journey['journeys'])==3
 assert all(len(r['history'])==8 for r in journey['journeys'])
 assert any(s['class_id']=='cognition-adept'for s in journey['journeys'][2]['history'])
 assert proofs['connected/proof.json']['xp_injected']is False and len(proofs['connected/proof.json']['casts'])==3
 mechanics=proofs['mechanics/proof.json'];assert set(mechanics['classes'])=={'psychic-warrior','divine-mind','cognition-adept'}
 assert all(mechanics['levels'][cls+str(at)]['history']==at for cls in ['psychic-warrior','divine-mind']for at in [1,4,8,15,20])
 assert all(mechanics['levels']['cognition'+str(at)]['prestige_levels']==at for at in range(6))
 assert all(mechanics['traces'][scope]and all(mechanics['traces'][scope].values())for scope in ['warrior','mind','cognition'])
 rows=copy.deepcopy(baseline['classes'])
 cohorts={'current-signatures':['soulknife','warblade','crusader','swordsage'],'current-mobile':['scout','rogue','swashbuckler','knight','duelist','arcane-trickster'],'current-supernatural':['warlock','binder','dragonfire-adept'],'current-performance':['bard','beguiler','spirit-shaman'],'current-upper':['wizard','cleric'],'current-psychic':['psion','wilder','cerebremancer'],'current-identities':['ardent','lurk','erudite'],'mechanics':mechanics['classes']}
 for row in rows:
  cls=row['id'];row['previous_acceptance_pin']=baseline['rules_ref']
  row['evidence']=[s.replace('data/rules/trhgd-character-v25.json#','data/rules/trhgd-character-v26.json#')for s in row['evidence']]
  row['current_kernel_evidence']='docs/implementation/game127-support/evidence/current-native-witnesses.json#classes/'+cls if row['kind']=='base'else'Inherited labelled history evidence, with targeted prestige consumers freshly exercised in current native phases.'
  phase=next((p for p,ids in cohorts.items()if cls in ids),None)
  if phase:
   row['verified_source']=source;row['persistence']['current_native']=True;row['early_mid_high']['current_tactical']=True
   row['evidence'].append('docs/implementation/game127-support/evidence/native-proof.json#proofs/'+phase)
   row['acceptance_sources']={'current':'Fresh matching-source v26 '+phase+' native tactical/cold proof plus all-base legal1–20 audit.','reused':'Prior specifically labelled GUI/earned acceptance only where unchanged; this wave captures Psychic Warrior/Divine Mind/Cognition and reruns inherited identity/prepared/performance native controls.'}
  if cls in mechanics['classes']:
   row['status']='COMPLETE';row['remaining']=[]
   row['status_scope']='Bounded original identity: permanent choices and progression, actual tactical costs/targets/effects/interruption/recovery, production controls, exact cold continuation and separate earned prestige journey. Human balance/readability remains separate.'
   row['advancement']['current_native_levels']=[1,4,8,15,20]if row['kind']=='base'else[1,2,3,4,5]
   row['early_mid_high']['scope']='Legal development base1/4/8/15/20 and five prestige levels; actual earned490XP/total8 with optional Cognition entry. No earned20 claim.'
   row['evidence']+=['tests/psychic_support/input.gd','tests/psychic_support/journey.gd','tests/psychic_support/connected.gd','docs/implementation/game127-support/evidence/screenshots.json']
   row['limitations']=['One original finite shared psychic pool; arcane spell resources and owning-class attributes remain independent.','Cognition direct psychic damage precedes a separate weapon roll; no hit-rider conversion.','Divine Mind aura has no per-turn upkeep; living untransformed source, radius3 and clear line of sight are required.','Natural forms suppress psychic actions; original humanoid art fallback and human usability/balance review remain.']
 queue=copy.deepcopy(baseline['repair_queue'])
 for q in queue:q['cohort']=[c for c in q['cohort']if c not in mechanics['classes']]
 partial={r['id']for r in rows if r['status']=='PARTIAL'};queued=[c for q in queue for c in q['cohort']]
 assert set(queued)==partial and len(queued)==len(set(queued))
 statuses={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']}
 report=dict(baseline,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v26.json').read_bytes()).hexdigest(),classes=rows,repair_queue=queue,verified_source=source,milestone_complete=False)
 out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
 lines=['# Supported character readiness','','Generated from matching-source v26 native Windows contracts and explicitly labelled historical evidence. Technical acceptance is bounded; human review and the wider catalogue remain unfinished.','',str(statuses),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 for r in rows:lines.append('| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |')
 lines+=['','## Finite exit plan','']
 for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
 lines+=['',report['exit_policy']];(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
 print(json.dumps(dict(classes=len(rows),statuses=statuses)))
