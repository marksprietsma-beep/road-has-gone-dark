"""Promote exactly two careers only from matching-source native Windows evidence."""
import copy,hashlib,json,subprocess
BASE='c796043aa2543bcab144e8d0353628c35c2ab610'
def generate(root,pack,pin,native_root):
 assert native_root is not None,'Matching-source native evidence required'
 native=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
 assert native['acceptance_cohort']=='mystic-theurge-abjurant-champion'and native['rules_ref']==pin
 assert native['production_launch']and native['empty_path']and native['separate_process_restart']and not native['source_helper_override']
 source=native['source_commit'];proofs=native['proofs']
 assert subprocess.check_output(['git','diff',source,'HEAD','--','scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg'],cwd=root)==b'','Native inputs changed'
 for phase in ['mechanics','journey','connected-a','connected-b','audit','current-upper','historical28','historical18','legacy','compatibility']:
  for filename in ['proof.json','restart-proof.json']:
   key=phase+'/'+filename;p=proofs[key];assert p['checks']>0 and p['failures']==0 and native['proof_sources'][key]==source
   if phase in ['mechanics','journey','connected-a','connected-b','audit','current-upper']:
    if 'rules_ref'in p:assert p['rules_ref']==pin
 for key in ['input','interactions','interactions-cold','frozen','pinned28-probe','entry','entry-cold']:assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and native['proof_sources'][key]==source
 assert proofs['frozen']['checks']==22181
 assert all(proofs['mechanics/proof.json']['contracts'][k]is True for k in ['permanent_entry','historical_pins','dual_casting','champion_progression','total20','independent_resources','casting_attributes','distinct_support','martial_outcomes','body_suppression','recovery'])
 j=proofs['journey/proof.json'];assert j['earned_xp']==640 and not j['xp_injected']and len(j['journeys'])==3 and all(len(r['history'])==9 for r in j['journeys'])
 assert set(j['earned_entry_witnesses'])=={'wizard','sorcerer','duskblade'}
 for cls,w in j['earned_entry_witnesses'].items():
  assert w['class_assigned']is False and w['current_level']==(7 if cls=='sorcerer'else 6)and w['next_level']==w['current_level']+1
  assert w['earned_xp']>=10*(w['next_level']-1)**2
  saved=json.loads((native_root/'journeys/cohort-0'/w['file']).read_text(encoding='utf-8'));assert saved['mechanics']['rules_ref']==pin
 primary=json.loads((native_root/'journeys/cohort-0/saves'/(j['slot']+'.json')).read_text(encoding='utf-8'))
 assert primary['mechanics']['rules_ref']==pin and all(primary['mechanics']['records'][id]['rules_ref']==pin for id in primary['party_ids'])
 for phase,abilities in [('connected-a',{'wizard-arcane-bolt','cleric-bless','abjurant-retaliation-1'}),('connected-b',{'cleric-bless','sorcerer-arcane-bolt','abjurant-aegis-3'})]:assert set(proofs[phase+'/proof.json']['casts'].values())==abilities
 c=native['captures'];assert c['checks']>0 and c['failures']==0 and len(c['screenshots'])>=18
 for image in c['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
 assert native['source_guard']['historical_pack_bytes_and_pins']==28
 baseline=json.loads((root/'docs/implementation/game123-dual-prestige/READINESS-V28-BASELINE.json').read_text(encoding='utf-8'))
 assert baseline==json.loads(subprocess.check_output(['git','show',BASE+':docs/implementation/game129/READINESS.json'],cwd=root))
 assert len(baseline['classes'])==50 and sum(r['status']=='COMPLETE'for r in baseline['classes'])==35
 rows=copy.deepcopy(baseline['classes']);classes={r['id']:r for r in pack['classes']}
 for row in rows:
  if row['id']not in ['mystic-theurge','abjurant-champion']:
   row['acceptance_carry_forward']=dict(pin=baseline['rules_ref'],source=baseline['verified_source'],scope='Prior35 source-labelled accepted careers retained. Current all-base20 and historical/frozen regression supplement, rather than freshly reaccepting every career choice.')
   continue
  cls=classes[row['id']];row.update(status='COMPLETE',remaining=[],verified_source=source,level_cap=cls['max_level'],status_scope='Bounded original prestige identity: deliberate funded permanent entry or decline, independent parent casting, actual actions/costs/counterplay, production controls, supported path levels and exact cold continuation; human balance remains separate.')
  row['previous_acceptance_pin']=baseline['rules_ref'];row['advancement'].update(cap=cls['max_level'],current_native_levels=list(range(1,cls['max_level']+1)))
  row['defining_features']['description']=cls['description'];row['defining_features']['source_features']=sorted({f['id']for f in cls['features']})
  row['defining_features']['owned_possible_abilities']=sorted({a['id']for a in pack['abilities']if a['id'].startswith('mystic-theurge-power-')})if row['id']=='mystic-theurge'else row['defining_features']['owned_possible_abilities']
  row['prestige']['requirements']=cls['requirements'];row['selections']['career_groups']=[g['id']for g in cls['career_choices']]
  row['early_mid_high'].update(current_tactical=True,scope='Every supported Theurge1–10 or Champion1–5 and legal total20 development histories, real independent casting/defensive outcomes. Separate fresh exported-game640XP/9 campaign and isolated manual entry/decline/connected forks; no earned20 claim.')
  row['persistence']['current_native']=True
  row['evidence']+=['tests/dual_prestige_acceptance/mechanics.gd','tests/dual_prestige_acceptance/input.gd','tests/dual_prestige_acceptance/journey.gd','tests/dual_prestige_acceptance/entry.gd','tests/dual_prestige_acceptance/connected.gd','docs/implementation/game123-dual-prestige/evidence/native-proof.json','docs/implementation/game123-dual-prestige/screenshots/README.md']
  row['limitations']=['Original tactical adaptation, not exhaustive tabletop parity.','Historical1–28 pins keep their original five-level Theurge and original requirements/technique behavior. No migration.','Human balance, long-list/small-screen usability and humanoid LPC fallbacks remain separate.']
 queue=[]
 for q in baseline['repair_queue']:
  item=copy.deepcopy(q);item['cohort']=[x for x in item['cohort']if x not in ['mystic-theurge','abjurant-champion']]
  if item['cohort']:item['priority']=len(queue)+1;queue.append(item)
 partial={r['id']for r in rows if r['status']=='PARTIAL'};assert {x for q in queue for x in q['cohort']}==partial and len(partial)==13
 totals={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']};assert totals==dict(COMPLETE=37,PARTIAL=13,BLOCKED=0)
 report=dict(baseline,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v29.json').read_bytes()).hexdigest(),repair_queue=queue,verified_source=source,current_acceptance_cohort=['mystic-theurge','abjurant-champion'],milestone_complete=False,historical_acceptance_carry_forward=dict(pin=baseline['rules_ref'],source=baseline['verified_source'],scope='Prior35 source-labelled acceptance retained; current cohort only is promoted.'))
 out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 lines=['# Supported character readiness','','Matching-source native Windows accepts Mystic Theurge / Abjurant Champion. Technical acceptance remains separate from human balance and research breadth.','',str(totals),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 for row in rows:lines.append('| '+row['name']+' | '+row['kind']+' | '+row['status']+' | '+' '.join(row['remaining'])+' |')
 lines+=['','## Finite exit plan','']
 for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
 lines+=['',report['exit_policy']];(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(json.dumps(dict(classes=50,statuses=totals)))
