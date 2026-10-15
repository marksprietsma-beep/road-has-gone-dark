"""Keep all research occurrences. Candidate status must not imply native playability."""
from pathlib import Path
import json,argparse
root=Path(__file__).resolve().parents[2]
a=argparse.ArgumentParser();a.add_argument('--validated',action='store_true');args=a.parse_args()
path=root/'docs/implementation/game104/COVERAGE.json';coverage=json.loads(path.read_text(encoding='utf-8'))
additions={'base_class-erudite':('classes','erudite'),'base_class-divine-mind':('classes','divine-mind'),'base_class-marshal':('classes','marshal'),'prestige-illithid-slayer':('classes','cognition-adept'),'ancestry-bugbear':('ancestries','heritage-bugbear'),'ancestry-ogre':('ancestries','heritage-ogre'),'ancestry-half-giant':('ancestries','heritage-half-giant'),'ancestry-troglodyte':('ancestries','heritage-troglodyte'),'base_class-beguiler':('classes','beguiler'),'base_class-dragonfire-adept':('classes','dragonfire-adept'),'prestige-war-chanter':('classes','war-chanter'),'prestige-archmage':('classes','archmage'),'prestige-metamind':('classes','metamind'),'ancestry-air-genasi':('ancestries','heritage-air-genasi'),'ancestry-earth-genasi':('ancestries','heritage-earth-genasi'),'ancestry-fire-genasi':('ancestries','heritage-fire-genasi'),'ancestry-water-genasi':('ancestries','heritage-water-genasi')}
p=json.loads((root/'data/rules/trhgd-character-v14.json').read_text(encoding='utf-8'))
for row in coverage['entries']:
 if row['id']not in additions:continue
 category,id=additions[row['id']];definition=next(x for x in p[category]if x['id']==id)
 evidence=['tests/character_wave_four/mechanics_driver.gd','tests/character_wave_four/cohort_driver.gd','tests/character_wave_four/earned_driver.gd','docs/implementation/game112-wave-four/DELIVERY.md']if args.validated else[]
 row.update(status='playable'if args.validated else'implemented',playable=args.validated,evidence=evidence,blocking_subsystems=['Bounded adaptation; full source concept remains incomplete']if args.validated else['Focused mechanics and native acceptance pending'],next_action='Review bounded mechanics and expand source-concept coverage.'if args.validated else'Finish focused/native verification before promoting any mapping.')
 row['intended_implementation']={'kind':'earned_prestige_path'if definition.get('class_kind')=='prestige'else'distinct_class'if category=='classes'else'distinct_ancestry','production_id':id}
 row['implementation']={'pack_id':'trhgd-character-v14','level_cap':definition.get('max_level',0),'original_adaptation':True,'complete_sourcebook_conversion':False}
 row['source_variants'][0].update(status=row['status'],playable=args.validated,production_id=id,evidence=evidence,bounded_original_adaptation=True,complete_sourcebook_conversion=False)
coverage['wave_four']={'candidate_pack':'trhgd-character-v14','baseline_pack':'trhgd-character-v13','status':'native_validated'if args.validated else'implementation_under_validation','new_source_rows':list(additions),'all_occurrences_preserved':True,'complete_programme':False}
assert len(coverage['entries'])==720 and sum(len(r['source_variants'])for r in coverage['entries'])==760
path.write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
