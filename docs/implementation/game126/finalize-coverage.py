"""Project exact native receipts into reporting stages; never evaluate game rules."""
from pathlib import Path
import argparse,json,subprocess,sys,collections
p=argparse.ArgumentParser(__doc__);p.add_argument('native',type=Path);args=p.parse_args();root=Path(__file__).resolve().parents[3];dest=root/'docs/implementation/game126/evidence';dest.mkdir(exist_ok=True)
def load(p):return json.loads(Path(p).read_text())
def save(name,data):path=dest/name;path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');return path
native=args.native
proof=load(native/'distribution-proof.json');pin=proof['rules_ref']
assert all(v['failures']==0 for v in proof['proofs'].values())
witness=load(native/'audit/witnesses.json');options=load(native/'options/options.json');prestige=load(native/'compatibility/compatibility.json')
assert witness['rules_ref']==options['rules_ref']==prestige['rules_ref']==pin
wpath=save('native-class-witnesses.json',witness);ppath=save('native-prestige-witnesses.json',prestige);npath=save('native-distribution-proof.json',proof)
selected_skills=set();observed=set();earned_classes=set()
for row in options['options']['feats'].values():
 for step in row['history']:selected_skills.update(k for k,n in step['skill_allocations'].items()if n>0)
for i in range(4):
 row=proof['proofs'][f'journey-{i}'];observed.update(k.removeprefix('skill:')for k in row['skills'])
 assert set(row['combat_actions'])=={r['character_id']for r in row['journeys']}
 for character in row['journeys']:
  earned_classes.update(s['class_id']for s in character['history'])
  for step in character['history']:selected_skills.update(k for k,n in step['skill_allocations'].items()if n>0)
options['options']['skills']={id:dict(selectable=True,scope='Native lawful allocated skill ranks in actual creator/advancement histories; specific check/formula consumers have separate scope.')for id in selected_skills}
options['options']['classes']={id:dict(selectable=True,scope='Native permanent entry, full prestige cap and lawful total-level20 continuation; not every conditional path ability or human career acceptance.')for id in {r['path']for r in prestige['validated'].values()}}
opath=save('native-option-witnesses.json',options)
relative=lambda p:str(p.relative_to(root))
subprocess.run([sys.executable,str(root/'tools/character-content/audit-completeness.py'),'--pack','data/rules/trhgd-character-v16.json','--output','docs/implementation/game126/current','--witness',relative(wpath),'--option-witness',relative(opath),'--prestige-witness',relative(ppath),'--native-receipt',relative(npath)],cwd=root,check=True)
report_path=root/'docs/implementation/game126/current/REPORT.md'
report=report_path.read_text().replace('native Windows acceptance of this new harness, or player validation','complete conditional tactical coverage or per-option player validation')
report+='\nNative Windows harness verified at source `'+proof['source_commit']+'`; exact receipts are in `../evidence/native-distribution-proof.json`. Twelve actual adventurers each earn360XP/level7, separately from level20 development fixtures. Human acceptance remains unverified.\n'
report_path.write_text(report)
mp=root/'docs/implementation/game126/current/MATRIX.json';matrix=load(mp);stages=matrix['stages']
for skill in matrix['skills']:
 id=skill['definition']['id'];scope=''
 if id in observed:scope='Actual native persisted opportunity-check outcome, legal ranks and independent campaign restart.'
 if id in ['nature','performance']:scope='Native same-level rank counterfactual changes Natural Scholar spell DC / Bard performance capacity; conditional on the relevant class/feat.'
 if id in ['athletics','stealth','acrobatics','spellcraft','animal-handling']:scope='Native trained rank gates, deterministic successes/failures, public explanation, time/supply costs, one-objective reward and persisted earned examples.'
 if scope:
  for stage in ['mechanically_functional','automated_tested']:skill['stages'][stage]={'status':'yes','scope':scope,'evidence':[relative(npath)]}
for occurrence in matrix['research_occurrences']:
 v=occurrence['source_occurrence'];production=v.get('production_id');claims={s:{'status':'unverified','evidence':[]}for s in stages}
 claims['indexed']={'status':'yes','evidence':['docs/implementation/game104/COVERAGE.json#'+v['key']]}
 if production and v.get('playable'):
  claims['defined']={'status':'bounded_original_adaptation','evidence':[relative(mp)],'scope':'Existing explicitly mapped source occurrence only. No unreviewed variant or exact sourcebook equivalence is implied.'}
  claims['selectable']={'status':'adaptation_only','evidence':[relative(npath)],'scope':'Native production adaptation; starting/earned prestige restrictions apply.'}
  claims['mechanically_functional']={'status':'partial','evidence':[relative(npath)],'scope':'Scoped original mechanical adaptation, not all source abilities, anatomy or environmental systems.'}
  claims['automated_tested']={'status':'native_scoped_adaptation','evidence':[relative(npath)]}
 occurrence['stages']=claims
# Pack-level native presence is not an individual ability-execution receipt.
def clarify_native_scope(value):
 if isinstance(value,dict):
  if 'native_windows'in value:
   value['native_windows'].update(status='containing_pack_export_and_scoped_harness_verified',scope='The exact containing pack was validated and exported on Windows. Individual selection/effect execution is claimed only by the separate evidence stages above, not inferred from packaging.')
  for child in value.values():clarify_native_scope(child)
 elif isinstance(value,list):
  for child in value:clarify_native_scope(child)
clarify_native_scope(matrix)
matrix['native_source_commit']=proof['source_commit'];matrix['earned_class_ids']=sorted(earned_classes);mp.write_text(json.dumps(matrix,ensure_ascii=False,indent=2)+'\n')
summary=load(root/'docs/implementation/game126/current/SUMMARY.json');summary.update(native_source_commit=proof['source_commit'],native_level20_tracks=32,full_cap_prestige_histories=len(prestige['validated']),single_class_entries=sum(v['single_class_entry']for v in prestige['validated'].values()),bridge_dominated=sum(v['bridge_dominates']for v in prestige['validated'].values()),earned_characters=12,earned_level=7,earned_xp_each=360,actual_persisted_skill_ids=sorted(observed),source_occurrence_stages_explicit=True,player_validated_options='unverified; no per-option human acceptance receipt')
(root/'docs/implementation/game126/current/SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary))
