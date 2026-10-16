"""Preserve760source occurrences; promote only the first mapped occurrence after a Windows native receipt."""
from pathlib import Path
import json,argparse,subprocess
root=Path(__file__).resolve().parents[2]
a=argparse.ArgumentParser();a.add_argument('--native-windows');args=a.parse_args()
p=json.loads((root/'data/rules/trhgd-character-v15.json').read_text(encoding='utf-8'))
pin=next(x['rules_ref']for x in json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'))['packs']if x['rules_ref']['pack_id']==p['pack_id'])
validated=bool(args.native_windows)
receipts=[]
if validated:
 for file in [args.native_windows]:
  receipt=json.loads(Path(file).read_text(encoding='utf-8'))
  assert receipt['target']=='windows-x64'
  assert receipt['source_commit']==subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
  assert receipt['production_launch'] and receipt['empty_path'] and receipt['separate_process_restart']
  assert all(r['failures']==0 and r['checks']>0 and r['rules_ref']==pin for r in receipt['proofs'].values())
  receipts.append(dict(source_commit=receipt['source_commit'],sha256=receipt['sha256']))
path=root/'docs/implementation/game104/COVERAGE.json';coverage=json.loads(path.read_text(encoding='utf-8'))
mapping={'base_class-duskblade':('classes','duskblade'),'base_class-spirit-shaman':('classes','spirit-shaman'),'prestige-abjurant-champion':('classes','abjurant-champion'),'prestige-holt-warden':('classes','grove-warden'),'ancestry-catfolk':('ancestries','heritage-catfolk'),'ancestry-darfellan':('ancestries','heritage-riverborn'),'ancestry-killoren':('ancestries','heritage-wildborn'),'ancestry-nezumi':('ancestries','heritage-ratfolk')}
found=set();evidence=['tests/character_wave_five/mechanics_driver.gd','tests/character_wave_five/earned_driver.gd','docs/implementation/game112-wave-five/TESTING.md']
for row in coverage['entries']:
 if row['id']not in mapping:continue
 found.add(row['id']);category,id=mapping[row['id']];definition=next(x for x in p[category]if x['id']==id)
 row.update(status='playable'if validated else'implemented',playable=validated,evidence=evidence,blocking_subsystems=['Bounded original adaptation; remaining source-concept mechanics and human review']if validated else['Source and native acceptance pending'],next_action='Review this bounded adaptation; preserve remaining source variants and Wave Five objectives.')
 row['intended_implementation']={'kind':'earned_prestige_path'if definition.get('class_kind')=='prestige'else'distinct_class'if category=='classes'else'distinct_ancestry','production_id':id}
 row['implementation']={'pack_id':p['pack_id'],'level_cap':definition.get('max_level',0),'original_adaptation':True,'complete_sourcebook_conversion':False}
 row['source_variants'][0].update(status=row['status'],playable=validated,production_id=id,evidence=evidence,bounded_original_adaptation=True,complete_sourcebook_conversion=False)
assert found==set(mapping),set(mapping)-found
assert len(coverage['entries'])==720 and sum(len(r['source_variants'])for r in coverage['entries'])==760
coverage['wave_five']={'candidate_pack':p['pack_id'],'baseline_pack':'trhgd-character-v14','status':'native_validated'if validated else'implementation_under_validation','new_source_rows':list(mapping),'native_receipts':receipts,'all_occurrences_preserved':True,'complete_wave':False,'complete_programme':False}
path.write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
