"""Only these two careers promote, against exact-source full Windows-native receipts."""
from pathlib import Path
import copy,hashlib,json,subprocess
BASE='0a7b690fe17f665c9ab1c581a0f0ddc91aa5d154'
TARGETS={'dragon-disciple':10,'warshaper':5}
PATHS=['scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg']
def baseline(root):
 raw=subprocess.check_output(['git','show',BASE+':docs/implementation/game129/READINESS.json'],cwd=root)
 p=json.loads(raw);assert len(p['classes'])==50 and sum(r['status']=='COMPLETE'for r in p['classes'])==45;return p

def check_receipt(root,pin,n):
 assert n['acceptance_cohort']=='dragon-warshaper'and n['rules_ref']==pin
 assert n['production_launch']and n['empty_path']and n['separate_process_restart']and not n['source_helper_override']and n['high_level_fixtures_not_earned']
 assert n['earned_xp']==2280 and n['earned_level']==16 and n['earned_prestige_caps']==TARGETS
 source=n['source_commit'];assert subprocess.check_output(['git','diff',source,'--',*PATHS],cwd=root)==b'','Native inputs changed'
 pins={r['rules_ref']['pack_id']:r['rules_ref']for r in json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs']};proofs=n['proofs']
 historical={'historical33':'v33','historical32':'v32','historical31':'v31','historical30':'v30','historical30-extended':'v30','historical29':'v29','historical18':'v18','legacy':'v16','compatibility':'v16'}
 for phase in ['mechanics','journey','connected','audit','current-upper','sentinel-campaign',*historical]:
  for file in ['proof.json','restart-proof.json']:
   key=phase+'/'+file;p=proofs[key];assert p['checks']>0 and p['failures']==0 and n['proof_sources'][key]==source
   if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+historical.get(phase,'v34')]
 for key in ['pins','probe','input','sentinel-probe','capture','historical33-input','historical32-input','historical31-input','historical30-input','frozen']:
  assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and n['proof_sources'][key]==source
 assert proofs['pins']['pack_count']==34 and proofs['frozen']['checks']==22181
 for row in json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs']:
  assert proofs['pins']['raw_sha256'][row['rules_ref']['pack_id']]==hashlib.sha256((root/row['path'].removeprefix('res://')).read_bytes()).hexdigest()
 m=proofs['mechanics/proof.json'];assert all(m['contracts'][key]is True for key in ['entry','dragon','morph','forms','limits','paid_exhaustion','ward_and_claws','incapacitation','late'])
 assert m['dragon_levels']['wizard']==m['dragon_levels']['sorcerer']==list(range(1,11))and m['morph_levels']['druid']==list(range(1,6))
 assert m['attacks']['hits']>0 and m['attacks']['misses']>0
 damage=m['observations']['morph_tradeoffs']['incoming_damage'];assert damage['3']==damage['5']+2
 j=proofs['journey/proof.json'];assert j['earned_xp']==2280 and not j['xp_injected']and j['full_careers']and len(j['journeys'])==len(j['builds'])==len(j['earned_entries'])==3
 expected={'dragon-sorcerer':['sorcerer']*6+['dragon-disciple']*10,'warshaper-druid':['druid']*6+['warshaper']*5+['druid']*5,'dragon-wizard':['wizard']*5+['dragon-disciple']*10+['wizard']}
 assert {r['role']for r in j['builds'].values()}==set(expected)
 for r in j['builds'].values():assert r['xp']==2280 and [s['class_id']for s in r['history']]==expected[r['role']]
 for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(250 if info['parent']=='wizard'else 360)and all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
 c=proofs['connected/proof.json'];assert set(c['owned_actions'])=={'summon','companion'}and all(r['before_hp']>r['after_hp']for r in c['owned_actions'].values())
 assert set(c['casts'].values())=={'dragon-disciple-technique-7','warshaper-technique-3','dragon-disciple-technique-4'}
 assert proofs['sentinel-campaign/proof.json']['expiry']==[2,1,0]and proofs['sentinel-campaign/restart-proof.json']['exact_cold']
 footers=proofs['input']['footer_observations'];assert len(footers)==4 and any(r['fullscreen']for r in footers)
 assert len(n['captures']['screenshots'])>=24
 assert n['source_guard']['historical_pack_bytes_and_pins']==33 and n['source_guard']['roster_unchanged']
 return expected

