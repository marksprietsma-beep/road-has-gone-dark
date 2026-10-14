"""Keep 760 occurrences; candidate status remains distinct from native playable status."""
from pathlib import Path
import json,argparse
root=Path(__file__).resolve().parents[2]
a=argparse.ArgumentParser();a.add_argument('--validated',action='store_true');args=a.parse_args()
path=root/'docs/implementation/game104/COVERAGE.json';coverage=json.loads(path.read_text());pack=json.loads((root/'data/rules/trhgd-character-v13.json').read_text())
additions={'base_class-ardent':('classes','ardent'),'base_class-lurk':('classes','lurk'),'prestige-beast-heart-adept':('classes','beast-steward'),'prestige-cerebremancer':('classes','cerebremancer'),'ancestry-elan':('ancestries','heritage-elan'),'ancestry-xeph':('ancestries','heritage-xeph'),'ancestry-maenad':('ancestries','heritage-maenad'),'ancestry-dromite':('ancestries','heritage-dromite')}
evidence=['tests/character_psychic/mechanics_driver.gd','tests/character_psychic/journey_driver.gd','docs/implementation/game112-wave-three/DELIVERY.md']
for row in coverage['entries']:
 if row['id']not in additions:continue
 category,id=additions[row['id']];definition=next(x for x in pack[category]if x['id']==id)
 row.update(status='playable'if args.validated else'implemented',playable=args.validated,evidence=evidence if args.validated else[],blocking_subsystems=['Native Windows/Linux validation pending']if not args.validated else['Bounded original adaptation; human review and broader source-concept completion remain'],next_action='Verify actual native mechanics/journey/restart.'if not args.validated else'Expand bounded source-concept coverage without counting other variants as completed.')
 row['intended_implementation']={'kind':'earned_prestige_path'if definition.get('class_kind')=='prestige'else'distinct_class'if category=='classes'else'distinct_ancestry','production_id':id}
 row['implementation']={'pack_id':'trhgd-character-v13','level_cap':definition.get('max_level',0),'original_adaptation':True,'complete_sourcebook_conversion':False,'mechanics_test':evidence[0],'tactical_test':evidence[1],'art_status':'neutral_humanoid_fallback'if category=='ancestries'else'neutral_humanoid_lpc'}
 row['source_variants'][0].update(status=row['status'],playable=args.validated,production_id=id,evidence=evidence if args.validated else[],bounded_original_adaptation=True,complete_sourcebook_conversion=False)
coverage['wave_three']={'candidate_pack':'trhgd-character-v13','baseline_pack':'trhgd-character-v12','status':'native_validated'if args.validated else'implementation_under_validation','before':{'base_classes':23,'prestige_classes':10,'ancestry_families':21,'heritages':30,'feats':45,'skills':14,'creatures':3,'selectable_powers':0},'after':{'base_classes':sum(x.get('class_kind')=='base'for x in pack['classes']),'prestige_classes':sum(x.get('class_kind')=='prestige'for x in pack['classes']),'ancestry_families':len({x['people_id']for x in pack['ancestries']}),'heritages':len(pack['ancestries']),'feats':len(pack['feats']),'skills':len(pack['skills']),'creatures':len(pack['creatures']),'selectable_powers':len(pack['psychic_powers']),'career_choices':sum(len(x.get('career_choices',[]))for x in pack['classes'])},'new_source_rows':list(additions),'all_occurrences_preserved':True,'complete_programme':False}
path.write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n');print(json.dumps(coverage['wave_three']))
