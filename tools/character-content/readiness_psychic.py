"""Evidence-gated v24 reassessment; historical rows and their source pins stay labelled."""
from pathlib import Path
import json,hashlib,copy

def generate(root,pack,pin,native_root):
 assert native_root is not None,'v24 promotion requires complete native Windows receipts'
 native=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
 assert native['rules_ref']==pin and native['production_launch']and native['separate_process_restart']and native['empty_path']
 proofs=native['proofs']
 phases=['mechanics','current-upper','current-performance','current-supernatural','current-signatures','current-mobile','audit','journey','connected','historical13','historical23','legacy','compatibility']
 for phase in phases:
  for name in ['proof.json','restart-proof.json']:
   proof=proofs[phase+'/'+name];assert proof['checks']>0 and proof['failures']==0,(phase,name)
   if phase.startswith('current-')or phase in ['mechanics','audit','journey','connected']:
    if 'rules_ref'in proof:assert proof['rules_ref']==pin,(phase,name)
 for phase in ['input','current-upper-input','current-performance-input','frozen-rules','baseline']:assert proofs[phase]['checks']>0 and proofs[phase]['failures']==0
 assert proofs['frozen-rules']['checks']==22181
 assert proofs['historical13/proof.json']['rules_ref']['pack_id']=='trhgd-character-v13'
 assert proofs['historical23/proof.json']['rules_ref']['pack_id']=='trhgd-character-v23'
 captures=native['captures'];assert captures['failures']==0 and len(captures['screenshots'])>=15
 for image in captures['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
 journey=proofs['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False
 mechanics=proofs['mechanics/proof.json'];assert set(mechanics['classes'])=={'psion','wilder','cerebremancer'}
 for cls in ['psion','wilder']:
  for level in [1,3,8,15,20]:assert mechanics['levels'][cls+str(level)]['history']==level
  assert any(x['history'][0]['class_id']==cls for x in journey['journeys'])
 assert any(sum(s['class_id']=='cerebremancer'for s in x['history'])==2 for x in journey['journeys'])
 assert mechanics['traces']['hybrid']['casting_levels']['sorcerer']==8 and mechanics['traces']['hybrid']['manifesting_level']==8
 assert sum(s['class_id']=='cerebremancer'for s in mechanics['traces']['hybrid']['history'])==5
 assert len(proofs['connected/proof.json']['casts'])==3
 baseline=json.loads((root/'docs/implementation/game152/evidence/readiness-v23-baseline.json').read_text())
 assert baseline['rules_ref']['pack_id']=='trhgd-character-v23'
 assert sum(r['status']=='COMPLETE'for r in baseline['classes'])==20
 rows=copy.deepcopy(baseline['classes']);tables={k:{r['id']:r for r in v}for k,v in pack.items()if isinstance(v,list)and v and isinstance(v[0],dict)and'id'in v[0]}
 cohort_map={'current-signatures':['soulknife','warblade','crusader','swordsage'],'current-mobile':['scout','rogue','swashbuckler','knight','duelist','arcane-trickster'],'current-supernatural':['warlock','binder','dragonfire-adept'],'current-performance':['bard','beguiler','spirit-shaman'],'current-upper':['wizard','cleric'],'mechanics':['psion','wilder','cerebremancer']}
 oldpack=json.loads((root/'data/rules/trhgd-character-v23.json').read_text());oldclasses={x['id']:x for x in oldpack['classes']}
 def class_contract(value):
  result=copy.deepcopy(value)
  for group in result.get('career_choices',[]):
   for option in group['options']:
    if option['features']==['psion-discipline-assault']or any('known_power'in tables['features'][feature]for feature in option['features']):option.pop('description',None)
  return result
 historical=json.loads((root/'docs/implementation/game146/evidence/historical-aura-readiness-review.json').read_text())
 assert historical['workflow_conclusion']=='success'and historical['comparison']['project_auras_function_unchanged']
 historical_pack=json.loads((root/'data/rules/trhgd-character-v20.json').read_text())
 historical_tables={k:{x['id']:x for x in v}for k,v in historical_pack.items()if isinstance(v,list)and v and isinstance(v[0],dict)and'id'in v[0]}
 text=(root/'scripts/rules/rules_wave_four.gd').read_text();start=text.index('static func project_auras(');end=text.find('\nstatic func ',start+1)
 assert hashlib.sha256(text[start:end if end>=0 else len(text)].encode()).hexdigest()==historical['comparison']['project_auras_sha256']
 aura_review=dict(source_commit=native['source_commit'],rules_ref=pin,projection_function_unchanged=True,classes={},scope='Reuse only unchanged aura function/data. The documented shared Weakened extension is freshly tested by the native psychic suite, not claimed byte-identical or a new targeted War Chanter encounter.')
 for cls,comparison in historical['comparison']['classes'].items():
  assert tables['classes'][cls]==historical_tables['classes'][cls]
  changes=[]
  for key in comparison['record_keys']:
   category,identity=key.split('/',1);before=historical_tables[category][identity];after=tables[category][identity]
   if before==after:continue
   assert key=='statuses/weakened'
   projected=copy.deepcopy(after);assert projected.pop('capabilities')=={'ability_damage':{'psychic':-2}}
   projected['provenance']['revision']=before['provenance']['revision'];assert projected==before
   assert mechanics['traces']['damage']['weakened']==1;changes.append(key)
  aura_review['classes'][cls]=dict(unchanged_references=len(comparison['record_keys'])-len(changes),documented_changes=changes,fresh_changed_consumer='final-distribution-proof.json#proofs/mechanics'if changes else None)
 (root/'docs/implementation/game152/evidence/aura-reuse-review.json').write_text(json.dumps(aura_review,indent=2)+'\n',encoding='utf-8')
 for row in rows:
  cls=row['id'];definition=tables['classes'][cls]
  assert cls in oldclasses
  expected=copy.deepcopy(oldclasses[cls])
  if cls=='cerebremancer':
   expected['requirements']['args'].append(dict(op='spell_tier',id='arcane',min=1))
   expected['description']=definition['description'];expected['provenance']['revision']='game152-psychic-resource-parity'
  assert class_contract(definition)==class_contract(expected),cls
  row['evidence']=[x for x in row['evidence']if not x.startswith('data/rules/trhgd-character-v23.json')]+['data/rules/trhgd-character-v24.json#classes/'+cls]
  row['defining_features']['description']=definition['description']
  row['previous_acceptance_pin']=baseline['rules_ref'];row['current_kernel_evidence']='docs/implementation/game152/evidence/current-native-witnesses.json#classes/'+cls if row['kind']=='base'else'Inherited prerequisite/history evidence remains explicitly pinned; only targeted paths gain current tactical evidence.'
  phase=next((phase for phase,classes in cohort_map.items()if cls in classes),None)
  if phase:
   row['status']='COMPLETE';row['verified_source']=native.get('proof_sources',{}).get(phase+'/proof.json',native['source_commit']);row['persistence']['current_native']=True;row['early_mid_high']['current_tactical']=True
   row['evidence']+=['docs/implementation/game152/evidence/final-distribution-proof.json#proofs/'+phase,'tests/psychic_parity/'+('mechanics.gd'if phase=='mechanics'else phase.replace('-','_')+'.gd')]
   row['acceptance_sources']={'current':'Matching v24 '+phase+' native tactics and exact cold replay; all-base legal1–20 audit.','reused':'Previous source-labelled earned/GUI evidence for unchanged class definitions; fresh GUI targets psychic/prepared/performance cohorts. No claim every historical control permutation was recaptured.'}
  if cls in ['psion','wilder','cerebremancer']:
   row['remaining']=[];row['status_scope']='Bounded original psychic/dual-casting identity: real known-power GUI, augmentation/costs, saves/resistance, finite resources/recovery, permanent optional prestige, legal progressions and cold combat; human balance separate.'
   row['advancement']['current_native_levels']=[1,3,8,15,20]if cls!='cerebremancer'else[1,2,3,4,5]
   row['early_mid_high']['scope']='Psion/Wilder development1/3/8/15/20; complete five-level Cerebremancer development route; actual490XP level8 Psion/Wilder/Psion3-Wizard3-Cerebremancer2 campaign and saved mixed-resource combat. No earned20 claim.'
   row['limitations']=['Original finite shared manifesting pool and five-level Cerebremancer adaptation; no exhaustive tabletop psychic catalogue or new surge randomness.','Cerebremancer-authored powers retain its existing INT profile; earlier class-owned powers retain that class attribute. Human balance/readability acceptance remains pending.']
   row['evidence']+=['tests/psychic_parity/input.gd','tests/psychic_parity/journey.gd','tests/psychic_parity/connected.gd','docs/implementation/game152/evidence/screenshots.json']
   if cls=='cerebremancer':row['prestige']['requirements']=definition['requirements']
  elif cls in ['marshal','war-chanter']:
   row['status_scope']='Original aura/limited-command identity: labelled historical native aura/earned path, unchanged aura projection and referenced data except the documented freshly tested generic Weakened extension. No fresh targeted v24 aura encounter is claimed.'
   row['acceptance_sources']={'current':'v24 kernel/cold audit where applicable; fresh generic Weakened damage/expiry consumer if referenced.','reused':'Labelled historical native aura/earned path, exact unchanged projection and remaining dependency rows; see aura-reuse-review.json.'}
   row['limitations']=[x for x in row.get('limitations',[])if 'unchanged defining data/consumer'not in x]
   row['limitations'].append('No fresh targeted v24 aura encounter; only unchanged historical portions are reused, with the changed generic Weakened consumer separately native-tested.')
   row['evidence'].append('docs/implementation/game152/evidence/aura-reuse-review.json')
 assert len(rows)==50 and len({r['id']for r in rows})==50
 # Finite acceptance cohorts, covering every remaining PARTIAL exactly once. No roster growth.
 queue=[dict(cohort=['psychic-warrior','ardent','lurk','erudite','divine-mind','cognition-adept','metamind','pyrokineticist'],goal='Audit actual mantle, distinct-per-rest, psychic strike/veil, aura and finite advanced resource consumers. Repair strongest2–4 reproducible defects per bounded cohort, then accept demonstrated existing functionality.'),dict(cohort=['sorcerer','druid','duskblade','archmage','mystic-theurge','abjurant-champion'],goal='Finish supported high-tier spontaneous/nature/channel and hybrid-path restrictions, not full sourcebook spell conversion; prove real choices/costs/targets/counterplay.'),dict(cohort=['barbarian','fighter','monk','paladin','ranger','eldritch-knight','shadowdancer','dwarven-defender'],goal='Close concrete equipment/rage/ki/divine/precision/ward/path trigger gaps in real combat, including exhaustion, expiry and negative cases.'),dict(cohort=['dragon-disciple','warshaper','bonded-summoner','beast-steward','grove-warden'],goal='Verify owned-creature actions, growth/limits, transformations, body/equipment restoration and path benefits; no unsupported flight/environment claims.')]
 remaining={r['id']for r in rows if r['status']=='PARTIAL'};queued=[cls for q in queue for cls in q['cohort']]
 assert set(queued)==remaining and len(queued)==len(set(queued))
 for i,q in enumerate(queue,1):q['priority']=i;q['exit']='Current native positive/negative tactical, legitimate choices and costs/recovery, lawful progression, actual controls, exact cold persistence; earned paths separately. No remaining defining advertised defect.'
 report=dict(baseline,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v24.json').read_bytes()).hexdigest(),classes=rows,repair_queue=queue,verified_source=native['source_commit'],milestone_complete=False,exit_policy='Finish these finite supported-career gates, consolidate human Windows visual/balance acceptance and GAME-123 exit review; no added roster/sourcebook breadth is required. Then GAME-142 and GAME-141.')
 out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
 statuses={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']}
 lines=['# Supported character readiness','', 'Generated from complete v24 Windows receipts and explicitly labelled historical acceptance. Technical COMPLETE is a bounded original adaptation, not sourcebook completeness or human balance approval.','',str(statuses),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 for row in rows:lines.append('| '+row['name']+' | '+row['kind']+' | '+row['status']+' | '+' '.join(row['remaining'])+' |')
 lines+=['','## Finite exit plan','']
 for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
 lines+=['',report['exit_policy']];(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
 print(json.dumps(dict(classes=len(rows),statuses=statuses)))
