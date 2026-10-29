"""Promote ONLY the final three careers against exact-source native Windows receipts."""
from pathlib import Path
import copy,hashlib,json,subprocess
BASE='7c70fb27bfd3572505421c996102bd11e9b6da1a'
TARGETS={'eldritch-knight':5,'shadowdancer':10,'dwarven-defender':10}
PATHS=['scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg']
def baseline(root):
 p=json.loads(subprocess.check_output(['git','show',BASE+':docs/implementation/game129/READINESS.json'],cwd=root));assert len(p['classes'])==50 and sum(r['status']=='COMPLETE'for r in p['classes'])==47;return p

def check_receipt(root,pin,n):
 assert n['acceptance_cohort']=='final-prestige'and n['rules_ref']==pin
 assert n['production_launch']and n['empty_path']and n['separate_process_restart']and not n['source_helper_override']and n['high_level_fixtures_not_earned']
 assert n['earned_xp']==1960 and n['earned_level']==15 and n['earned_prestige_caps']==TARGETS
 source=n['source_commit'];assert subprocess.check_output(['git','diff',source,'--',*PATHS],cwd=root)==b'','Native inputs changed'
 manifest=json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'));pins={r['rules_ref']['pack_id']:r['rules_ref']for r in manifest['packs']};proofs=n['proofs']
 historical={'historical34':'v34','historical33':'v33','historical32':'v32','historical31':'v31','historical30':'v30','historical30-extended':'v30','historical29':'v29','historical18':'v18','legacy':'v16','compatibility':'v16'}
 for phase in ['mechanics','journey','connected','audit','current-upper','sentinel-campaign',*historical]:
  for file in ['proof.json','restart-proof.json']:
   key=phase+'/'+file;p=proofs[key];assert p['checks']>0 and p['failures']==0 and n['proof_sources'][key]==source
   if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+historical.get(phase,'v35')]
 for key in ['pins','probe','input','portable','sentinel-probe','capture','historical34-input','historical33-input','historical32-input','historical31-input','historical30-input','frozen']:
  assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and n['proof_sources'][key]==source
 assert proofs['portable']['exact_earned_campaign']and proofs['portable']['clean_library_cache']and not proofs['portable']['xp_injected']
 assert proofs['pins']['pack_count']==35 and proofs['frozen']['checks']==22181
 for row in manifest['packs']:assert proofs['pins']['raw_sha256'][row['rules_ref']['pack_id']]==hashlib.sha256((root/row['path'].removeprefix('res://')).read_bytes()).hexdigest()
 m=proofs['mechanics/proof.json'];assert all(m['contracts'][key]is True for key in ['entry','channels','knight','shadow','defender','resources','suppression','late'])
 assert set(m['knight_levels'])=={'wizard','sorcerer','bard','beguiler','duskblade'}and all(v==list(range(1,6))for v in m['knight_levels'].values())
 assert m['shadow_levels']==m['defender_levels']==list(range(1,11))and len(m['channel_cases'])==19
 assert m['attacks']['hits']>=19 and m['attacks']['misses']>=19
 j=proofs['journey/proof.json'];assert j['earned_xp']==1960 and not j['xp_injected']and j['full_careers']and len(j['journeys'])==len(j['builds'])==len(j['earned_entries'])==3
 expected={'wizard-knight':['wizard']*5+['fighter']*2+['eldritch-knight']*5+['wizard']*3,'rogue-shadow':['rogue']*5+['shadowdancer']*10,'dwarf-defender':['fighter']*5+['dwarven-defender']*10}
 assert {r['role']for r in j['builds'].values()}==set(expected)
 for r in j['builds'].values():assert r['xp']==1960 and [s['class_id']for s in r['history']]==expected[r['role']]
 for info in j['earned_entries'].values():assert info['earned_xp']==info['required_xp']==(490 if info['path']=='eldritch-knight'else 250)and all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
 assert set(proofs['connected/proof.json']['casts'].values())=={'eldritch-channel-wizard-enfeeble','shadowdancer-technique-10','dwarven-defender-technique-10'}
 assert proofs['sentinel-campaign/proof.json']['expiry']==[2,1,0]and proofs['sentinel-campaign/restart-proof.json']['exact_cold']
 assert len(proofs['input']['screenshots'])==4 and len(n['captures']['screenshots'])>=24
 assert n['source_guard']['historical_pack_bytes_and_pins']==34 and n['source_guard']['roster_unchanged']and n['source_guard']['authority_unchanged']
 return expected

