"""Promote only Grove/Bonded against actual matching-source Windows-native evidence."""
import copy,hashlib,json,subprocess

def generate(root,pack,pin,native_root):
 assert native_root is not None,'Matching-source native Windows receipt required'
 n=json.loads((native_root/'distribution-proof.json').read_text(encoding='utf-8'))
 assert n['acceptance_cohort']=='grove-summoner'and n['rules_ref']==pin
 assert n['production_launch']and n['empty_path']and n['separate_process_restart']and not n['source_helper_override']and n['high_level_fixtures_not_earned']
 assert n['earned_xp']==810 and n['earned_level']==10 and n['earned_prestige_caps']=={'grove-warden':3,'bonded-summoner':5}
 source=n['source_commit'];paths=['scripts','data','scenes','assets','tests','tools','vendor','.github','project.godot','export_presets.cfg']
 assert subprocess.check_output(['git','diff',source,'HEAD','--',*paths],cwd=root)==b'','Native inputs changed'
 pins={r['rules_ref']['pack_id']:r['rules_ref']for r in json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs']}
 proofs=n['proofs']
 historical={'historical32':'v32','historical31':'v31','historical30':'v30','historical30-extended':'v30','historical29':'v29','historical18':'v18','legacy':'v16','compatibility':'v16'}
 for phase in ['mechanics','journey','connected','audit','current-upper',*historical]:
  for filename in ['proof.json','restart-proof.json']:
   key=phase+'/'+filename;p=proofs[key]
   assert p['checks']>0 and p['failures']==0 and n['proof_sources'][key]==source
   if 'rules_ref'in p:assert p['rules_ref']==pins['trhgd-character-'+historical.get(phase,'v33')]
 for key in ['input','pinned32-probe','historical32-input','historical31-input','historical30-input','frozen']:
  assert proofs[key]['checks']>0 and proofs[key]['failures']==0 and n['proof_sources'][key]==source
 assert proofs['frozen']['checks']==22181
 assert proofs['historical30-input']['suppressed_cases']==3 and proofs['historical30-input']['resisted_cases']==2
 m=proofs['mechanics/proof.json'];assert all(m['contracts'][k]is True for k in ['entry','aura','renewal','casting','calls','creatures','limits','forms','late'])
 assert m['attacks']['hits']>0 and m['attacks']['misses']>0
 aura=m['observations']['aura_attack'];assert aura['protected_defence']==aura['bare_defence']+3 and ' hits 'in aura['bare_log'][-1]and aura['protected_log'][-1].endswith('miss.')
 j=proofs['journey/proof.json'];assert j['earned_xp']==810 and not j['xp_injected']and len(j['journeys'])==len(j['builds'])==len(j['earned_entries'])==3
 assert all(len(row['history'])==10 for row in j['journeys'])
 assert {row['role']for row in j['builds'].values()}=={'grove-shaman','bonded-wizard','grove-druid'}
 for info in j['earned_entries'].values():
  assert info['earned_xp']==info['required_xp']==(250 if info['path']=='bonded-summoner'else 360)and all(info['alternatives'].values())and info['decline_committed']and info['decline_hash']
  assert len(info['original_history'])==(5 if info['path']=='bonded-summoner'else 6)
  declined=json.loads((native_root/'journeys/cohort-0'/('declined-'+str(info['member_index']))/(j['slot']+'.json')).read_text(encoding='utf-8'))
  record=declined['mechanics']['records'][info['character_id']]
  assert record['rules_ref']==pin and len(record['advancement_history'])==len(info['original_history'])+1
  assert not any(s['class_id']==info['path']for s in record['advancement_history'])
 assert j['retrieval']['second_change_rejected']and j['retrieval']['spent']==0 and j['retrieval']['recovered']==1
 primary=json.loads((native_root/'journeys/cohort-0/saves'/(j['slot']+'.json')).read_text(encoding='utf-8'))
 assert primary['mechanics']['rules_ref']==pin
 expected={'grove-shaman':['spirit-shaman']*6+['grove-warden']*3+['spirit-shaman'],'bonded-wizard':['wizard']*5+['bonded-summoner']*5,'grove-druid':['druid','spirit-shaman']+['druid']*4+['grove-warden']*3+['druid']}
 for identity,build in j['builds'].items():
  record=primary['mechanics']['records'][identity];assert record['rules_ref']==pin and [s['class_id']for s in record['advancement_history']]==expected[build['role']]
 c=proofs['connected/proof.json'];assert set(c['owned_actions'])=={'summon','companion'}and all(x['before_hp']>x['after_hp']for x in c['owned_actions'].values())
 assert set(c['casts'].values())=={'grove-protection-1','bonded-summoner-technique-5','grove-protection-2'}
 audit=json.loads((native_root/'all-base/witnesses.json').read_text(encoding='utf-8'));assert len(audit['classes'])==32 and all(r['complete_track']for r in audit['classes'].values())
 captures=n['captures'];assert captures['checks']>0 and captures['failures']==0 and len(captures['screenshots'])>=24
 for image in captures['screenshots']:assert hashlib.sha256((native_root/'captures'/image['file']).read_bytes()).hexdigest()==image['sha256']
 assert {x['width']for x in captures['screenshots']}=={640,1280,2560}
 assert all(any(x['file'].startswith('fixture-'+label+'-combat-')for x in captures['screenshots'])for label in ['active-call5','sanctuary_saved_hit'])
 assert n['source_guard']['historical_pack_bytes_and_pins']==32 and n['source_guard']['new_content_records']==0
 receipt=json.loads((root/'docs/implementation/game123-grove-summoner/READINESS-BASELINE.json').read_text(encoding='utf-8'))
 raw=subprocess.check_output(['git','show',receipt['source']+':'+receipt['path']],cwd=root);assert hashlib.sha256(raw).hexdigest()==receipt['sha256']
 baseline=json.loads(raw);assert len(baseline['classes'])==50 and sum(r['status']=='COMPLETE'for r in baseline['classes'])==43
 rows=copy.deepcopy(baseline['classes']);classes={r['id']:r for r in pack['classes']}
 for row in rows:
  identity=row['id']
  if identity not in ['grove-warden','bonded-summoner']:
   row['acceptance_carry_forward']=dict(pin=baseline['rules_ref'],source=baseline['verified_source'],accepted=row['status']=='COMPLETE',scope='Previous source-labelled status retained; prior43 accepted careers and five remaining partial careers are not newly promoted by this pair. Current all-base and historical/frozen regressions supplement earlier career-specific evidence.')
   continue
  cls=classes[identity];cap=int(cls['max_level']);row.pop('acceptance_carry_forward',None)
  row.update(status='COMPLETE',remaining=[],verified_source=source,level_cap=cap,status_scope='Bounded native Grove/Bonded acceptance: genuine permanent entry and optional XP-funded entry/committed decline, selected existing caster progression, finite aura/renewal/calls, real temporary/permanent owned actor effects and costs, body restrictions and exact cold continuation. Human balance remains separate.')
  row['previous_acceptance_pin']=baseline['rules_ref'];row['advancement'].update(cap=cap,current_native_levels=list(range(1,cap+1)),total_character_level_cap=20)
  features={f['id']for f in cls['features']};features.update(f for group in cls['career_choices']for option in group['options']for f in option['features'])
  row['defining_features'].update(description=cls['description'],source_features=sorted(features))
  row['selections']['career_groups']=[g['id']for g in cls['career_choices']]
  row['selections']['parent_casting']=[dict(group=g['id'],options=[o['advance_casting']for o in g['options']if'advance_casting'in o])for g in cls['career_choices']if any('advance_casting'in o for o in g['options'])]
  row['early_mid_high'].update(current_tactical=True,scope='Every supported Grove1–3/Bonded1–5 and total20 development history, actual caster spells/attributes/independent pools, aura hit→miss/range/LoS/expiry, renewal, varied owned creature actions/growth/limits/survival and forms, exact cold. Separately actual810XP/total10 earns all3 Grove/all5 Bonded levels for three persistent characters, with funded250/360XP entry and truly committed decline forks, retrieval/rest and real summon/companion damage; no earned20 claim.')
  row['persistence']['current_native']=True
  row['prestige'].update(requirements=cls['requirements'],automatic_entry=False,starting_class=False,current_native=True,earned_entry_xp=360 if identity=='grove-warden'else 250,entry_total_level=7 if identity=='grove-warden'else 6,earned_prestige_levels=cap,development_prestige_levels=cap)
  row['current_kernel_evidence']='docs/implementation/game123-grove-summoner/evidence/native-proof.json#mechanics/proof.json'
  row['evidence']+=['tests/grove_summoner/mechanics.gd','tests/grove_summoner/input.gd','tests/grove_summoner/journey.gd','tests/grove_summoner/connected.gd','docs/implementation/game123-grove-summoner/evidence/native-proof.json','docs/implementation/game123-grove-summoner/screenshots/README.md']
  row['limitations']=['Original bounded tactical adaptation, not exhaustive tabletop conversion or final human balance.','All historical1–32 pins/behavior remain exact without silent migration.','Grove retains genuine Spirit Reserve/Spirit Shaman restriction and existing body suppression; no terrain travel or spirit dialogue. Existing summons retain one shared active slot, bounded global expiry/history, owner-defeat withdrawal at the next global boundary, and labelled humanoid LPC fallback. No new pet/AI/world engine.','Long-label/small-window presentation and the separate50-career browser task remain outside this cohort.']
 queue=[]
 for old in baseline['repair_queue']:
  item=copy.deepcopy(old);item['cohort']=[i for i in item['cohort']if i not in ['grove-warden','bonded-summoner']]
  if item['cohort']:item['priority']=len(queue)+1;queue.append(item)
 partial={r['id']for r in rows if r['status']=='PARTIAL'}
 assert partial=={'eldritch-knight','shadowdancer','dwarven-defender','dragon-disciple','warshaper'}=={i for item in queue for i in item['cohort']}
 totals={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']};assert totals==dict(COMPLETE=45,PARTIAL=5,BLOCKED=0)
 report=dict(baseline,classes=rows,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/'data/rules/trhgd-character-v33.json').read_bytes()).hexdigest(),repair_queue=queue,verified_source=source,current_acceptance_cohort=['grove-warden','bonded-summoner'],milestone_complete=False,historical_acceptance_carry_forward=dict(pin=baseline['rules_ref'],source=baseline['verified_source'],scope='Prior43 source-labelled accepted careers retained; only this pair is promoted.'))
 out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 lines=['# Supported character readiness','','Matching-source native Windows accepts Grove Warden and Bonded Summoner. Technical acceptance remains separate from human balance and research breadth.','',str(totals),'','| Career | Kind | Status | Remaining acceptance |','|---|---|---|---|']
 lines+=['| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |'for r in rows]
 lines+=['','## Finite exit plan','']+[str(i['priority'])+'. '+', '.join(i['cohort'])+': '+i['goal']for i in queue]+['',report['exit_policy']]
 (out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(json.dumps(dict(classes=50,statuses=totals)))
