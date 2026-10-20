"""Reproducible all-supported-class readiness, separate from research coverage.
Usage: python tools/character-content/build-readiness.py [--native DIR]
Only exact selected-pack zero-failure native receipts promote technical status. Human balance and sourcebook breadth are separate.
"""
from pathlib import Path
import argparse,json,hashlib
root=Path(__file__).resolve().parents[2];parser=argparse.ArgumentParser();parser.add_argument('--native',type=Path);parser.add_argument('--pack',default='trhgd-character-v21');args=parser.parse_args()
p=json.loads((root/('data/rules/'+args.pack+'.json')).read_text(encoding='utf-8'));t={k:{x['id']:x for x in v}for k,v in p.items()if isinstance(v,list)and v and isinstance(v[0],dict)and'id'in v[0]}
pin=next(x['rules_ref']for x in json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs']if x['rules_ref']['pack_id']==p['pack_id'])
prior=json.loads((root/'docs/implementation/game126/current/MATRIX.json').read_text(encoding='utf-8'));base={x['id']:x for x in prior['classes']}
prestige=json.loads((root/'docs/implementation/game126/evidence/native-prestige-witnesses.json').read_text(encoding='utf-8'))
cohort=['soulknife','warblade','crusader','swordsage'];native=None
if args.native:
 native=json.loads((args.native/'distribution-proof.json').read_text(encoding='utf-8'));assert native['rules_ref']==pin
 assert all(x['checks']>0 and x['failures']==0 for x in native['proofs'].values())
 assert native['production_launch'] and native['separate_process_restart']
 assert native['captures']['failures']==0 and native['captures']['screenshots']
 if args.pack in ['trhgd-character-v20','trhgd-character-v21']:
  required=['mechanics','current-signatures','v19','v18','legacy','compatibility','audit','journey','prestige-journey','connected']
  if args.pack=='trhgd-character-v21':required=[x for x in required if x!='prestige-journey']+['current-mobile','v20']
  for phase in required:
   for file in ['proof.json','restart-proof.json']:assert native['proofs'][phase+'/'+file]['failures']==0
  if args.pack=='trhgd-character-v20':assert native['proofs']['prestige-journey/proof.json']['earned_xp']==490
  else:
   for phase in ['mechanics','current-signatures','current-mobile','audit','journey','connected']:
    assert native['proofs'][phase+'/proof.json']['rules_ref']==pin
   journey=native['proofs']['journey/proof.json'];assert journey['earned_xp']==490 and journey['xp_injected']is False
   assert {x['history'][0]['class_id']for x in journey['journeys']}=={'warlock','binder','dragonfire-adept'}
   assert native['proofs']['input']['checks']>=17
   cohort+=['warlock','binder','dragonfire-adept']
  cohort+=['scout','rogue','swashbuckler','knight','duelist','arcane-trickster']
  historical=json.loads((root/'docs/implementation/game146/evidence/historical-aura-readiness-review.json').read_text(encoding='utf-8'))
  assert historical['workflow_conclusion']=='success'and historical['comparison']['project_auras_function_unchanged']
  assert all(v['class_row_identical']and v['unchanged_non_equipment_records']for v in historical['comparison']['classes'].values())
  if args.pack=='trhgd-character-v21':
   old_pack=json.loads((root/'data/rules/trhgd-character-v20.json').read_text(encoding='utf-8'))
   old_tables={k:{x['id']:x for x in v}for k,v in old_pack.items()if isinstance(v,list)and v and isinstance(v[0],dict)and'id'in v[0]}
   for id,comparison in historical['comparison']['classes'].items():
    assert t['classes'][id]==old_tables['classes'][id]
    for key in comparison['record_keys']:
     category,record_id=key.split('/',1);assert t[category][record_id]==old_tables[category][record_id]
   text=(root/'scripts/rules/rules_wave_four.gd').read_text(encoding='utf-8');start=text.index('static func project_auras(');end=text.find('\nstatic func ',start+1)
   assert hashlib.sha256(text[start:end if end>=0 else len(text)].encode()).hexdigest()==historical['comparison']['project_auras_sha256']
  cohort+=historical['classes']
# Each item is a specific remaining acceptance gap, not a request for extra counts.
gaps={
'barbarian':['Verify rage-power choices in early/mid/late native combat, including defence trade-offs and expiry; earned journey alone is not every rage variant.'],
'bard':['Tier3 and later repertoire diversity remains thin; verify maintained performance limits with spell actions and rest.'],
'cleric':['Upper tiers8–9 remain scaled templates; domain/channel alternatives require current native tactical coverage.'],
'druid':['Tiers8–9 and permanent companion/form interactions beyond the v18 cohort need targeted acceptance; transformed casting remains explicitly unsupported.'],
'fighter':['Verify equipment-specialisation/feat alternatives in actual mid/late native attacks and protection; legal feat counts alone are insufficient.'],
'monk':['Verify late flurry/ki with unarmed/armour restrictions and reaction competition in actual native combat.'],
'paladin':['Audit smite/divine-grace and touch-healing combinations against actual resources, targets and high-level spell options.'],
'ranger':['Quarry selection uses a bounded raider target profile; verify alternate styles/companion and low-tier nature repertoire before claiming broader enemy typing.'],
'rogue':['Precision currently requires an allied melee threat and once-per-activation gating; verify talent alternatives and repeated/reaction hit boundaries.'],
'sorcerer':['Tiers8–9 and bloodline alternatives remain materially thinner than the v18 tier4–7 cohort.'],
'wizard':['Tiers8–9 and actual school restrictions/specialist option interactions require a bounded repertoire/choice wave.'],
'psion':['Verify the full selected-discipline/augmentation cohort in production controls, power-point exhaustion and manifester cap; no count-only acceptance.'],
'psychic-warrior':['Audit manifested strikes versus physical augmentations and natural forms, including independent multiclass power reserves.'],
'soulknife':['Human playtest clarity/balance remains; v19 is an original bounded mind-blade adaptation, not a complete tabletop Soulknife conversion.'],
'warlock':['Late invocations largely share damage/ward scaling; audit distinctive control/utility consumers and at-will versus limited uses.'],
'scout':['Verify real movement qualification versus merely spent movement tokens, ranged reactions and the advertised mobile-skirmisher feat.'],
'swashbuckler':['Audit finesse/panache and disarming-labelled effects against actual equipment interactions; no claim of a full disarm engine.'],
'knight':['Challenge weakens without a real AI taunt; verify shared-reaction protection/adjacency and late alternatives within that explicit scope.'],
'warblade':['Human stance/riposte readability and balance remain; v19 does not implement a sourcebook manoeuvre deck.'],
'crusader':['Human sustain/balance remains; automatic bounded renewal is an original deterministic adaptation, not a random granted-manoeuvre system.'],
'swordsage':['Human concealment/meditation balance remains; no teleportation or general reaction-choice modal is claimed.'],
'wilder':['Verify surge self-weakening, points and chosen powers together at native low/mid/high levels.'],
'binder':['Pact/covenant actions exist but later signature diversity and persistent pact-choice restrictions need full tactical parity witnesses.'],
'ardent':['Mantles/power eligibility are implemented; verify all advertised mantle restrictions in actual native advancement/UI and multi-manifester builds.'],
'lurk':['Verify veil then melee ambush across hit/miss/visibility and resource exhaustion at representative levels; do not imply a general stealth engine.'],
'erudite':['Verify distinct-per-rest limit with augmented/repeated identities, cold restart and production selector at representative levels.'],
'divine-mind':['Verify aura source, range, refresh, incapacitation and psychic casting interactions, not just derived ally bonuses.'],
'marshal':['Verify maintained aura replacement, shared-party stacking and limited commands after source defeat/return.'],
'beguiler':['Audit illusion/control repertoire against real concealment/status counterplay; no general observer-world illusion engine is claimed.'],
'dragonfire-adept':['Verify breath choices/resistance/area targeting and invocation alternatives at native early/mid/late tiers.'],
'duskblade':['Hit-conditioned channeling is implemented; audit the full eligible spell cohort and late slot/channel combinations in production controls.'],
'spirit-shaman':['Eligible-rest retrieval exists; upper-tier repertoire and spirit-feature interactions need a focused diversity/GUI wave.']}
if args.pack=='trhgd-character-v21':
 for id in ['warlock','binder','dragonfire-adept']:gaps[id]=['The v21 candidate implements new defining choices/effects; matching complete native tactical, input, earned and cold acceptance must be supplied before promotion.']
pgaps={
'duelist':'Verify actual finesse/defensive path powers and their equipment limitations in native earned career combat.',
'eldritch-knight':'Verify martial/spell resource interplay and path action delivery in actual native combat, beyond caster-level derivation.',
'arcane-trickster':'Verify precision/control interaction and once-per-event limits on real hit/miss results.',
'mystic-theurge':'v18 independently validates arcane/divine casting levels/resources; broader path feature combinations and earned continuation need parity review.',
'shadowdancer':'Verify maintained concealment, disruption and resource expiry; do not imply unimplemented teleportation/world stealth.',
'dragon-disciple':'Verify inherited/body/natural-weapon progression with armour suppression and existing transformations.',
'dwarven-defender':'Verify actual defensive stance, movement trade-offs and shared protection in native encounters.',
'pyrokineticist':'Verify fire riders/resistances and psychic resource interaction across all supported path levels.',
'warshaper':'Verify form-dependent benefits, natural weapon reach and reversion/equipment restoration.',
'bonded-summoner':'Verify actual owned summon growth/action/duration/duplication limits beyond catalogue definitions.',
'cerebremancer':'Verify simultaneous known powers and arcane slots with independent ability gates in native path combat.',
'beast-steward':'Verify owned companion growth/special actions, owner defeat and permanent identity across an earned path.',
'cognition-adept':'Verify chosen psychic identities/augmentation and actual advanced path powers, not just resource scaling.',
'war-chanter':'Verify actual performance/aura/command overlap, source defeat and bounded resource recovery.',
'archmage':'Verify permanent selected spell-tier prerequisites and each advanced spell option in native battle.',
'metamind':'Verify finite reclaim reserve and no-rest bypass across cold process restart and earned path combat.',
'abjurant-champion':'Verify channel/ward interactions on real hit/miss and independent spell-resource exhaustion.',
'grove-warden':'Verify owned creatures/forms/rest retrieval with actual path benefits; no unsupported terrain engine.'}
rows=[]
for cls in p['classes']:
 if cls.get('class_kind')not in ['base','prestige']:continue
 id=cls['id'];kind=cls['class_kind'];old=base.get(id,{})
 features={v['id'] for v in cls['features']}
 features.update(f for g in cls.get('career_choices',[])for o in g['options']for f in o['features'])
 abilities=sorted({a for f in features for a in t['features'][f].get('abilities',[])})
 pools=sorted({a for f in features for a in t['features'][f].get('resources',[])})
 refs={}
 for a in abilities:
  v=t['abilities'].get(a,{})
  if v.get('casting_class')==id:refs[str(v['spell_tier'])]=refs.get(str(v['spell_tier']),0)+1
 current=id in cohort and native is not None
 routes=[v for v in prestige['validated'].values()if v['path']==id]if kind=='prestige'else[]
 row=dict(id=id,name=cls['name'],kind=kind,level_cap=cls['max_level'],status='COMPLETE'if current else'PARTIAL',status_scope='Bounded original class identity has native tactical positive/negative, costs, progression, input and cold witnesses; human balance is separate.'if current else'Playable original adaptation; material conditional/repertoire acceptance remains. Historical derivation is not complete parity.',creation=dict(legal_at_level_one=kind=='base',historical_native=old.get('stages',{}).get('selectable',{})if kind=='base'else'Prestige is excluded at birth; permanent requirements and explicit XP-funded advancement only'),advancement=dict(cap=cls['max_level'],historical_kernel_levels=len(old.get('levels',[])),current_native_levels=[1,4,8,13,20]if current else[],ordered_history=True),defining_features=dict(description=cls['description'],source_features=sorted(features),owned_possible_abilities=abilities,scope='Union of alternatives, not one build owning every career choice.'),early_mid_high=dict(historical_level_witnesses=[1,8,20]if old else[],current_tactical=current,scope='Current native receipts identify actual action/hit/cost; level tables alone never promote status.'),resources=[dict(id=a,capacity=t['resources'][a]['capacity'],refresh=t['resources'][a]['refresh'])for a in pools if a in t['resources']],selections=dict(class_skills=cls['class_skills'],career_groups=[g['id']for g in cls.get('career_choices',[])],spell_refs_by_tier=refs),noncombat=dict(scope='Only existing fourteen skills/contextual opportunities; no new class-specific world mechanics.',evidence='scripts/rules/rules_completeness.gd'),persistence=dict(current_native=current,historical_evidence=old.get('stages',{}).get('automated_tested',{})if kind=='base'else'docs/implementation/game126/evidence/native-prestige-witnesses.json',historical_pin=prior['rules_ref']),prestige=dict(requirements=cls['requirements'],historical_reachable_routes=len(routes),historical_pin=prestige['rules_ref'],automatic_entry=False,starting_class=False)if kind=='prestige'else None,evidence=['data/rules/'+args.pack+'.json#classes/'+id,'docs/implementation/game126/current/MATRIX.json#'+('classes/'if kind=='base'else'prestige_paths/')+id],remaining=gaps[id]if kind=='base'else[pgaps[id]])
 if current:
  wave='game148'if args.pack=='trhgd-character-v21'else'game146'if args.pack=='trhgd-character-v20'else'game129'
  row['evidence']+=['docs/implementation/'+wave+'/evidence/'+('final-distribution-proof.json'if wave in ['game146','game148']else'native-distribution-proof.json'),'tests/supernatural_signatures/mechanics.gd'if id in ['warlock','binder','dragonfire-adept']and wave=='game148'else'tests/mobile_precision/mechanics.gd'if id in ['scout','rogue','swashbuckler','knight','duelist','arcane-trickster']else'tests/class_signatures/mechanics_driver.gd']
  row['verified_source']=native['source_commit'];row['remaining']=[]
  row['limitations']=['Scoped original adaptation; final human balance/readability acceptance remains separate. No exhaustive tabletop ability catalogue is claimed.']
  if id in ['warlock','binder','dragonfire-adept']:
   row['advancement']['current_native_levels']=[1,6,12,20]
   row['early_mid_high']['scope']='Current native lawful1/6/12/20 histories/effects; actual late board control/protection/breath, selected choices, costs/counterplay, cold replay and separate earned level8 campaign. Not every sourcebook power.'
   row['limitations'].append('Original bounded invocations/covenants and enemy/ally-centred radius breath. No general stealth/world pacts, daily rebinding, cones or flight.')
  if id in ['scout','rogue','swashbuckler','knight']:
   row['advancement']['current_native_levels']=[1,8,20]
   row['early_mid_high']['scope']='Current native lawful1/8/20 histories; actual Scout/Swashbuckler early/mid/late strikes, Rogue/Knight tactical8, earned level8 and full-process restart. Not every talent permutation.'
  if kind=='prestige':
   row['advancement']['current_native_levels']=list(range(1,cls['max_level']+1))
   row['early_mid_high']['scope']='Permanent prerequisite-directed development route through every path level and total20; separately real XP-funded level8 prestige careers. These scopes are not conflated.'
  if id in ['marshal','war-chanter']:
   row['status_scope']='Original aura/limited-command identity: explicitly reused v14 native tactics and v19 earned/cold path, unchanged defining historical-to-current data/consumer, plus current kernel audit. Not a fresh targeted aura claim.'
   row['early_mid_high']['current_tactical']=False
   row['advancement']['current_native_levels']=list(range(1,21))if id=='marshal'else[]
   row['advancement']['historical_native_path_levels']=list(range(1,6))if id=='war-chanter'else[]
   row['persistence']['current_native']=id=='marshal'
   row['evidence']=[e for e in row['evidence']if e not in ['tests/mobile_precision/mechanics.gd','tests/class_signatures/mechanics_driver.gd','tests/supernatural_signatures/mechanics.gd']]
   row['evidence']+=['tests/character_wave_four/mechanics_driver.gd','tests/character_wave_four/cohort_driver.gd','tests/character_wave_four/earned_driver.gd']
   row['early_mid_high']['scope']='Historical native aura radius/line-of-sight/replacement/source-defeat tests and actual Marshal6/WarChanter1 at360XP; current base kernel/cold audit. Source versions are explicit.'
   row['evidence']+=['docs/implementation/game146/evidence/historical-aura-readiness-review.json','docs/implementation/game146/evidence/historical-aura-native-proof.json','docs/implementation/game146/evidence/historical-aura-earned-proof.json']
   row['limitations'].append('No fresh selected-pack aura interaction receipt; unchanged defining data/consumer and labelled historical native proof are reused.')
  if args.pack=='trhgd-character-v21' and id in ['duelist','arcane-trickster']:
   row['early_mid_high']['scope']='Current21 permanent-prerequisite development route through every path level/total20 and cold replay; explicitly reused unchanged historical20 earned490XP/level8 prestige choice/decline. No fresh21 earned-prestige claim.'
   row['evidence'].append('docs/implementation/game146/evidence/final-distribution-proof.json')
  if args.pack=='trhgd-character-v21' and id not in ['warlock','binder','dragonfire-adept','marshal','war-chanter']:
   row['acceptance_sources']=dict(current='Matching21 signature/mobile tactical and cold fixtures plus all-base kernel audit.',reused='Earlier earned/creator/input acceptance for unchanged definitions and shared controller, with source versions retained. Current21 input witnesses target the new cohort, not every historical button permutation.')
  if id=='knight':row['limitations'].append('Protection is adjacent Guarding with a shared reaction; challenge weakens an enemy. No forced AI targeting is advertised or required.')
  if id in ['swashbuckler','duelist']:row['limitations'].append('Travel Blade/light armour fencing; hit-conditioned control/parry. No general disarm engine or sourcebook panache conversion.')
 rows.append(row)
assert len(rows)==50 and sum(r['kind']=='base'for r in rows)==32 and sum(r['kind']=='prestige'for r in rows)==18
queue=[dict(priority=1,cohort=['scout','swashbuckler','rogue','knight','duelist','arcane-trickster'],goal='Resolve actual movement, precision, equipment/control and shared-reaction trigger acceptance; reuse v19 authoritative event consumers.'),dict(priority=2,cohort=['warlock','binder','dragonfire-adept','metamind','pyrokineticist'],goal='Distinct pact/invocation signature actions, finite/at-will boundaries and late conditional consumers.'),dict(priority=3,cohort=['bard','beguiler','spirit-shaman','duskblade','wizard','cleric','sorcerer','druid'],goal='Close actual supported-tier repertoire and specialist restrictions under GAME-128; no arbitrary spell count target.'),dict(priority=4,cohort=['psion','psychic-warrior','wilder','ardent','lurk','erudite','divine-mind','marshal','cerebremancer','cognition-adept','war-chanter'],goal='Native selected-power/point/aura and hybrid interaction acceptance; fix only observed deficits.'),dict(priority=5,cohort=['barbarian','fighter','monk','paladin','ranger','dragon-disciple','dwarven-defender','warshaper','bonded-summoner','beast-steward','archmage','eldritch-knight','shadowdancer','mystic-theurge','abjurant-champion','grove-warden'],goal='Close remaining explicit feature/gear/creature/path witnesses, then human acceptance and milestone exit review.' )]
if native and args.pack in ['trhgd-character-v20','trhgd-character-v21']:
 queue=queue[1:]
 for i,q in enumerate(queue,1):
  q['priority']=i;q['cohort']=[id for id in q['cohort']if id not in ['marshal','war-chanter']]
 queue[0]['cohort']=['warlock','binder','dragonfire-adept']
 queue[0]['goal']='Audit defining pact/invocation/breath consumers and fix the strongest2–4 actual gaps; real at-will/finite resource boundaries, selected specialisations and native tactical counterplay. No roster growth or decorative powers.'
 queue[2]['cohort']+=['metamind','pyrokineticist']
if native and args.pack=='trhgd-character-v21':
 queue=queue[1:]
 queue.insert(1,dict(cohort=['wizard','cleric','sorcerer','druid','duskblade'],goal='Audit remaining upper supported-tier repertoire and real school/domain/bloodline/channel restrictions; fix material gaps rather than expanding counts.'))
 queue[0]['cohort']=['bard','beguiler','spirit-shaman']
 queue[0]['goal']='Audit maintained performance, save-aware illusion/control and rest-bound retrieval; repair2–4 strongest executable identity/repertoire gaps using existing authority.'
 for i,q in enumerate(queue,1):q['priority']=i;q['cohort']=[id for id in q['cohort']if id not in cohort]
 assert {x['id']for x in rows if x['status']=='PARTIAL'}<=set(id for q in queue for id in q['cohort'])
report=dict(schema_version=1,rules_ref=pin,source_pack_sha256=hashlib.sha256((root/('data/rules/'+args.pack+'.json')).read_bytes()).hexdigest(),policy=dict(COMPLETE='Actual meaningful class identity with scoped tactical/choice/resource/persistence evidence; not sourcebook completeness or final human balance.',PARTIAL='Playable but material mechanics or practical acceptance missing.',BLOCKED='A defining advertised capability is broken/absent; requires a reproduced blocker, not merely no new action at a level.'),classes=rows,repair_queue=queue,milestone_complete=False,programme_source_occurrences=760,world_transition='GAME-142 then GAME-141 only once all supported-class functional gates and GAME-123 acceptance are met; source catalogue is not that gate.')
out=root/'docs/implementation/game129';(out/'READINESS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
lines=['# Supported character readiness','', 'Generated by tools/character-content/build-readiness.py. All50 supported careers are reassessed from their definitions and labelled evidence. Historical v16 source/kernel evidence is labelled and never substituted for current native tactical proof. COMPLETE means the scoped original identity, not every tabletop rule or final human balance. The research index is a separate ledger.','', '| Class | Kind | Status | Remaining acceptance |','|---|---|---|---|']
for r in rows:lines.append('| '+r['name']+' | '+r['kind']+' | '+r['status']+' | '+' '.join(r['remaining'])+' |')
lines+=['','## Finite repair queue','']
for q in queue:lines.append(str(q['priority'])+'. '+', '.join(q['cohort'])+': '+q['goal'])
lines+=['','No added roster/source-index breadth is required to exit the current milestone. Evaluate this matrix after each bounded code wave; do not expand counts indefinitely or declare parity from level20 snapshots.']
(out/'READINESS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n');print(json.dumps(dict(classes=len(rows),statuses={s:sum(r['status']==s for r in rows)for s in ['COMPLETE','PARTIAL','BLOCKED']})))