def expected_report(root,pack,pin,n):
 check_receipt(root,pin,n);old=baseline(root);rows=copy.deepcopy(old['classes']);definitions={r['id']:r for r in pack['classes']}
 for row in rows:
  identity=row['id']
  if identity not in TARGETS:continue # All prior47 accepted records remain verbatim.
  definition=definitions[identity];cap=TARGETS[identity];row.pop('acceptance_carry_forward',None)
  row.update(status='COMPLETE',remaining=[],verified_source=n['source_commit'],level_cap=cap,status_scope='Bounded native final-prestige acceptance: durable prerequisites, earned optional entry/committed decline, actual selected-parent/channel/shadow/stance trade-offs, finite resources, counterplay and exact cold. Human balance/usability remains open.')
  row['previous_acceptance_pin']=old['rules_ref'];row['advancement'].update(cap=cap,current_native_levels=list(range(1,cap+1)),total_character_level_cap=20)
  row['defining_features'].update(description=definition['description'],source_features=sorted(r['id']for r in definition['features']))
  row['selections']['career_groups']=[g['id']for g in definition['career_choices']]
  row['selections']['parent_casting']=[dict(group=g['id'],options=[r['advance_casting']for r in g['options']if'advance_casting'in r])for g in definition['career_choices']if any('advance_casting'in r for r in g['options'])]
  row['early_mid_high'].update(current_tactical=True,scope='Every supported prestige level and labelled total20 alternatives. Native adventures earn1960XP/total15 and all three prestige caps, optional entry/committed decline, real class abilities, resolution/home rest and independent cold. No earned20 claim.')
  row['persistence']['current_native']=True
  row['prestige'].update(requirements=definition['requirements'],automatic_entry=False,starting_class=False,current_native=True,earned_entry_xp=[490]if identity=='eldritch-knight'else[250],earned_prestige_levels=cap,development_prestige_levels=cap)
  row['current_kernel_evidence']='docs/implementation/game123-final-prestige/evidence/native-proof.json#mechanics/proof.json'
  row['evidence']+=['tests/final_prestige/mechanics.gd','tests/final_prestige/input.gd','tests/final_prestige/journey.gd','tests/final_prestige/connected.gd','docs/implementation/game123-final-prestige/evidence/native-proof.json','docs/implementation/game123-final-prestige/screenshots/README.md']
  row['limitations']=['Original bounded adaptation, not exhaustive tabletop parity or final human balance.','Historical1–34 saves retain exact original rules and pins.','No teleportation, exploration stealth, new anatomy art or out-of-turn manual spell interrupt. Existing humanoid LPC fallback and shared long-label/small-window clipping remain.','50-career technical readiness is separate from catalogue breadth, browser158 and pending human playtest.']
 assert sum(r['status']=='COMPLETE'for r in rows)==50 and not any(r['status']in ['PARTIAL','BLOCKED']for r in rows)
 return dict(old,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v35.json').read_bytes()).hexdigest(),repair_queue=[],verified_source=n['source_commit'],current_acceptance_cohort=list(TARGETS),milestone_complete=False,historical_acceptance_carry_forward=dict(pin=old['rules_ref'],source=old['verified_source'],integration_source=BASE,scope='All prior47 accepted records retained verbatim; only Knight, Shadowdancer and Dwarven Defender promote. Overall milestone remains open pending human review.'))

def generate(root,pack,pin,native_root):
 assert native_root is not None,'Matching-source native Windows receipt required'
 n=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'));expected=check_receipt(root,pin,n)
 primary=json.loads((native_root/'journeys/cohort-0/saves'/(n['proofs']['journey/proof.json']['slot']+'.json')).read_text(encoding='utf-8'));assert primary['mechanics']['rules_ref']==pin
 for identity,r in n['proofs']['journey/proof.json']['builds'].items():assert [s['class_id']for s in primary['mechanics']['records'][identity]['advancement_history']]==expected[r['role']]
 for info in n['proofs']['journey/proof.json']['earned_entries'].values():
  declined=json.loads((native_root/'journeys/cohort-0'/('declined-'+str(info['member_index']))/(n['proofs']['journey/proof.json']['slot']+'.json')).read_text(encoding='utf-8'));record=declined['mechanics']['records'][info['character_id']]
  assert record['rules_ref']==pin and len(record['advancement_history'])==len(info['original_history'])+1 and not any(s['class_id']==info['path']for s in record['advancement_history'])
 for im in n['captures']['screenshots']:assert hashlib.sha256((native_root/'captures'/im['file']).read_bytes()).hexdigest()==im['sha256']
 for im in n['proofs']['input']['screenshots']:assert hashlib.sha256((native_root/'mechanics'/im['file']).read_bytes()).hexdigest()==im['sha256']
 audit=json.loads((native_root/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(r['complete_track']for r in audit['classes'].values())
 report=expected_report(root,pack,pin,n);out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 lines=['# Supported character readiness','','50 COMPLETE / 0 PARTIAL / 0 BLOCKED. Evidence-backed technical acceptance; milestone remains OPEN for human playtest, balance and usability.','','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 lines+=['| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |'for r in report['classes']]
 lines+=['','The finite50-career technical queue is empty. Stop for human playtest; no living-world/monster/pantheon work starts automatically.',report['exit_policy']]
 (out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(json.dumps(dict(classes=50,statuses=dict(COMPLETE=50,PARTIAL=0,BLOCKED=0))))