def expected_report(root,pack,pin,n):
 check_receipt(root,pin,n);old=baseline(root);rows=copy.deepcopy(old['classes']);definitions={r['id']:r for r in pack['classes']}
 for row in rows:
  identity=row['id']
  if identity not in TARGETS:continue # Preserve all other45 records verbatim.
  definition=definitions[identity];cap=TARGETS[identity];row.pop('acceptance_carry_forward',None)
  row.update(status='COMPLETE',remaining=[],verified_source=n['source_commit'],level_cap=cap,status_scope='Bounded native Dragon/Warshaper acceptance: permanent prerequisites, explicit earned entry/committed decline, actual independent caster/body choices, paid tactical effects and exact cold. Original adaptation, not exhaustive tabletop parity or final human balance.')
  row['previous_acceptance_pin']=old['rules_ref'];row['advancement'].update(cap=cap,current_native_levels=list(range(1,cap+1)),total_character_level_cap=20)
  row['defining_features'].update(description=definition['description'],source_features=sorted(r['id']for r in definition['features']))
  row['selections']['career_groups']=[g['id']for g in definition['career_choices']]
  row['selections']['parent_casting']=[dict(group=g['id'],options=[r['advance_casting']for r in g['options']if'advance_casting'in r])for g in definition['career_choices']if any('advance_casting'in r for r in g['options'])]
  row['early_mid_high'].update(current_tactical=True,scope='All supported Dragon1–10/Warshaper1–5 with real commands, saves/counterplay, finite exhaustion/recovery, scales/claws/ward/fire, distinct reach/mitigation, transformation/gear/expiry/incapacitation and full cold. Actual2280XP/total16 independently earns both entire Dragon tracks and Warshaper5; total20 alternatives are development fixtures, never earned20.')
  row['persistence']['current_native']=True
  row['prestige'].update(requirements=definition['requirements'],automatic_entry=False,starting_class=False,current_native=True,earned_entry_xp=[250,360]if identity=='dragon-disciple'else[360],earned_prestige_levels=cap,development_prestige_levels=cap)
  row['current_kernel_evidence']='docs/implementation/game123-dragon-warshaper/evidence/native-proof.json#mechanics/proof.json'
  row['evidence']+=['tests/dragon_warshaper/mechanics.gd','tests/dragon_warshaper/input.gd','tests/dragon_warshaper/journey.gd','tests/dragon_warshaper/connected.gd','docs/implementation/game123-dragon-warshaper/evidence/native-proof.json','docs/implementation/game123-dragon-warshaper/screenshots/README.md']
  row['limitations']=['Original bounded adaptation, not full tabletop conversion or final human balance.','Historical1–33 saves retain exact pins/behavior; no silent migration.','Existing shared body/equipment/creature policies and labelled humanoid LPC anatomy fallback remain. No flight, new transformation engine or custom dragon/animal art.','Shared long-label/small-window clipping and browser158 remain separate.']
 queue=[]
 for entry in old['repair_queue']:
  r=copy.deepcopy(entry);r['cohort']=[i for i in r['cohort']if i not in TARGETS]
  if r['cohort']:r['priority']=len(queue)+1;queue.append(r)
 partial={r['id']for r in rows if r['status']=='PARTIAL'};assert partial=={'eldritch-knight','shadowdancer','dwarven-defender'}=={i for r in queue for i in r['cohort']}
 assert sum(r['status']=='COMPLETE'for r in rows)==47 and not any(r['status']=='BLOCKED'for r in rows)
 return dict(old,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v34.json').read_bytes()).hexdigest(),repair_queue=queue,verified_source=n['source_commit'],current_acceptance_cohort=list(TARGETS),milestone_complete=False,historical_acceptance_carry_forward=dict(pin=old['rules_ref'],source=old['verified_source'],integration_source=BASE,scope='All prior45 accepted records and three remaining partial records retained verbatim; only Dragon Disciple and Warshaper promote.'))

def generate(root,pack,pin,native_root):
 assert native_root is not None,'Matching-source native Windows receipt required'
 n=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'));expected=check_receipt(root,pin,n)
 primary=json.loads((native_root/'journeys/cohort-0/saves'/(n['proofs']['journey/proof.json']['slot']+'.json')).read_text(encoding='utf-8'));assert primary['mechanics']['rules_ref']==pin
 for identity,r in n['proofs']['journey/proof.json']['builds'].items():assert [s['class_id']for s in primary['mechanics']['records'][identity]['advancement_history']]==expected[r['role']]
 for info in n['proofs']['journey/proof.json']['earned_entries'].values():
  declined=json.loads((native_root/'journeys/cohort-0'/('declined-'+str(info['member_index']))/(n['proofs']['journey/proof.json']['slot']+'.json')).read_text(encoding='utf-8'));record=declined['mechanics']['records'][info['character_id']]
  assert record['rules_ref']==pin and len(record['advancement_history'])==len(info['original_history'])+1 and not any(s['class_id']==info['path']for s in record['advancement_history'])
 for im in n['captures']['screenshots']:assert hashlib.sha256((native_root/'captures'/im['file']).read_bytes()).hexdigest()==im['sha256']
 for im in n['proofs']['input']['footer_observations']:assert hashlib.sha256((native_root/'mechanics'/im['file']).read_bytes()).hexdigest()==im['sha256']
 audit=json.loads((native_root/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(r['complete_track']for r in audit['classes'].values())
 report=expected_report(root,pack,pin,n);out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 lines=['# Supported character readiness','','Matching-source native Windows accepts Dragon Disciple and Warshaper. Technical acceptance is separate from human balance and research breadth.','','47 COMPLETE / 3 PARTIAL / 0 BLOCKED','','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 lines+=['| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |'for r in report['classes']]
 lines+=['','## Finite exit plan','']+[str(r['priority'])+'. '+', '.join(r['cohort'])+': '+r['goal']for r in report['repair_queue']]+['',report['exit_policy']]
 (out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(json.dumps(dict(classes=50,statuses=dict(COMPLETE=47,PARTIAL=3,BLOCKED=0))))
